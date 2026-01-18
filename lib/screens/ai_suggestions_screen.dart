import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:farmer/services/weather_service.dart';
import 'package:farmer/services/gemini_service.dart';
import 'package:farmer/widgets/auto_translated_text.dart';

class AISuggestionsScreen extends StatefulWidget {
  const AISuggestionsScreen({super.key});

  @override
  State<AISuggestionsScreen> createState() => _AISuggestionsScreenState();
}

class _AISuggestionsScreenState extends State<AISuggestionsScreen> {
  final WeatherService _weatherService = WeatherService();
  final GeminiService _geminiService = GeminiService();

  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _forecast = [];
  String _aiAdvice = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. Get Location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 2. Fetch Weather
      final forecast = await _weatherService.getNext4DaysForecast(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _forecast = forecast;
      });

      // 3. Fetch AI Advice
      final advice = await _geminiService.getFarmingAdvice(forecast);

      setState(() {
        _aiAdvice = advice;
        _isLoading = false;
      });
    } catch (e) {
      print('Error in AI Suggestions: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: AutoTranslatedText(
          'AI Suggestions',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Error: $_errorMessage',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _fetchData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Weather Forecast (Next 4 Days)'),
                  const SizedBox(height: 10),
                  _buildForecastList(),
                  const SizedBox(height: 25),
                  _buildSectionHeader('AI Farming Advice'),
                  const SizedBox(height: 10),
                  _buildAdviceCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return AutoTranslatedText(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildForecastList() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _forecast.length,
        itemBuilder: (context, index) {
          final day = _forecast[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
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
                Text(
                  day['date'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${day['temp']}°C',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  day['description'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.water_drop, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      '${day['humidity']}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdviceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purple.shade400),
              const SizedBox(width: 10),
              Text(
                "Gemini AI Analysis",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade800,
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          AutoTranslatedText(
            _aiAdvice,
            parseBold: true,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
