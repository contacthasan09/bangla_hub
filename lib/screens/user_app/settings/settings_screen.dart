import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bangla_hub/main.dart';
import 'package:bangla_hub/models/user_model.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/auth/signup_screen.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:shared_preferences/shared_preferences.dart';

// IMPORTANT: Remove the global key from home_screen.dart if it's also defined there
// Keep only one global key in the entire app

class PremiumSettingsScreen extends StatefulWidget {
  @override
  _PremiumSettingsScreenState createState() => _PremiumSettingsScreenState();
}

class _PremiumSettingsScreenState extends State<PremiumSettingsScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  // Premium Color Palette - Bengali Flag Inspired
  final Color _primaryRed = Color(0xFFE03C32); // Bangladesh flag red
  final Color _primaryGreen = Color(0xFF006A4E); // Bangladesh flag green
  final Color _darkGreen = Color(0xFF00432D);
  final Color _lightGreen = Color(0xFFE8F5E9);
  final Color _goldAccent = Color(0xFFFFD700);
  final Color _deepRed = Color(0xFFC62828);
  final Color _bgGradient1 = Color(0xFF0A2F1D);
  final Color _bgGradient2 = Color(0xFF004D38);
  final Color _cardColor = Color(0x1AFFFFFF);
  final Color _borderColor = Color(0x33FFFFFF);
  final Color _textWhite = Color(0xFFFFFFFF);
  final Color _textLight = Color(0xFFE0E0E0);
  final Color _textMuted = Color(0xFFAAAAAA);
  final Color _flagGradient1 = Color(0xFF0A2F1D); // Dark green
  final Color _flagGradient2 = Color(0xFF006A4E); // Medium green
  final Color _flagGradient3 = Color(0xFFE03C32); // Bangladesh red

  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  // Controllers for edit dialogs
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _currentPasswordController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _profileImageFile;
  String? _tempLocation;
  double? _tempLatitude;
  double? _tempLongitude;
  bool _isLoadingLocation = false;
  bool _isSaving = false;

  FocusNode _phoneFocusNode = FocusNode();
  String _selectedCountryCode = '+1'; // Default to US
  String? _selectedCountryName;
  String? _selectedCountryFlag;
  bool _isPhoneValid = true;

  Country? _selectedCountry;
  bool _showPhoneField = false;

  @override
  void initState() {
    super.initState();
    
    // ✅ Add WidgetsBindingObserver
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    )..forward();
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    )..forward();
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });
    
    if (state == AppLifecycleState.resumed) {
      // App is visible - start animations
      _startAnimations();
    } else {
      // App is not visible - stop animations to save resources
      _stopAnimations();
    }
  }
  
  void _startAnimations() {
    if (_appLifecycleState == AppLifecycleState.resumed && mounted) {
      _fadeController.forward();
      _slideController.forward();
    }
  }
  
  void _stopAnimations() {
    _fadeController.stop();
    _slideController.stop();
  }

  void _showLoginRequiredDialog(BuildContext context, String feature) {
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
                padding: EdgeInsets.all(16), // Reduced from 24
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
                      padding: EdgeInsets.all(10), // Reduced from 16
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 28, // Reduced from 40
                      ),
                    ),
                    SizedBox(height: 8), // Reduced from 16
                    Text(
                      'Login Required',
                      style: GoogleFonts.poppins(
                        fontSize: 20, // Reduced from 24
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: EdgeInsets.all(20), // Reduced from 24
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'You need to login to $feature',
                      style: GoogleFonts.inter(
                        fontSize: 14, // Reduced from 16
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4), // Reduced from 8
                    Text(
                      'Create an account or sign in to access full details',
                      style: GoogleFonts.inter(
                        fontSize: 12, // Reduced from 14
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16), // Reduced from 24
                    
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
                          padding: EdgeInsets.symmetric(vertical: 12), // Reduced from 16
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Login',
                          style: GoogleFonts.poppins(
                            fontSize: 16, // Reduced from 18
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8), // Reduced from 12
                    
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
                          padding: EdgeInsets.symmetric(vertical: 12), // Reduced from 16
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Create Account',
                          style: GoogleFonts.poppins(
                            fontSize: 16, // Reduced from 18
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8), // Reduced from 12
                    
                    // Continue Browsing - slightly reduced size
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Continue Browsing',
                        style: GoogleFonts.inter(
                          fontSize: 14, // Reduced from 16
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
  }

  @override
  void dispose() {
    print('🗑️ PremiumSettingsScreen disposing...');
    
    // ✅ Remove observer
    WidgetsBinding.instance.removeObserver(this);
    
    // ✅ Dispose animation controllers
    _fadeController.dispose();
    _slideController.dispose();
    
    // ✅ Dispose focus node
    _phoneFocusNode.dispose();
    
    // ✅ Dispose all controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        // Remove the global key from here - it's causing conflicts
        // key: homeScaffoldKey, // DON'T USE THIS HERE
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _flagGradient1,
                _flagGradient2,
                _primaryGreen,
                _primaryRed.withOpacity(0.2),
              ],
              stops: [0.0, 0.4, 0.7, 1.0],
            ),
          ),
          child: shouldAnimate
              ? FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildContent(currentUser, isTablet, context),
                  ),
                )
              : _buildContent(currentUser, isTablet, context),
        ),
      ),
    );
  }

  Widget _buildContent(UserModel? currentUser, bool isTablet, BuildContext context) {
    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        // Premium App Bar with Bengali Flag Pattern
        SliverAppBar(
          expandedHeight: isTablet ? 250 : 180,
          collapsedHeight: 120,
          floating: false,
          pinned: true,
          snap: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryGreen.withOpacity(0.95),
                    _primaryRed.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 40 : 24,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bengali Pattern Design
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryRed, _goldAccent, _primaryRed],
                            stops: [0.0, 0.5, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: 20),
                      
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Setting',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: isTablet ? 36 : 28,
                                    fontWeight: FontWeight.w800,
                                    color: _textWhite,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10,
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Manage your account and preferences',
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 16 : 14,
                                    color: _textLight,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 20),
                      // Another decorative line
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryGreen.withOpacity(0.5), Colors.transparent],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            child: Column(
              children: [
                // Premium Profile Card with Flag Pattern Background
                _buildPremiumProfileCard(context, currentUser, isTablet),
                SizedBox(height: 24),

                // Account Information Card
                _buildAccountInfoCard(context, currentUser, isTablet),
                SizedBox(height: 24),

                // Profile Management Section
                _buildSectionTitle('Profile Management', isTablet),
                SizedBox(height: 16),
                _buildProfileManagementCards(context, isTablet),
                SizedBox(height: 24),

                // App Settings Section
                _buildSectionTitle('App Settings', isTablet),
                SizedBox(height: 16),
                _buildAppSettingsCards(context, isTablet),
                SizedBox(height: 32),

                // Logout Button
                _buildPremiumLogoutButton(context, isTablet),
                SizedBox(height: 40),

                // Footer with Bengali Pattern
                _buildPremiumFooter(isTablet),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumProfileCard(
      BuildContext context, UserModel? user, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 30 : 24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image with Bengali Flag Border
          Stack(
            children: [
              Container(
                width: isTablet ? 160 : 120,
                height: isTablet ? 160 : 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_primaryRed, _primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: ClipOval(
                    child: _getPremiumProfileImage(user, isTablet ? 152 : 112),
                  ),
                ),
              ),
              // Only show camera icon if user is logged in
              if (user != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _showImageSourceSheet(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryRed, _primaryGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 24),

          // Name and Email with Bengali Typography
          Column(
            children: [
              Text(
                user?.fullName ?? "Guest User",
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 28 : 22,
                  fontWeight: FontWeight.w800,
                  color: _textWhite,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: Text(
                  user?.email ?? "Not signed in",
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 16 : 14,
                    color: _textLight,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Login Button for Guest Users
          if (user == null) ...[
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _navigateToLogin(context),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  transform: Matrix4.identity()..scale(1.0),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32 : 24,
                      vertical: isTablet ? 16 : 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryRed, _primaryGreen],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                        BoxShadow(
                          color: _primaryRed.withOpacity(0.4),
                          blurRadius: 25,
                          offset: Offset(-4, 0),
                        ),
                        BoxShadow(
                          color: _primaryGreen.withOpacity(0.4),
                          blurRadius: 25,
                          offset: Offset(4, 0),
                        ),
                        BoxShadow(
                          color: _goldAccent.withOpacity(0.2),
                          blurRadius: 15,
                          offset: Offset(0, 0),
                          blurStyle: BlurStyle.inner,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(isTablet ? 8 : 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.login_rounded,
                            color: Colors.white,
                            size: isTablet ? 22 : 18,
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 8),
                        Expanded(
                          child: Text(
                            'Sign In',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                                Shadow(
                                  color: _goldAccent.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 8),
                        Container(
                          width: isTablet ? 36 : 30,
                          height: isTablet ? 36 : 30,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.4),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _goldAccent.withOpacity(0.3),
                                blurRadius: 10,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: isTablet ? 18 : 14,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 4,
                                offset: Offset(0, 1),
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

            SizedBox(height: 16),
            
            // Guest Info Text
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: _goldAccent,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sign in to access all features and save your preferences',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 13 : 12,
                        color: _textLight,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Admin Badge with Bengali Pattern (only for logged in admin users)
          if (user?.isAdmin ?? false)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_goldAccent, Color(0xFFFFC107)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: _goldAccent.withOpacity(0.4),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Admin',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

          // Member Since with Bengali Date (only for logged in users)
          if (user?.createdAt != null)
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: _primaryGreen, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Joined ${_formatDate(user!.createdAt)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Navigation helper methods
  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterScreen(role: 'user')),
    );
  }

  Widget _buildAccountInfoCard(
      BuildContext context, UserModel? user, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 28 : 22),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryRed, _primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.account_circle_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.w800,
                        color: _textWhite,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your account details and status',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 14 : 12,
                        color: _textLight,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Email (Read-only)
          _buildInfoRow(
            context,
            Icons.email_rounded,
            'Email Address',
            user?.email ?? 'Not available',
            isTablet,
            isEditable: false,
            color: _primaryRed,
          ),
          SizedBox(height: 16),

          // Phone (Read-only for now)
          _buildInfoRow(
            context,
            Icons.phone_rounded,
            'Phone Number',
            user?.phoneNumber?.isNotEmpty ?? false ? user!.phoneNumber! : 'Not set',
            isTablet,
            isEditable: false,
            color: Colors.green,
          ),
          SizedBox(height: 16),

          // Location (Editable)
          _buildInfoRow(
            context,
            Icons.location_on_rounded,
            'Location',
            user?.location?.isNotEmpty ?? false ? user!.location! : 'Not set',
            isTablet,
            isEditable: true,
            color: _primaryRed,
            onEdit: () {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              // Check if guest mode
              if (authProvider.isGuestMode) {
                _showLoginRequiredDialog(context, 'Edit location');
                return;
              }
              _showLocationEditDialog(context, user);
            },
          ),
          SizedBox(height: 16),

          // Email Verification Status
          _buildInfoRow(
            context,
            Icons.verified_rounded,
            'Email Verification',
            user?.isEmailVerified ?? false ? 'Verified' : 'Not Verified',
            isTablet,
            isEditable: false,
            color: user?.isEmailVerified ?? false ? Colors.green : Colors.orange,
            trailingWidget: user?.isEmailVerified ?? false
                ? Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green, Colors.lightGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      // Check if guest mode
                      if (authProvider.isGuestMode) {
                        _showLoginRequiredDialog(context, 'Resend Verification Email');
                        return;
                      }
                      _resendVerificationEmail(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange, Colors.deepOrange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Send Again',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    bool isTablet, {
    required bool isEditable,
    required Color color,
    VoidCallback? onEdit,
    Widget? trailingWidget,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEditable ? onEdit : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 14 : 12,
                        color: _textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 16 : 14,
                        color: _textWhite,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isEditable)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: color,
                      size: 20,
                    ),
                  ),
                ),
              if (trailingWidget != null) ...[
                SizedBox(width: 12),
                trailingWidget,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isTablet) {
    return Container(
      padding: EdgeInsets.only(left: 4, bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryRed, _primaryGreen],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 22 : 20,
              fontWeight: FontWeight.w800,
              color: _textWhite,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileManagementCards(BuildContext context, bool isTablet) {
    return Column(
      children: [
        _buildPremiumSettingCard(
          context,
          icon: Icons.person_rounded,
          title: 'Edit Profile',
          subtitle: 'Update your name and information',
          gradientColors: [_primaryGreen, _darkGreen],
          onTap: () => _showEditProfileDialog(context),
          isTablet: isTablet,
        ),
        SizedBox(height: 16),
        _buildPremiumSettingCard(
          context,
          icon: Icons.lock_reset_rounded,
          title: 'Change Password',
          subtitle: 'Update your password for security',
          gradientColors: [_primaryRed, _deepRed],
          onTap: () {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            // Check if guest mode
            if (authProvider.isGuestMode) {
              _showLoginRequiredDialog(context, 'Change Password');
              return;
            }
            _showChangePasswordDialog(context);
          },
          isTablet: isTablet,
        ),
      ],
    );
  }

  Widget _buildAppSettingsCards(BuildContext context, bool isTablet) {
    return Column(
      children: [
        _buildPremiumSettingCard(
          context,
          icon: Icons.security_rounded,
          title: 'Privacy & Security',
          subtitle: 'Manage your privacy settings',
          gradientColors: [_primaryRed, _primaryGreen],
          onTap: () {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            // Check if guest mode
            if (authProvider.isGuestMode) {
              _showLoginRequiredDialog(context, 'Privacy & Security Settings');
              return;
            }
            _showComingSoon(context);
          },
          isTablet: isTablet,
        ),
        SizedBox(height: 16),
        _buildPremiumSettingCard(
          context,
          icon: Icons.help_outline_rounded,
          title: 'Help & Support',
          subtitle: 'Get help or contact support',
          gradientColors: [_primaryGreen, _darkGreen],
          onTap: () {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            // Check if guest mode
            if (authProvider.isGuestMode) {
              _showLoginRequiredDialog(context, 'Help & Support');
              return;
            }
            _showComingSoon(context);
          },
          isTablet: isTablet,
        ),
        SizedBox(height: 16),
        _buildPremiumSettingCard(
          context,
          icon: Icons.info_outline_rounded,
          title: 'About',
          subtitle: 'Learn more about BanglaHub',
          gradientColors: [_primaryRed, _primaryGreen],
          onTap: () => _showAboutDialog(context),
          isTablet: isTablet,
        ),
      ],
    );
  }

  Widget _buildPremiumSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 18 : 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.4),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: isTablet ? 50 : 44,
                height: isTablet ? 50 : 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isTablet ? 22 : 18,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 10 : 9,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumLogoutButton(BuildContext context, bool isTablet) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          // Check if guest mode
          if (authProvider.isGuestMode) {
            _showLoginRequiredDialog(context, 'Logout');
            return;
          }
          _showPremiumLogoutDialog(context);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 22 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryRed, _deepRed],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _primaryRed.withOpacity(0.4),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: isTablet ? 28 : 24,
              ),
              SizedBox(width: 16),
              Text(
                'Logout',
                style: GoogleFonts.notoSansBengali(
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFooter(bool isTablet) {
    return Column(
      children: [
        Container(
          height: 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryGreen, _primaryRed, _primaryGreen],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(height: 24),
        Text(
          'BanglaHub Community',
          style: GoogleFonts.notoSansBengali(
            fontSize: isTablet ? 18 : 16,
            color: _textWhite,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Version 1.0.0 • © 2026 All rights reserved',
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 14 : 12,
            color: _textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        // Bengali Pattern
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            8,
            (index) => Container(
              width: 12,
              height: 4,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryGreen, _primaryRed],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper Methods
  Widget _getPremiumProfileImage(UserModel? user, double size) {
    if (_profileImageFile != null) {
      return Image.file(
        _profileImageFile!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (user?.profileImageUrl == null || user!.profileImageUrl!.isEmpty) {
      return _buildDefaultProfileAvatar(size);
    }

    final imageUrl = user.profileImageUrl!;

    if (imageUrl.startsWith('data:image/')) {
      try {
        final base64Data = imageUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image(
          image: MemoryImage(bytes),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultProfileAvatar(size);
          },
        );
      } catch (e) {
        return _buildDefaultProfileAvatar(size);
      }
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            color: _goldAccent,
            strokeWidth: 2.5,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildDefaultProfileAvatar(size);
      },
    );
  }

  Widget _buildDefaultProfileAvatar(double size) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryGreen, _primaryRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          color: Colors.white.withOpacity(0.9),
          size: size * 0.5,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${monthNames[date.month - 1]}, ${date.year}';
  }

  // Dialog Methods
  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _bgGradient2,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          border: Border.all(color: _borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 16),
              Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: _borderColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Update Profile Picture',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textWhite,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Choose a method to update your profile picture',
                style: TextStyle(
                  fontSize: 14,
                  color: _textMuted,
                ),
              ),
              SizedBox(height: 24),
              _buildImageSourceOption(
                icon: Icons.camera_alt_rounded,
                title: 'Capture Photo',
                subtitle: 'Use your camera',
                gradientColors: [_primaryGreen, _darkGreen],
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              SizedBox(height: 16),
              _buildImageSourceOption(
                icon: Icons.photo_library_rounded,
                title: 'Choose from Gallery',
                subtitle: 'Select from your photos',
                gradientColors: [_primaryRed, _deepRed],
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              SizedBox(height: 32),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18),
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: _textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        const maxSize = 5 * 1024 * 1024;

        if (fileSize > maxSize) {
          _showSnackBar('Image size must be less than 5MB', _primaryRed);
          return;
        }

        final extension = pickedFile.path.split('.').last.toLowerCase();
        final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

        if (!allowedExtensions.contains(extension)) {
          _showSnackBar('দয়া করে একটি বৈধ ছবি নির্বাচন করুন (JPG, PNG, GIF, WebP)', _primaryRed);
          return;
        }

        if (mounted) {
          setState(() {
            _profileImageFile = file;
          });
        }

        // Upload image to Firestore as base64
        await _uploadProfileImage(file);
      }
    } catch (e) {
      _handleImagePickerError(e);
    }
  }

  Future<void> _uploadProfileImage(File imageFile) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;
      if (currentUser == null) return;

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryGreen, _primaryRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: _goldAccent,
                  strokeWidth: 3,
                ),
                SizedBox(height: 20),
                Text(
                  'Uploading...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Convert to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // Update user in Firestore
      final updatedUser = currentUser.copyWith(profileImageUrl: base64Image);
      await authProvider.updateUserProfile(updatedUser);

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Profile picture updated successfully!', _primaryGreen);
      }

    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Failed to upload image: $e', _primaryRed);
      }
    }
  }

  void _showEditProfileDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    _firstNameController.text = user?.firstName ?? '';
    _lastNameController.text = user?.lastName ?? '';
    _phoneController.text = user?.phoneNumber?.replaceFirst(_selectedCountryCode, '') ?? '';
    
    // Initialize country code from user data
    if (user?.countryCode != null) {
      _selectedCountryCode = user!.countryCode!;
    }
    
    // Set initial state for phone field
    _showPhoneField = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final mediaQuery = MediaQuery.of(context);
          final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
          final screenHeight = mediaQuery.size.height;
          final isSmallScreen = screenHeight < 600;
          
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isKeyboardVisible ? 10 : 20,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 10,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  minWidth: 280,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_bgGradient2, _primaryGreen.withOpacity(0.9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: _borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryRed, _primaryGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Edit Profile',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 20 : 22,
                                fontWeight: FontWeight.w800,
                                color: _textWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Form Fields
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // First Name
                          TextFormField(
                            controller: _firstNameController,
                            style: TextStyle(
                              color: _textWhite, 
                              fontSize: isSmallScreen ? 15 : 16
                            ),
                            decoration: InputDecoration(
                              labelText: 'First Name',
                              labelStyle: TextStyle(
                                color: _textMuted,
                                fontSize: isSmallScreen ? 14 : null,
                              ),
                              prefixIcon: Icon(Icons.person, color: _primaryRed),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryGreen),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: isSmallScreen ? 14 : 16,
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),

                          // Last Name
                          TextFormField(
                            controller: _lastNameController,
                            style: TextStyle(
                              color: _textWhite, 
                              fontSize: isSmallScreen ? 15 : 16
                            ),
                            decoration: InputDecoration(
                              labelText: 'Last Name',
                              labelStyle: TextStyle(
                                color: _textMuted,
                                fontSize: isSmallScreen ? 14 : null,
                              ),
                              prefixIcon: Icon(Icons.person_outline, color: _primaryRed),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryGreen),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: isSmallScreen ? 14 : 16,
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),

                          // Phone Number Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_rounded,
                                    color: _textLight,
                                    size: isSmallScreen ? 18 : 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Phone Number',
                                      style: GoogleFonts.poppins(
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: _textWhite,
                                      ),
                                    ),
                                  ),
                                  if (!_showPhoneField)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _showPhoneField = true;
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [_primaryRed, _primaryGreen],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Change',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 8),

                              // Current Phone Display or Edit Field
                              if (!_showPhoneField && user?.phoneNumber != null)
                                Container(
                                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.phone_android_rounded,
                                        color: _primaryRed,
                                        size: isSmallScreen ? 18 : 20,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Current Phone',
                                              style: TextStyle(
                                                fontSize: isSmallScreen ? 11 : 12,
                                                color: _textMuted,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              user!.phoneNumber!,
                                              style: TextStyle(
                                                fontSize: isSmallScreen ? 14 : 16,
                                                color: _textWhite,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              if (_showPhoneField || user?.phoneNumber == null)
                                _buildPremiumPhoneNumberField(context, isSmallScreen),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Info Text
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_rounded, 
                              color: _primaryRed, 
                              size: isSmallScreen ? 18 : 20
                            ),
                            SizedBox(width: isSmallScreen ? 8 : 12),
                            Expanded(
                              child: Text(
                                _showPhoneField 
                                  ? 'Enter your new phone number with country code'
                                  : 'Phone number can be changed by clicking "Change"',
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: isSmallScreen ? 13 : 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Buttons
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isKeyboardVisible && isSmallScreen) SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      _showPhoneField = false;
                                      Navigator.pop(context);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: isSmallScreen ? 14 : 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _borderColor),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: _textMuted,
                                            fontWeight: FontWeight.w700,
                                            fontSize: isSmallScreen ? 15 : 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 12 : 16),
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isSaving ? null : () async {
                                      await _saveProfileChanges(context, setState);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: isSmallScreen ? 14 : 16,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [_primaryGreen, _darkGreen],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _primaryGreen.withOpacity(0.4),
                                            blurRadius: 10,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: _isSaving
                                            ? SizedBox(
                                                width: isSmallScreen ? 20 : 24,
                                                height: isSmallScreen ? 20 : 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: isSmallScreen ? 2.5 : 3,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                              'Save',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: isSmallScreen ? 15 : 16,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Add extra spacing when keyboard is visible on small screens
                          if (isKeyboardVisible && isSmallScreen) SizedBox(height: 12),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumPhoneNumberField(BuildContext context, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _phoneFocusNode.hasFocus ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.03),
        border: Border.all(
          color: _phoneFocusNode.hasFocus ? _primaryGreen : _borderColor,
          width: _phoneFocusNode.hasFocus ? 2 : 1.5,
        ),
        boxShadow: _phoneFocusNode.hasFocus
            ? [
                BoxShadow(
                  color: _primaryGreen.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Country Code Picker
          GestureDetector(
            onTap: () => _showCountryPickerForPhone(),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 14 : 18,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryGreen.withOpacity(0.1),
                    _primaryRed.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                border: Border(
                  right: BorderSide(
                    color: _borderColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedCountry != null)
                    Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text(
                        _selectedCountry!.flagEmoji,
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                      ),
                    ),
                  Text(
                    _selectedCountryCode,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.white,
                    size: isSmallScreen ? 18 : 20,
                  ),
                ],
              ),
            ),
          ),
          
          // Phone Number Input
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.poppins(
                color: _textWhite,
                fontSize: isSmallScreen ? 14 : 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
              decoration: InputDecoration(
                hintText: 'Enter phone number',
                hintStyle: GoogleFonts.poppins(
                  color: _textMuted,
                  fontSize: isSmallScreen ? 14 : 15,
                  letterSpacing: 0.3,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 14 : 18,
                ),
                prefixIcon: Container(
                  width: 50,
                  child: Icon(
                    Icons.phone_outlined,
                    color: _phoneFocusNode.hasFocus ? _primaryGreen : _textMuted,
                    size: isSmallScreen ? 20 : 22,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                
                String digits = value.replaceAll(RegExp(r'\D'), '');
                if (digits.length < 7) {
                  return 'Phone number is too short';
                }
                if (digits.length > 15) {
                  return 'Phone number is too long';
                }
                
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  // Add country picker function
  void _showCountryPickerForPhone() async {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search Country',
          hintText: 'Start typing country name...',
          hintStyle: TextStyle(color: _textMuted),
          prefixIcon: Icon(Icons.search, color: _primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _primaryGreen, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
        ),
      ),
      onSelect: (Country country) {
        if (mounted) {
          setState(() {
            _selectedCountry = country;
            _selectedCountryCode = country.phoneCode;
          });
        }
      },
    );
  }

  // Update the saveProfileChanges method to include phone number
  Future<void> _saveProfileChanges(BuildContext context, StateSetter setState) async {
    setState(() => _isSaving = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;
      
      if (currentUser != null) {
        final firstName = _firstNameController.text.trim();
        final lastName = _lastNameController.text.trim();
        String? phoneNumber;
        
        // Validate first name
        if (firstName.isEmpty) {
          _showSnackBar('Please enter first name', _primaryRed);
          setState(() => _isSaving = false);
          return;
        }

        // Handle phone number if being changed
        if (_showPhoneField) {
          final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
          if (phoneDigits.isNotEmpty) {
            // Validate phone number
            if (phoneDigits.length < 7) {
              _showSnackBar('Phone number is too short', _primaryRed);
              setState(() => _isSaving = false);
              return;
            }
            if (phoneDigits.length > 15) {
              _showSnackBar('Phone number is too long', _primaryRed);
              setState(() => _isSaving = false);
              return;
            }
            
            // Format phone number with country code
            phoneNumber = '$_selectedCountryCode$phoneDigits';
          }
        }
        
        // Get selected country name
        String? countryName;
        if (_selectedCountry != null) {
          countryName = _selectedCountry!.name;
        } else if (currentUser.country != null) {
          countryName = currentUser.country;
        }
        
        final updatedUser = currentUser.copyWith(
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber ?? currentUser.phoneNumber,
          country: countryName,
          countryCode: _selectedCountryCode,
        );
        
        await authProvider.updateUserProfile(updatedUser);
        
        // Reset phone field state
        _showPhoneField = false;
        
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar('Profile updated successfully!', _primaryGreen);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to update profile: $e', _primaryRed);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showLocationEditDialog(BuildContext context, UserModel? user) {
    _locationController.text = user?.location ?? '';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final mediaQuery = MediaQuery.of(context);
          final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
          final screenHeight = mediaQuery.size.height;
          final isSmallScreen = screenHeight < 650;
          final hasCurrentLocation = user?.location?.isNotEmpty ?? false;
          final hasTempLocation = _tempLocation != null;
          
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isKeyboardVisible ? 8 : 16,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  minWidth: 300,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_bgGradient2, _primaryGreen.withOpacity(0.9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: _borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 18 : 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: isSmallScreen ? 44 : 48,
                            height: isSmallScreen ? 44 : 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryRed, _primaryGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.location_on_rounded, 
                              color: Colors.white, 
                              size: isSmallScreen ? 24 : 28
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),
                          Expanded(
                            child: Text(
                              'Update Location',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 20 : 22,
                                fontWeight: FontWeight.w800,
                                color: _textWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 18 : 24),

                      // Current Location Display
                      if (hasCurrentLocation)
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _borderColor),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded, 
                                color: _primaryGreen, 
                                size: isSmallScreen ? 20 : 24
                              ),
                              SizedBox(width: isSmallScreen ? 12 : 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current location',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 11 : 12,
                                        color: _textMuted,
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 4 : 6),
                                    Text(
                                      user!.location!,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 16,
                                        color: _textWhite,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (hasCurrentLocation) SizedBox(height: isSmallScreen ? 16 : 20),

                      // Manual Location Input
                      TextFormField(
                        controller: _locationController,
                        style: TextStyle(
                          color: _textWhite, 
                          fontSize: isSmallScreen ? 15 : 16
                        ),
                        decoration: InputDecoration(
                          labelText: 'Enter new location',
                          labelStyle: TextStyle(
                            color: _textMuted,
                            fontSize: isSmallScreen ? 14 : null,
                          ),
                          prefixIcon: Icon(Icons.edit_location_rounded, color: _primaryGreen),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _primaryGreen),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: isSmallScreen ? 14 : 16,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // OR Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: _borderColor, thickness: 1)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
                            child: Text(
                              'Or',
                              style: TextStyle(
                                color: _textMuted, 
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 13 : null,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: _borderColor, thickness: 1)),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Get Current Location Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoadingLocation ? null : () => _getCurrentLocation(setState),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryGreen, _darkGreen],
                                begin: Alignment.centerLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryGreen.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isLoadingLocation)
                                  SizedBox(
                                    width: isSmallScreen ? 20 : 24,
                                    height: isSmallScreen ? 20 : 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: isSmallScreen ? 2 : 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.gps_fixed_rounded, 
                                    color: Colors.white, 
                                    size: isSmallScreen ? 20 : 24
                                  ),
                                SizedBox(width: isSmallScreen ? 12 : 16),
                                Expanded(
                                  child: Text(
                                    'Use current location',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Location Preview
                      if (hasTempLocation)
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _primaryGreen),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded, 
                                color: _primaryGreen, 
                                size: isSmallScreen ? 20 : 24
                              ),
                              SizedBox(width: isSmallScreen ? 12 : 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Selected location',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 11 : 12,
                                        color: _primaryGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 4 : 6),
                                    Text(
                                      _tempLocation!,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 16,
                                        color: _textWhite,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (hasTempLocation) SizedBox(height: isSmallScreen ? 16 : 20),

                      // Buttons
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Extra spacing when keyboard is visible
                          if (isKeyboardVisible && isSmallScreen) SizedBox(height: 8),
                          
                          Row(
                            children: [
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      _tempLocation = null;
                                      Navigator.pop(context);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: isSmallScreen ? 14 : 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _borderColor),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: _textMuted,
                                            fontWeight: FontWeight.w700,
                                            fontSize: isSmallScreen ? 14 : 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 12 : 16),
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isSaving ? null : () async {
                                      await _saveLocationChanges(context, setState);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: isSmallScreen ? 14 : 16,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [_primaryGreen, _darkGreen],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _primaryGreen.withOpacity(0.4),
                                            blurRadius: 10,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: _isSaving
                                            ? SizedBox(
                                                width: isSmallScreen ? 20 : 24,
                                                height: isSmallScreen ? 20 : 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: isSmallScreen ? 2.5 : 3,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                              'Save',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: isSmallScreen ? 14 : 16,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          // Extra spacing when keyboard is visible
                          if (isKeyboardVisible && isSmallScreen) SizedBox(height: 12),
                        ],
                      ),
                      
                      // Add extra bottom padding only when keyboard is visible
                      if (isKeyboardVisible && !isSmallScreen) SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _getCurrentLocation(StateSetter setState) async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location service is enabled
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showSnackBar('Location services are disabled. Please enable it.', _primaryRed);
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission denied.', _primaryRed);
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
          'Location permission has been permanently denied. Please enable it from the app settings.',
          _primaryRed,
        );
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Get current position safely
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        );
      } on TimeoutException {
        _showSnackBar('Location request timed out. Please try again.', _primaryRed);
        setState(() => _isLoadingLocation = false);
        return;
      } catch (e) {
        _showSnackBar('Current location not found: $e', _primaryRed);
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Get City & Country
      String locationText = '';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          List<String> parts = [];
          if (place.locality != null && place.locality!.isNotEmpty) {
            parts.add(place.locality!);
          }
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            parts.add(place.administrativeArea!);
          }
          if (place.country != null && place.country!.isNotEmpty) {
            parts.add(place.country!);
          }
          locationText = parts.join(', ');
        }

        if (locationText.isEmpty) {
          locationText =
              '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        }
      } catch (_) {
        locationText =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }

      if (mounted) {
        setState(() {
          _tempLocation = locationText;
          _tempLatitude = position.latitude;
          _tempLongitude = position.longitude;
          _locationController.text = locationText;
          _isLoadingLocation = false;
        });
      }

      _showSnackBar('Location found! $locationText', _primaryGreen);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
      _showSnackBar('Location not found: $e', _primaryRed);
    }
  }

  Future<void> _saveLocationChanges(BuildContext context, StateSetter setState) async {
    setState(() => _isSaving = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;
      
      if (currentUser != null) {
        final location = _tempLocation ?? _locationController.text.trim();
        
        if (location.isEmpty) {
          _showSnackBar('Please enter a location', _primaryRed);
          setState(() => _isSaving = false);
          return;
        }

        final updatedUser = currentUser.copyWith(
          location: location,
          latitude: _tempLatitude,
          longitude: _tempLongitude,
        );
        
        await authProvider.updateUserProfile(updatedUser);
        
        _tempLocation = null;
        
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar('Location updated successfully!', _primaryGreen);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to update location: $e', _primaryRed);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final mediaQuery = MediaQuery.of(context);
          final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
          final screenHeight = mediaQuery.size.height;
          final isSmallScreen = screenHeight < 600;
          
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isKeyboardVisible ? 10 : 20,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 10,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  minWidth: 280,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_bgGradient2, _primaryGreen.withOpacity(0.9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: _borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryRed, _primaryGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.lock_reset_rounded, color: Colors.white, size: 24),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Change Password',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 20 : 22,
                                fontWeight: FontWeight.w800,
                                color: _textWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Form Fields
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _currentPasswordController,
                            obscureText: true,
                            style: TextStyle(
                              color: _textWhite, 
                              fontSize: isSmallScreen ? 15 : 16
                            ),
                            decoration: InputDecoration(
                              labelText: 'Current Password',
                              labelStyle: TextStyle(
                                color: _textMuted,
                                fontSize: isSmallScreen ? 14 : null,
                              ),
                              prefixIcon: Icon(Icons.lock_rounded, color: _primaryRed),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryRed),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: isSmallScreen ? 14 : 16,
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),

                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: true,
                            style: TextStyle(
                              color: _textWhite, 
                              fontSize: isSmallScreen ? 15 : 16
                            ),
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              labelStyle: TextStyle(
                                color: _textMuted,
                                fontSize: isSmallScreen ? 14 : null,
                              ),
                              prefixIcon: Icon(Icons.lock_open_rounded, color: _primaryGreen),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryGreen),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: isSmallScreen ? 14 : 16,
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),

                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            style: TextStyle(
                              color: _textWhite, 
                              fontSize: isSmallScreen ? 15 : 16
                            ),
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              labelStyle: TextStyle(
                                color: _textMuted,
                                fontSize: isSmallScreen ? 14 : null,
                              ),
                              prefixIcon: Icon(Icons.lock_reset_rounded, color: _primaryGreen),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryGreen),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: isSmallScreen ? 14 : 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Info Text
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.security_rounded, 
                              color: _primaryGreen, 
                              size: isSmallScreen ? 18 : 20
                            ),
                            SizedBox(width: isSmallScreen ? 8 : 12),
                            Expanded(
                              child: Text(
                                'Password must be at least 8 characters',
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: isSmallScreen ? 13 : 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Buttons
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isKeyboardVisible && isSmallScreen) SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Navigator.pop(context),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: isSmallScreen ? 14 : 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _borderColor),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: _textMuted,
                                            fontWeight: FontWeight.w700,
                                            fontSize: isSmallScreen ? 15 : 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 12 : 16),
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isSaving ? null : () async {
                                      await _changePassword(context, setState);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: isSmallScreen ? 14 : 16,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [_primaryRed, _deepRed],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _primaryRed.withOpacity(0.4),
                                            blurRadius: 10,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: _isSaving
                                            ? SizedBox(
                                                width: isSmallScreen ? 20 : 24,
                                                height: isSmallScreen ? 20 : 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: isSmallScreen ? 2.5 : 3,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                              'Update',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: isSmallScreen ? 15 : 16,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Add extra spacing when keyboard is visible on small screens
                          if (isKeyboardVisible && isSmallScreen) SizedBox(height: 12),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _changePassword(BuildContext context, StateSetter setState) async {
    setState(() => _isSaving = true);
    
    try {
      final currentPassword = _currentPasswordController.text.trim();
      final newPassword = _newPasswordController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      // Validation
      if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
        _showSnackBar('Please fill in all fields', _primaryRed);
        setState(() => _isSaving = false);
        return;
      }

      if (newPassword.length < 8) {
        _showSnackBar('Password must be at least 8 characters', _primaryRed);
        setState(() => _isSaving = false);
        return;
      }

      if (newPassword != confirmPassword) {
        _showSnackBar('New password does not match', _primaryRed);
        setState(() => _isSaving = false);
        return;
      }

      final authProvider = context.read<AuthProvider>();
      await authProvider.updatePassword(
        context: context,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      // Clear controllers
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Password changed successfully!', _primaryGreen);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to change password: $e', _primaryRed);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _resendVerificationEmail(BuildContext context) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      
      if (user != null) {
        await authProvider.sendVerificationEmail();
        _showSnackBar('Verification email sent! Please check your inbox.', _primaryGreen);
      }
    } catch (e) {
      _showSnackBar('Failed to send verification email: $e', _primaryRed);
    }
  }

  void _showPremiumLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_bgGradient2, _primaryRed.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: _borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryRed, _deepRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryRed.withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Confirm Logout',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _textWhite,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Are you sure you want to log out of BanglaHub?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _textLight,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderColor),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                color: _textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          await _performPremiumLogout(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryRed, _deepRed],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryRed.withOpacity(0.4),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

/* Future<void> _performPremiumLogout(BuildContext context) async {
  BuildContext? dialogContext;
  
  try {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogContext = context;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryGreen, _primaryRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: _goldAccent,
                  strokeWidth: 3,
                ),
                SizedBox(height: 20),
                Text(
                  'Logging out...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    final authProvider = context.read<AuthProvider>();
    await authProvider.signOut();
    
    // Clear saved index from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_tab_index');
    print('📊 Cleared saved tab index on logout');

    // ✅ CRITICAL FIX: Use a post-frame callback to ensure the dialog is popped
    // before the widget tree is rebuilt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pop the loading dialog first
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      }
      
      // Then navigate to login screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });

  } catch (e) {
    // Handle error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      }
      _showSnackBar('Logout failed: $e', _primaryRed);
    });
  }
}  */


/* Future<void> _performPremiumLogout(BuildContext context) async {
  BuildContext? dialogContext;
  
  try {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogContext = context;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryGreen, _primaryRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: _goldAccent,
                  strokeWidth: 3,
                ),
                SizedBox(height: 20),
                Text(
                  'Logging out...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    final authProvider = context.read<AuthProvider>();
    await authProvider.signOut();
    
    // Clear saved index from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_tab_index');
    print('📊 Cleared saved tab index on logout');

    // ✅ FIX: Pop dialog and navigate with a slight delay
    if (dialogContext != null && Navigator.canPop(dialogContext!)) {
      Navigator.of(dialogContext!, rootNavigator: true).pop();
    }
    
    // ✅ Use a microtask to ensure the dialog is fully dismissed
    Future.microtask(() {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    });

  } catch (e) {
    // Handle error
    if (dialogContext != null && Navigator.canPop(dialogContext!)) {
      Navigator.of(dialogContext!, rootNavigator: true).pop();
    }
    if (mounted) {
      _showSnackBar('Logout failed: $e', _primaryRed);
    }
  }
} */

Future<void> _performPremiumLogout(BuildContext context) async {
  BuildContext? dialogContext;
  
  try {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogContext = context;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryGreen, _primaryRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: _goldAccent,
                  strokeWidth: 3,
                ),
                SizedBox(height: 20),
                Text(
                  'Logging out...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    final authProvider = context.read<AuthProvider>();
    await authProvider.signOut();
    
    // Clear saved index from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_tab_index');
    print('📊 Cleared saved tab index on logout');

    // ✅ FIX: First pop the loading dialog
    if (dialogContext != null && Navigator.canPop(dialogContext!)) {
      Navigator.of(dialogContext!, rootNavigator: true).pop();
    }

    // ✅ Use global navigator key instead of context
    // This is more reliable because it's always valid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use the global navigator key from main.dart
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });

  } catch (e) {
    // Handle error
    if (dialogContext != null && Navigator.canPop(dialogContext!)) {
      Navigator.of(dialogContext!, rootNavigator: true).pop();
    }
    
    // Use global navigator key for error case too
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: _primaryRed,
          ),
        );
      }
    });
  }
}

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_bgGradient2, _primaryGreen.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: _borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_goldAccent, Color(0xFFFFC107)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _goldAccent.withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.info_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'About BanglaHub',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _textWhite,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'BanglaHub is a premium community platform that connects Bengali people worldwide.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textLight,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAboutFeature('🌍 Connect with the global Bengali community'),
                    _buildAboutFeature('📅 Share and discover cultural events'),
                    _buildAboutFeature('🏢 Find local Bengali businesses'),
                    _buildAboutFeature('📰 Stay updated with Bengali news'),
                    _buildAboutFeature('👥 Build meaningful relationships'),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Center(
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: _textWhite,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
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

  Widget _buildAboutFeature(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.arrow_right_rounded, size: 24, color: _primaryGreen),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: _textLight, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    _showSnackBar('Coming soon!', _primaryGreen);
  }

  void _handleImagePickerError(dynamic error) {
    String errorMessage = 'Failed to pick image';

    if (error is PlatformException) {
      switch (error.code) {
        case 'photo_access_denied':
          errorMessage = 'Photo access denied. Please enable photo permissions.';
          break;
        case 'camera_access_denied':
          errorMessage = 'Camera access denied. Please enable camera permissions.';
          break;
        case 'no_media_selected':
          errorMessage = 'No image selected';
          break;
        case 'cancelled':
          errorMessage = 'Image selection cancelled';
          break;
        default:
          errorMessage = error.message ?? 'An unknown error occurred';
      }
    }

    _showSnackBar(errorMessage, _primaryRed);
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
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
                color == _primaryGreen ? Icons.check_circle_rounded : Icons.error_rounded,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.zero,
      ),
    );
  }
}