import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:farmer/widgets/glass_container.dart';
import 'package:farmer/screens/market_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _marketCropController = TextEditingController();
  String? marketResult;
  
  // Weather State
  String _temperature = '--';
  String _condition = 'Loading...';
  String _location = 'Locating...';
  IconData _weatherIcon = Icons.cloud;
  bool _isLoadingWeather = true;
  // final String _apiKey = 'YOUR_API_KEY'; // API Key removed to prevent exhaustion

  @override
  void initState() {
    super.initState();
    _initWeather();
  }

  Future<void> _initWeather() async {
    // Simulate network delay for realistic feel
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _temperature = '28°C';
        _condition = 'Sunny';
        _location = 'Pune (Demo)';
        _weatherIcon = Icons.wb_sunny;
        _isLoadingWeather = false;
      });
    }
  }

  // Future<Position> _determinePosition() async { ... } // Removed to avoid unnecessary permission requests if not using API

  // Future<void> _fetchWeather(double lat, double lon) async { ... } // Removed API call

  void _checkMarketPrice() {
    if (_marketCropController.text.isNotEmpty) {
      setState(() {
        marketResult = 'Market Price: ₹2200/qt\nGovt Price: ₹2350/qt\nNearest APMC: Mandi District A';
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
        title: Text(
          'Farmer Dashboard',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
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
                            Text(
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
              onTap: () {
                // Navigate to add crop page
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
                    Text(
                      'Add Crop',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Current Crops
            _buildSectionHeader('Current Crops'),
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCropCard('Wheat', 'Sown: 10 Jan', 'Stage: Germination', Colors.orange),
                  _buildCropCard('Mustard', 'Sown: 15 Jan', 'Stage: Seedling', Colors.yellow),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Previous Crops
            _buildSectionHeader('Previous Crops'),
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCropCard('Rice', 'Harvested: Dec 2023', 'Yield: 40qt', Colors.green),
                  _buildCropCard('Cotton', 'Harvested: Nov 2023', 'Yield: 20qt', Colors.blueGrey),
                ],
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
                      child: const Icon(Icons.store, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Marketplace',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
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
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0, left: 5),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCropCard(String name, String line1, String line2, Color color) {
    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.grass, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            line1,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            line2,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
