import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:bangla_hub/main.dart';
import 'package:bangla_hub/models/user_model.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/auth/signup_screen.dart';
import 'package:bangla_hub/screens/user_app/webview_screen.dart';
import 'package:bangla_hub/services/cloudinary_service.dart';
import 'package:bangla_hub/widgets/common/global_location_guard.dart';
import 'package:bangla_hub/widgets/common/profile_image_picker.dart';
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
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class PremiumSettingsScreen extends StatefulWidget {
  @override
  _PremiumSettingsScreenState createState() => _PremiumSettingsScreenState();
}

class _PremiumSettingsScreenState extends State<PremiumSettingsScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

    bool _isInitialized = false;
      bool _isRefreshing = false; // Add this flag
        bool _isUpdatingImage = false;



      // Add this flag
  bool _isUploading = false;
  File? _pendingUploadFile;


  // Premium Color Palette - Bengali Flag Inspired
  final Color _primaryRed = Color(0xFFE03C32);
  final Color _primaryGreen = Color(0xFF006A4E);
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
  final Color _flagGradient1 = Color(0xFF0A2F1D);
  final Color _flagGradient2 = Color(0xFF006A4E);
  final Color _flagGradient3 = Color(0xFFE03C32);

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
  String _selectedCountryCode = '+1';
  String? _selectedCountryName;
  String? _selectedCountryFlag;
  bool _isPhoneValid = true;

  Country? _selectedCountry;
  bool _showPhoneField = false;

  // URLs for legal pages
  final String privacyPolicyUrl = 'https://contacthasan09.github.io/banglahub-us/privacy_policy.html';
  final String termsOfServiceUrl = 'https://contacthasan09.github.io/banglahub-us/terms_of_service.html';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
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
      _startAnimations();
    } else {
      _stopAnimations();
    }
  }


// In your PremiumSettingsScreen, update the didChangeDependencies:

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  
  // DO NOT auto-refresh here - it causes infinite loops
  // Only mark as initialized
  if (!_isInitialized && mounted) {
    _isInitialized = true;
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
  void dispose() {
    print('🗑️ PremiumSettingsScreen disposing...');
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _slideController.dispose();
    _phoneFocusNode.dispose();
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
    return LocationGuard(
      required: false, 
      child: _buildMainContent(context),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
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
                                'Settings',
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
              _buildPremiumProfileCard(context, currentUser, isTablet),
              
              // Refresh Button (for debugging - remove after fixing)
          /*    if (currentUser != null)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: GestureDetector(
                    onTap: () async {
                      final authProvider = context.read<AuthProvider>();
                      await authProvider.refreshUserData();
                      setState(() {});
                      _showSnackBar('Profile refreshed', _primaryGreen);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _goldAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _goldAccent.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh, size: 14, color: _goldAccent),
                          SizedBox(width: 6),
                          Text(
                            'Refresh Profile',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: _goldAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ), */
              
              SizedBox(height: 24),
              _buildAccountInfoCard(context, currentUser, isTablet),
              SizedBox(height: 24),
              _buildSectionTitle('Profile Management', isTablet),
              SizedBox(height: 16),
              _buildProfileManagementCards(context, isTablet),
              SizedBox(height: 24),
              _buildSectionTitle('App Settings', isTablet),
              SizedBox(height: 16),
              _buildAppSettingsCards(context, isTablet),
              SizedBox(height: 32),
              _buildPremiumLogoutButton(context, isTablet),
              SizedBox(height: 40),
              _buildPremiumFooter(isTablet),
            ],
          ),
        ),
      ),
    ],
  );
} 
 

/*  Widget _buildPremiumProfileCard(BuildContext context, UserModel? user, bool isTablet) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 16 : (isSmallScreen ? 12 : 14)),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: isTablet ? 20 : 12,
            offset: Offset(0, isTablet ? 6 : 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image Picker
        ProfileImagePicker(
          size: isTablet ? 100 : (isSmallScreen ? 80 : 90),
          onImageUpdated: () async {
            print('🔄 Image updated callback triggered');
            
            // Just refresh the user data without forcing full UI rebuild
            if (mounted) {
              await authProvider.refreshUserData();
              // Only update this screen, not the entire app
              setState(() {});
            }
          },
        ),
          SizedBox(height: isTablet ? 12 : (isSmallScreen ? 8 : 10)),
          
          // User Info
          Column(
            children: [
              Text(
                currentUser?.fullName ?? "Guest User",
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 18 : (isSmallScreen ? 16 : 17),
                  fontWeight: FontWeight.w700,
                  color: _textWhite,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 10, 
                  vertical: isSmallScreen ? 4 : 5
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                  border: Border.all(color: _borderColor, width: 0.5),
                ),
                child: Text(
                  currentUser?.email ?? "Not signed in",
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 11 : (isSmallScreen ? 10 : 11),
                    color: _textLight,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          
          SizedBox(height: isTablet ? 12 : (isSmallScreen ? 8 : 10)),
          
          // Login Button for Guest
          if (currentUser == null) ...[
            GestureDetector(
              onTap: () => _navigateToLogin(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : (isSmallScreen ? 12 : 14),
                  vertical: isTablet ? 8 : (isSmallScreen ? 6 : 7),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryRed, _primaryGreen],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: isTablet ? 12 : 8,
                      offset: Offset(0, isTablet ? 4 : 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.login_rounded,
                      color: Colors.white,
                      size: isTablet ? 14 : (isSmallScreen ? 12 : 13),
                    ),
                    SizedBox(width: isTablet ? 6 : (isSmallScreen ? 4 : 5)),
                    Text(
                      'Sign In',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 12 : (isSmallScreen ? 11 : 12),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isTablet ? 10 : (isSmallScreen ? 8 : 9)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 10, 
                vertical: isSmallScreen ? 6 : 8
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                border: Border.all(color: _borderColor, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: _goldAccent,
                    size: isSmallScreen ? 10 : 12,
                  ),
                  SizedBox(width: isSmallScreen ? 4 : 5),
                  Expanded(
                    child: Text(
                      'Sign in to access all features',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 9 : (isSmallScreen ? 8 : 9),
                        color: _textLight,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Admin Badge
          if (currentUser?.isAdmin ?? false)
            Padding(
              padding: EdgeInsets.only(top: isSmallScreen ? 6 : 8),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 14, 
                  vertical: isSmallScreen ? 4 : 5
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_goldAccent, Color(0xFFFFC107)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
                  boxShadow: [
                    BoxShadow(
                      color: _goldAccent.withOpacity(0.3),
                      blurRadius: isTablet ? 6 : 4,
                      offset: Offset(0, isTablet ? 2 : 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_rounded, 
                      color: Colors.white, 
                      size: isSmallScreen ? 12 : 14
                    ),
                    SizedBox(width: isSmallScreen ? 4 : 6),
                    Text(
                      'Admin',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
          // Join Date
          if (currentUser?.createdAt != null)
            Padding(
              padding: EdgeInsets.only(top: isTablet ? 10 : (isSmallScreen ? 8 : 9)),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 10, 
                  vertical: isSmallScreen ? 4 : 5
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                  border: Border.all(color: _borderColor, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_rounded,
                      color: _primaryGreen, 
                      size: isSmallScreen ? 10 : 12
                    ),
                    SizedBox(width: isSmallScreen ? 4 : 6),
                    Text(
                      'Joined ${_formatDate(currentUser!.createdAt)}',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 9 : 10,
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


*/



/*Widget _buildPremiumProfileCard(BuildContext context, UserModel? user, bool isTablet) {
  final authProvider = Provider.of<AuthProvider>(context);
  final currentUser = authProvider.user;
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenWidth < 380;
  
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(isTablet ? 16 : (isSmallScreen ? 12 : 14)),
    decoration: BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
      border: Border.all(color: _borderColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: isTablet ? 20 : 12,
          offset: Offset(0, isTablet ? 6 : 3),
        ),
      ],
    ),
    child: Column(
      children: [
        // Profile Image Picker with ValueListenableBuilder
        ValueListenableBuilder<String?>(
          valueListenable: authProvider.profileImageNotifier,
          builder: (context, profileImageUrl, child) {
            return ProfileImagePicker(
              size: isTablet ? 100 : (isSmallScreen ? 80 : 90),
              onImageUpdated: () async {
                print('🔄 Image updated callback triggered');
                // Small delay to ensure upload is complete
                await Future.delayed(const Duration(milliseconds: 300));
                if (mounted) {
                  // This will only refresh the user data without full rebuild
                  await authProvider.refreshUserData();
                }
              },
            );
          },
        ),
        SizedBox(height: isTablet ? 12 : (isSmallScreen ? 8 : 10)),
        
        // User Info
        Column(
          children: [
            Text(
              currentUser?.fullName ?? "Guest User",
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 18 : (isSmallScreen ? 16 : 17),
                fontWeight: FontWeight.w700,
                color: _textWhite,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 2 : 4),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 10, 
                vertical: isSmallScreen ? 4 : 5
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                border: Border.all(color: _borderColor, width: 0.5),
              ),
              child: Text(
                currentUser?.email ?? "Not signed in",
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 11 : (isSmallScreen ? 10 : 11),
                  color: _textLight,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        
        SizedBox(height: isTablet ? 12 : (isSmallScreen ? 8 : 10)),
        
        // Login Button for Guest
        if (currentUser == null) ...[
          GestureDetector(
            onTap: () => _navigateToLogin(context),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : (isSmallScreen ? 12 : 14),
                vertical: isTablet ? 8 : (isSmallScreen ? 6 : 7),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryRed, _primaryGreen],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: isTablet ? 12 : 8,
                    offset: Offset(0, isTablet ? 4 : 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.login_rounded,
                    color: Colors.white,
                    size: isTablet ? 14 : (isSmallScreen ? 12 : 13),
                  ),
                  SizedBox(width: isTablet ? 6 : (isSmallScreen ? 4 : 5)),
                  Text(
                    'Sign In',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 12 : (isSmallScreen ? 11 : 12),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isTablet ? 10 : (isSmallScreen ? 8 : 9)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 10, 
              vertical: isSmallScreen ? 6 : 8
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
              border: Border.all(color: _borderColor, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: _goldAccent,
                  size: isSmallScreen ? 10 : 12,
                ),
                SizedBox(width: isSmallScreen ? 4 : 5),
                Expanded(
                  child: Text(
                    'Sign in to access all features',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 9 : (isSmallScreen ? 8 : 9),
                      color: _textLight,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Admin Badge
        if (currentUser?.isAdmin ?? false)
          Padding(
            padding: EdgeInsets.only(top: isSmallScreen ? 6 : 8),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 14, 
                vertical: isSmallScreen ? 4 : 5
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_goldAccent, Color(0xFFFFC107)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
                boxShadow: [
                  BoxShadow(
                    color: _goldAccent.withOpacity(0.3),
                    blurRadius: isTablet ? 6 : 4,
                    offset: Offset(0, isTablet ? 2 : 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_rounded, 
                    color: Colors.white, 
                    size: isSmallScreen ? 12 : 14
                  ),
                  SizedBox(width: isSmallScreen ? 4 : 6),
                  Text(
                    'Admin',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
        // Join Date
        if (currentUser?.createdAt != null)
          Padding(
            padding: EdgeInsets.only(top: isTablet ? 10 : (isSmallScreen ? 8 : 9)),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 10, 
                vertical: isSmallScreen ? 4 : 5
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                border: Border.all(color: _borderColor, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_rounded,
                    color: _primaryGreen, 
                    size: isSmallScreen ? 10 : 12
                  ),
                  SizedBox(width: isSmallScreen ? 4 : 6),
                  Text(
                    'Joined ${_formatDate(currentUser!.createdAt)}',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 9 : 10,
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

*/



Widget _buildPremiumProfileCard(BuildContext context, UserModel? user, bool isTablet) {
  final authProvider = Provider.of<AuthProvider>(context);
  final currentUser = authProvider.user;
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenWidth < 380;
  
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(isTablet ? 16 : (isSmallScreen ? 12 : 14)),
    decoration: BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
      border: Border.all(color: _borderColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: isTablet ? 20 : 12,
          offset: Offset(0, isTablet ? 6 : 3),
        ),
      ],
    ),
    child: Column(
      children: [
        // Profile Image Picker - NO ValueListenableBuilder here to prevent rebuilds
        // The ProfileImagePicker itself will update when onImageUpdated is called
        ProfileImagePicker(
          size: isTablet ? 100 : (isSmallScreen ? 80 : 90),
          onImageUpdated: () async {
            print('🔄 Image updated callback triggered');
            // Small delay to ensure upload is complete
            await Future.delayed(const Duration(milliseconds: 300));
            // Only refresh user data - no setState needed
            if (mounted) {
              await authProvider.refreshUserData();
            }
          },
        ),
        SizedBox(height: isTablet ? 12 : (isSmallScreen ? 8 : 10)),
        
        // User Info - This will update when authProvider notifies
        Column(
          children: [
            Text(
              currentUser?.fullName ?? "Guest User",
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 18 : (isSmallScreen ? 16 : 17),
                fontWeight: FontWeight.w700,
                color: _textWhite,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 2 : 4),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 10, 
                vertical: isSmallScreen ? 4 : 5
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                border: Border.all(color: _borderColor, width: 0.5),
              ),
              child: Text(
                currentUser?.email ?? "Not signed in",
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 11 : (isSmallScreen ? 10 : 11),
                  color: _textLight,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        
        SizedBox(height: isTablet ? 12 : (isSmallScreen ? 8 : 10)),
        
        // Login Button for Guest
        if (currentUser == null) ...[
          GestureDetector(
            onTap: () => _navigateToLogin(context),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : (isSmallScreen ? 12 : 14),
                vertical: isTablet ? 8 : (isSmallScreen ? 6 : 7),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryRed, _primaryGreen],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: isTablet ? 12 : 8,
                    offset: Offset(0, isTablet ? 4 : 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.login_rounded,
                    color: Colors.white,
                    size: isTablet ? 14 : (isSmallScreen ? 12 : 13),
                  ),
                  SizedBox(width: isTablet ? 6 : (isSmallScreen ? 4 : 5)),
                  Text(
                    'Sign In',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 12 : (isSmallScreen ? 11 : 12),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isTablet ? 10 : (isSmallScreen ? 8 : 9)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 10, 
              vertical: isSmallScreen ? 6 : 8
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
              border: Border.all(color: _borderColor, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: _goldAccent,
                  size: isSmallScreen ? 10 : 12,
                ),
                SizedBox(width: isSmallScreen ? 4 : 5),
                Expanded(
                  child: Text(
                    'Sign in to access all features',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 9 : (isSmallScreen ? 8 : 9),
                      color: _textLight,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Admin Badge
        if (currentUser?.isAdmin ?? false)
          Padding(
            padding: EdgeInsets.only(top: isSmallScreen ? 6 : 8),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 14, 
                vertical: isSmallScreen ? 4 : 5
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_goldAccent, Color(0xFFFFC107)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
                boxShadow: [
                  BoxShadow(
                    color: _goldAccent.withOpacity(0.3),
                    blurRadius: isTablet ? 6 : 4,
                    offset: Offset(0, isTablet ? 2 : 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_rounded, 
                    color: Colors.white, 
                    size: isSmallScreen ? 12 : 14
                  ),
                  SizedBox(width: isSmallScreen ? 4 : 6),
                  Text(
                    'Admin',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
        // Join Date
        if (currentUser?.createdAt != null)
          Padding(
            padding: EdgeInsets.only(top: isTablet ? 10 : (isSmallScreen ? 8 : 9)),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 10, 
                vertical: isSmallScreen ? 4 : 5
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                border: Border.all(color: _borderColor, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_rounded,
                    color: _primaryGreen, 
                    size: isSmallScreen ? 10 : 12
                  ),
                  SizedBox(width: isSmallScreen ? 4 : 6),
                  Text(
                    'Joined ${_formatDate(currentUser!.createdAt)}',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 9 : 10,
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





// Add this debug method to test the profile image picker
void _testProfileImagePicker() async {
  print('🧪 [TEST] Testing ProfileImagePicker manually');
  print('🧪 [TEST] Checking AuthProvider state...');
  
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final currentUser = authProvider.user;
  
  if (currentUser == null) {
    print('❌ [TEST] No user logged in');
    _showSnackBar('Please login first', _primaryRed);
    return;
  }
  
  print('✅ [TEST] User logged in: ${currentUser.email}');
  print('✅ [TEST] Current profile image: ${currentUser.profileImageUrl ?? 'NULL'}');
  
  // Test image picker directly
  try {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      print('✅ [TEST] Image picked: ${pickedFile.path}');
      
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading...'), backgroundColor: Colors.orange),
      );
      
      final file = File(pickedFile.path);
      final userId = CloudinaryService.sanitizeEmailForFolder(currentUser.email);
      final imageUrl = await CloudinaryService.uploadProfileImage(
        file,
        customFolder: 'profile_images/$userId',
      );
      
      if (imageUrl != null) {
        print('✅ [TEST] Upload successful: $imageUrl');
        
        final updatedUser = currentUser.copyWith(
          profileImageUrl: imageUrl,
          updatedAt: DateTime.now(),
        );
        
        await authProvider.updateUserProfile(updatedUser);
        await authProvider.refreshUserData();
        
        setState(() {});
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!'), backgroundColor: Colors.green),
        );
      } else {
        print('❌ [TEST] Upload failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed'), backgroundColor: Colors.red),
        );
      }
    }
  } catch (e) {
    print('❌ [TEST] Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
    );
  }
}


  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }


Widget _buildAccountInfoCard(BuildContext context, UserModel? user, bool isTablet) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenWidth < 380;
  
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(isTablet ? 16 : (isSmallScreen ? 12 : 14)),
    decoration: BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
      border: Border.all(color: _borderColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: isTablet ? 15 : 10,
          offset: Offset(0, isTablet ? 5 : 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row - Smaller
        Row(
          children: [
            Container(
              width: isTablet ? 36 : (isSmallScreen ? 30 : 32),
              height: isTablet ? 36 : (isSmallScreen ? 30 : 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryRed, _primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: isTablet ? 6 : 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.account_circle_rounded,
                color: Colors.white,
                size: isTablet ? 20 : (isSmallScreen ? 16 : 18),
              ),
            ),
            SizedBox(width: isSmallScreen ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Information',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: isTablet ? 16 : (isSmallScreen ? 13 : 14),
                      fontWeight: FontWeight.w800,
                      color: _textWhite,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Your account details and status',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 11 : (isSmallScreen ? 9 : 10),
                      color: _textLight,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : (isSmallScreen ? 12 : 14)),
        
        // Info Rows - Smaller
        _buildInfoRow(
          context,
          Icons.email_rounded,
          'Email',
          user?.email ?? 'Not available',
          isTablet,
          isSmallScreen: isSmallScreen,
          isEditable: false,
          color: _primaryRed,
        ),
        SizedBox(height: isSmallScreen ? 8 : 10),
        
        _buildInfoRow(
          context,
          Icons.phone_rounded,
          'Phone',
          user?.phoneNumber?.isNotEmpty ?? false ? user!.phoneNumber! : 'Not set',
          isTablet,
          isSmallScreen: isSmallScreen,
          isEditable: false,
          color: Colors.green,
        ),
        SizedBox(height: isSmallScreen ? 8 : 10),
        
        _buildInfoRow(
          context,
          Icons.location_on_rounded,
          'Location',
          user?.location?.isNotEmpty ?? false ? user!.location! : 'Not set',
          isTablet,
          isSmallScreen: isSmallScreen,
          isEditable: true,
          color: _primaryRed,
          onEdit: () {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            if (authProvider.isGuestMode) {
              _showLoginRequiredDialog(context, 'Edit location');
              return;
            }
            _showLocationEditDialog(context, user);
          },
        ),
        SizedBox(height: isSmallScreen ? 8 : 10),
        
        _buildInfoRow(
          context,
          Icons.verified_rounded,
          'Email Verification',
          user?.isEmailVerified ?? false ? 'Verified' : 'Not Verified',
          isTablet,
          isSmallScreen: isSmallScreen,
          isEditable: false,
          color: user?.isEmailVerified ?? false ? Colors.green : Colors.orange,
          trailingWidget: user?.isEmailVerified ?? false
              ? Container(
                  width: isSmallScreen ? 10 : 12,
                  height: isSmallScreen ? 10 : 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.lightGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: isTablet ? 4 : 3,
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    if (authProvider.isGuestMode) {
                      _showLoginRequiredDialog(context, 'Resend Verification Email');
                      return;
                    }
                    _resendVerificationEmail(context);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 10,
                      vertical: isSmallScreen ? 4 : 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: isTablet ? 4 : 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send_rounded, size: isSmallScreen ? 10 : 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Send',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 10 : 11,
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
  bool isSmallScreen = false,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: isEditable ? onEdit : null,
      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 10 : (isSmallScreen ? 8 : 9)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          border: Border.all(color: _borderColor, width: 0.8),
        ),
        child: Row(
          children: [
            // Icon Container - Smaller
            Container(
              width: isTablet ? 28 : (isSmallScreen ? 24 : 26),
              height: isTablet ? 28 : (isSmallScreen ? 24 : 26),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
              ),
              child: Icon(
                icon,
                color: color,
                size: isTablet ? 14 : (isSmallScreen ? 12 : 13),
              ),
            ),
            SizedBox(width: isSmallScreen ? 10 : 12),
            
            // Text Content - Smaller
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 11 : (isSmallScreen ? 9 : 10),
                      color: _textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 13 : (isSmallScreen ? 11 : 12),
                      color: _textWhite,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Edit Button - Smaller
            if (isEditable)
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: EdgeInsets.all(isTablet ? 6 : (isSmallScreen ? 5 : 6)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                    border: Border.all(color: color.withOpacity(0.3), width: 0.5),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: color,
                    size: isTablet ? 12 : (isSmallScreen ? 10 : 11),
                  ),
                ),
              ),
              
            // Trailing Widget
            if (trailingWidget != null) ...[
              SizedBox(width: isSmallScreen ? 6 : 8),
              trailingWidget,
            ],
          ],
        ),
      ),
    ),
  );
}


Widget _buildSectionTitle(String title, bool isTablet) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenWidth < 380;
  
  return Container(
    padding: EdgeInsets.only(left: 4, bottom: isSmallScreen ? 4 : 6),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: _borderColor, width: 0.8),
      ),
    ),
    child: Row(
      children: [
        // Left accent bar - smaller
        Container(
          width: 3,
          height: isTablet ? 18 : (isSmallScreen ? 14 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryRed, _primaryGreen],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 10),
        
        // Title text - smaller
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 16 : (isSmallScreen ? 13 : 14),
            fontWeight: FontWeight.w700,
            color: _textWhite,
            letterSpacing: 0.3,
          ),
        ),
      ],
    ),
  );
}



Widget _buildProfileManagementCards(BuildContext context, bool isTablet) {
  return Column(
    children: [
      // Edit Profile Card
      _buildPremiumSettingCard(
        context,
        icon: Icons.person_rounded,
        title: 'Edit Profile',
        subtitle: 'Update your name and information',
        gradientColors: [_primaryGreen, _darkGreen],
        onTap: () {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.isGuestMode) {
            _showLoginRequiredDialog(context, 'Edit Profile');
            return;
          }
          _showEditProfileDialog(context);
        },
        isTablet: isTablet,
      ),
      
      SizedBox(height: 12),
      
      // Change Password Card
      _buildPremiumSettingCard(
        context,
        icon: Icons.lock_reset_rounded,
        title: 'Change Password',
        subtitle: 'Update your password for security',
        gradientColors: [_primaryRed, _deepRed],
        onTap: () {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
      // Privacy & Legal Section Header
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: _primaryRed,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Privacy & Legal',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w700,
                color: _textWhite,
              ),
            ),
          ],
        ),
      ),
      
      // Privacy Policy
      _buildPremiumSettingCard(
        context,
        icon: Icons.privacy_tip_rounded,
        title: 'Privacy Policy',
        subtitle: 'Read how we protect your personal information',
        gradientColors: [_primaryGreen, _darkGreen],
        onTap: () {
      /*    final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.isGuestMode) {
            _showLoginRequiredDialog(context, 'Privacy Policy');
            return;
          } */
          _openWebView('Privacy Policy', privacyPolicyUrl);
        },
        isTablet: isTablet,
      ),
      const SizedBox(height: 10),
      
      // Terms of Service
      _buildPremiumSettingCard(
        context,
        icon: Icons.description_rounded,
        title: 'Terms of Service',
        subtitle: 'Terms and conditions for using Bangla Hub',
        gradientColors: [_primaryGreen, _darkGreen],
        onTap: () {
      /*    final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.isGuestMode) {
            _showLoginRequiredDialog(context, 'Terms of Service');
            return;
          }  */
          _openWebView('Terms of Service', termsOfServiceUrl);
        },
        isTablet: isTablet,
      ),
      const SizedBox(height: 10),
      
    
      // Delete Account
      _buildPremiumSettingCard(
        context,
        icon: Icons.delete_forever_rounded,
        title: 'Delete Account',
        subtitle: 'Permanently delete your account and all data',
        gradientColors: [_primaryRed, _deepRed],
        onTap: () {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.isGuestMode) {
            _showLoginRequiredDialog(context, 'Delete Account');
            return;
          }
          _confirmDeleteAccount(context);
        },
        isTablet: isTablet,
      ),
      
      const SizedBox(height: 20),
      
      // Help & Support Section Header
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: _primaryRed,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Help & Support',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w700,
                color: _textWhite,
              ),
            ),
          ],
        ),
      ),
      
      // Contact Support
      _buildPremiumSettingCard(
        context,
        icon: Icons.support_agent_rounded,
        title: 'Contact Support',
        subtitle: 'Get help from our support team',
        gradientColors: [_primaryRed, _deepRed],
        onTap: () {
       /*   final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.isGuestMode) {
            _showLoginRequiredDialog(context, 'Contact Support');
            return;
          }  */
          _showContactOptions(context);
        },
        isTablet: isTablet,
      ),
      const SizedBox(height: 10),
      
      // Report a Problem
      _buildPremiumSettingCard(
        context,
        icon: Icons.report_problem_rounded,
        title: 'Report a Problem',
        subtitle: 'Report bugs, issues, or inappropriate content',
        gradientColors: [_primaryRed, _deepRed],
        onTap: () {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.isGuestMode) {
            _showLoginRequiredDialog(context, 'Report a Problem');
            return;
          }
          _showReportProblemDialog(context);
        },
        isTablet: isTablet,
      ),
      const SizedBox(height: 10),
      
      // FAQs
      _buildPremiumSettingCard(
        context,
        icon: Icons.quiz_rounded,
        title: 'FAQs',
        subtitle: 'Frequently asked questions',
        gradientColors: [_primaryGreen, _darkGreen],
        onTap: () {
        /*  final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.isGuestMode) {
            _showLoginRequiredDialog(context, 'FAQs');
            return;
          }  */
          _showFaqDialog(context);
        },
        isTablet: isTablet,
      ),
      const SizedBox(height: 10),
      
      // Send Feedback
      _buildPremiumSettingCard(
        context,
        icon: Icons.feedback_rounded,
        title: 'Send Feedback',
        subtitle: 'Help us improve Bangla Hub',
        gradientColors: [_primaryGreen, _darkGreen],
        onTap: () {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.isGuestMode) {
            _showLoginRequiredDialog(context, 'Send Feedback');
            return;
          }
          _sendFeedback(context);
        },
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
      onTap: () {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isGuestMode) {
          _showLoginRequiredDialog(context, title);
          return;
        }
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isTablet ? 14 : 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.3),
              blurRadius: isTablet ? 12 : 8,
              offset: Offset(0, isTablet ? 6 : 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container - Smaller
            Container(
              width: isTablet ? 42 : 38,
              height: isTablet ? 42 : 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: isTablet ? 20 : 16,
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            
            // Text Content - Smaller
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 15 : 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 11 : 10,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow Icon - Smaller
            Container(
              width: isTablet ? 26 : 24,
              height: isTablet ? 26 : 24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.9),
                size: isTablet ? 18 : 16,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}



Widget _buildPremiumLogoutButton(BuildContext context, bool isTablet) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenWidth < 380;
  
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isGuestMode) {
          _showLoginRequiredDialog(context, 'Logout');
          return;
        }
        _showPremiumLogoutDialog(context);
      },
      borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isTablet ? 12 : (isSmallScreen ? 10 : 11)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryRed, _deepRed],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
          boxShadow: [
            BoxShadow(
              color: _primaryRed.withOpacity(0.3),
              blurRadius: isTablet ? 10 : 8,
              offset: Offset(0, isTablet ? 4 : 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: isTablet ? 20 : (isSmallScreen ? 16 : 18),
            ),
            SizedBox(width: isSmallScreen ? 10 : 12),
            Text(
              'Logout',
              style: GoogleFonts.notoSansBengali(
                fontSize: isTablet ? 18 : (isSmallScreen ? 14 : 16),
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildPremiumFooter(bool isTablet) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenWidth < 380;
  
  return Column(
    children: [
      // Top decorative line - thinner
      Container(
        height: 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryGreen, _primaryRed, _primaryGreen],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
      SizedBox(height: isSmallScreen ? 16 : 20),
      
      // App Name - smaller
      Text(
        'BanglaHub',
        style: GoogleFonts.notoSansBengali(
          fontSize: isTablet ? 16 : (isSmallScreen ? 13 : 14),
          color: _textWhite,
          fontWeight: FontWeight.w700,
        ),
      ),
      SizedBox(height: isSmallScreen ? 6 : 8),
      
      // Version info - smaller
      Text(
        'Version 1.0.0 • © 2026 All rights reserved',
        style: GoogleFonts.poppins(
          fontSize: isTablet ? 11 : (isSmallScreen ? 9 : 10),
          color: _textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(height: isSmallScreen ? 6 : 8),
      
      // Decorative dots - smaller
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          6,  // Reduced from 8 to 6 dots
          (index) => Container(
            width: 8,
            height: 2,
            margin: EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryGreen, _primaryRed],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    ],
  );
}
 
  // ====================== HELPER METHODS ======================

Widget _getPremiumProfileImage(UserModel? user, double size) {
  // First check for locally picked file
  if (_profileImageFile != null) {
    print('📸 Showing local image file');
    return CircleAvatar(
      radius: size / 2,
      backgroundImage: FileImage(_profileImageFile!),
      backgroundColor: _primaryGreen,
      child: null,
    );
  }

  // Check for stored profile image URL
  if (user?.profileImageUrl == null || user!.profileImageUrl!.isEmpty) {
    print('📸 No profile image, showing default');
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _primaryGreen,
      child: Icon(Icons.person, size: size * 0.5, color: Colors.white),
    );
  }

  final imageUrl = user.profileImageUrl!;
  print('📸 Loading profile image from URL: ${imageUrl.substring(0, imageUrl.length > 80 ? 80 : imageUrl.length)}...');

  return CircleAvatar(
    radius: size / 2,
    backgroundImage: NetworkImage(imageUrl),
    backgroundColor: _primaryGreen,
    child: null,
    onBackgroundImageError: (error, stackTrace) {
      print('❌ Error loading profile image: $error');
      // Try to refresh on error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          authProvider.refreshUserData();
        }
      });
    },
  );
}


Widget _buildDefaultProfileAvatar(double size) {
  return ClipOval(
    child: Container(
      width: size,
      height: size,
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

  // ====================== CONTACT SUPPORT METHODS ======================

  void _openWebView(String title, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          title: title,
          url: url,
        ),
      ),
    );
  }

void _showDataPrivacyDialog(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final isSmallScreen = mediaQuery.size.height < 600;
  
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with icon
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
                    child: Icon(Icons.privacy_tip, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Data & Privacy',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 20 : 22,
                        fontWeight: FontWeight.w800,
                        color: _textWhite,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Main content
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'We collect and use your data to provide better services:',
                      style: TextStyle(
                        color: _textWhite,
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 14 : 15,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPrivacyBulletPoint('📍 Location data for local recommendations', isSmallScreen),
                    _buildPrivacyBulletPoint('📧 Account info for authentication', isSmallScreen),
                    _buildPrivacyBulletPoint('📝 Content you post (events, listings)', isSmallScreen),
                    _buildPrivacyBulletPoint('📊 Usage analytics to improve the app', isSmallScreen),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Your Rights section
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryGreen.withOpacity(0.1), _primaryRed.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryGreen.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_rounded, color: _primaryGreen, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Your Rights',
                          style: TextStyle(
                            color: _textWhite,
                            fontWeight: FontWeight.w700,
                            fontSize: isSmallScreen ? 15 : 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRightItem('✓ Access your data anytime', isSmallScreen),
                    _buildRightItem('✓ Request data deletion', isSmallScreen),
                    _buildRightItem('✓ Opt out of data collection', isSmallScreen),
                    _buildRightItem('✓ Export your data', isSmallScreen),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action buttons
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
                              'Close',
                              style: TextStyle(
                                color: Colors.white,
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
                        onTap: () {
                          Navigator.pop(context);
                        //  _showComingSoon(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 14 : 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryRed, _primaryGreen],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryRed.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                           //   'Manage Preferences',
                           "Ok",
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
            ],
          ),
        ),
      ),
    ),
  );
}

// Helper method for bullet points
Widget _buildPrivacyBulletPoint(String text, bool isSmallScreen) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '•',
          style: TextStyle(
            color: _primaryGreen,
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: _textLight,
              fontSize: isSmallScreen ? 13 : 14,
            ),
          ),
        ),
      ],
    ),
  );
}

// Helper method for rights items
Widget _buildRightItem(String text, bool isSmallScreen) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(
          Icons.check_circle_outline,
          color: _primaryGreen,
          size: isSmallScreen ? 16 : 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: _textLight,
              fontSize: isSmallScreen ? 13 : 14,
            ),
          ),
        ),
      ],
    ),
  );
}



/* void _confirmDeleteAccount(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final isSmallScreen = mediaQuery.size.height < 600;
  
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with icon
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
                    child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Delete Account',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 20 : 22,
                        fontWeight: FontWeight.w800,
                        color: _textWhite,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Warning message
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: _primaryRed, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This action is permanent and cannot be undone!',
                            style: TextStyle(
                              color: _textWhite,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 14 : 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '⚠️ This will delete:',
                      style: TextStyle(
                        color: _textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        _buildDeleteItem('Your profile information', isSmallScreen),
                        _buildDeleteItem('All your posts and events', isSmallScreen),
                        _buildDeleteItem('Saved items and preferences', isSmallScreen),
                        _buildDeleteItem('Your account history', isSmallScreen),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action buttons
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
                                color: Colors.white,
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
                        onTap: () async {
                          Navigator.pop(context);
                          await _deleteAccount(context);
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
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Delete Forever',
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
            ],
          ),
        ),
      ),
    ),
  );
}

*/


void _confirmDeleteAccount(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final isSmallScreen = mediaQuery.size.height < 600;
  
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with icon
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
                    child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Delete Account',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 20 : 22,
                        fontWeight: FontWeight.w800,
                        color: _textWhite,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Warning message
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: _primaryRed, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This action is permanent and cannot be undone!',
                            style: TextStyle(
                              color: _textWhite,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 14 : 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '⚠️ This will delete:',
                      style: TextStyle(
                        color: _textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        _buildDeleteItem('Your profile information', isSmallScreen),
                        _buildDeleteItem('All your posts and events', isSmallScreen),
                        _buildDeleteItem('Saved items and preferences', isSmallScreen),
                        _buildDeleteItem('Your account history', isSmallScreen),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action buttons
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
                                color: Colors.white,
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
                        onTap: () async {
                          Navigator.pop(context); // Close confirmation dialog
                          await _deleteAccount(context);
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
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Delete Forever',
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
            ],
          ),
        ),
      ),
    ),
  );
}


// Helper method to build delete items
Widget _buildDeleteItem(String text, bool isSmallScreen) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(
          Icons.close_rounded,
          color: _primaryRed,
          size: isSmallScreen ? 16 : 18,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: _textLight,
            fontSize: isSmallScreen ? 13 : 14,
          ),
        ),
      ],
    ),
  );
}
  
/*  Future<void> _deleteAccount(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: _primaryGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Text(
                'Deleting your account...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.deleteAccount(context);
      
      if (mounted) {
        Navigator.pop(context);
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    }
  }

*/


Future<void> _deleteAccount(BuildContext context) async {
  final authProvider = context.read<AuthProvider>();
  
  try {
    // Call deleteAccount - it will handle its own loading dialog
    await authProvider.deleteAccount(context);
    
    // After successful deletion, authProvider already:
    // - Showed loading dialog
    // - Closed loading dialog  
    // - Showed success snackbar
    // - Navigated to login screen
    
  } catch (e) {
    // Error is already handled in authProvider
    print('Delete account error: $e');
  }
}




void _showContactOptions(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final isSmallScreen = mediaQuery.size.height < 600;
  
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 450,
          minWidth: 280,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgGradient2, _primaryGreen.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with icon - Smaller
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryRed, _primaryGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.contact_support_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Contact Support',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.w700,
                        color: _textWhite,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Contact Options
              _buildContactOptionDialog(
                icon: Icons.email_rounded,
                title: 'Email Support',
              //  subtitle: 'Get help via email',
              subtitle: 'info@banglahub.us',
                color: _primaryGreen,
                onTap: () {
                  Navigator.pop(context);
                //  _sendEmail('info@banglahub.us', 'Support Request');
                },
                isSmallScreen: isSmallScreen,
              ),
              
        
              
              const SizedBox(height: 20),
              
              // OK Button - Smaller
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 10 : 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryRed, _primaryGreen],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryRed.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'OK',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: isSmallScreen ? 14 : 15,
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
    ),
  );
}



Widget _buildContactOptionDialog({
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
  required bool isSmallScreen,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor, width: 0.8),
        ),
        child: Row(
          children: [
            // Icon Container - Smaller
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: isSmallScreen ? 18 : 20),
            ),
            const SizedBox(width: 12),
            
            // Text Content - Smaller
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 10 : 11,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow Icon - Smaller
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.5),
              size: isSmallScreen ? 16 : 18,
            ),
          ],
        ),
      ),
    ),
  );
}



  void _sendEmail(String email, String subject) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showSnackBar('Could not open email client', _primaryRed);
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showSnackBar('Could not make phone call', _primaryRed);
    }
  }

  void _openWhatsApp(String phoneNumber) async {
    // Remove '+' if present for WhatsApp URL
    String cleanNumber = phoneNumber.replaceAll('+', '');
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');
    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('WhatsApp is not installed', _primaryRed);
    }
  }


/*void _showReportProblemDialog(BuildContext context) {
  final problemController = TextEditingController();
  String problemType = 'Bug/Technical Issue';
  
  final mediaQuery = MediaQuery.of(context);
  final isSmallScreen = mediaQuery.size.height < 600;
  
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 450,
            minWidth: 280,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_bgGradient2, _primaryGreen.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with icon - Smaller
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryRed, _primaryGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.report_problem_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Report a Problem',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.w700,
                          color: _textWhite,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Problem Type Section - Smaller
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderColor, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.category_rounded, color: _primaryRed, size: isSmallScreen ? 16 : 18),
                          const SizedBox(width: 6),
                          Text(
                            'Problem Type',
                            style: GoogleFonts.poppins(
                              color: _textWhite,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          border: Border.all(color: _borderColor, width: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: problemType,
                            isExpanded: true,
                            dropdownColor: _bgGradient2,
                            style: GoogleFonts.poppins(
                              color: _textWhite,
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Bug/Technical Issue', child: Text('🐛 Bug/Technical Issue')),
                              DropdownMenuItem(value: 'Inappropriate Content', child: Text('🚫 Inappropriate Content')),
                              DropdownMenuItem(value: 'Account Issue', child: Text('👤 Account Issue')),
                              DropdownMenuItem(value: 'Payment Issue', child: Text('💳 Payment Issue')),
                              DropdownMenuItem(value: 'Other', child: Text('📝 Other')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                problemType = value!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Description Field - Smaller
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderColor, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description_rounded, color: _primaryGreen, size: isSmallScreen ? 16 : 18),
                          const SizedBox(width: 6),
                          Text(
                            'Describe the problem',
                            style: GoogleFonts.poppins(
                              color: _textWhite,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: problemController,
                        maxLines: 3,
                        style: GoogleFonts.inter(
                          color: _textWhite,
                          fontSize: isSmallScreen ? 13 : 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Please provide details...',
                          hintStyle: GoogleFonts.inter(
                            color: _textMuted,
                            fontSize: isSmallScreen ? 12 : 13,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _borderColor, width: 0.8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _borderColor, width: 0.8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _primaryGreen, width: 1.5),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Info Message - Smaller
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryGreen.withOpacity(0.1), _primaryRed.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _primaryGreen.withOpacity(0.3), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_rounded, color: _primaryGreen, size: isSmallScreen ? 14 : 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can also include screenshots by emailing us directly.',
                          style: GoogleFonts.inter(
                            fontSize: isSmallScreen ? 10 : 11,
                            color: _textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Action Buttons - Smaller
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 10 : 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _borderColor, width: 0.8),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmallScreen ? 13 : 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 10 : 12),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _submitReport(problemType, problemController.text);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 10 : 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryRed, _primaryGreen],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryRed.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Submit Report',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: isSmallScreen ? 13 : 14,
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
      ),
    ),
  );
}

*/


/* void _showReportProblemDialog(BuildContext context) {
  final problemController = TextEditingController();
  String problemType = 'Bug/Technical Issue';
  
  final mediaQuery = MediaQuery.of(context);
  final isSmallScreen = mediaQuery.size.height < 600;
  
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        // Listen to keyboard visibility
        final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: isKeyboardVisible ? 10 : 20,
          ),
          child: SingleChildScrollView(
            // Add padding at bottom when keyboard is open
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 450,
                minWidth: 280,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_bgGradient2, _primaryGreen.withOpacity(0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with icon
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryRed, _primaryGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.report_problem_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Report a Problem',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.w700,
                              color: _textWhite,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Problem Type Section
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _borderColor, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.category_rounded, color: _primaryRed, size: isSmallScreen ? 16 : 18),
                              const SizedBox(width: 6),
                              Text(
                                'Problem Type',
                                style: GoogleFonts.poppins(
                                  color: _textWhite,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmallScreen ? 13 : 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              border: Border.all(color: _borderColor, width: 0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: problemType,
                                isExpanded: true,
                                dropdownColor: _bgGradient2,
                                style: GoogleFonts.poppins(
                                  color: _textWhite,
                                  fontSize: isSmallScreen ? 13 : 14,
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Bug/Technical Issue', child: Text('🐛 Bug/Technical Issue')),
                                  DropdownMenuItem(value: 'Inappropriate Content', child: Text('🚫 Inappropriate Content')),
                                  DropdownMenuItem(value: 'Account Issue', child: Text('👤 Account Issue')),
                                  DropdownMenuItem(value: 'Payment Issue', child: Text('💳 Payment Issue')),
                                  DropdownMenuItem(value: 'Other', child: Text('📝 Other')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    problemType = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Description Field
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _borderColor, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description_rounded, color: _primaryGreen, size: isSmallScreen ? 16 : 18),
                              const SizedBox(width: 6),
                              Text(
                                'Describe the problem',
                                style: GoogleFonts.poppins(
                                  color: _textWhite,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmallScreen ? 13 : 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: problemController,
                            maxLines: 3,
                            style: GoogleFonts.inter(
                              color: _textWhite,
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Please provide details...',
                              hintStyle: GoogleFonts.inter(
                                color: _textMuted,
                                fontSize: isSmallScreen ? 12 : 13,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: _borderColor, width: 0.8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: _borderColor, width: 0.8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: _primaryGreen, width: 1.5),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: isSmallScreen ? 10 : 12,
                              ),
                            ),
                            onTap: () {
                              // Trigger rebuild to adjust scroll when keyboard opens
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Info Message
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryGreen.withOpacity(0.1), _primaryRed.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _primaryGreen.withOpacity(0.3), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_rounded, color: _primaryGreen, size: isSmallScreen ? 14 : 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You can also include screenshots by emailing us directly.',
                              style: GoogleFonts.inter(
                                fontSize: isSmallScreen ? 10 : 11,
                                color: _textLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                problemController.dispose();
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 10 : 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _borderColor, width: 0.8),
                                ),
                                child: Center(
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isSmallScreen ? 13 : 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 10 : 12),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (problemController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Please describe your problem'),
                                      backgroundColor: _primaryRed,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      margin: EdgeInsets.all(12),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(context);
                                _submitReport(problemType, problemController.text);
                                problemController.dispose();
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 10 : 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryRed, _primaryGreen],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryRed.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'Submit Report',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: isSmallScreen ? 13 : 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Add extra bottom padding when keyboard is open
                    if (isKeyboardVisible) 
                      SizedBox(height: isSmallScreen ? 10 : 16),
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



  void _submitReport(String problemType, String description) {
    final subject = 'Problem Report: $problemType';
    final body = '''
Problem Type: $problemType
Description: $description

---
App Version: 1.0.0
Device: ${Platform.operatingSystem}
''';
    
    final Uri emailUri = Uri(
      scheme: 'mailto',
    //  path: 'support@banglahub.com',
    path : 'rif97965@gmail.com',
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    
    canLaunchUrl(emailUri).then((canLaunch) {
      if (canLaunch) {
        launchUrl(emailUri);
        _showSnackBar('Opening email client...', _primaryGreen);
      } else {
        _showSnackBar('Please email us at rif97965@gmail.com', _primaryRed);
      }
    });
  }


*/

void _showReportProblemDialog(BuildContext context) {
  final problemController = TextEditingController();
  String problemType = 'Bug/Technical Issue';
  
  final mediaQuery = MediaQuery.of(context);
  final isSmallScreen = mediaQuery.size.height < 600;
  
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: isKeyboardVisible ? 10 : 20,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 450,
                minWidth: 280,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_bgGradient2, _primaryGreen.withOpacity(0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryRed, _primaryGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.report_problem_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Report a Problem',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.w700,
                              color: _textWhite,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Problem Type
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _borderColor, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.category_rounded, color: _primaryRed, size: isSmallScreen ? 16 : 18),
                              const SizedBox(width: 6),
                              Text(
                                'Problem Type',
                                style: GoogleFonts.poppins(
                                  color: _textWhite,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmallScreen ? 13 : 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              border: Border.all(color: _borderColor, width: 0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: problemType,
                                isExpanded: true,
                                dropdownColor: _bgGradient2,
                                style: GoogleFonts.poppins(
                                  color: _textWhite,
                                  fontSize: isSmallScreen ? 13 : 14,
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Bug/Technical Issue', child: Text('🐛 Bug/Technical Issue')),
                                  DropdownMenuItem(value: 'Inappropriate Content', child: Text('🚫 Inappropriate Content')),
                                  DropdownMenuItem(value: 'Account Issue', child: Text('👤 Account Issue')),
                                  DropdownMenuItem(value: 'Payment Issue', child: Text('💳 Payment Issue')),
                                  DropdownMenuItem(value: 'Other', child: Text('📝 Other')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    problemType = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Description
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _borderColor, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description_rounded, color: _primaryGreen, size: isSmallScreen ? 16 : 18),
                              const SizedBox(width: 6),
                              Text(
                                'Describe the problem',
                                style: GoogleFonts.poppins(
                                  color: _textWhite,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmallScreen ? 13 : 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: problemController,
                            maxLines: 3,
                            style: GoogleFonts.inter(
                              color: _textWhite,
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Please provide details...',
                              hintStyle: GoogleFonts.inter(
                                color: _textMuted,
                                fontSize: isSmallScreen ? 12 : 13,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: _borderColor, width: 0.8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: _borderColor, width: 0.8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: _primaryGreen, width: 1.5),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: isSmallScreen ? 10 : 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Info Message
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryGreen.withOpacity(0.1), _primaryRed.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _primaryGreen.withOpacity(0.3), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_rounded, color: _primaryGreen, size: isSmallScreen ? 14 : 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your report will be sent to our support team.',
                              style: GoogleFonts.inter(
                                fontSize: isSmallScreen ? 10 : 11,
                                color: _textLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                // Dispose controller before closing
                                problemController.dispose();
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 10 : 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _borderColor, width: 0.8),
                                ),
                                child: Center(
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isSmallScreen ? 13 : 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 10 : 12),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                final description = problemController.text.trim();
                                if (description.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Please describe your problem'),
                                      backgroundColor: _primaryRed,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      margin: EdgeInsets.all(12),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                
                                // Close dialog
                                Navigator.pop(context);
                                
                                // Submit report
                                _submitReport(problemType, description);
                                
                                // Dispose controller after dialog is closed
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  if (!problemController.hasListeners) {
                                    problemController.dispose();
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 10 : 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryRed, _primaryGreen],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryRed.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'Submit Report',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: isSmallScreen ? 13 : 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (isKeyboardVisible) 
                      SizedBox(height: isSmallScreen ? 10 : 16),
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

void _submitReport(String problemType, String description) {
  final subject = 'Problem Report: $problemType';
  final body = '''
Problem Type: $problemType
Description: $description

---
App Version: 1.0.0

Date: ${DateTime.now().toLocal()}
''';
  
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: 'rif97965@gmail.com',
    query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
  );
  
  canLaunchUrl(emailUri).then((canLaunch) {
    if (canLaunch) {
      launchUrl(emailUri);
      _showSnackBar('Opening email client...', _primaryGreen);
    } else {
      _showSnackBar('Please email us at info@banglahub.us', _primaryRed);
    }
  }).catchError((error) {
    _showSnackBar('Could not open email client', _primaryRed);
  });
}


void _showFaqDialog(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final isSmallScreen = mediaQuery.size.height < 600;
  
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 450,
          minWidth: 280,
          maxHeight: 500,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgGradient2, _primaryGreen.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with icon - Smaller
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryRed, _primaryGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.quiz_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Frequently Asked Questions',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: _textWhite,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // FAQ List
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildFaqItemDialog(
                        'How do I post an event?',
                        'Go to the Events tab, tap the + Create Event button, fill in event details, and submit for approval.',
                        isSmallScreen,
                      ),
                      _buildFaqItemDialog(
                        'How long does approval take?',
                        'Events and listings are typically approved within 24-48 hours.',
                        isSmallScreen,
                      ),
                      _buildFaqItemDialog(
                        'Is Bangla Hub free?',
                        'Yes, basic features are free. Premium features may be added in the future.',
                        isSmallScreen,
                      ),
                      _buildFaqItemDialog(
                        'How do I report inappropriate content?',
                        'Use the Report Problem feature in Settings > Help & Support.',
                        isSmallScreen,
                      ),
                      _buildFaqItemDialog(
                        'How do I change my password?',
                        'Go to Settings > Profile Management > Change Password.',
                        isSmallScreen,
                      ),
                      _buildFaqItemDialog(
                        'How do I delete my account?',
                        'Go to Settings > Privacy & Legal > Delete Account.',
                        isSmallScreen,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // OK Button - Smaller
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 10 : 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryRed, _primaryGreen],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryRed.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Got it',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: isSmallScreen ? 14 : 15,
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
    ),
  );
}

Widget _buildFaqItemDialog(String question, String answer, bool isSmallScreen) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _borderColor, width: 0.8),
    ),
    child: Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryRed, _primaryGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            Icons.question_mark,
            color: Colors.white,
            size: isSmallScreen ? 14 : 16,
          ),
        ),
        title: Text(
          question,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: _textWhite,
            fontSize: isSmallScreen ? 13 : 14,
          ),
        ),
        trailing: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: _primaryGreen,
          size: isSmallScreen ? 18 : 20,
        ),
        collapsedIconColor: _primaryGreen,
        iconColor: _primaryGreen,
        childrenPadding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderColor.withOpacity(0.5), width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: _primaryGreen,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    answer,
                    style: GoogleFonts.inter(
                      color: _textLight,
                      fontSize: isSmallScreen ? 12 : 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}



void _sendFeedback(BuildContext context) {
  final feedbackController = TextEditingController();
  
  final mediaQuery = MediaQuery.of(context);
  final isSmallScreen = mediaQuery.size.height < 600;
  
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 450,
          minWidth: 280,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgGradient2, _primaryGreen.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with icon - Smaller
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryRed, _primaryGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.feedback_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Send Feedback',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.w700,
                        color: _textWhite,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Welcome message - Smaller
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryGreen.withOpacity(0.1), _primaryRed.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _primaryGreen.withOpacity(0.3), width: 0.8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite_rounded, color: _primaryRed, size: isSmallScreen ? 14 : 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'We value your feedback! Your suggestions help us improve Bangla Hub.',
                        style: GoogleFonts.inter(
                          color: _textLight,
                          fontSize: isSmallScreen ? 11 : 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Feedback TextField - Smaller
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _borderColor, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note_rounded, color: _primaryGreen, size: isSmallScreen ? 14 : 16),
                        const SizedBox(width: 6),
                        Text(
                          'Your Feedback',
                          style: GoogleFonts.poppins(
                            color: _textWhite,
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallScreen ? 13 : 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: feedbackController,
                      maxLines: 4,
                      style: GoogleFonts.inter(
                        color: _textWhite,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Share your suggestions, ideas, or concerns...',
                        hintStyle: GoogleFonts.inter(
                          color: _textMuted,
                          fontSize: isSmallScreen ? 12 : 13,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _borderColor, width: 0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _borderColor, width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _primaryGreen, width: 1.5),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: isSmallScreen ? 10 : 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action Buttons - Smaller
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _borderColor, width: 0.8),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 13 : 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 10 : 12),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (feedbackController.text.trim().isNotEmpty) {
                            Navigator.pop(context);
                            _submitFeedback(feedbackController.text);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Please enter your feedback'),
                                backgroundColor: _primaryRed,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                margin: EdgeInsets.all(12),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryRed, _primaryGreen],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryRed.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Send Feedback',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: isSmallScreen ? 13 : 14,
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
    ),
  );
}

  void _submitFeedback(String feedback) {
    final subject = 'App Feedback';
    final body = feedback;
    
    final Uri emailUri = Uri(
      scheme: 'mailto',
    //  path: 'feedback@banglahub.com',
    path: 'info@banglahub.us',
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    
    canLaunchUrl(emailUri).then((canLaunch) {
      if (canLaunch) {
        launchUrl(emailUri);
        _showSnackBar('Thank you for your feedback!', _primaryGreen);
      } else {
        _showSnackBar('Please email us at info@banglahub.us', _primaryRed);
      }
    });
  }

  void _rateApp(BuildContext context) async {
    const String appStoreUrl = 'https://apps.apple.com/app/idYOUR_APP_ID';
    final Uri url = Uri.parse(appStoreUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Could not open App Store', _primaryRed);
    }
  }

  void _shareApp(BuildContext context) async {
    const String shareText = '''
🇧🇩 Check out Bangla Hub - The ultimate app for the Bengali community!

Features:
• Discover local events
• Find Bengali businesses
• Connect with the community
• Job postings and opportunities

Download now: https://apps.apple.com/app/idYOUR_APP_ID
''';
    
    final Uri shareUri = Uri.parse('https://apps.apple.com/app/idYOUR_APP_ID');
    try {
      await launchUrl(shareUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showSnackBar('Could not share app', _primaryRed);
    }
  }

  // ====================== IMAGE PICKER METHODS ======================


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
            SizedBox(height: 12),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: _borderColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Update Profile Picture',
              style: GoogleFonts.notoSansBengali(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textWhite,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Choose a method to update your profile picture',
              style: TextStyle(
                fontSize: 12,
                color: _textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
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
            SizedBox(height: 12),
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
            SizedBox(height: 20),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        color: _textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _pickImage(ImageSource source) async {
  print('📸 Picking image...');

  try {
    final picker = ImagePicker();

    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 600,   // ↓ reduce more for performance
      maxHeight: 600,
      imageQuality: 70, // ↓ better compression
    );

    if (pickedFile == null) return;

    if (!mounted) return;

    final file = File(pickedFile.path);

    // Show image instantly
    setState(() => _profileImageFile = file);

    // Show loader safely
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.user;

    if (currentUser == null) {
      _safePop();
      return;
    }

    final userId =
        CloudinaryService.sanitizeEmailForFolder(currentUser.email);

    // Upload with timeout
    final imageUrl = await CloudinaryService.uploadImage(
      file,
      customFolder: 'profile_images/$userId',
    ).timeout(const Duration(seconds: 20));

    _safePop(); // close dialog safely

    if (imageUrl == null) {
      _showSnackBar('Upload failed', _primaryRed);
      return;
    }

    // Update user (NO extra refresh needed)
    final updatedUser = currentUser.copyWith(
      profileImageUrl: imageUrl,
      updatedAt: DateTime.now(),
    );

    await authProvider.updateUserProfile(updatedUser);

    // Clear local preview
    if (mounted) {
      setState(() => _profileImageFile = null);
    }

    _showSnackBar('Profile updated ✅', _primaryGreen);

  } catch (e) {
    print('❌ Error: $e');
    _safePop();
    _showSnackBar('Something went wrong', _primaryRed);
  }
}

void _safePop() {
  if (mounted && Navigator.canPop(context)) {
    Navigator.pop(context);
  }
}

Future<void> _uploadProfileImage(File imageFile) async {
  try {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.user;
    if (currentUser == null) {
      print('❌ No user logged in');
      return;
    }
    
    print('========== UPLOAD START ==========');
    print('User email: ${currentUser.email}');
    
    // Show loading dialog
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
              CircularProgressIndicator(color: _goldAccent, strokeWidth: 3),
              SizedBox(height: 20),
              Text('Uploading to Cloudinary...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
    
    // Upload to Cloudinary
    final imageUrl = await CloudinaryService.uploadImage(imageFile);
    
    if (imageUrl == null) {
      throw Exception('Failed to upload image to Cloudinary');
    }
    
    print('✅ Uploaded to Cloudinary: $imageUrl');
    
    // Update Firestore
    final updatedUser = currentUser.copyWith(
      profileImageUrl: imageUrl,
      updatedAt: DateTime.now(),
    );
    
    await authProvider.updateUserProfile(updatedUser);
    print('✅ Firestore updated');
    
    // Close loading dialog
    if (mounted) {
      Navigator.pop(context);
    }
    
    // Clear local file
    if (mounted) {
      setState(() {
        _profileImageFile = null;
      });
    }
    
    // Refresh user data
    await authProvider.refreshUserData();
    
    // Force UI rebuild
    if (mounted) {
      setState(() {});
      _showSnackBar('Profile picture updated successfully!', _primaryGreen);
    }
    
    print('========== UPLOAD COMPLETE ==========');
    
  } catch (e) {
    print('❌ Upload error: $e');
    if (mounted) {
      Navigator.pop(context);
      _showSnackBar('Failed to upload image: ${e.toString()}', _primaryRed);
    }
  }
}
  // ====================== EDIT PROFILE METHODS ======================

  void _showEditProfileDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    _firstNameController.text = user?.firstName ?? '';
    _lastNameController.text = user?.lastName ?? '';
    _phoneController.text = user?.phoneNumber?.replaceFirst(_selectedCountryCode, '') ?? '';
    
    if (user?.countryCode != null) {
      _selectedCountryCode = user!.countryCode!;
    }
    
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
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                                            color: Colors.white,
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

  Future<void> _saveProfileChanges(BuildContext context, StateSetter setState) async {
    setState(() => _isSaving = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;
      
      if (currentUser != null) {
        final firstName = _firstNameController.text.trim();
        final lastName = _lastNameController.text.trim();
        String? phoneNumber;
        
        if (firstName.isEmpty) {
          _showSnackBar('Please enter first name', _primaryRed);
          setState(() => _isSaving = false);
          return;
        }

        if (_showPhoneField) {
          final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
          if (phoneDigits.isNotEmpty) {
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
            phoneNumber = '$_selectedCountryCode$phoneDigits';
          }
        }
        
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

  // ====================== LOCATION METHODS ======================

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
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 450,
                minWidth: 300,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_bgGradient2, _primaryGreen.withOpacity(0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header - Smaller
                    Row(
                      children: [
                        Container(
                          width: isSmallScreen ? 36 : 40,
                          height: isSmallScreen ? 36 : 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryRed, _primaryGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.location_on_rounded, 
                            color: Colors.white, 
                            size: isSmallScreen ? 18 : 20
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 10 : 12),
                        Expanded(
                          child: Text(
                            'Update Location',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.w700,
                              color: _textWhite,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 14 : 16),
                    
                    // Current Location Display - Smaller
                    if (hasCurrentLocation)
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderColor, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded, 
                              color: _primaryGreen, 
                              size: isSmallScreen ? 16 : 18
                            ),
                            SizedBox(width: isSmallScreen ? 10 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current location',
                                    style: GoogleFonts.inter(
                                      fontSize: isSmallScreen ? 10 : 11,
                                      color: _textMuted,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 2 : 4),
                                  Text(
                                    user!.location!,
                                    style: GoogleFonts.poppins(
                                      fontSize: isSmallScreen ? 13 : 14,
                                      color: _textWhite,
                                      fontWeight: FontWeight.w600,
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
                    if (hasCurrentLocation) SizedBox(height: isSmallScreen ? 12 : 14),
                    
                    // Text Field - Smaller
                    TextFormField(
                      controller: _locationController,
                      style: GoogleFonts.inter(
                        color: _textWhite, 
                        fontSize: isSmallScreen ? 14 : 15
                      ),
                      decoration: InputDecoration(
                        labelText: 'Enter new location',
                        labelStyle: GoogleFonts.inter(
                          color: _textMuted,
                          fontSize: isSmallScreen ? 12 : 13,
                        ),
                        prefixIcon: Icon(Icons.edit_location_rounded, color: _primaryGreen, size: isSmallScreen ? 18 : 20),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _borderColor, width: 0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _borderColor, width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _primaryGreen, width: 1.5),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 14),
                    
                    // Divider - Smaller
                    Row(
                      children: [
                        Expanded(child: Divider(color: _borderColor, thickness: 0.8)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 12),
                          child: Text(
                            'Or',
                            style: GoogleFonts.poppins(
                              color: _textMuted, 
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 12 : 13,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: _borderColor, thickness: 0.8)),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 14),
                    
                    // GPS Button - Smaller
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoadingLocation ? null : () => _getCurrentLocation(setState),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryGreen, _darkGreen],
                              begin: Alignment.centerLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryGreen.withOpacity(0.25),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoadingLocation)
                                SizedBox(
                                  width: isSmallScreen ? 18 : 20,
                                  height: isSmallScreen ? 18 : 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: isSmallScreen ? 2 : 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.gps_fixed_rounded, 
                                  color: Colors.white, 
                                  size: isSmallScreen ? 18 : 20
                                ),
                              SizedBox(width: isSmallScreen ? 10 : 12),
                              Expanded(
                                child: Text(
                                  'Use current location',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isSmallScreen ? 13 : 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 14),
                    
                    // Selected Location Display - Smaller
                    if (hasTempLocation)
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _primaryGreen, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded, 
                              color: _primaryGreen, 
                              size: isSmallScreen ? 16 : 18
                            ),
                            SizedBox(width: isSmallScreen ? 10 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected location',
                                    style: GoogleFonts.inter(
                                      fontSize: isSmallScreen ? 10 : 11,
                                      color: _primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 2 : 4),
                                  Text(
                                    _tempLocation!,
                                    style: GoogleFonts.poppins(
                                      fontSize: isSmallScreen ? 13 : 14,
                                      color: _textWhite,
                                      fontWeight: FontWeight.w600,
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
                    if (hasTempLocation) SizedBox(height: isSmallScreen ? 12 : 14),
                    
                    // Action Buttons - Smaller
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isKeyboardVisible && isSmallScreen) SizedBox(height: 6),
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
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 10 : 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: _borderColor, width: 0.8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Cancel',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: isSmallScreen ? 13 : 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 10 : 12),
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isSaving ? null : () async {
                                    await _saveLocationChanges(context, setState);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 10 : 12,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_primaryRed, _deepRed],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _primaryRed.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: _isSaving
                                          ? SizedBox(
                                              width: isSmallScreen ? 18 : 20,
                                              height: isSmallScreen ? 18 : 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: isSmallScreen ? 2 : 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                            'Save',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: isSmallScreen ? 13 : 14,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isKeyboardVisible && isSmallScreen) SizedBox(height: 8),
                      ],
                    ),
                    if (isKeyboardVisible && !isSmallScreen) SizedBox(height: 6),
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
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showSnackBar('Location services are disabled. Please enable it.', _primaryRed);
        setState(() => _isLoadingLocation = false);
        return;
      }

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

  // ====================== CHANGE PASSWORD METHODS ======================


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
            horizontal: 16,
            vertical: isKeyboardVisible ? 8 : 16,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 450,
                minWidth: 280,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_bgGradient2, _primaryGreen.withOpacity(0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header - Smaller
                    Row(
                      children: [
                        Container(
                          width: isSmallScreen ? 36 : 40,
                          height: isSmallScreen ? 36 : 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryRed, _primaryGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.lock_reset_rounded, color: Colors.white, size: isSmallScreen ? 18 : 20),
                        ),
                        SizedBox(width: isSmallScreen ? 10 : 12),
                        Expanded(
                          child: Text(
                            'Change Password',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.w700,
                              color: _textWhite,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 14 : 16),
                    
                    // Form Fields - Smaller
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: true,
                          style: GoogleFonts.inter(
                            color: _textWhite, 
                            fontSize: isSmallScreen ? 14 : 15
                          ),
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            labelStyle: GoogleFonts.inter(
                              color: _textMuted,
                              fontSize: isSmallScreen ? 12 : 13,
                            ),
                            prefixIcon: Icon(Icons.lock_rounded, color: _primaryRed, size: isSmallScreen ? 18 : 20),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _borderColor, width: 0.8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _borderColor, width: 0.8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _primaryRed, width: 1.5),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: isSmallScreen ? 10 : 12,
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 10 : 12),
                        
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: true,
                          style: GoogleFonts.inter(
                            color: _textWhite, 
                            fontSize: isSmallScreen ? 14 : 15
                          ),
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            labelStyle: GoogleFonts.inter(
                              color: _textMuted,
                              fontSize: isSmallScreen ? 12 : 13,
                            ),
                            prefixIcon: Icon(Icons.lock_open_rounded, color: _primaryGreen, size: isSmallScreen ? 18 : 20),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _borderColor, width: 0.8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _borderColor, width: 0.8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _primaryGreen, width: 1.5),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: isSmallScreen ? 10 : 12,
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 10 : 12),
                        
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          style: GoogleFonts.inter(
                            color: _textWhite, 
                            fontSize: isSmallScreen ? 14 : 15
                          ),
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            labelStyle: GoogleFonts.inter(
                              color: _textMuted,
                              fontSize: isSmallScreen ? 12 : 13,
                            ),
                            prefixIcon: Icon(Icons.lock_reset_rounded, color: _primaryGreen, size: isSmallScreen ? 18 : 20),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _borderColor, width: 0.8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _borderColor, width: 0.8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _primaryGreen, width: 1.5),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: isSmallScreen ? 10 : 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 14),
                    
                    // Info Message - Smaller
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _borderColor, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.security_rounded, 
                            color: _primaryGreen, 
                            size: isSmallScreen ? 14 : 16
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 10),
                          Expanded(
                            child: Text(
                              'Password must be at least 8 characters',
                              style: GoogleFonts.inter(
                                color: _textMuted,
                                fontSize: isSmallScreen ? 11 : 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 18),
                    
                    // Action Buttons - Smaller
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isKeyboardVisible && isSmallScreen) SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 10 : 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: _borderColor, width: 0.8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Cancel',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: isSmallScreen ? 13 : 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 10 : 12),
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isSaving ? null : () async {
                                    await _changePassword(context, setState);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 10 : 12,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_primaryRed, _deepRed],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _primaryRed.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: _isSaving
                                          ? SizedBox(
                                              width: isSmallScreen ? 18 : 20,
                                              height: isSmallScreen ? 18 : 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: isSmallScreen ? 2 : 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                            'Update',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: isSmallScreen ? 13 : 14,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isKeyboardVisible && isSmallScreen) SizedBox(height: 8),
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

  // ====================== LOGOUT METHODS ======================

void _showPremiumLogoutDialog(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final isSmallScreen = mediaQuery.size.height < 600;
  
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (context) => Dialog(
      backgroundColor: _darkGreen,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _flagGradient1,
              _flagGradient2,
              _darkGreen,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 20),
          border: Border.all(
            color: _lightGreen.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 25,
              spreadRadius: 1,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: _primaryGreen.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: EdgeInsets.all(isSmallScreen ? 18 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon - Smaller
            Container(
              width: isSmallScreen ? 50 : 56,
              height: isSmallScreen ? 50 : 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryRed, _deepRed],
                ),
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
                boxShadow: [
                  BoxShadow(
                    color: _primaryRed.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: isSmallScreen ? 24 : 28,
              ),
            ),
            SizedBox(height: isSmallScreen ? 14 : 16),
            
            // Title - Smaller
            Text(
              'Confirm Logout',
              style: GoogleFonts.notoSansBengali(
                fontSize: isSmallScreen ? 20 : 22,
                fontWeight: FontWeight.w800,
                color: _textWhite,
              ),
            ),
            SizedBox(height: isSmallScreen ? 10 : 12),
            
            // Message - Smaller
            Text(
              'Are you sure you want to log out of BanglaHub?',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: isSmallScreen ? 13 : 14,
                color: _textLight,
                height: 1.4,
              ),
            ),
            SizedBox(height: isSmallScreen ? 20 : 24),
            
            // Buttons - Smaller
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _borderColor, width: 0.8),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 14 : 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 14),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      await _performPremiumLogout(context);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryRed, _deepRed],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryRed.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Logout',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 14 : 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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

  Future<void> _performPremiumLogout(BuildContext context) async {
    BuildContext? dialogContext;
    
    try {
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
      await authProvider.signOut(context);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_tab_index');
      print('📊 Cleared saved tab index on logout');

      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
    } catch (e) {
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      }
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