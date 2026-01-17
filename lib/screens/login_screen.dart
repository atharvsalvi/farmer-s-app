import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:farmer/widgets/glass_container.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:farmer/screens/home_screen.dart';
import 'package:farmer/screens/officer_dashboard_screen.dart';

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
          content: Text('Please enter a valid 10-digit mobile number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    // 2. Generate OTP
    String otp = _generateRandomOtp();
    setState(() {
      _generatedOtp = otp;
    });

    // 3. Send OTP via Backend
    try {
      // Use Deployed Backend
      final String baseUrl = 'https://farmer-backend-5rka.onrender.com';
      final url = Uri.parse('$baseUrl/send-otp');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': '+91$phone', // Assuming India (+91)
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          otpSent = true;
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP Sent successfully via Backend!')),
        );
      } else {
        print('Backend Error: ${response.body}');
        setState(() {
          isLoading = false;
          // Fallback for demo if backend fails (e.g. server not running)
          otpSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backend Failed (Is server running?). Mock OTP: $otp',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print("Network Error: $e");
      setState(() {
        isLoading = false;
        // Fallback for demo
        otpSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connection Failed (Is server running?). Mock OTP: $otp',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _handleSubmit() {
    String enteredOtp = _otpController.text.trim();

    if (enteredOtp == _generatedOtp || enteredOtp == '1234') {
      // Backdoor for testing
      if (isFarmer) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const OfficerDashboardScreen(),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Green Nature Gradient Background
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

          // Loading Indicator
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

  Widget _buildWelcomeView() {
    return GlassContainer(
      key: const ValueKey('welcome'),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dummy Image Area
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
          Text(
            'Smart Farming\nFor a Better Future',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'AI-powered insights for optimal crop growth and yield.',
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
                    child: Text(
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
                    child: Text(
                      'Sign In',
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
          Text(
            isRegistering ? 'Create Account' : 'Hello Again!',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isRegistering
                ? 'Join the smart farming revolution'
                : 'Welcome back, you\'ve been missed!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 30),

          // User Type Toggle
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
                        child: Text(
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
                        child: Text(
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

          // Mobile Input
          TextField(
            controller: _mobileController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Mobile Number (10 digits)',
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

          // OTP Input (Conditional)
          if (otpSent) ...[
            TextField(
              controller: _otpController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter 6-digit OTP',
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

          // Action Button
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
              child: Text(
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
            child: Text(
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
