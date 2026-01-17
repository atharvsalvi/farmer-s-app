import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmer/widgets/glass_container.dart';
import 'package:farmer/screens/purchase_screen.dart';
import 'package:farmer/widgets/auto_translated_text.dart';

class CropDetailsScreen extends StatefulWidget {
  final String cropName;
  final bool isSelling; // New parameter to distinguish Buy vs Sell

  const CropDetailsScreen({
    super.key,
    required this.cropName,
    this.isSelling = false, // Default to buying
  });

  @override
  State<CropDetailsScreen> createState() => _CropDetailsScreenState();
}

class _CropDetailsScreenState extends State<CropDetailsScreen> {
  Map<String, dynamic>? cropData;
  List<Map<String, dynamic>> marketPrices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load Crop Data
      final String cropJson = await rootBundle.loadString('backend/assets/crop_data.json');
      final List<dynamic> crops = json.decode(cropJson);
      final crop = crops.firstWhere(
        (c) => c['name'] == widget.cropName,
        orElse: () => null,
      );

      // Load Market Data based on mode
      final String fileName = widget.isSelling ? 'backend/assets/sell_market_data.json' : 'backend/assets/market_data.json';
      final String marketJson = await rootBundle.loadString(fileName);
      final List<dynamic> markets = json.decode(marketJson);
      
      List<Map<String, dynamic>> prices = [];
      for (var market in markets) {
        if (market['prices'].containsKey(widget.cropName)) {
          prices.add({
            'market_name': market['market_name'],
            'type': market['type'],
            'price': market['prices'][widget.cropName],
          });
        }
      }

      setState(() {
        cropData = crop;
        marketPrices = prices;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _getBestDeal() {
    if (marketPrices.isEmpty) return null;
    
    var sorted = List<Map<String, dynamic>>.from(marketPrices);
    if (widget.isSelling) {
      // For Selling: We want the HIGHEST price
      sorted.sort((a, b) => b['price'].compareTo(a['price']));
    } else {
      // For Buying: We want the LOWEST price
      sorted.sort((a, b) => a['price'].compareTo(b['price']));
    }
    return sorted.first;
  }

  @override
  Widget build(BuildContext context) {
    final bestDeal = _getBestDeal();
    final actionText = widget.isSelling ? 'Sell' : 'Buy';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: AutoTranslatedText(widget.cropName, style: GoogleFonts.poppins(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cropData == null
              ? const Center(child: AutoTranslatedText('Crop details not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Crop Header Image
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: NetworkImage(cropData!['image']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Growth Time
                      GlassContainer(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        borderRadius: BorderRadius.circular(20),
                        child: Row(
                          children: [
                            const Icon(Icons.timer, color: Colors.green, size: 30),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoTranslatedText(
                                  'Time to Grow',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                AutoTranslatedText(
                                  cropData!['growth_time'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Recommendation
                      if (bestDeal != null) ...[
                        AutoTranslatedText(
                          'Recommendation',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoTranslatedText(
                                'Best Place to $actionText',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 5),
                              AutoTranslatedText(
                                bestDeal['market_name'],
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  AutoTranslatedText(
                                    'Price: ₹${bestDeal['price']}/qt',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (bestDeal['type'] == 'government')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: AutoTranslatedText(
                                        'GOVT',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              AutoTranslatedText(
                                _getRecommendationText(bestDeal),
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                      ],

                      // All Prices
                      AutoTranslatedText(
                        'Market Prices Comparison',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: marketPrices.length,
                        itemBuilder: (context, index) {
                          final market = marketPrices[index];
                          final isBest = market == bestDeal;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: isBest ? Border.all(color: Colors.green, width: 2) : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AutoTranslatedText(
                                      market['market_name'],
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    AutoTranslatedText(
                                      market['type'].toString().toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '₹${market['price']}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: isBest ? Colors.green : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      // Buy Now Button (Only in Buy Mode)
                      if (!widget.isSelling && bestDeal != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 20),
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PurchaseScreen(
                                    cropName: widget.cropName,
                                    pricePerQt: (bestDeal['price'] as num).toDouble(),
                                    marketName: bestDeal['market_name'],
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 5,
                            ),
                            child: AutoTranslatedText(
                              'Buy Now',
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  String _getRecommendationText(Map<String, dynamic> bestDeal) {
    if (widget.isSelling) {
      if (bestDeal['type'] == 'government') {
        return 'The Government MSP is currently the highest. We recommend selling here.';
      } else {
        return 'A private market is offering a higher rate than the Government MSP.';
      }
    } else {
      if (bestDeal['type'] == 'government') {
        return 'The Government Supermarket offers the best rate. We recommend buying from here.';
      } else {
        return 'A private market offers a better rate than the Government Supermarket.';
      }
    }
  }
}
