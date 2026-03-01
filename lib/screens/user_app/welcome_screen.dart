import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const WelcomeScreen({Key? key, required this.onComplete}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late Timer _autoNavigateTimer;
  
  // Color scheme
  final Color _primaryRed = Color(0xFFF42A41);
  final Color _primaryGreen = Color(0xFF006A4E);
  final Color _darkGreen = Color(0xFF004D38);
  final Color _goldAccent = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    // Auto-navigate after 4 seconds
    _autoNavigateTimer = Timer(Duration(seconds: 4), () {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _autoNavigateTimer.cancel();
    super.dispose();
  }

  void _skipToHome() {
    _autoNavigateTimer.cancel();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Scaffold(
      backgroundColor: _darkGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipToHome,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ),

              // Lottie Animation
              Expanded(
                child: Center(
                  child: Lottie.asset(
                    'assets/animations/welcome.json',
                    width: min(250.0, screenSize.width * 0.7),
                    height: min(250.0, screenSize.width * 0.7),
                    animate: true,
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Welcome Message
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.white, _goldAccent],
                        stops: [0.7, 1.0],
                      ).createShader(bounds),
                      child: Text(
                        'Welcome to BanglaHub!',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'We\'re excited to have you join our community. '
                      'Your presence makes BanglaHub stronger.',
                      style: GoogleFonts.inter(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // Get Started Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _skipToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryRed,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Auto-navigate indicator
              Text(
                'Auto navigating in 4 seconds...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}