import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

import 'package:farmer/screens/market_screen.dart';
import 'package:farmer/screens/purchase_history_screen.dart';
import 'package:farmer/screens/add_crop_screen.dart';
import 'package:farmer/screens/disease_detection_screen.dart';
import 'package:farmer/providers/language_provider.dart';
import 'package:farmer/widgets/auto_translated_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmer/screens/login_screen.dart';
import 'package:farmer/screens/ai_suggestions_screen.dart';

import 'package:farmer/services/api_constants.dart';

class HomeScreen extends StatefulWidget {
  final String? phone;
  const HomeScreen({super.key, this.phone});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _marketCropController = TextEditingController();
  String? marketResult;

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // Weather State
  String _temperature = '--';
  String _condition = 'Loading...';
  String _location = 'Locating...';
  IconData _weatherIcon = Icons.cloud;
  bool _isLoadingWeather = true;

  // Advisories State
  List<dynamic> _advisories = [];
  bool _isLoadingAdvisories = true;

  // User Data State
  List<dynamic> _previousCrops = [];
  bool _isLoadingUserData = true;

  // Crops State
  List<Map<String, dynamic>> _currentCrops = [
    {
      'name': 'Wheat',
      'line1': 'Sown: 10 Jan',
      'line2': 'Stage: Germination',
      'color': Colors.orange,
    },
    {
      'name': 'Mustard',
      'line1': 'Sown: 15 Jan',
      'line2': 'Stage: Seedling',
      'color': Colors.yellow,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _getLocationAndWeather();
    await _fetchAdvisories();
    if (widget.phone != null) {
      await _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/user/${widget.phone}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _previousCrops = data['previousCrops'] ?? [];
            // Also update current crops if available in DB
            if (data['crops'] != null) {
              List<dynamic> dbCrops = data['crops'];
              _currentCrops = dbCrops
                  .map((c) {
                    if (c is String) {
                      // Legacy string format
                      return {
                        'name': c,
                        'line1': 'Active',
                        'line2': 'Healthy',
                        'color': Colors.green,
                      };
                    } else {
                      // New object format
                      return {
                        'name': c['name'],
                        'line1': 'Sown: ${c['sowingDate']}',
                        'line2': 'Stage: ${c['stage']}',
                        'health': c['health'] ?? 'Healthy',
                        'color': c['color'] == 'orange'
                            ? Colors.orange
                            : (c['color'] == 'yellow'
                                  ? Colors.yellow
                                  : Colors.green),
                      };
                    }
                  })
                  .toList()
                  .cast<Map<String, dynamic>>();
            }
            _isLoadingUserData = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
      if (mounted) setState(() => _isLoadingUserData = false);
    }
  }

  Future<void> _getLocationAndWeather() async {
    try {
      // 1. Request Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // 2. Get Position
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // 3. Get City Name (Reverse Geocoding)
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty) {
            String city =
                placemarks.first.locality ??
                placemarks.first.subAdministrativeArea ??
                'Unknown';
            setState(() {
              _location = city;
            });
          }
        } catch (e) {
          print('Geocoding error (likely missing API key on Web): $e');
          // Fallback: Use free API for Web/Dev
          try {
            final url = Uri.parse(
              'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${position.latitude}&longitude=${position.longitude}&localityLanguage=en',
            );
            final response = await http.get(url);
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              String city =
                  data['locality'] ??
                  data['city'] ??
                  data['principalSubdivision'] ??
                  'Mumbai';
              print('Fallback Geocoding found: $city');
              setState(() => _location = city);
            } else {
              setState(
                () => _location = 'Mumbai',
              ); // Default to Mumbai for testing if all else fails
            }
          } catch (apiError) {
            print('Fallback API error: $apiError');
            setState(() => _location = 'Mumbai'); // Ultimate fallback
          }
        }
      } else {
        setState(() => _location = 'Mumbai'); // Fallback if denied
      }
    } catch (e) {
      print('Location error: $e');
      setState(() => _location = 'Mumbai');
    }

    // Simulate Weather Fetch (Mock for now, or could use API)
    if (mounted) {
      setState(() {
        _temperature = '28°C';
        _condition = 'Sunny';
        _weatherIcon = Icons.wb_sunny;
        _isLoadingWeather = false;
      });
    }
  }

  Future<void> _fetchAdvisories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/advisories'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> allAdvisories = jsonDecode(response.body);

        // Filter by Location
        final filtered = allAdvisories.where((advisory) {
          final target =
              advisory['targetRegion']?.toString().toLowerCase() ?? 'all';
          final current = _location.toLowerCase();

          print('Checking Advisory: ${advisory['title']}');
          print('Target: "$target" vs Current: "$current"');

          final match =
              target == 'all' ||
              current.contains(target) ||
              target.contains(current);
          print('Match: $match');

          return match;
        }).toList();

        if (mounted) {
          setState(() {
            _advisories = filtered;
            _isLoadingAdvisories = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching advisories: $e');
      if (mounted) setState(() => _isLoadingAdvisories = false);
    }
  }

  void _checkMarketPrice() {
    if (_marketCropController.text.isNotEmpty) {
      setState(() {
        marketResult =
            'Market Price: ₹2200/qt\nGovt Price: ₹2350/qt\nNearest APMC: Mandi District A';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: AutoTranslatedText(
          'Farmer Dashboard',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {
              setState(() {
                _isLoadingAdvisories = true;
                _isLoadingUserData = true;
                _isLoadingWeather = true;
              });
              _initData();
            },
          ),
          // Language Selector
          Consumer<LanguageProvider>(
            builder: (context, provider, child) {
              return PopupMenuButton<Locale>(
                icon: const Icon(Icons.language, color: Colors.black87),
                onSelected: (Locale locale) {
                  provider.changeLanguage(locale);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
                  const PopupMenuItem<Locale>(
                    value: Locale('en'),
                    child: Text('English'),
                  ),
                  const PopupMenuItem<Locale>(
                    value: Locale('hi'),
                    child: Text('हिंदी'),
                  ),
                  const PopupMenuItem<Locale>(
                    value: Locale('mr'),
                    child: Text('मराठी'),
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PurchaseHistoryScreen(phone: widget.phone),
                ),
              );
            },
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ALERTS SECTION
            if (_advisories.isNotEmpty) ...[
              _buildSectionHeader('Alerts & Advisories'),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _advisories.length,
                  itemBuilder: (context, index) {
                    final advisory = _advisories[index];
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 15, bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.red.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AutoTranslatedText(
                                  advisory['title'] ?? 'Alert',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade900,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: AutoTranslatedText(
                              advisory['message'] ?? '',
                              style: GoogleFonts.poppins(
                                color: Colors.red.shade800,
                                fontSize: 13,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: AutoTranslatedText(
                                  advisory['severity'] ?? 'Info',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                              ),
                              Text(
                                advisory['date'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Weather Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: _isLoadingWeather
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoTranslatedText(
                              'Today\'s Weather',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _temperature,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AutoTranslatedText(
                              '$_condition, $_location',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Icon(_weatherIcon, color: Colors.white, size: 50),
                      ],
                    ),
            ),
            const SizedBox(height: 25),

            // Add Crop Bar
            _buildSectionHeader('Plan New Crop'),
            GestureDetector(
              onTap: () async {
                final newCrop = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddCropScreen(
                      currentTemperature: _temperature,
                      currentWeather: _condition,
                      phone: widget.phone,
                    ),
                  ),
                );

                if (newCrop != null) {
                  setState(() {
                    _currentCrops.add({
                      'name': newCrop['name'],
                      'line1': 'Sown: ${newCrop['sowingDate']}',
                      'line2': 'Stage: ${newCrop['stage']}',
                      'color': newCrop['color'] == 'orange'
                          ? Colors.orange
                          : (newCrop['color'] == 'yellow'
                                ? Colors.yellow
                                : Colors.green),
                    });
                  });
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.green),
                    ),
                    const SizedBox(width: 15),
                    AutoTranslatedText(
                      'Add New Crop',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Current Crops
            _buildSectionHeader('Current Crops'),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _currentCrops.length,
                itemBuilder: (context, index) {
                  final crop = _currentCrops[index];
                  return _buildCropCard(
                    crop['name'],
                    crop['line1'],
                    crop['line2'],
                    crop['color'] ?? Colors.green,
                    index: index,
                    isCurrent: true,
                    health: crop['health'],
                  );
                },
              ),
            ),
            const SizedBox(height: 25),

            // Previous Crops
            _buildSectionHeader('Previous Crops'),
            SizedBox(
              height: 140,
              child: _isLoadingUserData
                  ? const Center(child: CircularProgressIndicator())
                  : _previousCrops.isEmpty
                  ? const Center(child: Text("No history found"))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _previousCrops.length,
                      itemBuilder: (context, index) {
                        final crop = _previousCrops[index];
                        return _buildCropCard(
                          crop['name'],
                          'Harvested: ${crop['harvestDate']}',
                          'Yield: ${crop['yield']}',
                          crop['color'] == 'green'
                              ? Colors.green
                              : Colors.blueGrey,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 25),

            // Crop Health Check
            _buildSectionHeader('Crop Health'),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DiseaseDetectionScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoTranslatedText(
                          'Check Health',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AutoTranslatedText(
                          'Detect Diseases & Gets Cures',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Market Insights
            _buildSectionHeader('Market Insights'),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MarketScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.store,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoTranslatedText(
                          'Marketplace',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AutoTranslatedText(
                          'Buy & Sell Crops',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // AI Suggestions
            _buildSectionHeader('AI Suggestions'),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AISuggestionsScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoTranslatedText(
                          'Smart Assistant',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AutoTranslatedText(
                          'Get AI-powered farming advice',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0, left: 5),
      child: AutoTranslatedText(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCropCard(
    String name,
    String line1,
    String line2,
    Color color, {
    int? index,
    bool isCurrent = false,
    String? health,
  }) {
    bool isInfected = health == 'Infected';
    return GestureDetector(
      onTap: () {
        if (isCurrent && index != null) {
          _showCropDetailsDialog(index);
        }
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          border: isInfected ? Border.all(color: Colors.red, width: 2) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.grass, color: color, size: 20),
                ),
                if (isInfected)
                  const Icon(Icons.warning, color: Colors.red, size: 20)
                else if (isCurrent)
                  const Icon(Icons.more_vert, color: Colors.grey, size: 20),
              ],
            ),
            const Spacer(),
            AutoTranslatedText(
              name,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            AutoTranslatedText(
              line1,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
            AutoTranslatedText(
              line2,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showCropDetailsDialog(int index) {
    final crop = _currentCrops[index];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    crop['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(crop['line1'], style: TextStyle(color: Colors.grey[600])),
              Text(crop['line2'], style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DiseaseDetectionScreen(
                          phone: widget.phone,
                          cropIndex: index,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.health_and_safety),
                  label: const Text("Check for Disease"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
