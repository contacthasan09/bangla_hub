// lib/screens/user_app/job_sites/others_job_sites_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:bangla_hub/models/job_sites_browse_model.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/job_sites_browse_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/auth/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class OthersJobSitesScreen extends StatefulWidget {
  @override
  _OthersJobSitesScreenState createState() => _OthersJobSitesScreenState();
}

class _OthersJobSitesScreenState extends State<OthersJobSitesScreen> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  
  // Premium Color Palette - Charcoal Theme
  final Color _charcoal = Color(0xFF2C3E50); // Main charcoal
  final Color _darkCharcoal = Color(0xFF1A2632); // Dark charcoal
  final Color _lightCharcoal = Color(0xFF34495E); // Light charcoal
  
  final Color _secondaryGold = Color(0xFFFFB300); // Gold accent
  final Color _softGold = Color(0xFFFFD966); // Soft gold
  final Color _accentRed = Color(0xFFE74C3C); // Red accent
  final Color _accentBlue = Color(0xFF3498DB); // Blue accent
  final Color _accentGreen = Color(0xFF2ECC71); // Green accent
  
  // Supporting colors
  final Color _textPrimary = Color(0xFF2C3E50);
  final Color _textSecondary = Color(0xFF7F8C8D);
  final Color _borderLight = Color(0xFFE0E7E9);
  final Color _shadowColor = Color(0x1A000000);
  final Color _lightBg = Color(0xFFF8FAFC);
  
  // Background Gradient - Light with Charcoal Accents
  final LinearGradient _bodyBgGradient = LinearGradient(
    colors: [
      Color(0xFFF8FAFC), // Light background
      Color(0xFFECF0F1), // Very light gray
      Color(0xFFE0E7E9), // Light border color
      Color(0xFFD5DBDB), // Slightly darker
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.4, 0.7, 1.0],
  );

  final LinearGradient _appBarGradient = LinearGradient(
    colors: [
      Color(0xFF2C3E50), // Charcoal
      Color(0xFF1A2632), // Dark Charcoal
      Color(0xFF34495E), // Light Charcoal
      Color(0xFF3D566E), // Blue-gray
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.4, 0.7, 1.0],
  );

  // Gradients for accents
  final LinearGradient _preciousGradient = LinearGradient(
    colors: [
      Color(0xFFFFB300), // gold
      Color(0xFF2C3E50), // charcoal
      Color(0xFFE74C3C), // red
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _gemstoneGradient = LinearGradient(
    colors: [
      Color(0xFF2C3E50), // charcoal
      Color(0xFFFFB300), // gold
      Color(0xFF3498DB), // blue
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _royalGradient = LinearGradient(
    colors: [
      Color(0xFF2C3E50), // charcoal
      Color(0xFFFFB300), // gold
      Color(0xFFE74C3C), // red
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _charcoalGradient = LinearGradient(
    colors: [
      Color(0xFF2C3E50), // charcoal
      Color(0xFF34495E), // light charcoal
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _glassMorphismGradient = LinearGradient(
    colors: [
      Colors.white.withOpacity(0.3),
      Colors.white.withOpacity(0.1),
      Colors.white.withOpacity(0.2),
      Colors.white.withOpacity(0.05),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rotateController;
  
  // Particle animation controllers
  late List<AnimationController> _particleControllers;
  late List<AnimationController> _bubbleControllers;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  
  // Flag to track if initialization has been attempted
  bool _initializationAttempted = false;
  
  // Cache for failed image loads to prevent retry loops
  final Set<String> _failedImageLoads = {};
  
  // Search debounce timer
  Timer? _searchDebounceTimer;

/*  void _showLoginRequiredDialog(BuildContext context, String feature) {
    final Color _primaryRed = Color(0xFFF42A41);
    final Color _primaryGreen = Color(0xFF006A4E);
    final Color _goldAccent = Color(0xFFFFD700);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient - reduced size
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryRed, _primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Login Required',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'You need to login to $feature',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Create an account or sign in to access full details',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    
                    // Login Button - reduced size
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Login',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    // Sign Up Button - reduced size
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterScreen(role: 'user'),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryGreen,
                          side: BorderSide(color: _primaryGreen, width: 2),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Create Account',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    // Continue Browsing - slightly reduced size
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Continue Browsing',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }   */


/*   void _showLoginRequiredDialog(BuildContext context, String feature) {
  final Color _primaryRed = Color(0xFFE03C32);
  final Color _primaryGreen = Color(0xFF006A4E);
  final Color _goldAccent = Color(0xFFFFD700);
  final Color _deepRed = Color(0xFFC62828);
  
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryGreen, _primaryRed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: _primaryRed.withOpacity(0.3),
              blurRadius: 30,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient - smaller
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryRed, _primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_goldAccent, Color(0xFFFFC107)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _goldAccent.withOpacity(0.4),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Login Required',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'to access $feature',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      'Create an account or sign in to access full details',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Login Button - colorful
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _primaryGreen,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                        shadowColor: Colors.white.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Login',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  
                  // Sign Up Button - colorful
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterScreen(role: 'user'),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white, width: 1.5),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Create Account',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  
                  // Continue Browsing - elegant
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    ),
                    child: Text(
                      'Continue Browsing',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

*/



  void _showLoginRequiredDialog(BuildContext context, String feature) {
    final Color _primaryRed = Color(0xFFE03C32);
    final Color _primaryGreen = Color(0xFF006A4E);
    final Color _goldAccent = Color(0xFFFFD700);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_primaryGreen, _primaryRed]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [_primaryRed, _primaryGreen]), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                child: Column(
                  children: [
                    Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(gradient: LinearGradient(colors: [_goldAccent, Color(0xFFFFC107)]), shape: BoxShape.circle), child: Icon(Icons.lock_rounded, color: Colors.white, size: 24)),
                    SizedBox(height: 8),
                    Text('Login Required', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('to access $feature', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.9))),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen())); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _primaryGreen, padding: EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text('Login', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)))),
                    SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen(role: 'user'))); }, style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white, width: 1.5), padding: EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text('Create Account', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)))),
                    SizedBox(height: 10),
                    TextButton(onPressed: () => Navigator.pop(context), child: Text('Continue Browsing', style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.7)))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  



  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // ✅ Add WidgetsBindingObserver
    WidgetsBinding.instance.addObserver(this);
    
    _tabController = TabController(length: JobSiteCategory.values.length, vsync: this);
    
    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );
    
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    
    _rotateController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    
    // Initialize particle controllers
    _particleControllers = List.generate(30, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(seconds: 3 + (index % 3)),
      )..repeat(reverse: true);
    });
    
    _bubbleControllers = List.generate(8, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(seconds: 8 + (index * 2)),
      )..repeat(reverse: true);
    });
    
    // Start animations if app is visible
    if (_appLifecycleState == AppLifecycleState.resumed) {
      _startAnimations();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });
    
    if (state == AppLifecycleState.resumed) {
      _startAnimations();
    } else {
      _stopAnimations();
    }
  }

  void _startAnimations() {
    if (_appLifecycleState == AppLifecycleState.resumed && mounted) {
      _fadeController.forward();
      _slideController.forward();
      _pulseController.repeat(reverse: true);
      _rotateController.repeat(reverse: true);
      // Particle and bubble controllers already running via repeat
    }
  }

  void _stopAnimations() {
    _fadeController.stop();
    _slideController.stop();
    _pulseController.stop();
    _rotateController.stop();
  }

  @override
  void dispose() {
    print('🗑️ OthersJobSitesScreen disposing...');
    
    // ✅ Remove observer
    WidgetsBinding.instance.removeObserver(this);
    
    // ✅ Cancel debounce timer
    _searchDebounceTimer?.cancel();
    
    // ✅ Dispose all controllers
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    
    // ✅ Dispose particle controllers
    for (var controller in _particleControllers) {
      controller.dispose();
    }
    
    // ✅ Dispose bubble controllers
    for (var controller in _bubbleControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  Color _getCategoryColor(JobSiteCategory category) {
    switch (category) {
      case JobSiteCategory.general:
        return _charcoal;
      case JobSiteCategory.tech:
        return _accentBlue;
      case JobSiteCategory.healthcare:
        return _accentRed;
      case JobSiteCategory.education:
        return Colors.orange;
      case JobSiteCategory.remote:
        return Colors.purple;
      case JobSiteCategory.freelance:
        return _secondaryGold;
      case JobSiteCategory.entryLevel:
        return _accentGreen;
      case JobSiteCategory.executive:
        return Colors.indigo;
    }
  }

  Widget _buildAnimatedParticle(int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final controller = _particleControllers[index % _particleControllers.length];
    
    return Positioned(
      left: (index * 37) % screenWidth,
      top: (index * 53) % screenHeight,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final value = controller.value;
          return Opacity(
            opacity: (0.1 + (value * 0.2)) * (0.5 + (index % 3) * 0.1),
            child: Transform.rotate(
              angle: value * 6.28,
              child: Container(
                width: 2 + (index % 3) * 2,
                height: 2 + (index % 3) * 2,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _charcoal.withOpacity(0.5),
                      _secondaryGold.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingBubble(int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final size = 50 + (index * 15).toDouble();
    final controller = _bubbleControllers[index % _bubbleControllers.length];
    
    return Positioned(
      left: (index * 73) % screenWidth,
      top: (index * 47) % screenHeight,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final value = controller.value;
          return Transform.translate(
            offset: Offset(0, 20 * (value - 0.5)),
            child: Opacity(
              opacity: 0.1 + (value * 0.1),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _charcoal.withOpacity(0.1),
                      _secondaryGold.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _secondaryGold.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: _bodyBgGradient,
          ),
          child: Consumer<JobSitesBrowseProvider>(
            builder: (context, provider, child) {
              // Initialize provider only once
              if (!provider.isInitialized && !_initializationAttempted && !provider.isLoading) {
                _initializationAttempted = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    provider.initialize();
                  }
                });
                return _buildLoadingState(isTablet);
              }

              // Show loading while initializing
              if (provider.isLoading && provider.jobSites.isEmpty) {
                return _buildLoadingState(isTablet);
              }

              // Show error if any
              if (provider.error.isNotEmpty) {
                return _buildErrorState(provider, isTablet);
              }

              return Stack(
                children: [
                  // Animated Background Particles
                  ...List.generate(30, (index) => _buildAnimatedParticle(index)),
                  
                  // Floating Bubbles
                  ...List.generate(8, (index) => _buildFloatingBubble(index)),
                  
                  // Main Content
                  CustomScrollView(
                    physics: BouncingScrollPhysics(),
                    slivers: [
                      _buildPremiumAppBar(isTablet, provider),
                      SliverToBoxAdapter(
                        child: _buildHeader(provider, isTablet),
                      ),
                      _buildContent(provider, isTablet),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildPremiumAppBar(bool isTablet, JobSitesBrowseProvider provider) {
    return SliverAppBar(
      expandedHeight: isTablet ? 280 : 220,
      floating: false,
      pinned: true,
      snap: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_charcoal, _darkCharcoal, _lightCharcoal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 40 : 24,
                vertical: isTablet ? 30 : 20,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Pattern Line
                  Container(
                    height: 4,
                    width: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_secondaryGold, _softGold, _secondaryGold],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  
                  // Title with Gradient
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.white, _secondaryGold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'Job Sites',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 32 : 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  
                  // Subtitle
                  Text(
                    '🌐 Discover Opportunities Worldwide',
                    style: GoogleFonts.inter(
                   //   fontSize: isTablet ? 18 : 16,
                      fontSize: isTablet ? 14 : 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  SizedBox(height: isTablet ? 20 : 16),
                  
                  // Stats Row
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 16 : 12,
                          vertical: isTablet ? 8 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.work_rounded, color: _secondaryGold, size: isTablet ? 18 : 16),
                            SizedBox(width: isTablet ? 8 : 6),
                            Text(
                              '${provider.jobSites.length} Sites Available',
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 12 : 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: Colors.white, fontWeight: FontWeight.bold, size: isTablet ? 28 : 24),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildLoadingState(bool isTablet) {
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return RotationTransition(
                turns: AlwaysStoppedAnimation(value),
                child: Container(
                  width: isTablet ? 100 : 80,
                  height: isTablet ? 100 : 80,
                  decoration: BoxDecoration(
                    gradient: _royalGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _charcoal.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: isTablet ? 80 : 60,
                      height: isTablet ? 80 : 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: isTablet ? 40 : 30,
                          height: isTablet ? 40 : 30,
                          child: CircularProgressIndicator(
                            color: _charcoal,
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: isTablet ? 24 : 16),
          ShaderMask(
            shaderCallback: (bounds) => _gemstoneGradient.createShader(bounds),
            child: Text(
              'Loading Job Sites...',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          shouldAnimate
              ? ScaleTransition(
                  scale: _pulseAnimation,
                  child: Text(
                    'Discover the best opportunities',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 15 : 13,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Text(
                  'Discover the best opportunities',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 15 : 13,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildErrorState(JobSitesBrowseProvider provider, bool isTablet) {
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 40 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.85 + (0.15 * value),
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 32 : 28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_lightCharcoal.withOpacity(0.1), _accentRed.withOpacity(0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: isTablet ? 80 : 70,
                      color: _accentRed,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: isTablet ? 40 : 30),
            ShaderMask(
              shaderCallback: (bounds) => _gemstoneGradient.createShader(bounds),
              child: Text(
                'Error Loading Sites',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 30 : 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              provider.error,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 18 : 16,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 30 : 24),
            GestureDetector(
              onTap: () {
                _initializationAttempted = false;
                provider.initialize();
              },
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.92 + (0.08 * value),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 50 : 40,
                        vertical: isTablet ? 18 : 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: _royalGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: _charcoal.withOpacity(0.3),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          shouldAnimate
                              ? RotationTransition(
                                  turns: _rotateController,
                                  child: Icon(Icons.refresh_rounded, color: Colors.white, size: isTablet ? 26 : 22),
                                )
                              : Icon(Icons.refresh_rounded, color: Colors.white, size: isTablet ? 26 : 22),
                          SizedBox(width: 12),
                          Text(
                            'Try Again',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(JobSitesBrowseProvider provider, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _shadowColor,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search job sites...',
                hintStyle: GoogleFonts.inter(color: _textSecondary),
                prefixIcon: Icon(Icons.search_rounded, color: _charcoal),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: _textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isTablet ? 16 : 14),
              ),
              onChanged: (value) {
                _searchDebounceTimer?.cancel();
                _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    provider.setSearchQuery(value);
                  }
                });
              },
            ),
          ),
          
          SizedBox(height: isTablet ? 20 : 16),
          
          // Category Filters
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: JobSiteCategory.values.length,
              itemBuilder: (context, index) {
                final category = JobSiteCategory.values[index];
                final isSelected = provider.selectedCategory == category;
                final categoryColor = _getCategoryColor(category);
                final count = provider.getSitesByCategory(category).length;
                
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    onSelected: (selected) {
                      provider.setCategoryFilter(selected ? category : null);
                    },
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(category.icon, size: 14, color: isSelected ? Colors.white : categoryColor),
                        SizedBox(width: 6),
                        Text(
                          category.displayName,
                          style: GoogleFonts.poppins(
                            color: isSelected ? Colors.white : _textPrimary,
                            fontSize: isTablet ? 13 : 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (count > 0) ...[
                          SizedBox(width: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : categoryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              count.toString(),
                              style: TextStyle(
                                color: isSelected ? categoryColor : categoryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: categoryColor,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(
                        color: isSelected ? categoryColor : _borderLight,
                        width: 1,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 16 : 12,
                      vertical: isTablet ? 10 : 8,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Filter Info Bar
          if (provider.searchQuery.isNotEmpty || provider.selectedCategory != null) ...[
            SizedBox(height: isTablet ? 16 : 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _charcoal.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _charcoal.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list_rounded, size: 16, color: _charcoal),
                  SizedBox(width: 8),
                  Text(
                    '${provider.filteredSites.length} sites found',
                    style: GoogleFonts.inter(
                      color: _charcoal,
                      fontSize: isTablet ? 13 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (provider.searchQuery.isNotEmpty || provider.selectedCategory != null) ...[
                    Container(
                      width: 1,
                      height: 16,
                      color: _borderLight,
                      margin: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        provider.clearFilters();
                      },
                      child: Row(
                        children: [
                          Icon(Icons.close_rounded, size: 14, color: _accentRed),
                          SizedBox(width: 4),
                          Text(
                            'Clear',
                            style: GoogleFonts.inter(
                              color: _accentRed,
                              fontSize: isTablet ? 12 : 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(JobSitesBrowseProvider provider, bool isTablet) {
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    if (provider.filteredSites.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 40 : 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.85 + (0.15 * value),
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 32 : 28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_lightCharcoal.withOpacity(0.1), _secondaryGold.withOpacity(0.1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          provider.jobSites.isEmpty ? Icons.work_off_rounded : Icons.filter_list_off_rounded,
                          size: isTablet ? 80 : 70,
                          color: _charcoal,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: isTablet ? 40 : 30),
                ShaderMask(
                  shaderCallback: (bounds) => _gemstoneGradient.createShader(bounds),
                  child: Text(
                    provider.jobSites.isEmpty ? 'No Job Sites Found' : 'No Sites Match',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 30 : 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 16 : 12),
                Text(
                  provider.jobSites.isEmpty 
                      ? 'Check back later for updates'
                      : 'Try adjusting your search or category filter',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 18 : 16,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (provider.jobSites.isNotEmpty) ...[
                  SizedBox(height: isTablet ? 30 : 24),
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      provider.clearFilters();
                    },
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.92 + (0.08 * value),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 50 : 40,
                              vertical: isTablet ? 18 : 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: _royalGradient,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: _charcoal.withOpacity(0.3),
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.clear_all_rounded, color: Colors.white, size: isTablet ? 26 : 22),
                                SizedBox(width: 12),
                                Text(
                                  'Clear Filters',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: isTablet ? 20 : 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final site = provider.filteredSites[index];
            
            // Only apply animations if app is visible
            Widget card = _buildPremiumJobSiteCard(site, provider, index, isTablet);
            
            if (shouldAnimate) {
              card = FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: card,
                ),
              );
            }
            
            return Padding(
              padding: EdgeInsets.only(bottom: isTablet ? 20 : 16),
              child: card,
            );
          },
          childCount: provider.filteredSites.length,
        ),
      ),
    );
  }

  Widget _buildPremiumJobSiteCard(JobSite site, JobSitesBrowseProvider provider, int index, bool isTablet) {
    final categoryColor = _getCategoryColor(site.category);
    final String siteKey = '${site.id}_${site.name}';
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        // Clamp the value to ensure it's between 0.0 and 1.0
        final clampedValue = value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.92 + (0.08 * clampedValue),
          child: Opacity(
            opacity: clampedValue,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _charcoal.withOpacity(0.12),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                    spreadRadius: -3,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.9),
                          _lightCharcoal.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          if (authProvider.isGuestMode) {
                            _showLoginRequiredDialog(context, 'view this job site');
                            return;
                          }
                          _openJobSite(site, provider);
                        },
                        borderRadius: BorderRadius.circular(24),
                        splashColor: _secondaryGold.withOpacity(0.1),
                        highlightColor: Colors.transparent,
                        child: Padding(
                          padding: EdgeInsets.all(isTablet ? 18 : 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with Logo and Name
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Site Logo
                                  Container(
                                    width: isTablet ? 55 : 45,
                                    height: isTablet ? 55 : 45,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.white, _lightBg],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: categoryColor.withOpacity(0.3), width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _charcoal.withOpacity(0.1),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: _buildSiteLogo(site, size: isTablet ? 28 : 24, key: siteKey),
                                  ),
                                  
                                  SizedBox(width: 12),
                                  
                                  // Site Name and Category
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          site.name,
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.w800,
                                            color: _textPrimary,
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: categoryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: categoryColor.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(site.category.icon, size: 11, color: categoryColor),
                                              SizedBox(width: 3),
                                              Text(
                                                site.category.displayName,
                                                style: GoogleFonts.poppins(
                                                  color: categoryColor,
                                                  fontSize: isTablet ? 11 : 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Visit Count Badge
                                  Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: _preciousGradient,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _secondaryGold.withOpacity(0.3),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: shouldAnimate
                                        ? RotationTransition(
                                            turns: _rotateController,
                                            child: Icon(
                                              Icons.trending_up_rounded,
                                              color: Colors.white,
                                              size: isTablet ? 15 : 13,
                                            ),
                                          )
                                        : Icon(
                                            Icons.trending_up_rounded,
                                            color: Colors.white,
                                            size: isTablet ? 15 : 13,
                                          ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 12),
                              
                              // Description
                              Text(
                                site.description,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 13 : 12,
                                  color: _textSecondary,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              // Features
                              if (site.features.isNotEmpty) ...[
                                SizedBox(height: 10),
                                Wrap(
                                  spacing: 5,
                                  runSpacing: 5,
                                  children: site.features.map((feature) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: _glassMorphismGradient,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: _secondaryGold.withOpacity(0.25)),
                                      ),
                                      child: Text(
                                        feature,
                                        style: GoogleFonts.poppins(
                                          color: _charcoal,
                                          fontSize: isTablet ? 11 : 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                              
                              SizedBox(height: 12),
                              
                              // Stats and Visit Button
                              Row(
                                children: [
                                  // Click Count
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _charcoal.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.remove_red_eye_rounded, 
                                          size: 12,
                                          color: _charcoal
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          '${_formatNumber(site.clickCount)} clicks',
                                          style: GoogleFonts.poppins(
                                            color: _charcoal,
                                            fontSize: isTablet ? 11 : 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const Spacer(),
                                  
                                  // Visit Site Button
                                  GestureDetector(
                                    onTap: () {
                                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                      if (authProvider.isGuestMode) {
                                        _showLoginRequiredDialog(context, 'view this job site');
                                        return;
                                      }
                                      _openJobSite(site, provider);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 16 : 12,
                                        vertical: isTablet ? 8 : 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: _royalGradient,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _charcoal.withOpacity(0.25),
                                            blurRadius: 8,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Visit Site',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: isTablet ? 13 : 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 5),
                                          Icon(
                                            Icons.open_in_new_rounded,
                                            color: Colors.white,
                                            size: isTablet ? 14 : 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 10),
                              
                              // URL Row
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _charcoal.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _borderLight),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.link_rounded, 
                                      size: 14,
                                      color: _charcoal.withOpacity(0.5)
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        site.url,
                                        style: GoogleFonts.inter(
                                          color: _textSecondary,
                                          fontSize: isTablet ? 12 : 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _copyToClipboard(site.url),
                                      icon: Icon(Icons.copy_rounded, 
                                        size: 14,
                                        color: _charcoal
                                      ),
                                      constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                                      padding: EdgeInsets.zero,
                                      tooltip: 'Copy URL',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Main logo builder that handles both asset and base64
  Widget _buildSiteLogo(JobSite site, {required double size, required String key}) {
    // If previously failed, show fallback immediately
    if (_failedImageLoads.contains(key)) {
      return _buildFallbackIcon(site, size: size);
    }

    // PRIORITY 1: Try base64 logo first (for admin uploaded sites)
    if (site.logoBase64 != null && site.logoBase64!.isNotEmpty) {
      return _buildBase64Logo(site, size: size, key: key) ?? 
             _buildFallbackIcon(site, size: size);
    }
    
    // PRIORITY 2: Try asset logo (for predefined sites)
    if (site.logoUrl != null && site.logoUrl!.isNotEmpty) {
      return _buildAssetLogo(site, size: size, key: key);
    }
    
    // Fallback to icon
    return _buildFallbackIcon(site, size: size);
  }

  // Build logo from base64 string (for admin uploaded sites)
  Widget? _buildBase64Logo(JobSite site, {required double size, required String key}) {
    try {
      String base64String = site.logoBase64!;
      
      // Clean the base64 string
      if (base64String.contains('base64,')) {
        base64String = base64String.split('base64,').last;
      }
      
      // Remove any whitespace
      base64String = base64String.replaceAll(RegExp(r'\s'), '');
      
      // Ensure proper padding for base64
      while (base64String.length % 4 != 0) {
        base64String += '=';
      }
      
      final bytes = base64Decode(base64String);
      
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error decoding base64 for ${site.name}: $error');
            if (mounted) {
              setState(() {
                _failedImageLoads.add(key);
              });
            }
            return _buildFallbackIcon(site, size: size);
          },
        ),
      );
    } catch (e) {
      print('❌ Error processing base64 for ${site.name}: $e');
      if (mounted) {
        setState(() {
          _failedImageLoads.add(key);
        });
      }
      return null;
    }
  }

  // Build logo from asset (for predefined sites)
  Widget _buildAssetLogo(JobSite site, {required double size, required String key}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        site.logoUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading asset logo for ${site.name}: $error');
          if (mounted) {
            setState(() {
              _failedImageLoads.add(key);
            });
          }
          return _buildFallbackIcon(site, size: size);
        },
      ),
    );
  }

  // Fallback icon when logo fails to load
  Widget _buildFallbackIcon(JobSite site, {required double size}) {
    return Icon(
      site.category.icon,
      color: _getCategoryColor(site.category),
      size: size * 0.7,
    );
  }

  Future<void> _openJobSite(JobSite site, JobSitesBrowseProvider provider) async {
    HapticFeedback.mediumImpact();
    
    try {
      String url = site.url.trim();
      
      // Add protocol if missing
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      
      final Uri uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        // Record click
        if (site.id != null) {
          await provider.recordSiteClick(site.id!, site.name);
        }
        
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (mounted) {
          _showSnackBar('Opening ${site.name}...', _charcoal);
        }
      } else {
        if (mounted) {
          _showSnackBar('Could not open website', _accentRed);
        }
      }
    } catch (e) {
      print('Error opening website: $e');
      if (mounted) {
        _showSnackBar('Error opening website', _accentRed);
      }
    }
  }

  Future<void> _refreshSites(BuildContext context, JobSitesBrowseProvider provider) async {
    HapticFeedback.lightImpact();
    await provider.refresh();
    if (mounted) {
      _showSnackBar('Refreshed!', _charcoal);
    }
  }

  Future<void> _copyToClipboard(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      _showSnackBar('URL copied to clipboard', _charcoal);
    }
    HapticFeedback.lightImpact();
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: color == _accentRed 
                  ? [color, color.withOpacity(0.8)] 
                  : [_charcoal, _lightCharcoal],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                color == _accentRed ? Icons.error_rounded : Icons.check_circle_rounded,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}