// screens/user_app/entrepreneurship/small_business_promotion/small_business_promotion_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:bangla_hub/models/community_services_models.dart';
import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/location_filter_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/auth/signup_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/small_business_promotion/business_promotion_details_screen.dart';
import 'package:bangla_hub/widgets/common/distance_widget.dart';
import 'package:bangla_hub/widgets/common/global_location_filter_bar.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class SmallBusinessPromotionScreen extends StatefulWidget {
  @override
  _SmallBusinessPromotionScreenState createState() => _SmallBusinessPromotionScreenState();
}

class _SmallBusinessPromotionScreenState extends State<SmallBusinessPromotionScreen> 
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin, WidgetsBindingObserver {
  
  // Premium Color Palette - Following BanglaClassesScreen Theme
  final Color _primaryOrange = Color(0xFFFF9800);
  final Color _darkOrange = Color(0xFFF57C00);
  final Color _lightOrange = Color(0xFFFFF3E0);
  final Color _redAccent = Color(0xFFE53935);
  final Color _greenAccent = Color(0xFF43A047);
  final Color _goldAccent = Color(0xFFFFB300);
  final Color _purpleAccent = Color(0xFF8E24AA);
  final Color _tealAccent = Color(0xFF00897B);
  final Color _creamWhite = Color(0xFFFAF7F2);
  final Color _softGray = Color(0xFFECF0F1);
  final Color _textPrimary = Color(0xFF1E2A3A);
  final Color _textSecondary = Color(0xFF5D6D7E);
  final Color _borderLight = Color(0xFFE0E7E9);
  final Color _successGreen = Color(0xFF4CAF50);
  final Color _warningOrange = Color(0xFFFF9800);
  final Color _infoBlue = Color(0xFF2196F3);
  
  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _rotateController;
  
  // Particle animation controllers
  late List<AnimationController> _particleControllers;
  late List<AnimationController> _bubbleControllers;

  // LOCAL FILTER STATE - separate from global filter
  String? _localSelectedState;
  String? _localSelectedCity;
  String? _localSelectedIndustry;
  bool _isFilterView = false;
  final ScrollController _filterScrollController = ScrollController();
  
  // Track which local filters are active
  bool _hasLocalFilters = false;
  Map<String, dynamic> _activeLocalFilters = {};

  bool _isLoading = false;
  String? _selectedCategoryFilter = 'All';
  final List<String> _categoryFilters = ['All', 'Retail', 'Food', 'Services', 'Healthcare', 'Education', 'Technology'];

  // Track global filter state
  bool _previousGlobalFilterState = false;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

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
      duration: Duration(milliseconds: 1200),
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
    
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    
    _rotateController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    
    // Initialize particle controllers (30 particles)
    _particleControllers = List.generate(30, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(seconds: 3 + (index % 3)),
      )..repeat(reverse: true);
    });
    
    // Initialize bubble controllers (8 bubbles)
    _bubbleControllers = List.generate(8, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(seconds: 8 + (index * 2)),
      )..repeat(reverse: true);
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      
      // Get user location if not already
      final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
      if (locationProvider.currentUserLocation == null) {
        locationProvider.getUserLocation(showLoading: false);
      }
      
      // Start animations if app is visible
      if (_appLifecycleState == AppLifecycleState.resumed) {
        _startAnimations();
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
      _scaleController.forward();
      _pulseController.repeat(reverse: true);
      _rotateController.repeat(reverse: true);
      // Particle and bubble controllers already running via repeat
    }
  }
  
  void _stopAnimations() {
    _fadeController.stop();
    _slideController.stop();
    _pulseController.stop();
    _scaleController.stop();
    _rotateController.stop();
    // Particle and bubble controllers will continue but we don't stop them
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Listen to location provider changes but DON'T automatically apply filter
    final locationProvider = Provider.of<LocationFilterProvider>(context);
    
    // Only reload when global filter changes to show/hide global filter bar
    if (locationProvider.isFilterActive != _previousGlobalFilterState) {
      _previousGlobalFilterState = locationProvider.isFilterActive;
      _loadData();
    }
  }

  @override
  void dispose() {
    print('🗑️ SmallBusinessPromotionScreen disposing...');
    
    // ✅ Remove observer
    WidgetsBinding.instance.removeObserver(this);
    
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    
    // ✅ Dispose particle controllers
    for (var controller in _particleControllers) {
      controller.dispose();
    }
    
    // ✅ Dispose bubble controllers
    for (var controller in _bubbleControllers) {
      controller.dispose();
    }
    
    _filterScrollController.dispose();
    
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
      final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
      
      // IMPORTANT: Do NOT apply global filter automatically
      // The provider will handle global filter separately
      
      // Apply LOCAL filters if any
      if (_hasLocalFilters) {
        if (_localSelectedState != null) {
          provider.setFilter(EntrepreneurshipCategory.smallBusinessPromotion, 'local_state', _localSelectedState);
        }
        if (_localSelectedCity != null && _localSelectedCity!.isNotEmpty) {
          provider.setFilter(EntrepreneurshipCategory.smallBusinessPromotion, 'local_city', _localSelectedCity);
        }
        if (_localSelectedIndustry != null && _localSelectedIndustry!.isNotEmpty) {
          provider.setFilter(EntrepreneurshipCategory.smallBusinessPromotion, 'local_industry', _localSelectedIndustry);
        }
      }
      
      await provider.loadBusinessPromotions();
      
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading promotions: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _applyLocalFilters() async {
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    // Clear any existing local filters first
    provider.clearAllFilters(EntrepreneurshipCategory.smallBusinessPromotion);
    
    // Build active filters map for display
    Map<String, dynamic> newActiveFilters = {};
    
    // Apply new local filters
    if (_localSelectedState != null) {
      provider.setFilter(EntrepreneurshipCategory.smallBusinessPromotion, 'local_state', _localSelectedState);
      newActiveFilters['local_state'] = _localSelectedState;
    }
    if (_localSelectedCity != null && _localSelectedCity!.isNotEmpty) {
      provider.setFilter(EntrepreneurshipCategory.smallBusinessPromotion, 'local_city', _localSelectedCity);
      newActiveFilters['local_city'] = _localSelectedCity;
    }
    if (_localSelectedIndustry != null && _localSelectedIndustry!.isNotEmpty) {
      provider.setFilter(EntrepreneurshipCategory.smallBusinessPromotion, 'local_industry', _localSelectedIndustry);
      newActiveFilters['local_industry'] = _localSelectedIndustry;
    }
    
    setState(() {
      _hasLocalFilters = newActiveFilters.isNotEmpty;
      _activeLocalFilters = newActiveFilters;
      _isFilterView = false;
    });
    
    await provider.loadBusinessPromotions();
  }

  void _clearLocalFilters() {
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    // Clear all local filters from provider
    provider.clearAllFilters(EntrepreneurshipCategory.smallBusinessPromotion);
    
    // Reset local state
    setState(() {
      _localSelectedState = null;
      _localSelectedCity = null;
      _localSelectedIndustry = null;
      _hasLocalFilters = false;
      _activeLocalFilters.clear();
      _isFilterView = false;
    });
    
    provider.loadBusinessPromotions();
  }

  // Get filtered promotions - applying BOTH global and local filters
  List<SmallBusinessPromotion> _getFilteredPromotions(
    List<SmallBusinessPromotion> promotions,
    LocationFilterProvider locationProvider,
  ) {
    // Start with all verified and active promotions
    var filteredPromotions = promotions
        .where((p) => p.isVerified && p.isActive && !p.isDeleted)
        .toList();
    
    print('📊 Initial verified promotions: ${filteredPromotions.length}');
    
    // Apply GLOBAL location filter if active (from LocationFilterProvider)
    if (locationProvider.isFilterActive && locationProvider.selectedState != null) {
      filteredPromotions = filteredPromotions.where((promotion) {
        return promotion.state == locationProvider.selectedState;
      }).toList();
      print('📍 After GLOBAL filter (${locationProvider.selectedState}): ${filteredPromotions.length} promotions');
    }
    
    // Apply LOCAL filters if any (from this screen's filter view)
    if (_hasLocalFilters) {
      // State filter
      if (_localSelectedState != null) {
        filteredPromotions = filteredPromotions.where((promotion) => 
          promotion.state == _localSelectedState
        ).toList();
      }
      
      // City filter
      if (_localSelectedCity != null && _localSelectedCity!.isNotEmpty) {
        filteredPromotions = filteredPromotions.where((promotion) => 
          promotion.city.toLowerCase().contains(_localSelectedCity!.toLowerCase())
        ).toList();
      }
      
      // Industry filter
      if (_localSelectedIndustry != null && _localSelectedIndustry!.isNotEmpty) {
        filteredPromotions = filteredPromotions.where((promotion) => 
          promotion.productsServices.any((service) => 
            service.toLowerCase().contains(_localSelectedIndustry!.toLowerCase())
          )
        ).toList();
      }
      
      print('📊 After LOCAL filters: ${filteredPromotions.length} promotions');
    }
    
    // Apply category filter (from chips)
    if (_selectedCategoryFilter != 'All') {
      filteredPromotions = filteredPromotions.where((p) {
        return p.productsServices.any((service) => 
          service.toLowerCase().contains(_selectedCategoryFilter!.toLowerCase())
        );
      }).toList();
    }
    
    return filteredPromotions;
  }

  Future<void> _launchPhone(String phone) async {
    String formattedPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (!formattedPhone.startsWith('1') && formattedPhone.length == 10) {
      formattedPhone = '1$formattedPhone';
    }
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+$formattedPhone';
    }
    
    final Uri phoneUri = Uri(scheme: 'tel', path: formattedPhone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        if (mounted) _showSuccessSnackBar('Opening phone dialer...');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Could not launch phone dialer');
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Inquiry about your business',
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        if (mounted) _showSuccessSnackBar('Opening email app...');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Could not launch email app');
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      String finalUrl = url;
      if (!finalUrl.startsWith('http')) {
        finalUrl = 'https://$finalUrl';
      }
      
      final Uri uri = Uri.parse(finalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) _showSuccessSnackBar('Opening link...');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Invalid URL');
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: _successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
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
            SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: _redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.all(16),
      ),
    );
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
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;

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
            gradient: LinearGradient(
              colors: [
                _lightOrange.withOpacity(0.3),
                _creamWhite,
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Animated Background Particles
              ...List.generate(30, (index) => _buildAnimatedParticle(index, screenWidth, MediaQuery.of(context).size.height)),
              
              // Floating Bubbles
              ...List.generate(8, (index) => _buildFloatingBubble(index, screenWidth, MediaQuery.of(context).size.height)),
              
              // Main Content
              RefreshIndicator(
                color: _goldAccent,
                backgroundColor: Colors.white,
                onRefresh: _loadData,
                child: _isFilterView
                    ? _buildFiltersView(isTablet)
                    : CustomScrollView(
                        physics: BouncingScrollPhysics(),
                        slivers: [
                          _buildPremiumAppBar(isTablet),
                          
                          // Global Location Filter Bar - SEPARATE
                          SliverToBoxAdapter(
                            child: Consumer<LocationFilterProvider>(
                              builder: (context, locationProvider, _) {
                                return GlobalLocationFilterBar(
                                  isTablet: isTablet,
                                  onClearTap: () {
                                    // This only clears GLOBAL filter
                                    locationProvider.clearLocationFilter();
                                    _loadData(); // Reload with global filter cleared
                                  },
                                );
                              },
                            ),
                          ),
                          
                          // Local Filter Toggle Button - SEPARATE
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 20 : 16,
                                vertical: 8,
                              ),
                              child: _buildLocalFilterToggleButton(isTablet),
                            ),
                          ),
                          
                          // Active LOCAL Filters Display
                          _buildActiveLocalFilters(isTablet),
                          
                          // Category Filters (always visible)
                          SliverToBoxAdapter(
                            child: _buildCategoryFilterChips(isTablet),
                          ),
                          
                          _buildContent(),
                        ],
                      ),
              ),
              
              // Premium Floating Action Button
              Positioned(
                bottom: 30,
                right: 30,
                child: _buildPremiumFloatingActionButton(isTablet, shouldAnimate),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersView(bool isTablet) {
    return CustomScrollView(
      controller: _filterScrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildPremiumAppBar(isTablet),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        
        // Global Location Filter Bar - still visible but separate
        SliverToBoxAdapter(
          child: Consumer<LocationFilterProvider>(
            builder: (context, locationProvider, _) {
              return GlobalLocationFilterBar(
                isTablet: isTablet,
                onClearTap: () {
                  locationProvider.clearLocationFilter();
                },
              );
            },
          ),
        ),
        
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.all(isTablet ? 24 : 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryOrange, _redAccent],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.tune_rounded, color: Colors.white),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Filters',
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 24 : 20,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                  ),
                                ),
                                Text(
                                  'Apply filters specific to this screen',
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 14 : 12,
                                    color: _textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 24),
                      
                      // State Dropdown
                      _buildDropdown<String?>(
                        value: _localSelectedState,
                        label: 'Select State',
                        icon: Icons.location_on_rounded,
                        items: [
                          DropdownMenuItem<String?>(value: null, child: Text('All States')),
                          ...CommunityStates.states.map((state) => 
                            DropdownMenuItem<String?>(value: state, child: Text(state))
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _localSelectedState = newValue;
                            _localSelectedCity = null;
                          });
                        },
                        isTablet: isTablet,
                      ),
                      
                      if (_localSelectedState != null) ...[
                        SizedBox(height: 16),
                        // City Text Field (optional)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            initialValue: _localSelectedCity,
                            onChanged: (value) => _localSelectedCity = value,
                            decoration: InputDecoration(
                              labelText: 'City (Optional)',
                              labelStyle: GoogleFonts.poppins(fontSize: 13),
                              prefixIcon: Icon(Icons.location_city_rounded, color: _primaryOrange, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                      
                      SizedBox(height: 16),
                      
                      // Industry Text Field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          initialValue: _localSelectedIndustry,
                          onChanged: (value) => _localSelectedIndustry = value,
                          decoration: InputDecoration(
                            labelText: 'Industry/Category (Optional)',
                            labelStyle: GoogleFonts.poppins(fontSize: 13),
                            prefixIcon: Icon(Icons.category_rounded, color: _primaryOrange, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              label: 'Apply',
                              onTap: _applyLocalFilters,
                              isPrimary: true,
                              isTablet: isTablet,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              label: 'Clear',
                              onTap: _clearLocalFilters,
                              isPrimary: false,
                              isTablet: isTablet,
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
        ),
        SliverToBoxAdapter(child: SizedBox(height: isTablet ? 100 : 80)),
      ],
    );
  }

  Widget _buildLocalFilterToggleButton(bool isTablet) {
    return GestureDetector(
      onTap: () {
        setState(() => _isFilterView = true);
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 14 : 12,
        ),
        decoration: BoxDecoration(
          gradient: _hasLocalFilters
              ? LinearGradient(colors: [_primaryOrange, _redAccent])
              : LinearGradient(colors: [_primaryOrange, _darkOrange]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _primaryOrange.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _hasLocalFilters ? Icons.filter_alt_rounded : Icons.tune_rounded,
              color: Colors.white,
              size: isTablet ? 20 : 18,
            ),
            SizedBox(width: 8),
            Text(
              _hasLocalFilters ? 'Edit Filters' : 'Filters',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_hasLocalFilters) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${_activeLocalFilters.length}',
                  style: GoogleFonts.poppins(
                    color: _primaryOrange,
                    fontSize: isTablet ? 12 : 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveLocalFilters(bool isTablet) {
    if (_activeLocalFilters.isEmpty) return SliverToBoxAdapter(child: SizedBox.shrink());
    
    final chips = <Widget>[];
    
    _activeLocalFilters.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        String label = '';
        IconData icon = Icons.filter_alt_rounded;
        
        switch (key) {
          case 'local_state':
            label = 'State: $value';
            icon = Icons.location_on_rounded;
            break;
          case 'local_city':
            label = 'City: $value';
            icon = Icons.location_city_rounded;
            break;
          case 'local_industry':
            label = 'Industry: $value';
            icon = Icons.category_rounded;
            break;
        }
        
        chips.add(_buildFilterChip(
          label: label,
          icon: icon,
          onRemove: () {
            // Remove this specific local filter
            final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
            provider.clearFilter(EntrepreneurshipCategory.smallBusinessPromotion, key);
            
            setState(() {
              _activeLocalFilters.remove(key);
              _hasLocalFilters = _activeLocalFilters.isNotEmpty;
              
              // Also clear the corresponding local state variable
              switch (key) {
                case 'local_state':
                  _localSelectedState = null;
                  break;
                case 'local_city':
                  _localSelectedCity = null;
                  break;
                case 'local_industry':
                  _localSelectedIndustry = null;
                  break;
              }
            });
            
            provider.loadBusinessPromotions();
          },
        ));
      }
    });
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Active Filters:',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w600,
                  color: _primaryOrange,
                ),
              ),
            ),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_primaryOrange, _darkOrange]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, color: Colors.white, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 13),
          prefixIcon: Icon(icon, color: _primaryOrange, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: _primaryOrange),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    required bool isTablet,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(colors: [_primaryOrange, _redAccent])
              : null,
          color: isPrimary ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isPrimary ? null : Border.all(color: _primaryOrange, width: 2),
          boxShadow: isPrimary
              ? [BoxShadow(color: _primaryOrange.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 6))]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isPrimary ? Colors.white : _primaryOrange,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildPremiumAppBar(bool isTablet) {
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
              colors: [_primaryOrange, _darkOrange, _redAccent],
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
                        colors: [_goldAccent, _greenAccent, _goldAccent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  
                  // Title
                  Text(
                    'Small Business',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 36 : 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: isTablet ? 8 : 4),
                  Text(
                    'Promotions',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 32 : 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  
                  // Subtitle
                  Text(
                    '🌟 Discover and support local businesses',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 18 : 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  SizedBox(height: isTablet ? 20 : 16),
                  
                  // Stats Row
                  Consumer<EntrepreneurshipProvider>(
                    builder: (context, provider, child) {
                      final verifiedCount = provider.businessPromotions
                          .where((p) => p.isVerified && p.isActive)
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
                                Icon(Icons.storefront_rounded, color: _goldAccent, size: isTablet ? 18 : 16),
                                SizedBox(width: isTablet ? 8 : 6),
                                Text(
                                  '$verifiedCount Active Businesses',
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

  Widget _buildCategoryFilterChips(bool isTablet) {
    return Container(
      height: 50,
      margin: EdgeInsets.only(top: 16, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
        itemCount: _categoryFilters.length,
        itemBuilder: (context, index) {
          final filter = _categoryFilters[index];
          final isSelected = _selectedCategoryFilter == filter;
          
          return Padding(
            padding: EdgeInsets.only(right: 12),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                filter,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : _textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: isTablet ? 14 : 12,
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedCategoryFilter = filter;
                });
                HapticFeedback.lightImpact();
              },
              backgroundColor: Colors.white,
              selectedColor: _primaryOrange,
              checkmarkColor: _goldAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: isSelected ? _primaryOrange : _borderLight,
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
                      _primaryOrange.withOpacity(0.5),
                      _greenAccent.withOpacity(0.3),
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

  Widget _buildFloatingBubble(int index, double width, double height) {
    final controller = _bubbleControllers[index % _bubbleControllers.length];
    final size = 50 + (index * 15).toDouble();
    
    return Positioned(
      left: (index * 73) % width,
      top: (index * 47) % height,
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
                      _lightOrange.withOpacity(0.3),
                      _greenAccent.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _goldAccent.withOpacity(0.1),
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

  Widget _buildPremiumFloatingActionButton(bool isTablet, bool shouldAnimate) {
    Widget button = Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      child: FloatingActionButton.extended(
        onPressed: () {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.isGuestMode) {
            _showLoginRequiredDialog(context, 'Add Promotion');
            return;
          }
          _showAddPromotionDialog(context);
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
              colors: [_primaryOrange, _redAccent, _greenAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _primaryOrange.withOpacity(0.4),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_business_rounded, color: Colors.white, size: isTablet ? 24 : 20),
              SizedBox(width: isTablet ? 12 : 8),
              Text(
                'Promote Business',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    return shouldAnimate
        ? ScaleTransition(scale: _pulseAnimation, child: button)
        : button;
  }

  Widget _buildContent() {
    return Consumer2<EntrepreneurshipProvider, LocationFilterProvider>(
      builder: (context, provider, locationProvider, child) {
        if (provider.isLoading || _isLoading) {
          return _buildLoadingState();
        }

        final filteredPromotions = _getFilteredPromotions(provider.businessPromotions, locationProvider);

        if (filteredPromotions.isEmpty) {
          return _buildEmptyState(locationProvider);
        }

        return SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final promotion = filteredPromotions[index];
                
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: _buildPremiumPromotionCard(promotion, index),
                    ),
                  ),
                );
              },
              childCount: filteredPromotions.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
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
                        colors: [_primaryOrange.withOpacity(0.1), _lightOrange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryOrange.withOpacity(0.3),
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
                              color: _primaryOrange,
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
                colors: [_primaryOrange, _redAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Loading Businesses...',
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
                      'Discover local businesses ✨',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 15 : 13,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : Text(
                    'Discover local businesses ✨',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 15 : 13,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
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
    
    String emptyMessage = 'No businesses found';
    if (locationProvider.isFilterActive && _hasLocalFilters) {
      emptyMessage = 'No businesses in ${locationProvider.selectedState} with your local filters';
    } else if (locationProvider.isFilterActive) {
      emptyMessage = 'No businesses in ${locationProvider.selectedState}';
    } else if (_hasLocalFilters) {
      emptyMessage = 'No businesses match your local filters';
    }
    
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
                        gradient: RadialGradient(
                          colors: [
                            _lightOrange,
                            _primaryOrange.withOpacity(0.3),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        size: isTablet ? 60 : 50,
                        color: _primaryOrange,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: isTablet ? 24 : 16),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [_primaryOrange, _redAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  emptyMessage,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Text(
                'Try adjusting your filters or be the first to promote!',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 15 : 13,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (locationProvider.isFilterActive || _hasLocalFilters) ...[
                SizedBox(height: isTablet ? 20 : 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (locationProvider.isFilterActive)
                      GestureDetector(
                        onTap: () {
                          locationProvider.clearLocationFilter();
                          _loadData();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 20 : 16,
                            vertical: isTablet ? 10 : 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryOrange, _darkOrange],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Clear Filter',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: isTablet ? 14 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (locationProvider.isFilterActive && _hasLocalFilters) SizedBox(width: 10),
                    if (_hasLocalFilters)
                      GestureDetector(
                        onTap: _clearLocalFilters,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 20 : 16,
                            vertical: isTablet ? 10 : 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryOrange, _redAccent],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Clear Local',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: isTablet ? 14 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // UPDATED: Now uses promotion's own user info fields and includes distance badge
  Widget _buildPremiumPromotionCard(SmallBusinessPromotion promotion, int index) {
    final isOfferActive = promotion.specialOfferDiscount != null && promotion.specialOfferDiscount! > 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
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
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                    spreadRadius: -3,
                  ),
                  BoxShadow(
                    color: _primaryOrange.withOpacity(0.1),
                    blurRadius: 25,
                    offset: Offset(0, 4),
                    spreadRadius: -5,
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
                          _lightOrange.withOpacity(0.3),
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
                            _showLoginRequiredDialog(context, 'View Promotion Details');
                            return;
                          }
                          _showPromotionDetails(promotion);
                        },
                        borderRadius: BorderRadius.circular(30),
                        splashColor: _primaryOrange.withOpacity(0.15),
                        highlightColor: Colors.transparent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Content Section
                            Padding(
                              padding: EdgeInsets.all(isTablet ? 20 : 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Special Offer Badge
                                  if (isOfferActive)
                                    Container(
                                      margin: EdgeInsets.only(bottom: 16),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 14 : 12,
                                        vertical: isTablet ? 6 : 5,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [_goldAccent, _primaryOrange],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _goldAccent.withOpacity(0.4),
                                            blurRadius: 10,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.local_offer_rounded, 
                                            color: Colors.white, 
                                            size: isTablet ? 14 : 12
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            '${promotion.specialOfferDiscount!.toStringAsFixed(0)}% OFF',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: isTablet ? 12 : 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  
                                  // User Info Row - Using promotion's stored user info
                                  Row(
                                    children: [
                                      // User Profile Image from promotion.postedByProfileImageBase64
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
                                                  colors: [_primaryOrange, _redAccent],
                                                ),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _primaryOrange.withOpacity(0.4),
                                                    blurRadius: 12,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.all(2),
                                                child: ClipOval(
                                                  child: _buildPromotionPosterImage(promotion),
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
                                            // User Name from promotion.postedByName
                                            ShaderMask(
                                              shaderCallback: (bounds) => LinearGradient(
                                                colors: [_primaryOrange, _redAccent],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ).createShader(bounds),
                                              child: Text(
                                                promotion.postedByName ?? 'Business Owner',
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
                                                      colors: [_primaryOrange, _redAccent],
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                SizedBox(width: 3),
                                                Text(
                                                  'Business Owner',
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
                                      if (promotion.isVerified)
                                        Container(
                                          padding: EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [_successGreen, _greenAccent],
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: _successGreen.withOpacity(0.4),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: shouldAnimate
                                              ? RotationTransition(
                                                  turns: _rotateController,
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
                                  
                                  // Business Name and Owner
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: [_primaryOrange, _redAccent],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ).createShader(bounds),
                                        child: Text(
                                          promotion.businessName,
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
                                      SizedBox(height: 2),
                                      Text(
                                        'by ${promotion.ownerName}',
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 14 : 12,
                                          fontWeight: FontWeight.w500,
                                          color: _goldAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 14),
                                  
                                  // Distance Badge - Add if location available
                                  if (promotion.latitude != null && promotion.longitude != null)
                                    Consumer<LocationFilterProvider>(
                                      builder: (context, locationProvider, _) {
                                        return Padding(
                                          padding: EdgeInsets.only(bottom: 12),
                                          child: DistanceBadge(
                                            latitude: promotion.latitude!,
                                            longitude: promotion.longitude!,
                                            isTablet: isTablet,
                                          ),
                                        );
                                      },
                                    ),
                                  
                                  // Tags
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _buildPremiumTagSmall(promotion.city, Icons.location_on_rounded, isTablet),
                                      _buildPremiumTagSmall('${promotion.productsServices.length} products', Icons.shopping_bag_rounded, isTablet),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 14),
                                  
                                  // Stats Row
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isTablet ? 10 : 8,
                                          vertical: isTablet ? 5 : 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _primaryOrange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: _primaryOrange.withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.remove_red_eye_rounded, 
                                              size: isTablet ? 12 : 10,
                                              color: _primaryOrange
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              '${promotion.totalViews}',
                                              style: GoogleFonts.poppins(
                                                color: _primaryOrange,
                                                fontSize: isTablet ? 11 : 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isTablet ? 10 : 8,
                                          vertical: isTablet ? 5 : 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _greenAccent.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: _greenAccent.withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.share_rounded, 
                                              size: isTablet ? 12 : 10,
                                              color: _greenAccent
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              '${promotion.totalShares}',
                                              style: GoogleFonts.poppins(
                                                color: _greenAccent,
                                                fontSize: isTablet ? 11 : 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 12),
                                  
                                  // Description preview
                                  Text(
                                    promotion.description.length > 80
                                        ? '${promotion.description.substring(0, 80)}...'
                                        : promotion.description,
                                    style: GoogleFonts.inter(
                                      fontSize: isTablet ? 13 : 12,
                                      color: _textSecondary,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  
                                  // Payment Methods Preview
                                  if (promotion.paymentMethods.isNotEmpty) ...[
                                    SizedBox(height: 10),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: promotion.paymentMethods.take(3).map((method) {
                                        return Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isTablet ? 8 : 6,
                                            vertical: isTablet ? 3 : 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _tealAccent.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: _tealAccent.withOpacity(0.3)),
                                          ),
                                          child: Text(
                                            method,
                                            style: GoogleFonts.inter(
                                              color: _tealAccent,
                                              fontSize: isTablet ? 11 : 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                  
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
                                              _showLoginRequiredDialog(context, 'View Promotion Details');
                                              return;
                                            }
                                            _showPromotionDetails(promotion);
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.symmetric(
                                              vertical: isTablet ? 14 : 12,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [_primaryOrange, _redAccent, _greenAccent],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ),
                                              borderRadius: BorderRadius.circular(24),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _primaryOrange.withOpacity(0.3),
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
                                                    fontSize: isTablet ? 16 : 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                shouldAnimate
                                                    ? RotationTransition(
                                                        turns: _rotateController,
                                                        child: Icon(
                                                          Icons.arrow_forward_rounded,
                                                          color: Colors.white,
                                                          size: isTablet ? 18 : 16,
                                                        ),
                                                      )
                                                    : Icon(
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
                          ],
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

  // NEW: Build poster image from promotion.postedByProfileImageBase64
  Widget _buildPromotionPosterImage(SmallBusinessPromotion promotion) {
    if (promotion.postedByProfileImageBase64 != null && promotion.postedByProfileImageBase64!.isNotEmpty) {
      try {
        String base64String = promotion.postedByProfileImageBase64!;
        
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

  Widget _buildPremiumTagSmall(String text, IconData icon, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 8,
        vertical: isTablet ? 5 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _goldAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: isTablet ? 11 : 10,
            color: _goldAccent
          ),
          SizedBox(width: isTablet ? 5 : 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: _textPrimary,
              fontSize: isTablet ? 11 : 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultProfileImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryOrange, _redAccent],
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

  // UPDATED: Now only passes promotion, not user
  void _showPromotionDetails(SmallBusinessPromotion promotion) async {
    HapticFeedback.mediumImpact();
    
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    await provider.incrementViewCount(EntrepreneurshipCategory.smallBusinessPromotion, promotion.id!);
    
    await provider.loadBusinessPromotions();
    
    if (!mounted) return;
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BusinessPromotionDetailsScreen(
          promotion: promotion,
          scrollController: ScrollController(),
          onLaunchPhone: _launchPhone,
          onLaunchEmail: _launchEmail,
          onLaunchUrl: _launchUrl,
          primaryOrange: _primaryOrange,
          redAccent: _redAccent,
          greenAccent: _greenAccent,
          goldAccent: _goldAccent,
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

  void _showAddPromotionDialog(BuildContext context) {
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
            child: PremiumAddPromotionDialog(
              scrollController: scrollController,
              onPromotionAdded: _loadData,
              primaryOrange: _primaryOrange,
              redAccent: _redAccent,
              greenAccent: _greenAccent,
              goldAccent: _goldAccent,
            ),
          );
        },
      ),
    );
  }
}

// ====================== PREMIUM ADD PROMOTION DIALOG ======================
class PremiumAddPromotionDialog extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback? onPromotionAdded;
  final Color primaryOrange;
  final Color redAccent;
  final Color greenAccent;
  final Color goldAccent;

  const PremiumAddPromotionDialog({
    Key? key,
    required this.scrollController,
    this.onPromotionAdded,
    required this.primaryOrange,
    required this.redAccent,
    required this.greenAccent,
    required this.goldAccent,
  }) : super(key: key);

  @override
  _PremiumAddPromotionDialogState createState() => _PremiumAddPromotionDialogState();
}

class _PremiumAddPromotionDialogState extends State<PremiumAddPromotionDialog> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _socialMediaController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _offerDiscountController = TextEditingController();
  final TextEditingController _offerValidityController = TextEditingController();
  final TextEditingController _paymentMethodController = TextEditingController();

  // State variables
  String? _selectedState;
  List<String> _productsServices = [];
  List<String> _paymentMethods = [];
  
  // ADDED: Location picking for business promotion
  double? _businessLatitude;
  double? _businessLongitude;
  String? _businessFullAddress;
  
  // Image handling
  List<File> _galleryImages = [];
  List<String> _galleryBase64 = [];
  
  final List<String> _states = CommunityStates.states;
  
  late TabController _tabController;
  late AnimationController _animationController;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  
  // Track completed tabs
  bool _isBasicInfoValid = false;
  bool _isDetailsTabValid = false;

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
    
    // Add listeners to validate on change
    _businessNameController.addListener(_validateBasicInfo);
    _ownerNameController.addListener(_validateBasicInfo);
    _contactEmailController.addListener(_validateBasicInfo);
    _contactPhoneController.addListener(_validateBasicInfo);
    _locationController.addListener(_validateBasicInfo);
    _cityController.addListener(_validateBasicInfo);
    
    _descriptionController.addListener(_validateDetailsTab);
    _productController.addListener(_validateDetailsTab);
    
    // Start animation if app is visible
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
      _animationController.forward();
    }
  }
  
  void _stopAnimations() {
    _animationController.stop();
  }

  void _validateBasicInfo() {
    setState(() {
      _isBasicInfoValid = 
          _businessNameController.text.isNotEmpty &&
          _ownerNameController.text.isNotEmpty &&
          _contactEmailController.text.isNotEmpty &&
          _contactPhoneController.text.isNotEmpty &&
          _locationController.text.isNotEmpty &&
          _cityController.text.isNotEmpty &&
          _selectedState != null &&
          _businessLatitude != null && // ADDED: Check location coordinates
          _businessLongitude != null; // ADDED: Check location coordinates
    });
  }

  void _validateDetailsTab() {
    setState(() {
      _isDetailsTabValid = 
          _descriptionController.text.isNotEmpty &&
          _productsServices.isNotEmpty;
    });
  }

  bool get _isSubmitEnabled {
    return _isBasicInfoValid && _isDetailsTabValid;
  }

  void _goToPreviousTab() {
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
    }
  }

  void _goToNextTab() {
    if (_tabController.index < 2) {
      if (_tabController.index == 0 && !_isBasicInfoValid) {
        _showErrorSnackBar('Please complete all required fields');
        return;
      }
      _tabController.animateTo(_tabController.index + 1);
    }
  }

  @override
  void dispose() {
    print('🗑️ PremiumAddPromotionDialog disposing...');
    
    // ✅ Remove observer
    WidgetsBinding.instance.removeObserver(this);
    
    _businessNameController.removeListener(_validateBasicInfo);
    _ownerNameController.removeListener(_validateBasicInfo);
    _contactEmailController.removeListener(_validateBasicInfo);
    _contactPhoneController.removeListener(_validateBasicInfo);
    _locationController.removeListener(_validateBasicInfo);
    _cityController.removeListener(_validateBasicInfo);
    
    _descriptionController.removeListener(_validateDetailsTab);
    
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _websiteController.dispose();
    _socialMediaController.dispose();
    _productController.dispose();
    _offerDiscountController.dispose();
    _offerValidityController.dispose();
    _paymentMethodController.dispose();
    
    _tabController.dispose();
    _animationController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    return FadeTransition(
      opacity: _animationController,
      child: Column(
        children: [
          // Premium Header
          Container(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.primaryOrange, widget.redAccent, widget.greenAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryOrange.withOpacity(0.3),
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
                  child: Icon(Icons.add_business_rounded, color: widget.goldAccent, size: isTablet ? 28 : 22),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Promote Your Business',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your promotion will be visible after admin approval',
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
                  colors: [widget.primaryOrange, widget.redAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: widget.primaryOrange,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: isTablet ? 14 : 12),
              unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: isTablet ? 13 : 11),
              tabs: [
                Tab(text: 'Basic Info'),
                Tab(text: 'Media'),
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
                  _buildMediaTab(isTablet),
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
                      onPressed: _goToPreviousTab,
                      isPrimary: false,
                      isTablet: isTablet,
                    ),
                  ),
                if (_tabController.index > 0) SizedBox(width: isTablet ? 12 : 8),
                Expanded(
                  child: _tabController.index < 2
                      ? _buildNavButton(
                          label: 'Next',
                          onPressed: _goToNextTab,
                          isPrimary: true,
                          isTablet: isTablet,
                        )
                      : _buildSubmitButton(isTablet, shouldAnimate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ADDED: Location Picker Field similar to other screens
  Widget _buildLocationPickerField(StateSetter setState, bool isTablet) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => OSMLocationPicker(
            initialLatitude: _businessLatitude,
            initialLongitude: _businessLongitude,
            initialAddress: _businessFullAddress,
            initialState: _selectedState,
            initialCity: _cityController.text,
            onLocationSelected: (lat, lng, address, state, city) {
              setState(() {
                _businessLatitude = lat;
                _businessLongitude = lng;
                _businessFullAddress = address;
                _selectedState = state;
                _cityController.text = city ?? '';
                _locationController.text = address;
              });
              _validateBasicInfo();
            },
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _businessLatitude != null ? widget.primaryOrange : Colors.grey.shade300,
            width: _businessLatitude != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: _businessLatitude != null ? widget.primaryOrange.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.primaryOrange, widget.redAccent],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _businessLatitude != null ? Icons.location_on : Icons.add_location,
                color: Colors.white,
                size: isTablet ? 20 : 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location *',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      color: widget.primaryOrange,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _businessFullAddress ?? 'Tap to select location on map',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 14 : 12,
                      color: _businessFullAddress != null ? Colors.black87 : Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: widget.primaryOrange,
              size: isTablet ? 16 : 14,
            ),
          ],
        ),
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
          _buildSectionHeader('Business Information', Icons.business_center_rounded, widget.primaryOrange, isTablet),
          SizedBox(height: isTablet ? 20 : 16),
          
          _buildPremiumTextField(
            controller: _businessNameController,
            label: 'Business Name *',
            icon: Icons.storefront_rounded,
            isRequired: true,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTextField(
            controller: _ownerNameController,
            label: 'Owner Name *',
            icon: Icons.person_rounded,
            isRequired: true,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTextField(
            controller: _contactEmailController,
            label: 'Contact Email *',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            isRequired: true,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTextField(
            controller: _contactPhoneController,
            label: 'Contact Phone *',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            isRequired: true,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          
          _buildSectionHeader('Location Information', Icons.location_on_rounded, widget.redAccent, isTablet),
          SizedBox(height: isTablet ? 16 : 12),
          
          // REPLACED: Street address field with location picker
          StatefulBuilder(
            builder: (context, setState) {
              return _buildLocationPickerField(setState, isTablet);
            },
          ),
          SizedBox(height: isTablet ? 16 : 12),
        ],
      ),
    );
  }

  Widget _buildMediaTab(bool isTablet) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Gallery Images', Icons.photo_library_rounded, widget.greenAccent, isTablet),
          SizedBox(height: isTablet ? 8 : 4),
          Text(
            'Add up to 5 images to showcase your business (optional)',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14 : 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 4 : 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _galleryImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _galleryImages.length) {
                return _buildAddImageButton(isTablet);
              }
              return _buildGalleryImageItem(index, isTablet);
            },
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
          _buildSectionHeader('Business Description', Icons.description_rounded, widget.redAccent, isTablet),
          SizedBox(height: isTablet ? 20 : 16),
          
          _buildPremiumTextField(
            controller: _descriptionController,
            label: 'Description *',
            icon: Icons.description_rounded,
            maxLines: 4,
            isRequired: true,
            isTablet: isTablet,
          ),
          
          SizedBox(height: isTablet ? 24 : 20),
          
          _buildSectionHeader('Products & Services *', Icons.shopping_bag_rounded, widget.primaryOrange, isTablet),
          SizedBox(height: isTablet ? 8 : 4),
          Text(
            'Add at least one product or service',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14 : 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          
          _buildTagInput(
            controller: _productController,
            tags: _productsServices,
            hint: 'Add product or service',
            onAdd: () {
              if (_productController.text.trim().isNotEmpty) {
                setState(() {
                  _productsServices.add(_productController.text.trim());
                  _productController.clear();
                  _validateDetailsTab();
                });
              }
            },
            onRemove: (index) {
              setState(() {
                _productsServices.removeAt(index);
                _validateDetailsTab();
              });
            },
            isRequired: true,
            isTablet: isTablet,
          ),
          
          SizedBox(height: isTablet ? 24 : 20),
          
          _buildSectionHeader('Payment Methods (Optional)', Icons.payment_rounded, widget.greenAccent, isTablet),
          SizedBox(height: isTablet ? 16 : 12),
          
          _buildTagInput(
            controller: _paymentMethodController,
            tags: _paymentMethods,
            hint: 'Add payment method (e.g., Cash, Card, PayPal)',
            onAdd: () {
              if (_paymentMethodController.text.trim().isNotEmpty) {
                setState(() {
                  _paymentMethods.add(_paymentMethodController.text.trim());
                  _paymentMethodController.clear();
                });
              }
            },
            onRemove: (index) {
              setState(() {
                _paymentMethods.removeAt(index);
              });
            },
            isRequired: false,
            isTablet: isTablet,
          ),
          
          SizedBox(height: isTablet ? 24 : 20),
          
          _buildSectionHeader('Special Offer (Optional)', Icons.local_offer_rounded, widget.goldAccent, isTablet),
          SizedBox(height: isTablet ? 16 : 12),
          
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: widget.goldAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.goldAccent.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                _buildPremiumTextField(
                  controller: _offerDiscountController,
                  label: 'Discount %',
                  icon: Icons.percent_rounded,
                  keyboardType: TextInputType.number,
                  isRequired: false,
                  isTablet: isTablet,
                ),
                SizedBox(height: isTablet ? 16 : 12),
                _buildPremiumTextField(
                  controller: _offerValidityController,
                  label: 'Valid Until (e.g., Dec 31, 2024)',
                  icon: Icons.calendar_today_rounded,
                  isRequired: false,
                  isTablet: isTablet,
                ),
              ],
            ),
          ),
          
          SizedBox(height: isTablet ? 24 : 20),
          
          _buildSectionHeader('Online Presence (Optional)', Icons.link_rounded, widget.primaryOrange, isTablet),
          SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTextField(
            controller: _websiteController,
            label: 'Website URL',
            icon: Icons.language_rounded,
            keyboardType: TextInputType.url,
            isRequired: false,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTextField(
            controller: _socialMediaController,
            label: 'Social Media Links',
            icon: Icons.link_rounded,
            keyboardType: TextInputType.url,
            isRequired: false,
            isTablet: isTablet,
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
          color: widget.primaryOrange,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: widget.primaryOrange, size: isTablet ? 22 : 18),
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
          borderSide: BorderSide(color: widget.primaryOrange, width: 2),
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

  Widget _buildTagInput({
    required TextEditingController controller,
    required List<String> tags,
    required String hint,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    required bool isRequired,
    required bool isTablet,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: isTablet ? 14 : 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: widget.primaryOrange, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 20 : 16,
                    vertical: isTablet ? 16 : 14,
                  ),
                ),
              ),
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.primaryOrange, widget.redAccent],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryOrange.withOpacity(0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: IconButton(
                onPressed: onAdd,
                icon: Icon(Icons.add_rounded, color: Colors.white, size: isTablet ? 22 : 20),
                padding: EdgeInsets.all(isTablet ? 12 : 10),
                constraints: BoxConstraints(),
              ),
            ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          SizedBox(height: isTablet ? 16 : 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(tags.length, (index) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 12,
                  vertical: isTablet ? 10 : 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.primaryOrange.withOpacity(0.1), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: widget.primaryOrange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tags[index],
                      style: GoogleFonts.poppins(
                        color: widget.primaryOrange,
                        fontSize: isTablet ? 14 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => onRemove(index),
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: widget.redAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: widget.redAccent,
                          size: isTablet ? 18 : 16,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
        if (isRequired && tags.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'At least one item is required',
              style: GoogleFonts.inter(
                color: widget.redAccent,
                fontSize: isTablet ? 12 : 11,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddImageButton(bool isTablet) {
    return GestureDetector(
      onTap: _galleryImages.length < 5 ? _pickGalleryImage : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[100]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _galleryImages.length < 5 ? Icons.add_photo_alternate_rounded : Icons.block_rounded,
              color: _galleryImages.length < 5 ? widget.primaryOrange : Colors.grey[400],
              size: isTablet ? 28 : 24,
            ),
            SizedBox(height: isTablet ? 6 : 4),
            Text(
              _galleryImages.length < 5 ? 'Add Image' : 'Max Reached',
              style: GoogleFonts.poppins(
                color: _galleryImages.length < 5 ? widget.primaryOrange : Colors.grey[500],
                fontSize: isTablet ? 12 : 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryImageItem(int index, bool isTablet) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            _galleryImages[index],
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _galleryImages.removeAt(index);
                _galleryBase64.removeAt(index);
              });
            },
            child: Container(
              padding: EdgeInsets.all(isTablet ? 6 : 4),
              decoration: BoxDecoration(
                color: widget.redAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.redAccent.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: isTablet ? 16 : 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickGalleryImage() async {
    if (_galleryImages.length >= 5) {
      _showErrorSnackBar('Maximum 5 images allowed');
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      maxWidth: 800, 
      maxHeight: 800, 
      imageQuality: 70,
    );
    
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      
      if (base64String.length > 200000) {
        _showErrorSnackBar('Image is too large. Please choose a smaller image.');
        return;
      }
      
      setState(() {
        _galleryImages.add(imageFile);
        _galleryBase64.add(base64String);
      });
    }
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
                  colors: [widget.primaryOrange, widget.redAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isPrimary ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: widget.primaryOrange, width: 2),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: widget.primaryOrange.withOpacity(0.3),
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
              color: isPrimary ? Colors.white : widget.primaryOrange,
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isTablet, bool shouldAnimate) {
    return GestureDetector(
      onTap: _submitForm,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 16 : 14,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.greenAccent, widget.greenAccent.withOpacity(0.8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.greenAccent.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            shouldAnimate
                ? RotationTransition(
                    turns: _animationController,
                    child: Icon(Icons.check_circle_rounded, color: Colors.white, size: isTablet ? 22 : 20),
                  )
                : Icon(Icons.check_circle_rounded, color: Colors.white, size: isTablet ? 22 : 20),
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

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedState == null) {
      _showErrorSnackBar('Please select a state');
      return;
    }

    // ADDED: Check location coordinates
    if (_businessLatitude == null || _businessLongitude == null) {
      _showErrorSnackBar('Please select a location on the map');
      return;
    }

    if (_productsServices.isEmpty) {
      _showErrorSnackBar('Please add at least one product or service');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    
    if (currentUser == null) {
      _showErrorSnackBar('You must be logged in to add a promotion');
      return;
    }

    // Get user's profile image
    String? userProfileImage;
    if (currentUser.profileImageUrl != null && currentUser.profileImageUrl!.isNotEmpty) {
      userProfileImage = currentUser.profileImageUrl;
    }

    int totalSize = 0;
    _galleryBase64.forEach((img) => totalSize += img.length);
    
    if (totalSize > 800000) {
      _showErrorSnackBar('Total image size too large. Please use smaller images.');
      return;
    }

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);

    final newPromotion = SmallBusinessPromotion(
      businessName: _businessNameController.text,
      ownerName: _ownerNameController.text,
      description: _descriptionController.text,
      uniqueSellingPoints: '',
      productsServices: _productsServices,
      targetAudience: '',
      location: _locationController.text,
      state: _selectedState!,
      city: _cityController.text,
      contactEmail: _contactEmailController.text,
      contactPhone: _contactPhoneController.text,
      website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
      socialMediaLinks: _socialMediaController.text.isNotEmpty ? _socialMediaController.text : null,
      logoImageBase64: null,
      galleryImagesBase64: _galleryBase64.isNotEmpty ? _galleryBase64 : null,
      paymentMethods: _paymentMethods,
      specialOfferDiscount: _offerDiscountController.text.isNotEmpty ? double.tryParse(_offerDiscountController.text) : null,
      offerValidity: _offerValidityController.text.isNotEmpty ? _offerValidityController.text : null,
      
      // ADDED: Location coordinates
      latitude: _businessLatitude,
      longitude: _businessLongitude,
      
      // Store user info directly in the promotion document
      postedByUserId: currentUser.id,
      postedByName: currentUser.fullName,
      postedByEmail: currentUser.email,
      postedByProfileImageBase64: userProfileImage,
      
      createdBy: currentUser.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isFeatured: false,
      isVerified: false,
      isActive: true,
      totalViews: 0,
      totalShares: 0,
      businessHours: [],
    );

    // Show loading
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
                child: CircularProgressIndicator(color: widget.primaryOrange),
              ),
              SizedBox(height: 20),
              Text('Submitting...', style: GoogleFonts.poppins()),
            ],
          ),
        ),
      ),
    );

    final success = await provider.addBusinessPromotion(newPromotion);
    
    if (mounted) {
      Navigator.pop(context); // Close loading
    }
    
    if (success) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        _showSuccessSnackBar('Promotion added successfully! Pending admin approval. ✨');
      }
      
      if (widget.onPromotionAdded != null) {
        widget.onPromotionAdded!();
      }
    } else {
      if (mounted) {
        _showErrorSnackBar('Failed to add promotion. Please try again.');
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
        backgroundColor: widget.greenAccent,
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
        backgroundColor: widget.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(12),
      ),
    );
  }
}