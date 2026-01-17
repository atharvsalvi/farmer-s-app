import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen> {
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
        _result = null; // Reset result on new image
      });
    }
  }

  Future<void> _detectDisease() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Use localhost for Android Emulator (10.0.2.2) vs Web (localhost)
      // Note: On web, localhost refers to the machine running the browser.
      // Make sure your backend enables CORS.
      final String baseUrl = kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
      var uri = Uri.parse('$baseUrl/predict');
      var request = http.MultipartRequest('POST', uri);
      
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          await _image!.readAsBytes(),
          filename: _image!.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
      }
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          _result = json.decode(response.body);
        });
      } else {
        _showError('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Failed to connect: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Crop Health Check', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview Area
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _image == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text('Take or upload a photo of the leaf', style: TextStyle(color: Colors.grey[600])),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: kIsWeb
                          ? Image.network(_image!.path, fit: BoxFit.cover)
                          : Image.file(File(_image!.path), fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Analyze Button
            if (_image != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _detectDisease,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Analyze Crop Health', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            
            const SizedBox(height: 30),

            // Results Area
            if (_result != null) _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final String status = _result!['status'] ?? 'Unknown';
    final bool isHealthy = status == 'Healthy';
    final Color statusColor = isHealthy ? Colors.green : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.outfit(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Disease Name:',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        Text(
          _result!['disease'] ?? 'Unknown',
          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Center(child: Text("Confidence: ${((_result!['confidence'] ?? 0) * 100).toStringAsFixed(1)}%", style: const TextStyle(color: Colors.grey))),
        const Divider(height: 40),
        
        if (!isHealthy) ...[
            _buildSection('Possible Causes', _result!['causes']),
            const SizedBox(height: 20),
            _buildSection('Prevention', _result!['prevention']),
        ] else
            const Text("Your crop looks healthy! Keep up the good work.")
      ],
    );
  }

  Widget _buildSection(String title, List<dynamic>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Text(item.toString())),
            ],
          ),
        )),
      ],
    );
  }
}
