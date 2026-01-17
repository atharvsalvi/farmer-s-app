import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmer/screens/crop_details_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> crops = [];
  List<dynamic> filteredCrops = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCrops();
    _searchController.addListener(_filterCrops);
  }

  Future<void> _loadCrops() async {
    try {
      final String response = await rootBundle.loadString('backend/assets/crop_data.json');
      final data = json.decode(response);
      setState(() {
        crops = data;
        filteredCrops = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading crops: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterCrops() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredCrops = crops.where((crop) {
        return crop['name'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Marketplace',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Buy Crops'),
            Tab(text: 'Sell Crops'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBuyTab(),
          _buildSellTab(),
        ],
      ),
    );
  }

  Widget _buildBuyTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search crops to buy...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredCrops.length,
            itemBuilder: (context, index) {
              final crop = filteredCrops[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      crop['image'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                        Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.grass)),
                    ),
                  ),
                  title: Text(
                    crop['name'],
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Growth Time: ${crop['growth_time']}',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CropDetailsScreen(cropName: crop['name']),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Text('View Details', style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSellTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search crops to sell...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredCrops.length,
            itemBuilder: (context, index) {
              final crop = filteredCrops[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      crop['image'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                        Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.grass)),
                    ),
                  ),
                  title: Text(
                    crop['name'],
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Growth Time: ${crop['growth_time']}',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CropDetailsScreen(
                            cropName: crop['name'],
                            isSelling: true, // Enable Sell Mode
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, // Different color for Sell
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Text('Sell Details', style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
