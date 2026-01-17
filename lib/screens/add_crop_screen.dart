import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AddCropScreen extends StatefulWidget {
  final String currentTemperature;
  final String currentWeather;

  const AddCropScreen({
    super.key,
    required this.currentTemperature,
    required this.currentWeather,
  });

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cropTypeController = TextEditingController();
  final TextEditingController _sowingDateController = TextEditingController();
  
  String _selectedMoisture = 'Moist'; // Default
  final List<String> _moistureOptions = ['Dry', 'Moist', 'Extremely Moist'];

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

  void _saveCrop() {
    if (_formKey.currentState!.validate()) {
      // Create crop object
      final newCrop = {
        'name': _cropTypeController.text,
        'sowingDate': _sowingDateController.text,
        'moisture': _selectedMoisture,
        'temperature': widget.currentTemperature,
        'weather': widget.currentWeather,
        'stage': 'Seedling', // Default stage
        'color': Colors.green, // Default color
      };

      // Return the new crop to the previous screen
      Navigator.pop(context, newCrop);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Add New Crop', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
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
                        Text(
                          'Current Conditions',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue[800]),
                        ),
                        Text(
                          '${widget.currentTemperature} • ${widget.currentWeather}',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[900]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Crop Type
              Text('Crop Type', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
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
                validator: (value) => value!.isEmpty ? 'Please enter crop type' : null,
              ),
              const SizedBox(height: 20),

              // Sowing Date
              Text('Sowing Date', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
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
                validator: (value) => value!.isEmpty ? 'Please select sowing date' : null,
              ),
              const SizedBox(height: 20),

              // Soil Moisture
              Text('Soil Moisture', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: _moistureOptions.map((option) {
                    return RadioListTile<String>(
                      title: Text(option, style: GoogleFonts.poppins()),
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
                  onPressed: _saveCrop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  child: Text(
                    'Add Crop',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
