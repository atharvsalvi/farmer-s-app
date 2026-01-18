import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmer/widgets/auto_translated_text.dart';

class PurchaseScreen extends StatefulWidget {
  final String cropName;
  final double pricePerQt;
  final String marketName;

  const PurchaseScreen({
    super.key,
    required this.cropName,
    required this.pricePerQt,
    required this.marketName,
  });

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  int _quantity = 1;
  bool _isProcessing = false;

  double get _totalPrice => widget.pricePerQt * _quantity;

  void _confirmPurchase() async {
    setState(() {
      _isProcessing = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Save Purchase to History
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> history =
          prefs.getStringList('purchase_history') ?? [];

      final purchaseData = {
        'cropName': widget.cropName,
        'marketName': widget.marketName,
        'quantity': _quantity,
        'totalPrice': _totalPrice,
        'date': DateTime.now().toIso8601String(),
      };

      history.add(jsonEncode(purchaseData));
      await prefs.setStringList('purchase_history', history);
    } catch (e) {
      print('Error saving history: $e');
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 10),
              AutoTranslatedText(
                'Purchase Successful!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: AutoTranslatedText(
            'You have successfully purchased $_quantity Quintals of ${widget.cropName} from ${widget.marketName}.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close Dialog
                Navigator.of(context).pop(); // Close Purchase Screen
                Navigator.of(context).pop(); // Close Details Screen
              },
              child: AutoTranslatedText(
                'Done',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: AutoTranslatedText(
          'Confirm Purchase',
          style: GoogleFonts.poppins(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AutoTranslatedText(
                        'Crop',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                      AutoTranslatedText(
                        widget.cropName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AutoTranslatedText(
                        'Market',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                      AutoTranslatedText(
                        widget.marketName,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AutoTranslatedText(
                        'Price per Qt',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                      Text(
                        '₹${widget.pricePerQt}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Quantity Selector
            AutoTranslatedText(
              'Select Quantity (Quintals)',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if (_quantity > 1) setState(() => _quantity--);
                    },
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    '$_quantity Qt',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _quantity++);
                    },
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Total Price & Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AutoTranslatedText(
                        'Total Amount',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '₹${_totalPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _confirmPurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : AutoTranslatedText(
                              'Confirm Purchase',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
