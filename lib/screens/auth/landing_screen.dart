import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
  
  const SplashScreen({Key? key, this.onAnimationComplete}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _gradientAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  
  // Premium color scheme
  final Color _primaryRed = Color(0xFFF42A41);
  final Color _primaryGreen = Color(0xFF006A4E);
  final Color _darkGreen = Color(0xFF004D38);
  final Color _goldAccent = Color(0xFFFFD700);
  final Color _platinum = Color(0xFFE5E4E2);
  final Color _offWhite = Color(0xFFF8F8F8);
  final Color _lightGold = Color(0xFFFFF8E1);

  @override
  void initState() {
    super.initState();
    
    // Change duration from 5 seconds to 4 seconds
    _animationController = AnimationController(
      duration: const Duration(seconds: 4), // Changed from 5 to 4
      vsync: this,
    );
    
    // Fade in entire screen (0-0.75 seconds)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.19, curve: Curves.easeInOut), // 0-0.75s of 4s
      ),
    );
    
    // Text fade animation (delayed) (1.6-3.2 seconds)
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.4, 0.8, curve: Curves.easeInOut), // 1.6-3.2s of 4s
      ),
    );
    
    // Scale animation for Logo (0.8-2.8 seconds) - enhanced for logo
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.7, curve: Curves.elasticOut), // 0.8-2.8s of 4s
      ),
    );
    
    // Additional logo scale animation for pulse effect
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        weight: 1,
        tween: Tween<double>(begin: 1.0, end: 1.1).chain(CurveTween(curve: Curves.easeInOut)),
      ),
      TweenSequenceItem(
        weight: 1,
        tween: Tween<double>(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
      ),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 0.9, curve: Curves.easeInOut),
      ),
    );
    
    // Logo rotation animation for premium effect
    _logoRotationAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.4, 0.8, curve: Curves.easeInOut),
      ),
    );
    
    // Slide animation for text (2.0-4.0 seconds)
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.5, 1.0, curve: Curves.easeOutBack), // 2.0-4.0s of 4s
      ),
    );
    
    // Gradient animation for background (0-4 seconds)
    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animations
    _animationController.forward().whenComplete(() {
      widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    final isTablet = screenWidth > 600;
    final isLandscape = screenWidth > screenHeight;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _darkGreen,
                  _primaryGreen.withOpacity(0.8 + _gradientAnimation.value * 0.2),
                  _darkGreen,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Animated gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5,
                      colors: [
                        _goldAccent.withOpacity(0.1 * _gradientAnimation.value),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.7],
                    ),
                  ),
                ),
                
                // Main content - Wrapped in SingleChildScrollView for overflow
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: SingleChildScrollView(
                    physics: NeverScrollableScrollPhysics(), // Disable manual scrolling
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: screenHeight,
                      ),
                      padding: EdgeInsets.all(isLandscape ? 16 : isTablet ? 24 : isSmallScreen ? 16 : 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo with enhanced animations
                          Transform.scale(
                            scale: _scaleAnimation.value * _logoScaleAnimation.value,
                            child: Transform.rotate(
                              angle: _logoRotationAnimation.value * pi,
                              child: Container(
                                width: isLandscape 
                                    ? min(screenWidth * 0.4, 200) 
                                    : min(isTablet ? 300 : 220, screenWidth * 0.7),
                                height: isLandscape 
                                    ? min(screenWidth * 0.4, 200) 
                                    : min(isTablet ? 300 : 220, screenWidth * 0.7),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.15),
                                      Colors.transparent,
                                  ],
                                    stops: [0.0, 0.7],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _goldAccent.withOpacity(0.3 * _scaleAnimation.value),
                                      blurRadius: 30,
                                      spreadRadius: 3,
                                    ),
                                    BoxShadow(
                                      color: _primaryRed.withOpacity(0.2 * _scaleAnimation.value),
                                      blurRadius: 40,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: isLandscape 
                                        ? min(screenWidth * 0.35, 180) 
                                        : min(isTablet ? 260 : 180, screenWidth * 0.6),
                                    height: isLandscape 
                                        ? min(screenWidth * 0.35, 180) 
                                        : min(isTablet ? 260 : 180, screenWidth * 0.6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          _primaryRed.withOpacity(0.1),
                                          _primaryGreen.withOpacity(0.1),
                                        ],
                                        stops: [0.0, 1.0],
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/logo/logo.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          print('Error loading logo: $error');
                                          return Center(
                                            child: Icon(
                                              Icons.people,
                                              color: _goldAccent,
                                              size: isLandscape ? 80 : 60,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: isLandscape ? 20 : isSmallScreen ? 20 : 30),
                          
                          // App Name with Premium Effects
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: min(screenWidth * 0.9, 400),
                            ),
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Opacity(
                                opacity: _textFadeAnimation.value,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isLandscape ? 16 : isTablet ? 24 : 16,
                                    vertical: isLandscape ? 12 : isTablet ? 16 : 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.1),
                                        Colors.white.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(isLandscape ? 16 : 20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2 * _textFadeAnimation.value),
                                        blurRadius: 20,
                                        offset: Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // BanglaHub Text with Premium Gradient
                                      ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: [_platinum, _goldAccent],
                                          stops: [0.6, 1.0],
                                        ).createShader(bounds),
                                        child: Text(
                                          'BanglaHub',
                                          style: GoogleFonts.poppins(
                                            fontSize: isLandscape 
                                                ? min(screenWidth * 0.06, 28) 
                                                : min(isTablet ? 36 : isSmallScreen ? 28 : 32, screenWidth * 0.12),
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.0,
                                            height: 1.1,
                                          ),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      
                                      SizedBox(height: isLandscape ? 6 : 8),
                                      
                                      // Tagline
                                      Text(
                                        'Celebrating Bengali\nCulture & Community',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: isLandscape 
                                              ? min(screenWidth * 0.03, 12) 
                                              : min(isTablet ? 16 : isSmallScreen ? 12 : 14, screenWidth * 0.045),
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: isLandscape ? 20 : isSmallScreen ? 20 : 30),
                          
                          // Premium Slogan Container
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: min(screenWidth * 0.9, 450),
                            ),
                            child: Opacity(
                              opacity: _textFadeAnimation.value,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Container(
                                  padding: EdgeInsets.all(isLandscape ? 12 : isTablet ? 20 : 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.black.withOpacity(0.3),
                                        Colors.black.withOpacity(0.15),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(isLandscape ? 16 : 20),
                                    border: Border.all(
                                      color: _goldAccent.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Main Slogan
                                      Text(
                                        'Connecting Bengalis\nAcross North America',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: isLandscape 
                                              ? min(screenWidth * 0.05, 22) 
                                              : min(isTablet ? 28 : isSmallScreen ? 20 : 24, screenWidth * 0.08),
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      
                                      SizedBox(height: isLandscape ? 8 : 12),
                                      
                                      // Animated Divider
                                      Container(
                                        width: isLandscape ? 60 : isSmallScreen ? 80 : 100,
                                        height: 3,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [_primaryRed, _goldAccent],
                                          ),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      
                                      SizedBox(height: isLandscape ? 8 : 12),
                                      
                                      // Sub Slogan
                                      Text(
                                        'One Platform. One Community.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: isLandscape 
                                              ? min(screenWidth * 0.035, 14) 
                                              : min(isTablet ? 18 : isSmallScreen ? 12 : 16, screenWidth * 0.045),
                                          fontWeight: FontWeight.w600,
                                          color: _lightGold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: isLandscape ? 20 : isSmallScreen ? 20 : 30),
                          
                          // Premium Loading Indicator
                          Opacity(
                            opacity: _textFadeAnimation.value,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Animated Loading Circle
                                Container(
                                  width: isLandscape ? 40 : isSmallScreen ? 45 : 55,
                                  height: isLandscape ? 40 : isSmallScreen ? 45 : 55,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _goldAccent.withOpacity(0.3),
                                        _primaryGreen.withOpacity(0.2),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation(_goldAccent),
                                    ),
                                  ),
                                ),
                                
                                SizedBox(height: isLandscape ? 12 : 16),
                                
                                // Loading Text
                                Text(
                                  'Loading your community...',
                                  style: GoogleFonts.inter(
                                    fontSize: isLandscape ? 12 : isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Decorative Elements - Only for portrait mode and not very small screens
                if (!isVerySmallScreen && !isLandscape) ...[
                  Positioned(
                    top: 30,
                    left: 15,
                    child: _buildDecorativeElement(true, isLandscape),
                  ),
                  Positioned(
                    top: 30,
                    right: 15,
                    child: _buildDecorativeElement(false, isLandscape),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDecorativeElement(bool isLeft, bool isLandscape) {
    return Container(
      width: isLandscape ? 25 : 35,
      height: isLandscape ? 25 : 35,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: isLeft ? [_primaryRed, Colors.white] : [_goldAccent, Colors.white],
          center: Alignment.center,
          radius: 0.6,
        ),
        shape: BoxShape.circle,
      ),
    );
  }
}