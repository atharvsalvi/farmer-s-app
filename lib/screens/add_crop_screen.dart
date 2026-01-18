import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:farmer/widgets/auto_translated_text.dart';

import 'package:farmer/services/api_constants.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class AddCropScreen extends StatefulWidget {
  final String currentTemperature;
  final String currentWeather;
  final String? phone;

  const AddCropScreen({
    super.key,
    required this.currentTemperature,
    required this.currentWeather,
    this.phone,
  });

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cropTypeController = TextEditingController();
  final TextEditingController _sowingDateController = TextEditingController();
  bool _isSaving = false;

  String _selectedMoisture = 'Moist'; // Default
  // We'll update options dynamically in build

  @override
  void dispose() {
    _cropTypeController.dispose();
    _sowingDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _sowingDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveCrop() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      // Create crop object
      final newCrop = {
        'name': _cropTypeController.text,
        'sowingDate': _sowingDateController.text,
        'moisture': _selectedMoisture,
        'temperature': widget.currentTemperature,
        'weather': widget.currentWeather,
        'stage': 'Seedling', // Default stage
        'color': 'green', // Default color string for DB
      };

      if (widget.phone != null) {
        try {
          final String baseUrl = ApiConstants.baseUrl;
          final response = await http.post(
            Uri.parse('$baseUrl/api/user/${widget.phone}/crops'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(newCrop),
          );

          if (response.statusCode == 200) {
            // Return the new crop to update UI immediately if needed
            if (mounted) Navigator.pop(context, newCrop);
          } else {
            _showError('Failed to save crop');
          }
        } catch (e) {
          print('Error saving crop: $e');
          _showError('Network error');
        } finally {
          if (mounted) setState(() => _isSaving = false);
        }
      } else {
        // Fallback for no phone (local only)
        Navigator.pop(context, newCrop);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AutoTranslatedText(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> moistureOptions = ['Dry', 'Moist', 'Wet'];

    // Ensure selected moisture is valid (reset if language changes)
    if (!moistureOptions.contains(_selectedMoisture)) {
      _selectedMoisture = moistureOptions[1]; // Default to Moist
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: AutoTranslatedText(
          'Add New Crop',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weather Info Card (Auto-filled)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud, color: Colors.blue),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoTranslatedText(
                          'Current Conditions',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.blue[800],
                          ),
                        ),
                        Text(
                          '${widget.currentTemperature} • ${widget.currentWeather}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Crop Type
              AutoTranslatedText(
                'Crop Type',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _cropTypeController,
                decoration: InputDecoration(
                  hintText: 'e.g., Wheat, Rice, Tomato',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.grass),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter crop type' : null,
              ),
              const SizedBox(height: 20),

              // Sowing Date
              AutoTranslatedText(
                'Sowing Date',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _sowingDateController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: InputDecoration(
                  hintText: 'Select Date',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please select sowing date' : null,
              ),
              const SizedBox(height: 20),

              // Soil Moisture
              AutoTranslatedText(
                'Soil Moisture',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: moistureOptions.map((option) {
                    return RadioListTile<String>(
                      title: AutoTranslatedText(
                        option,
                        style: GoogleFonts.poppins(),
                      ),
                      value: option,
                      groupValue: _selectedMoisture,
                      activeColor: Colors.green,
                      onChanged: (value) {
                        setState(() {
                          _selectedMoisture = value!;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCrop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : AutoTranslatedText(
                          'Add Crop',
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
      ),
    );
  }
}
