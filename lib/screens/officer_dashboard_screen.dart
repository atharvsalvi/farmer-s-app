import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmer/screens/login_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  int _currentIndex = 0; // 0: Dashboard, 1: Map
  Map<String, dynamic>? _stats;
  List<dynamic> _advisories = [];
  bool _isLoading = true;

  // Map State
  final MapController _mapController = MapController();
  List<CircleMarker> _circles = [];
  LatLng _initialCenter = const LatLng(19.0760, 72.8777); // Default Mumbai
  Map<String, List<dynamic>> _regionCrops = {};
  Map<String, LatLng> _regionCoordinates = {};
  String? _selectedRegion;
  bool _isLoadingMap = true;

  // Form Controllers
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _regionController = TextEditingController();
  String _selectedSeverity = 'Info';

  @override
  void initState() {
    super.initState();
    _fetchData();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _initialCenter = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchStats(), _fetchAdvisories(), _fetchFarmers()]);
    setState(() => _isLoading = false);
  }

  String get _baseUrl {
    // Use Deployed Backend
    return 'http://localhost:3000';
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _fetchStats() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/officer/stats'));
      if (response.statusCode == 200) {
        setState(() {
          _stats = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching stats: $e');
    }
  }

  Future<void> _fetchAdvisories() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/advisories'));
      if (response.statusCode == 200) {
        setState(() {
          _advisories = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching advisories: $e');
    }
  }

  Future<void> _fetchFarmers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/officer/farmers'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> farmers = json.decode(response.body);
        await _processFarmersForMap(farmers);
      }
    } catch (e) {
      print('Error fetching farmers: $e');
    }
  }

  Future<void> _processFarmersForMap(List<dynamic> farmers) async {
    Map<String, LatLng> regionCoordinates = {};
    Map<String, List<dynamic>> regionCrops = {};

    // 1. Group by Region (Location)
    for (var farmer in farmers) {
      String location = farmer['location'] ?? 'Unknown';
      if (location == 'Unknown') continue;

      // Aggregate crops
      if (!regionCrops.containsKey(location)) {
        regionCrops[location] = [];
      }
      if (farmer['crops'] != null) {
        regionCrops[location]!.addAll(farmer['crops']);
      }

      // Geocode if not already done
      if (!regionCoordinates.containsKey(location)) {
        try {
          // Check for known demo locations to save API calls/errors
          if (location.toLowerCase().contains('mumbai')) {
            regionCoordinates[location] = const LatLng(19.0760, 72.8777);
          } else if (location.toLowerCase().contains('pune')) {
            regionCoordinates[location] = const LatLng(18.5204, 73.8567);
          } else if (location.toLowerCase().contains('nashik')) {
            regionCoordinates[location] = const LatLng(19.9975, 73.7898);
          } else {
            // Real Geocoding
            List<Location> locations = await locationFromAddress(location);
            if (locations.isNotEmpty) {
              regionCoordinates[location] = LatLng(
                locations.first.latitude,
                locations.first.longitude,
              );
            }
          }
        } catch (e) {
          print('Error geocoding $location: $e');
        }
      }
    }

    // 2. Create Circles
    List<CircleMarker> circles = [];
    regionCoordinates.forEach((region, latLng) {
      circles.add(
        CircleMarker(
          point: latLng,
          color: Colors.blue.withOpacity(0.3),
          borderColor: Colors.blue,
          borderStrokeWidth: 2,
          radius: 40, // Fixed radius for visibility
          useRadiusInMeter: false, // Pixel radius for better visibility
        ),
      );
    });

    if (mounted) {
      setState(() {
        _circles = circles;
        _regionCrops = regionCrops;
        _regionCoordinates = regionCoordinates;
        _isLoadingMap = false;
      });
    }
  }

  Future<void> _sendAdvisory({String? reportId}) async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty)
      return;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/officer/advisories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _titleController.text,
          'message': _messageController.text,
          'targetRegion': _regionController.text.isEmpty
              ? 'All'
              : _regionController.text,
          'severity': _selectedSeverity,
        }),
      );

      if (response.statusCode == 200) {
        // If this advisory was triggered by a report, delete the report
        if (reportId != null) {
          await http.delete(
            Uri.parse('$_baseUrl/api/officer/reports/$reportId'),
          );
          _fetchStats(); // Refresh stats to remove report from list
        }

        Navigator.pop(context); // Close dialog
        _fetchAdvisories(); // Refresh list
        _clearForm();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Advisory Sent!")));
      }
    } catch (e) {
      print('Error sending advisory: $e');
    }
  }

  Future<void> _deleteAdvisory(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/officer/advisories/$id'),
      );
      if (response.statusCode == 200) {
        _fetchAdvisories(); // Refresh list
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Advisory Deleted")));
      }
    } catch (e) {
      print('Error deleting advisory: $e');
    }
  }

  void _clearForm() {
    _titleController.clear();
    _messageController.clear();
    _regionController.clear();
    setState(() => _selectedSeverity = 'Info');
  }

  void _showSendAdvisoryDialog({String? reportId}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Send Targeted Alert",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Alert Title",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: "Message",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _regionController,
                decoration: const InputDecoration(
                  labelText: "Target Region (Optional)",
                  hintText: "e.g., Nashik, Pune",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedSeverity,
                decoration: const InputDecoration(
                  labelText: "Severity",
                  border: OutlineInputBorder(),
                ),
                items: ['Info', 'Warning', 'Critical', 'High'].map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (v) => setState(() => _selectedSeverity = v!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => _sendAdvisory(reportId: reportId),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
            ),
            child: const Text("Send Alert"),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    if (_isLoadingMap) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          flex: 2,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 10.0,
              onTap: (tapPosition, point) {
                setState(() => _selectedRegion = null);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.farmer',
              ),
              CircleLayer(circles: _circles),
              MarkerLayer(
                markers: _regionCoordinates.entries.map((entry) {
                  return Marker(
                    point: entry.value,
                    width: 80,
                    height: 80,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRegion = entry.key;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedRegion != null
                      ? 'Crops in $_selectedRegion'
                      : 'Select a region on the map',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (_selectedRegion != null &&
                    _regionCrops.containsKey(_selectedRegion))
                  Expanded(
                    child: _buildGroupedCropList(
                      _regionCrops[_selectedRegion]!,
                    ),
                  )
                else if (_selectedRegion == null)
                  const Text(
                    'Tap on a highlighted circle to see crop details.',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedCropList(List<dynamic> crops) {
    // Group crops by name
    Map<String, List<dynamic>> groupedCrops = {};
    for (var crop in crops) {
      String name = crop is String ? crop : (crop['name'] ?? 'Unknown');
      if (!groupedCrops.containsKey(name)) {
        groupedCrops[name] = [];
      }
      groupedCrops[name]!.add(crop);
    }

    return ListView.builder(
      itemCount: groupedCrops.keys.length,
      itemBuilder: (context, index) {
        String cropName = groupedCrops.keys.elementAt(index);
        List<dynamic> cropInstances = groupedCrops[cropName]!;
        int infectedCount = cropInstances
            .where((c) => c is Map && c['health'] == 'Infected')
            .length;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: const Icon(Icons.grass, color: Colors.green),
            title: Text("$cropName (${cropInstances.length})"),
            subtitle: infectedCount > 0
                ? Text(
                    "$infectedCount Infected",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : const Text(
                    "All Healthy",
                    style: TextStyle(color: Colors.green),
                  ),
            children: cropInstances.map((crop) {
              if (crop is String)
                return const SizedBox.shrink(); // Legacy string data

              bool isInfected = crop['health'] == 'Infected';

              return ListTile(
                title: Text("Sown: ${crop['sowingDate'] ?? '-'}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Stage: ${crop['stage'] ?? '-'}"),
                    if (isInfected) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Disease: ${crop['diseaseName']}",
                        style: const TextStyle(color: Colors.red),
                      ),
                      Text(
                        "Reason: ${crop['reason']}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
                trailing: isInfected
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image, color: Colors.blue),
                            onPressed: () => _showInfectedCropImage(crop),
                            tooltip: "View Image",
                          ),
                          IconButton(
                            icon: const Icon(Icons.campaign, color: Colors.red),
                            onPressed: () => _sendInfectionAlert(crop),
                            tooltip: "Send Alert",
                          ),
                        ],
                      )
                    : const Chip(
                        label: Text("Healthy"),
                        backgroundColor: Colors.greenAccent,
                      ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showInfectedCropImage(dynamic crop) {
    if (crop['imageUrl'] == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              '$_baseUrl/uploads/${crop['imageUrl']}',
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.broken_image, size: 100),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Disease: ${crop['diseaseName']}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendInfectionAlert(dynamic crop) {
    _titleController.text = "Disease Alert: ${crop['diseaseName']}";
    _messageController.text =
        "A case of ${crop['diseaseName']} has been detected in your area (${_selectedRegion}).\n\nReason: ${crop['reason']}\n\nPreventive Measures: ${crop['preventiveMeasures']}";
    _regionController.text = _selectedRegion ?? "";
    setState(() => _selectedSeverity = 'High');

    _showSendAdvisoryDialog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Agricultural Officer',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _currentIndex == 0
          ? (_isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCards(),
                          const SizedBox(height: 20),
                          _buildSectionHeader("Active Alerts"),
                          _buildActiveAlerts(),
                          const SizedBox(height: 20),
                          const SizedBox(height: 20),
                          _buildSectionHeader("Recent Reports"),
                          _buildRecentReports(),
                        ],
                      ),
                    ),
                  ))
          : _buildMapTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map View'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showSendAdvisoryDialog,
              label: const Text("Send Alert"),
              icon: const Icon(Icons.campaign),
              backgroundColor: Colors.blue.shade800,
            )
          : null,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActiveAlerts() {
    if (_advisories.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "No active alerts.",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Column(
      children: _advisories.map((alert) {
        Color severityColor = Colors.blue;
        if (alert['severity'] == 'Critical' || alert['severity'] == 'High')
          severityColor = Colors.red;
        if (alert['severity'] == 'Warning') severityColor = Colors.orange;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: severityColor.withOpacity(0.5)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: severityColor.withOpacity(0.2),
              child: Icon(Icons.notifications_active, color: severityColor),
            ),
            title: Text(
              alert['title'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert['message']),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      "Region: ${alert['targetRegion'] ?? 'All'}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteAdvisory(alert['id']),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Total Reports",
            _stats?['totalReports']?.toString() ?? "0",
            Icons.assessment,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            "Active Alerts",
            _advisories.length.toString(),
            Icons.warning_amber,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildRecentReports() {
    final List<dynamic> reports = _stats?['recentReports'] ?? [];
    if (reports.isEmpty) return const Text("No recent reports.");

    return Column(
      children: reports.map((r) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            onTap: () {
              // Populate alert dialog with report details
              _titleController.text = "Disease Alert: ${r['disease']}";
              // Use stored reason/prevention if available, else generic
              String reason = r['reason'] ?? "Detected via image analysis.";
              String prevention =
                  r['preventiveMeasures'] ?? "Consult an expert.";

              _messageController.text =
                  "A case of ${r['disease']} has been detected in ${r['location']}.\n\nReason: $reason\n\nPreventive Measures: $prevention";
              _regionController.text = r['location'] ?? "";
              setState(() => _selectedSeverity = 'High');

              _showSendAdvisoryDialog(reportId: r['id']);
            },
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.bug_report, color: Colors.white),
              ),
              title: Text(
                r['disease'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "${r['location']} • Confidence: ${(r['confidence'] * 100).toStringAsFixed(1)}%",
              ),
              trailing: Text(
                r['timestamp'] != null
                    ? r['timestamp'].toString().substring(0, 10)
                    : 'Just now',
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
