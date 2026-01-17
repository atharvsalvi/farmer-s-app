import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _advisories = [];
  bool _isLoading = true;

  // Form Controllers
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _regionController = TextEditingController();
  String _selectedSeverity = 'Info';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchStats(), _fetchAdvisories()]);
    setState(() => _isLoading = false);
  }

  String get _baseUrl {
    // Use Deployed Backend
    return 'https://farmer-backend-5rka.onrender.com';
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

  Future<void> _sendAdvisory() async {
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

  void _showSendAdvisoryDialog() {
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
            onPressed: _sendAdvisory,
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
      ),
      body: _isLoading
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
                    _buildSectionHeader("Disease Outbreaks"),
                    _buildDiseaseChart(),
                    const SizedBox(height: 20),
                    _buildSectionHeader("Recent Reports"),
                    _buildRecentReports(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSendAdvisoryDialog,
        label: const Text("Send Alert"),
        icon: const Icon(Icons.campaign),
        backgroundColor: Colors.blue.shade800,
      ),
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

  Widget _buildDiseaseChart() {
    final Map<String, dynamic> counts = _stats?['diseaseCounts'] ?? {};
    if (counts.isEmpty) return const Text("No disease data yet.");

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: counts.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(e.key, style: const TextStyle(fontSize: 12)),
                ),
                Expanded(
                  flex: 3,
                  child: LinearProgressIndicator(
                    value: 1.0,
                    color: Colors.redAccent,
                    backgroundColor: Colors.red.withOpacity(0.1),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  e.value.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }).toList(),
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
        );
      }).toList(),
    );
  }
}
