// screens/user_app/education_youth/tutoring/tutoring_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:bangla_hub/models/community_services_models.dart';
import 'package:bangla_hub/models/education_models.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/education_provider.dart';
import 'package:bangla_hub/providers/location_filter_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/auth/signup_screen.dart';
import 'package:bangla_hub/screens/user_app/education_youth/tutoring/tutoring_details_screen.dart';
import 'package:bangla_hub/widgets/common/distance_widget.dart';
import 'package:bangla_hub/widgets/common/global_location_filter_bar.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TutoringScreen extends StatefulWidget {
  @override
  _TutoringScreenState createState() => _TutoringScreenState();
}

class _TutoringScreenState extends State<TutoringScreen> 
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin, WidgetsBindingObserver {
  
  // Premium Color Palette - Education Theme
  final Color _primaryBlue = Color(0xFF1976D2); // Deep blue
  final Color _primaryGreen = Color(0xFF2E7D32); // Education green
  final Color _darkBlue = Color(0xFF0D47A1);
  final Color _lightBlue = Color(0xFFE3F2FD);
  final Color _goldAccent = Color(0xFFFFB300); // Gold for achievements
  final Color _orangeAccent = Color(0xFFF57C00); // Orange for highlights
  final Color _purpleAccent = Color(0xFF8E24AA); // Purple for qualifications
  final Color _tealAccent = Color(0xFF00897B); // Teal for teaching methods
  final Color _creamWhite = Color(0xFFFAF7F2);
  final Color _softGray = Color(0xFFECF0F1);
  final Color _textPrimary = Color(0xFF1E2A3A);
  final Color _textSecondary = Color(0xFF5D6D7E);
  final Color _borderLight = Color(0xFFE0E7E9);
  final Color _shadowColor = Color(0x1A000000);
  final Color _successGreen = Color(0xFF4CAF50);
  final Color _warningOrange = Color(0xFFFF9800);
  final Color _infoBlue = Color(0xFF2196F3);
  final Color _royalPurple = Color(0xFF6B4E71);
  
  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Particle animation controllers
  late List<AnimationController> _particleControllers;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  bool _isLoading = false;
  String? _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Mathematics', 'Science', 'English', 'Bangla', 'Computer'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // ✅ Add WidgetsBindingObserver
    WidgetsBinding.instance.addObserver(this);
    
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
      duration: Duration(milliseconds: 1500),
    );
    
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    
    // Initialize particle controllers
    _particleControllers = List.generate(8, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(seconds: 3 + (index % 3)),
      )..repeat(reverse: true);
    });
    
    // Start animations if app is visible
    if (_appLifecycleState == AppLifecycleState.resumed) {
      _startAnimations();
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      
      // Get user location if not already
      final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
      if (locationProvider.currentUserLocation == null) {
        locationProvider.getUserLocation(showLoading: false);
      }
    });
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
      _pulseController.repeat(reverse: true);
      // Particle controllers already running via repeat
    }
  }
  
  void _stopAnimations() {
    _fadeController.stop();
    _slideController.stop();
    _pulseController.stop();
    // Particle controllers will continue but we don't stop them as they're repetitive
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // ✅ FIXED: Use post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
      final educationProvider = Provider.of<EducationProvider>(context, listen: false);
      
      // Apply state filter if active
      if (locationProvider.isFilterActive && locationProvider.selectedState != null) {
        educationProvider.setFilter(
          EducationCategory.tutoringHomework,
          'state',
          locationProvider.selectedState,
        );
        educationProvider.loadTutoringServices();
      }
    });
  }

  @override
  void dispose() {
    print('🗑️ TutoringScreen disposing...');
    
    // ✅ Remove observer
    WidgetsBinding.instance.removeObserver(this);
    
    // ✅ Dispose animation controllers
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    
    // ✅ Dispose particle controllers
    for (var controller in _particleControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    print('🔍 Loading tutoring services...');
    
    final provider = Provider.of<EducationProvider>(context, listen: false);
    await provider.loadTutoringServices();
    
    print('📊 Total tutoring services loaded: ${provider.tutoringServices.length}');
    print('✅ Verified services: ${provider.tutoringServices.where((s) => s.isVerified).length}');
    
    if (mounted) setState(() => _isLoading = false);
  }

  // Get filtered services - ONLY SHOW VERIFIED SERVICES and apply location filter
  List<TutoringService> _getFilteredServices(
    List<TutoringService> services,
    LocationFilterProvider locationProvider,
  ) {
    // Only show verified and active services
    var verifiedServices = services.where((service) => 
      service.isVerified == true && service.isActive == true
    ).toList();
    
    print('✅ Verified services: ${verifiedServices.length} out of ${services.length} total');
    
    // Apply global location filter if active
    if (locationProvider.isFilterActive && locationProvider.selectedState != null) {
      verifiedServices = verifiedServices.where((service) {
        return service.state == locationProvider.selectedState;
      }).toList();
      print('📍 After state filter (${locationProvider.selectedState}): ${verifiedServices.length} services');
    }
    
    // Apply subject filter
    if (_selectedFilter != 'All') {
      verifiedServices = verifiedServices.where((service) {
        return service.subjects.any((subject) => 
          subject.displayName.contains(_selectedFilter!) ||
          subject.displayName.toLowerCase().contains(_selectedFilter!.toLowerCase())
        );
      }).toList();
    }
    
    return verifiedServices;
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
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _creamWhite,
        body: Stack(
          children: [
            // Animated Background Particles
            ...List.generate(8, (index) => _buildAnimatedParticle(index, screenWidth, MediaQuery.of(context).size.height)),
            
            CustomScrollView(
              slivers: [
                _buildPremiumAppBar(isTablet),
                
                // Global Location Filter Bar
                SliverToBoxAdapter(
                  child: Consumer<LocationFilterProvider>(
                    builder: (context, locationProvider, _) {
                      return GlobalLocationFilterBar(
                        isTablet: isTablet,
                        onClearTap: () {
                          final educationProvider = Provider.of<EducationProvider>(context, listen: false);
                          educationProvider.clearFilter(
                            EducationCategory.tutoringHomework,
                            'state',
                          );
                          educationProvider.loadTutoringServices();
                        },
                      );
                    },
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: _buildFilterChips(isTablet),
                ),
                _buildContent(),
              ],
            ),
          ],
        ),
        floatingActionButton: _buildPremiumFloatingActionButton(isTablet),
      ),
    );
  }

  SliverAppBar _buildPremiumAppBar(bool isTablet) {
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
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
              colors: [_primaryBlue, _darkBlue, _royalPurple],
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
                        colors: [_goldAccent, _orangeAccent, _goldAccent],
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
                      colors: [Colors.white, _goldAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'Tutoring & Homework Help',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 36 : 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  
                  // Subtitle
                  Text(
                    '🌟 Find qualified tutors for all subjects',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 18 : 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  SizedBox(height: isTablet ? 20 : 16),
                  
                  // Stats Row
                  Consumer<EducationProvider>(
                    builder: (context, provider, child) {
                      final verifiedCount = provider.tutoringServices
                          .where((s) => s.isVerified && s.isActive)
                          .length;
                      
                      return Row(
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
                                shouldAnimate
                                    ? RotationTransition(
                                        turns: AlwaysStoppedAnimation(0),
                                        child: Icon(Icons.verified_rounded, color: _goldAccent, size: isTablet ? 18 : 16),
                                      )
                                    : Icon(Icons.verified_rounded, color: _goldAccent, size: isTablet ? 18 : 16),
                                SizedBox(width: isTablet ? 8 : 6),
                                Text(
                                  '$verifiedCount Verified Tutors',
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 14 : 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: Colors.white, fontWeight: FontWeight.bold, size: isTablet ? 28 : 24,),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildFilterChips(bool isTablet) {
    return Container(
      height: 50,
      margin: EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: EdgeInsets.only(right: 12),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : _textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: isTablet ? 14 : 12,
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
                HapticFeedback.lightImpact();
              },
              backgroundColor: Colors.white,
              selectedColor: _primaryBlue,
              checkmarkColor: _goldAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: isSelected ? _primaryBlue : Color(0xFFE0E7E9),
                  width: 1,
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 12,
                vertical: isTablet ? 10 : 8,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumFloatingActionButton(bool isTablet) {
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    Widget button = FloatingActionButton.extended(
      onPressed: () {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        // Check if guest mode
        if (authProvider.isGuestMode) {
          _showLoginRequiredDialog(context, 'Add Tutoring Service');
          return;
        }
        _showAddTutoringDialog(context);
      },
      backgroundColor: Colors.transparent,
      elevation: 12,
      label: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 20,
          vertical: isTablet ? 16 : 14,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryBlue, _purpleAccent, _tealAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _primaryBlue.withOpacity(0.4),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_rounded, color: Colors.white, size: isTablet ? 24 : 20),
            SizedBox(width: isTablet ? 12 : 8),
            Text(
              'Add Tutoring',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
    
    return Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      child: shouldAnimate
          ? ScaleTransition(scale: _pulseAnimation, child: button)
          : button,
    );
  }

  Widget _buildContent() {
    return Consumer2<EducationProvider, LocationFilterProvider>(
      builder: (context, provider, locationProvider, child) {
        if (provider.isLoading || _isLoading) {
          return _buildLoadingState();
        }

        final filteredServices = _getFilteredServices(provider.tutoringServices, locationProvider);

        if (filteredServices.isEmpty) {
          return _buildEmptyState(locationProvider);
        }

        return SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final service = filteredServices[index];
                
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 500 + (index * 100)),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    final clampedValue = value.clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: 0.95 + (0.05 * clampedValue),
                      child: Opacity(
                        opacity: clampedValue,
                        child: child,
                      ),
                    );
                  },
                  child: _buildPremiumTutoringCard(service, index),
                );
              },
              childCount: filteredServices.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                      gradient: LinearGradient(
                        colors: [_primaryBlue, _purpleAccent, _tealAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryBlue.withOpacity(0.3),
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
                              color: _primaryBlue,
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
              shaderCallback: (bounds) => LinearGradient(
                colors: [_primaryBlue, _purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Loading Tutors...',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            ScaleTransition(
              scale: _pulseAnimation,
              child: Text(
                'Finding tutors for you ✨',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 15 : 13,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(LocationFilterProvider locationProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 30 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                      padding: EdgeInsets.all(isTablet ? 24 : 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_lightBlue, _primaryBlue.withOpacity(0.3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        size: isTablet ? 60 : 50,
                        color: _primaryBlue,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: isTablet ? 24 : 16),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [_primaryBlue, _purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  locationProvider.isFilterActive
                      ? 'No Tutors in ${locationProvider.selectedState}'
                      : 'No Tutors Found',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Text(
                locationProvider.isFilterActive
                    ? 'Try clearing the location filter! 📚'
                    : 'Be the first to offer tutoring! 📚',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 15 : 13,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (locationProvider.isFilterActive) ...[
                SizedBox(height: isTablet ? 20 : 16),
                GestureDetector(
                  onTap: () {
                    locationProvider.clearLocationFilter();
                    final educationProvider = Provider.of<EducationProvider>(context, listen: false);
                    educationProvider.clearFilter(
                      EducationCategory.tutoringHomework,
                      'state',
                    );
                    educationProvider.loadTutoringServices();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24 : 20,
                      vertical: isTablet ? 12 : 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryBlue, _purpleAccent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.clear_rounded, color: Colors.white, size: isTablet ? 20 : 18),
                        SizedBox(width: isTablet ? 8 : 6),
                        Text(
                          'Clear Filter',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // UPDATED: Now uses service's own user info fields instead of separate UserModel
  Widget _buildPremiumTutoringCard(TutoringService service, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
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
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _primaryBlue.withOpacity(0.2),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: _goldAccent.withOpacity(0.1),
                    blurRadius: 25,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.9),
                          _lightBlue.withOpacity(0.3),
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
                            _showLoginRequiredDialog(context, 'View Tutoring Details');
                            return;
                          }
                          _showTutoringDetails(service);
                        },
                        borderRadius: BorderRadius.circular(30),
                        splashColor: _goldAccent.withOpacity(0.15),
                        highlightColor: Colors.transparent,
                        child: Padding(
                          padding: EdgeInsets.all(isTablet ? 20 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User Info Row - Using service's stored user info
                              Row(
                                children: [
                                  // User Profile Image from service.postedByProfileImageBase64
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: 1),
                                    duration: Duration(milliseconds: 700 + (index * 80)),
                                    curve: Curves.elasticOut,
                                    builder: (context, value, child) {
                                      final nestedClampedValue = value.clamp(0.0, 1.0);
                                      return Transform.scale(
                                        scale: 0.85 + (0.15 * nestedClampedValue),
                                        child: Container(
                                          width: isTablet ? 50 : 40,
                                          height: isTablet ? 50 : 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [_primaryBlue, _purpleAccent, _tealAccent],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _goldAccent.withOpacity(0.4),
                                                blurRadius: 12,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(2),
                                            child: ClipOval(
                                              child: _buildServicePosterImage(service),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  SizedBox(width: 12),
                                  
                                  // User Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // User Name from service.postedByName
                                        ShaderMask(
                                          shaderCallback: (bounds) => LinearGradient(
                                            colors: [_primaryBlue, _purpleAccent],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ).createShader(bounds),
                                          child: Text(
                                            service.postedByName ?? 'Tutor',
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 16 : 14,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [_primaryBlue, _purpleAccent],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'Tutor Provider',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                color: _goldAccent,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Verified Badge
                                  Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_goldAccent, _orangeAccent, _goldAccent],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _goldAccent.withOpacity(0.4),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: shouldAnimate
                                        ? RotationTransition(
                                            turns: AlwaysStoppedAnimation(0),
                                            child: Icon(
                                              Icons.verified_rounded, 
                                              color: Colors.white, 
                                              size: isTablet ? 16 : 14,
                                            ),
                                          )
                                        : Icon(
                                            Icons.verified_rounded, 
                                            color: Colors.white, 
                                            size: isTablet ? 16 : 14,
                                          ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Tutor Name and Organization
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [_primaryBlue, _purpleAccent],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds),
                                    child: Text(
                                      service.tutorName,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 20 : 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    service.organizationName ?? 'Independent Tutor',
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 14 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: _primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 12),
                              
                              // Subjects Preview
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: service.subjects.take(3).map((subject) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 10 : 8,
                                      vertical: isTablet ? 5 : 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_primaryBlue.withOpacity(0.1), _lightBlue],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _primaryBlue.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      subject.displayName,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 12 : 11,
                                        fontWeight: FontWeight.w600,
                                        color: _primaryBlue,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              
                              if (service.subjects.length > 3)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '+${service.subjects.length - 3} more subjects',
                                    style: GoogleFonts.inter(
                                      fontSize: isTablet ? 12 : 10,
                                      color: _textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              
                              SizedBox(height: 12),
                              
                              // Location, Distance, and Rate Row
                              Row(
                                children: [
                                  // Location
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(isTablet ? 6 : 5),
                                          decoration: BoxDecoration(
                                            color: _primaryBlue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.location_on_rounded,
                                            color: _primaryBlue,
                                            size: isTablet ? 18 : 16,
                                          ),
                                        ),
                                        SizedBox(width: isTablet ? 8 : 6),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Location',
                                                style: GoogleFonts.inter(
                                                  fontSize: isTablet ? 11 : 10,
                                                  color: _textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                '${service.city}, ${service.state}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: isTablet ? 13 : 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: _textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Distance Badge
                                  if (service.latitude != null && service.longitude != null)
                                    Padding(
                                      padding: EdgeInsets.only(right: isTablet ? 10 : 8),
                                      child: DistanceBadge(
                                        latitude: service.latitude!,
                                        longitude: service.longitude!,
                                        isTablet: isTablet,
                                      ),
                                    ),
                                  
                                  // Rate
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 12 : 10,
                                      vertical: isTablet ? 8 : 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_successGreen.withOpacity(0.1), _successGreen.withOpacity(0.05)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _successGreen.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.attach_money_rounded,
                                          color: _successGreen,
                                          size: isTablet ? 18 : 16,
                                        ),
                                        Text(
                                          service.formattedRate,
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 14 : 12,
                                            fontWeight: FontWeight.w700,
                                            color: _successGreen,
                                          ),
                                        ),
                                        Text(
                                          '/hr',
                                          style: GoogleFonts.inter(
                                            fontSize: isTablet ? 11 : 10,
                                            color: _textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 12),
                              
                              // Teaching Methods Preview
                              Row(
                                children: service.teachingMethods.take(2).map((method) {
                                  return Container(
                                    margin: EdgeInsets.only(right: 6),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 10 : 8,
                                      vertical: isTablet ? 5 : 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_tealAccent.withOpacity(0.1), _tealAccent.withOpacity(0.05)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _tealAccent.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          method == TeachingMethod.inPerson ? Icons.person : Icons.videocam_rounded,
                                          color: _tealAccent,
                                          size: isTablet ? 12 : 10,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          method.displayName,
                                          style: GoogleFonts.inter(
                                            fontSize: isTablet ? 11 : 10,
                                            fontWeight: FontWeight.w600,
                                            color: _tealAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              
                              SizedBox(height: 16),
                              
                              // View Details Button
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: Duration(milliseconds: 800),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  final buttonClampedValue = value.clamp(0.0, 1.0);
                                  return Transform.scale(
                                    scale: 0.92 + (0.08 * buttonClampedValue),
                                    child: GestureDetector(
                                      onTap: () {
                                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                        if (authProvider.isGuestMode) {
                                          _showLoginRequiredDialog(context, 'View Tutoring Details');
                                          return;
                                        }
                                        _showTutoringDetails(service);
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          vertical: isTablet ? 14 : 12,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [_primaryBlue, _purpleAccent, _tealAccent],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(24),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _primaryBlue.withOpacity(0.3),
                                              blurRadius: 14,
                                              offset: Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'View Details',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: isTablet ? 16 : 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.white,
                                              size: isTablet ? 18 : 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
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

  // NEW: Build poster image from service.postedByProfileImageBase64
  Widget _buildServicePosterImage(TutoringService service) {
    if (service.postedByProfileImageBase64 != null && service.postedByProfileImageBase64!.isNotEmpty) {
      try {
        String base64String = service.postedByProfileImageBase64!;
        
        if (base64String.contains('base64,')) {
          base64String = base64String.split('base64,').last;
        }
        
        base64String = base64String.replaceAll(RegExp(r'\s'), '');
        
        while (base64String.length % 4 != 0) {
          base64String += '=';
        }
        
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultProfileImage();
          },
        );
      } catch (e) {
        return _buildDefaultProfileImage();
      }
    }
    return _buildDefaultProfileImage();
  }

  Widget _buildDefaultProfileImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryBlue, _purpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  // UPDATED: Now only passes service, not user
  void _showTutoringDetails(TutoringService service) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => TutoringDetailsScreen(
          service: service,
          scrollController: ScrollController(),
          primaryBlue: _primaryBlue,
          successGreen: _successGreen,
          warningOrange: _warningOrange,
          tealAccent: _tealAccent,
          purpleAccent: _purpleAccent,
          goldAccent: _goldAccent,
          lightBlue: _lightBlue,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = Offset(1.0, 0.0);
          var end = Offset.zero;
          var curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 500),
      ),
    );
  }

  void _showAddTutoringDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, _creamWhite],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: PremiumAddTutoringDialog(
              scrollController: scrollController,
              onTutoringAdded: _loadData,
              primaryBlue: _primaryBlue,
              successGreen: _successGreen,
              tealAccent: _tealAccent,
              purpleAccent: _purpleAccent,
              appLifecycleState: _appLifecycleState,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildAnimatedParticle(int index, double width, double height) {
    final controller = _particleControllers[index % _particleControllers.length];
    
    return Positioned(
      left: (index * 37) % width,
      top: (index * 53) % height,
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
                      _primaryBlue.withOpacity(0.1),
                      _purpleAccent.withOpacity(0.05),
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
}

// ====================== PREMIUM ADD TUTORING DIALOG ======================
class PremiumAddTutoringDialog extends StatefulWidget {
  final VoidCallback? onTutoringAdded;
  final ScrollController scrollController;
  final Color primaryBlue;
  final Color successGreen;
  final Color tealAccent;
  final Color purpleAccent;
  final AppLifecycleState appLifecycleState;

  const PremiumAddTutoringDialog({
    Key? key,
    this.onTutoringAdded,
    required this.scrollController,
    required this.primaryBlue,
    required this.successGreen,
    required this.tealAccent,
    required this.purpleAccent,
    required this.appLifecycleState,
  }) : super(key: key);

  @override
  _PremiumAddTutoringDialogState createState() => _PremiumAddTutoringDialogState();
}

class _PremiumAddTutoringDialogState extends State<PremiumAddTutoringDialog> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tutorNameController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _qualificationsController = TextEditingController();
  final TextEditingController _availableDaysController = TextEditingController();
  final TextEditingController _availableTimesController = TextEditingController();

  // Location picking
  double? _latitude;
  double? _longitude;
  String? _fullAddress;
  String? _selectedState;

  List<TutoringSubject> _selectedSubjects = [];
  List<EducationLevel> _selectedLevels = [];
  List<TeachingMethod> _selectedMethods = [];

  final Color _textPrimary = const Color(0xFF1A2B3C);

  final List<String> _states = CommunityStates.states;
  
  late TabController _tabController;
  late AnimationController _animationController;
  
  // Track dialog lifecycle
  AppLifecycleState _dialogLifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    
    // ✅ Add WidgetsBindingObserver
    WidgetsBinding.instance.addObserver(this);
    
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animationController.forward();
    
    _dialogLifecycleState = widget.appLifecycleState;
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _dialogLifecycleState = state;
    });
  }

  @override
  void dispose() {
    // ✅ Remove observer
    WidgetsBinding.instance.removeObserver(this);
    
    _tutorNameController.dispose();
    _organizationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _hourlyRateController.dispose();
    _experienceController.dispose();
    _qualificationsController.dispose();
    _availableDaysController.dispose();
    _availableTimesController.dispose();
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
    return FadeTransition(
      opacity: _animationController,
      child: Column(
        children: [
          // Premium Header
          Container(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.primaryBlue, widget.purpleAccent, widget.tealAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryBlue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 12 : 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.school_rounded, color: widget.tealAccent, size: isTablet ? 28 : 22),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Tutoring Service',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your listing will be visible after admin approval',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: isTablet ? 13 : 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  iconSize: isTablet ? 24 : 20,
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: EdgeInsets.all(isTablet ? 20 : 16),
            height: isTablet ? 50 : 45,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  colors: [widget.primaryBlue, widget.purpleAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: widget.primaryBlue,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: isTablet ? 14 : 12),
              unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: isTablet ? 13 : 11),
              tabs: [
                Tab(text: 'Basic Info'),
                Tab(text: 'Subjects'),
                Tab(text: 'Details'),
              ],
            ),
          ),

          // Form Content
          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildBasicInfoTab(isTablet),
                  _buildSubjectsTab(isTablet),
                  _buildDetailsTab(isTablet),
                ],
              ),
            ),
          ),

          // Navigation Buttons
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_tabController.index > 0)
                  Expanded(
                    child: _buildNavButton(
                      label: 'Previous',
                      onPressed: () {
                        if (_tabController.index > 0) {
                          _tabController.animateTo(_tabController.index - 1);
                        }
                      },
                      isPrimary: false,
                      isTablet: isTablet,
                    ),
                  ),
                if (_tabController.index > 0) SizedBox(width: isTablet ? 12 : 8),
                Expanded(
                  child: _tabController.index < 2
                      ? _buildNavButton(
                          label: 'Next',
                          onPressed: () {
                            if (_tabController.index == 0) {
                              if (_validateBasicInfo()) {
                                _tabController.animateTo(_tabController.index + 1);
                              }
                            } else if (_tabController.index == 1) {
                              if (_validateSubjects()) {
                                _tabController.animateTo(_tabController.index + 1);
                              }
                            }
                          },
                          isPrimary: true,
                          isTablet: isTablet,
                        )
                      : _buildSubmitButton(isTablet),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab(bool isTablet) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Tutor Information', Icons.person_rounded, widget.primaryBlue, isTablet),
          SizedBox(height: isTablet ? 20 : 16),
          
          _buildPremiumTextField(
            controller: _tutorNameController,
            label: 'Tutor Name *',
            icon: Icons.person_rounded,
            isRequired: true,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTextField(
            controller: _organizationController,
            label: 'Organization (Optional)',
            icon: Icons.business_rounded,
            isRequired: false,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTextField(
            controller: _emailController,
            label: 'Email Address *',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            isRequired: true,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTextField(
            controller: _phoneController,
            label: 'Phone Number *',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            isRequired: true,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          
          // Location Picker with Map
          _buildLocationPickerField(isTablet),
          SizedBox(height: isTablet ? 16 : 12),
        ],
      ),
    );
  }

  Widget _buildLocationPickerField(bool isTablet) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => OSMLocationPicker(
            initialLatitude: _latitude,
            initialLongitude: _longitude,
            initialAddress: _fullAddress,
            initialState: _selectedState,
            initialCity: _cityController.text.isNotEmpty ? _cityController.text : null,
            onLocationSelected: (lat, lng, address, state, city) {
              setState(() {
                _latitude = lat;
                _longitude = lng;
                _fullAddress = address;
                _selectedState = state;
                _addressController.text = address;
                if (city != null) {
                  _cityController.text = city;
                }
              });
            },
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(isTablet ? 16 : 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: _latitude != null ? widget.primaryBlue : Colors.grey[300]!,
            width: _latitude != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: _latitude != null ? Colors.white.withOpacity(0.9) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 10 : 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.primaryBlue, widget.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _latitude != null ? Icons.location_on : Icons.add_location,
                color: Colors.white,
                size: isTablet ? 22 : 18,
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location *',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      color: widget.primaryBlue,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _fullAddress ?? 'Tap to select location on map',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 14 : 12,
                      color: _fullAddress != null ? _textPrimary : Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_latitude != null && _longitude != null) ...[
                    SizedBox(height: 4),
                    Text(
                      'Lat: ${_latitude!.toStringAsFixed(4)}, Lng: ${_longitude!.toStringAsFixed(4)}',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 11 : 10,
                        color: widget.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: widget.primaryBlue,
              size: isTablet ? 16 : 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsTab(bool isTablet) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Subjects', Icons.subject_rounded, widget.primaryBlue, isTablet),
          SizedBox(height: isTablet ? 20 : 16),
          
          Text(
            'Select Subjects *',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: widget.primaryBlue,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: TutoringSubject.values.map((subject) {
                final isSelected = _selectedSubjects.contains(subject);
                return CheckboxListTile(
                  title: Text(
                    subject.displayName,
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 15 : 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedSubjects.add(subject);
                      } else {
                        _selectedSubjects.remove(subject);
                      }
                    });
                  },
                  activeColor: widget.primaryBlue,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: 4),
                );
              }).toList(),
            ),
          ),
          
          SizedBox(height: isTablet ? 24 : 20),
          
          _buildSectionHeader('Education Levels', Icons.school_rounded, widget.successGreen, isTablet),
          SizedBox(height: isTablet ? 16 : 12),
          
          Text(
            'Select Levels *',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: widget.successGreen,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: EducationLevel.values.map((level) {
                final isSelected = _selectedLevels.contains(level);
                return CheckboxListTile(
                  title: Text(
                    level.displayName,
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 15 : 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedLevels.add(level);
                      } else {
                        _selectedLevels.remove(level);
                      }
                    });
                  },
                  activeColor: widget.successGreen,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: 4),
                );
              }).toList(),
            ),
          ),
          
          SizedBox(height: isTablet ? 24 : 20),
          
          _buildSectionHeader('Teaching Methods', Icons.video_call_rounded, widget.tealAccent, isTablet),
          SizedBox(height: isTablet ? 16 : 12),
          
          Text(
            'Select Methods *',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: widget.tealAccent,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: TeachingMethod.values.map((method) {
                final isSelected = _selectedMethods.contains(method);
                return CheckboxListTile(
                  title: Text(
                    method.displayName,
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 15 : 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedMethods.add(method);
                      } else {
                        _selectedMethods.remove(method);
                      }
                    });
                  },
                  activeColor: widget.tealAccent,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: 4),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(bool isTablet) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Description', Icons.description_rounded, widget.purpleAccent, isTablet),
          SizedBox(height: isTablet ? 20 : 16),
          
          _buildPremiumTextField(
            controller: _descriptionController,
            label: 'Description *',
            icon: Icons.description_rounded,
            maxLines: 3,
            isRequired: true,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTextField(
            controller: _hourlyRateController,
            label: 'Hourly Rate (\$) *',
            icon: Icons.attach_money_rounded,
            keyboardType: TextInputType.number,
            isRequired: true,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTextField(
            controller: _experienceController,
            label: 'Experience (Optional)',
            icon: Icons.work_history_rounded,
            isRequired: false,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTextField(
            controller: _qualificationsController,
            label: 'Qualifications (Optional)',
            icon: Icons.school_rounded,
            isRequired: false,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          
          _buildSectionHeader('Availability', Icons.schedule_rounded, widget.tealAccent, isTablet),
          SizedBox(height: isTablet ? 16 : 12),
          
          Row(
            children: [
              Expanded(
                child: _buildPremiumTextField(
                  controller: _availableDaysController,
                  label: 'Available Days',
                  icon: Icons.calendar_today_rounded,
                  isRequired: false,
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Expanded(
                child: _buildPremiumTextField(
                  controller: _availableTimesController,
                  label: 'Available Times',
                  icon: Icons.schedule_rounded,
                  isRequired: false,
                  isTablet: isTablet,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 12 : 8),
          
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.primaryBlue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: widget.primaryBlue, size: isTablet ? 20 : 18),
                SizedBox(width: isTablet ? 12 : 8),
                Expanded(
                  child: Text(
                    'Example: Monday, Wednesday, Friday | 4 PM - 8 PM',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 14 : 12,
                      color: widget.primaryBlue,
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

  Widget _buildSectionHeader(String title, IconData icon, Color color, bool isTablet) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 8 : 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: isTablet ? 20 : 18),
        ),
        SizedBox(width: isTablet ? 12 : 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required bool isRequired,
    required bool isTablet,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.inter(
        fontSize: isTablet ? 16 : 14,
        color: Colors.grey[800],
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: isTablet ? 14 : 12,
          color: widget.primaryBlue,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: widget.primaryBlue, size: isTablet ? 22 : 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: widget.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: maxLines > 1 ? (isTablet ? 20 : 16) : (isTablet ? 18 : 14),
        ),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  Widget _buildNavButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
    required bool isTablet,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 16 : 14,
        ),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  colors: [widget.primaryBlue, widget.purpleAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isPrimary ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: widget.primaryBlue, width: 2),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: widget.primaryBlue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isPrimary ? Colors.white : widget.primaryBlue,
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isTablet) {
    return GestureDetector(
      onTap: _submitForm,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 16 : 14,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.successGreen, widget.tealAccent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.successGreen.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: isTablet ? 22 : 20),
            SizedBox(width: isTablet ? 10 : 8),
            Text(
              'Submit',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _validateBasicInfo() {
    if (_tutorNameController.text.isEmpty) {
      _showErrorSnackBar('Please enter tutor name');
      return false;
    }
    if (_emailController.text.isEmpty) {
      _showErrorSnackBar('Please enter email address');
      return false;
    }
    if (!_emailController.text.contains('@')) {
      _showErrorSnackBar('Please enter a valid email address');
      return false;
    }
    if (_phoneController.text.isEmpty) {
      _showErrorSnackBar('Please enter phone number');
      return false;
    }
    if (_phoneController.text.length < 10) {
      _showErrorSnackBar('Please enter a valid phone number');
      return false;
    }
    if (_latitude == null || _longitude == null) {
      _showErrorSnackBar('Please select a location on the map');
      return false;
    }
    if (_selectedState == null) {
      _showErrorSnackBar('Location must include a valid state');
      return false;
    }
    if (_cityController.text.isEmpty) {
      _showErrorSnackBar('Please enter city');
      return false;
    }
    return true;
  }

  bool _validateSubjects() {
    if (_selectedSubjects.isEmpty) {
      _showErrorSnackBar('Please select at least one subject');
      return false;
    }
    if (_selectedLevels.isEmpty) {
      _showErrorSnackBar('Please select at least one education level');
      return false;
    }
    if (_selectedMethods.isEmpty) {
      _showErrorSnackBar('Please select at least one teaching method');
      return false;
    }
    return true;
  }

  void _submitForm() async {
    if (!_validateBasicInfo()) return;
    if (!_validateSubjects()) return;
    
    if (_descriptionController.text.isEmpty) {
      _showErrorSnackBar('Please enter description');
      return;
    }
    
    if (_descriptionController.text.length < 20) {
      _showErrorSnackBar('Description should be at least 20 characters');
      return;
    }
    
    if (_hourlyRateController.text.isEmpty) {
      _showErrorSnackBar('Please enter hourly rate');
      return;
    }

    final rate = double.tryParse(_hourlyRateController.text);
    if (rate == null || rate <= 0) {
      _showErrorSnackBar('Please enter a valid hourly rate');
      return;
    }

    // Get current user from AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    
    if (currentUser == null) {
      _showErrorSnackBar('You must be logged in to add tutoring services');
      return;
    }

    print('📝 Current user: ${currentUser.fullName} (ID: ${currentUser.id})');

    final provider = Provider.of<EducationProvider>(context, listen: false);

    // Get user's profile image
    String? userProfileImage;
    if (currentUser.profileImageUrl != null && currentUser.profileImageUrl!.isNotEmpty) {
      userProfileImage = currentUser.profileImageUrl;
    }

    final newService = TutoringService(
      tutorName: _tutorNameController.text,
      organizationName: _organizationController.text.isNotEmpty ? _organizationController.text : null,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _fullAddress ?? _addressController.text,
      state: _selectedState!,
      city: _cityController.text,
      subjects: _selectedSubjects,
      levels: _selectedLevels,
      teachingMethods: _selectedMethods,
      description: _descriptionController.text,
      hourlyRate: rate,
      experience: _experienceController.text.isNotEmpty ? _experienceController.text : null,
      qualifications: _qualificationsController.text.isNotEmpty ? _qualificationsController.text : null,
      availableDays: _availableDaysController.text.isNotEmpty 
          ? _availableDaysController.text.split(',').map((day) => day.trim()).toList()
          : ['Monday', 'Wednesday', 'Friday'],
      availableTimes: _availableTimesController.text.isNotEmpty
          ? _availableTimesController.text.split(',').map((time) => time.trim()).toList()
          : ['4 PM - 8 PM'],
      
      // Location coordinates
      latitude: _latitude,
      longitude: _longitude,
      
      // Store user info directly in the service document
      postedByUserId: currentUser.id,
      postedByName: currentUser.fullName,
      postedByEmail: currentUser.email,
      postedByProfileImageBase64: userProfileImage,
      
      createdBy: currentUser.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      isVerified: false,
    );

    print('📝 Creating tutoring service with createdBy: ${newService.createdBy} (user ID)');
    print('📍 Location: ${_latitude}, ${_longitude} in ${_selectedState}');
    print('📝 Service will be hidden until admin verification (isVerified: false)');

    // Show loading
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(color: widget.primaryBlue),
              ),
              SizedBox(height: 20),
              Text('Submitting...', style: GoogleFonts.poppins()),
            ],
          ),
        ),
      ),
    );

    final success = await provider.addTutoringService(newService);
    
    if (mounted) {
      Navigator.pop(context); // Close loading
    }
    
    if (success) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        _showSuccessSnackBar('Tutoring service added successfully! Pending admin approval. ✨');
        
        if (widget.onTutoringAdded != null) {
          widget.onTutoringAdded!();
        }
      }
    } else {
      if (mounted) {
        _showErrorSnackBar('Failed to add tutoring service. Please try again.');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: widget.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(12),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(12),
      ),
    );
  }
}