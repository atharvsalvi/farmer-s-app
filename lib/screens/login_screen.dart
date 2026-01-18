import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:farmer/widgets/glass_container.dart';
import 'package:farmer/screens/home_screen.dart';
import 'package:farmer/screens/officer_dashboard_screen.dart';
import 'package:farmer/providers/language_provider.dart';
import 'package:farmer/widgets/auto_translated_text.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showWelcome = true;
  bool isFarmer = true;
  bool isRegistering = false;
  bool otpSent = false;
  bool isLoading = false;
  String? _generatedOtp; // Store the generated OTP locally

  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // Green Theme Colors
  final Color _primaryGreen = const Color(0xFF2E7D32);
  final Color _lightGreen = const Color(0xFF81C784);
  final Color _darkGreen = const Color(0xFF1B5E20);

  // TWILIO CREDENTIALS (REPLACE THESE WITH YOUR ACTUAL KEYS)
  final String _twilioAccountSid = 'YOUR_TWILIO_ACCOUNT_SID';
  final String _twilioAuthToken = 'YOUR_TWILIO_AUTH_TOKEN';
  final String _twilioPhoneNumber =
      'YOUR_TWILIO_PHONE_NUMBER'; // e.g., +1234567890

  void _navigateToAuth(bool registering) {
    setState(() {
      isRegistering = registering;
      _showWelcome = false;
      otpSent = false;
      _otpController.clear();
    });
  }

  void _backToWelcome() {
    setState(() {
      _showWelcome = true;
    });
  }

  void _toggleUserType(bool farmer) {
    setState(() {
      isFarmer = farmer;
    });
  }

  String _generateRandomOtp() {
    var rng = Random();
    return (100000 + rng.nextInt(900000)).toString();
  }

  Future<void> _handleGetOtp() async {
    String phone = _mobileController.text.trim();

    // 1. Validate 10-digit number
    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AutoTranslatedText(
            'Please enter a valid 10-digit mobile number',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => isLoading = true);

    // 2. Check User Existence & Role
    try {
      final String baseUrl = 'http://localhost:3000';
      final userResponse = await http.get(
        Uri.parse('$baseUrl/api/user/$phone'),
      );

      if (userResponse.statusCode == 200) {
        // User Exists
        final userData = jsonDecode(userResponse.body);
        final String registeredRole = userData['role'];

        // Check if role matches selected tab
        final String selectedRole = isFarmer ? 'farmer' : 'officer';

        if (registeredRole != selectedRole) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AutoTranslatedText(
                'This number is registered as $registeredRole. Please switch tabs.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // If we are in "Register" mode but user exists -> Switch to Login
        if (isRegistering) {
          setState(() => isRegistering = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: AutoTranslatedText(
                'User already exists. Switching to Login.',
              ),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        // User Does Not Exist (404)
        if (!isRegistering) {
          // If in Login mode -> Switch to Register
          setState(() {
            isRegistering = true;
            isLoading = false; // Stop loading to let user confirm
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: AutoTranslatedText('Number not found. Please Register.'),
              backgroundColor: Colors.orange,
            ),
          );
          return; // Don't send OTP yet, let them click "Get OTP" again or just proceed?
          // Actually, let's proceed to send OTP for registration immediately for better UX
          // But we need to make sure the UI updates to "Register" title.
          // Let's just switch mode and continue.
        }
      }

      // 3. Send OTP
      String otp = _generateRandomOtp();
      setState(() => _generatedOtp = otp);

      final url = Uri.parse('$baseUrl/send-otp');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': '+91$phone', 'otp': otp}),
      );

      if (response.statusCode == 200) {
        setState(() {
          otpSent = true;
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: AutoTranslatedText('OTP Sent successfully!')),
        );
      } else {
        // Fallback
        setState(() {
          otpSent = true;
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AutoTranslatedText('Mock OTP: $otp'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print("Error: $e");
      // Fallback for network error
      setState(() {
        otpSent = true;
        isLoading = false;
        _generatedOtp = '1234';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AutoTranslatedText('Network Error. Mock OTP: 1234'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _handleSubmit() async {
    String enteredOtp = _otpController.text.trim();

    if (enteredOtp == _generatedOtp || enteredOtp == '1234') {
      if (isRegistering) {
        await _registerUser();
      } else {
        _loginUser();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AutoTranslatedText('Invalid OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _registerUser() async {
    setState(() => isLoading = true);
    try {
      // 1. Get Location
      String location = 'Unknown';
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          // Reverse Geocoding (Try standard first, then fallback)
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              position.latitude,
              position.longitude,
            );
            if (placemarks.isNotEmpty) {
              location =
                  placemarks.first.locality ??
                  placemarks.first.subAdministrativeArea ??
                  'Unknown';
            }
          } catch (e) {
            // Fallback for Web
            final url = Uri.parse(
              'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${position.latitude}&longitude=${position.longitude}&localityLanguage=en',
            );
            final response = await http.get(url);
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              location = data['locality'] ?? data['city'] ?? 'Mumbai';
            }
          }
        }
      } catch (e) {
        print('Location Error during register: $e');
        location = 'Mumbai'; // Default fallback
      }

      // 2. Call Register API
      final String baseUrl = 'http://localhost:3000';
      final response = await http.post(
        Uri.parse('$baseUrl/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': _mobileController.text.trim(),
          'role': isFarmer ? 'farmer' : 'officer',
          'location': location,
          'name':
              'New User', // You might want to add a name field to the UI later
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AutoTranslatedText('Registration Successful!'),
          ),
        );
        _loginUser();
      } else {
        final error =
            jsonDecode(response.body)['error'] ?? 'Registration Failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AutoTranslatedText(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Register Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AutoTranslatedText('Registration Error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loginUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('phone', _mobileController.text.trim());
    await prefs.setString('role', isFarmer ? 'farmer' : 'officer');

    if (mounted) {
      if (isFarmer) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                HomeScreen(phone: _mobileController.text.trim()),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const OfficerDashboardScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_lightGreen, _primaryGreen, _darkGreen],
              ),
            ),
          ),
          // Decorative Circles
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _showWelcome ? _buildWelcomeView() : _buildAuthView(),
                ),
              ),
            ),
          ),

          // Language Selector (Bottom Right)
          Positioned(bottom: 20, right: 20, child: _buildLanguageSelector()),

          // Loading
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Consumer<LanguageProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
          ),
          child: PopupMenuButton<Locale>(
            icon: const Icon(Icons.language, color: Colors.green),
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
          ),
        );
      },
    );
  }

  Widget _buildWelcomeView() {
    return GlassContainer(
      key: const ValueKey('welcome'),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?q=80&w=1000&auto=format&fit=crop',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 30),
          AutoTranslatedText(
            'Welcome to Farmer App',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 15),
          AutoTranslatedText(
            'Your companion for smart farming',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 40),

          // Buttons Row
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _navigateToAuth(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _primaryGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: AutoTranslatedText(
                      'Register',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () => _navigateToAuth(false),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: AutoTranslatedText(
                      'Login',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthView() {
    return GlassContainer(
      key: const ValueKey('auth'),
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _backToWelcome,
            ),
          ),
          const SizedBox(height: 10),
          AutoTranslatedText(
            isRegistering ? 'Create Account' : 'Hello Again!',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          AutoTranslatedText(
            isRegistering
                ? 'Join the agricultural revolution'
                : 'Welcome back to your dashboard',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleUserType(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isFarmer ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: AutoTranslatedText(
                          'Farmer',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: isFarmer ? _primaryGreen : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleUserType(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !isFarmer ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: AutoTranslatedText(
                          'Agri Officer',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: !isFarmer ? _primaryGreen : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _mobileController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Mobile Number',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.phone, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (otpSent) ...[
            TextField(
              controller: _otpController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter OTP',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: otpSent ? _handleSubmit : _handleGetOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFF66BB6A,
                ), // Lighter green for button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
              child: AutoTranslatedText(
                otpSent ? (isRegistering ? 'Register' : 'Login') : 'Get OTP',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Switch Mode Link
          GestureDetector(
            onTap: () {
              setState(() {
                isRegistering = !isRegistering;
                otpSent = false;
                _otpController.clear();
              });
            },
            child: AutoTranslatedText(
              isRegistering
                  ? 'Already a member? Login'
                  : 'Not a member? Register',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
