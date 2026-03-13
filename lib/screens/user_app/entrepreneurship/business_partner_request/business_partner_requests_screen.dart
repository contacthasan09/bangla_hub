// screens/user_app/entrepreneurship/partner_requests/partner_requests_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:bangla_hub/models/business_model.dart' hide BusinessPartnerRequest;
import 'package:bangla_hub/models/community_services_models.dart';
import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/location_filter_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/auth/signup_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/business_partner_request/partner_request_details_screen.dart';
import 'package:bangla_hub/widgets/common/distance_widget.dart';
import 'package:bangla_hub/widgets/common/global_location_filter_bar.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class BusinessPartnerRequestsScreen extends StatefulWidget {
  @override
  _BusinessPartnerRequestsScreenState createState() => _BusinessPartnerRequestsScreenState();
}

class _BusinessPartnerRequestsScreenState extends State<BusinessPartnerRequestsScreen> 
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin, WidgetsBindingObserver {
  
  // Premium Color Palette - Soft Green Accent Theme
  final Color _softGreen = Color(0xFF98D8C8); // Main soft green accent
  final Color _lightGreen = Color(0xFFE0F2F1); // Light green
  final Color _lightGreenBg = Color(0x80E0F2F1); // Light green with 50% opacity
  final Color _darkGreen = Color(0xFF2E7D32); // Dark green
  final Color _deepGreen = Color(0xFF1B5E20); // Deep green
  
  final Color _primaryGreen = Color(0xFF2E7D32); // Primary green
  final Color _secondaryGold = Color(0xFFFFB300); // Gold accent
  final Color _softGold = Color(0xFFFFD966); // Soft gold
  
  // Supporting colors
  final Color _textPrimary = Color(0xFF1A2B3C);
  final Color _textSecondary = Color(0xFF5D6D7E);
  final Color _borderLight = Color(0xFFE0E7E9);
  final Color _shadowColor = Color(0x1A000000);
  
  // Background Gradient - Light Green Priority
  final LinearGradient _bodyBgGradient = LinearGradient(
    colors: [
      Color(0xFFE0F2F1), // Light green
      Color(0xFFE8F5E9), // Very light green
      Color(0xFFF1F8E9), // Light mint
      Color(0xFFF9FBE7), // Light lime
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.4, 0.7, 1.0],
  );

  final LinearGradient _appBarGradient = LinearGradient(
    colors: [
      Color(0xFF2E7D32), // Primary Green
      Color(0xFF1B5E20), // Dark Green
      Color(0xFF98D8C8), // Soft Green
      Color(0xFF81C784), // Light Green
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.4, 0.7, 1.0],
  );

  // Gradients for accents
  final LinearGradient _preciousGradient = LinearGradient(
    colors: [
      Color(0xFFFFB300), // gold
      Color(0xFF2E7D32), // green
      Color(0xFF98D8C8), // soft green
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _gemstoneGradient = LinearGradient(
    colors: [
      Color(0xFF2E7D32), // green
      Color(0xFF98D8C8), // soft green
      Color(0xFFFFB300), // gold
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _royalGradient = LinearGradient(
    colors: [
      Color(0xFF2E7D32), // green
      Color(0xFFFFB300), // gold
      Color(0xFF98D8C8), // soft green
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _greenGradient = LinearGradient(
    colors: [
      Color(0xFF2E7D32), // green
      Color(0xFF98D8C8), // soft green
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
  
  bool _isLoading = false;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  
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
  PartnerType? _localSelectedPartnerType;
  BusinessType? _localSelectedBusinessType;
  String? _localSelectedIndustry;
  bool _isFilterView = false;
  final ScrollController _filterScrollController = ScrollController();

  // Track which filters are active (for display)
  bool _hasLocalFilters = false;
  Map<String, dynamic> _activeLocalFilters = {};

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
      _scaleController.forward();
      _pulseController.repeat(reverse: true);
      _rotateController.repeat();
      // Particle and bubble controllers already running via repeat
    }
  }
  
  void _stopAnimations() {
    _fadeController.stop();
    _slideController.stop();
    _pulseController.stop();
    _scaleController.stop();
    _rotateController.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Listen to location provider changes but DON'T automatically apply filter
    // This ensures global filter is separate
    final locationProvider = Provider.of<LocationFilterProvider>(context);
    
    // Only reload when global filter changes to show/hide global filter bar
    if (locationProvider.isFilterActive != _previousGlobalFilterState) {
      _previousGlobalFilterState = locationProvider.isFilterActive;
      _loadData();
    }
  }

  bool _previousGlobalFilterState = false;

  @override
  void dispose() {
    print('🗑️ BusinessPartnerRequestsScreen disposing...');
    
    // ✅ Remove observer
    WidgetsBinding.instance.removeObserver(this);
    
    // ✅ Dispose animation controllers
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
          provider.setFilter(EntrepreneurshipCategory.lookingForBusinessPartner, 'local_state', _localSelectedState);
        }
        if (_localSelectedCity != null) {
          provider.setFilter(EntrepreneurshipCategory.lookingForBusinessPartner, 'local_city', _localSelectedCity);
        }
        if (_localSelectedPartnerType != null) {
          provider.setFilter(EntrepreneurshipCategory.lookingForBusinessPartner, 'local_partnerType', _localSelectedPartnerType);
        }
        if (_localSelectedBusinessType != null) {
          provider.setFilter(EntrepreneurshipCategory.lookingForBusinessPartner, 'local_businessType', _localSelectedBusinessType);
        }
        if (_localSelectedIndustry != null && _localSelectedIndustry!.isNotEmpty) {
          provider.setFilter(EntrepreneurshipCategory.lookingForBusinessPartner, 'local_industry', _localSelectedIndustry);
        }
      }
      
      await provider.loadPartnerRequests();
      
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading partner requests: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _applyLocalFilters() async {
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    // Clear any existing local filters first
    provider.clearAllFilters(EntrepreneurshipCategory.lookingForBusinessPartner);
    
    // Build active filters map for display
    Map<String, dynamic> newActiveFilters = {};
    
    // Apply new local filters
    if (_localSelectedState != null) {
      provider.setFilter(EntrepreneurshipCategory.lookingForBusinessPartner, 'local_state', _localSelectedState);
      newActiveFilters['local_state'] = _localSelectedState;
    }
    if (_localSelectedCity != null && _localSelectedCity!.isNotEmpty) {
      provider.setFilter(EntrepreneurshipCategory.lookingForBusinessPartner, 'local_city', _localSelectedCity);
      newActiveFilters['local_city'] = _localSelectedCity;
    }
    if (_localSelectedPartnerType != null) {
      provider.setFilter(EntrepreneurshipCategory.lookingForBusinessPartner, 'local_partnerType', _localSelectedPartnerType);
      newActiveFilters['local_partnerType'] = _localSelectedPartnerType!.displayName;
    }
    if (_localSelectedBusinessType != null) {
      provider.setFilter(EntrepreneurshipCategory.lookingForBusinessPartner, 'local_businessType', _localSelectedBusinessType);
      newActiveFilters['local_businessType'] = _localSelectedBusinessType!.displayName;
    }
    if (_localSelectedIndustry != null && _localSelectedIndustry!.isNotEmpty) {
      provider.setFilter(EntrepreneurshipCategory.lookingForBusinessPartner, 'local_industry', _localSelectedIndustry);
      newActiveFilters['local_industry'] = _localSelectedIndustry;
    }
    
    setState(() {
      _hasLocalFilters = newActiveFilters.isNotEmpty;
      _activeLocalFilters = newActiveFilters;
      _isFilterView = false;
    });
    
    await provider.loadPartnerRequests();
  }

  void _clearLocalFilters() {
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    // Clear all local filters from provider
    provider.clearAllFilters(EntrepreneurshipCategory.lookingForBusinessPartner);
    
    // Reset local state
    setState(() {
      _localSelectedState = null;
      _localSelectedCity = null;
      _localSelectedPartnerType = null;
      _localSelectedBusinessType = null;
      _localSelectedIndustry = null;
      _hasLocalFilters = false;
      _activeLocalFilters.clear();
      _isFilterView = false;
    });
    
    provider.loadPartnerRequests();
  }

  // Get filtered requests - applying BOTH global and local filters
  List<BusinessPartnerRequest> _getFilteredRequests(
    List<BusinessPartnerRequest> requests,
    LocationFilterProvider locationProvider,
  ) {
    // Start with all verified and active requests
    var filteredRequests = requests.where((r) => 
      r.isVerified && r.isActive && !r.isDeleted
    ).toList();
    
    print('📊 Initial verified requests: ${filteredRequests.length}');
    
    // Apply GLOBAL location filter if active (from LocationFilterProvider)
    if (locationProvider.isFilterActive && locationProvider.selectedState != null) {
      filteredRequests = filteredRequests.where((request) {
        return request.state == locationProvider.selectedState;
      }).toList();
      print('📍 After GLOBAL filter (${locationProvider.selectedState}): ${filteredRequests.length} requests');
    }
    
    // Apply LOCAL filters if any (from this screen's filter view)
    if (_hasLocalFilters) {
      // State filter
      if (_localSelectedState != null) {
        filteredRequests = filteredRequests.where((request) => 
          request.state == _localSelectedState
        ).toList();
      }
      
      // City filter
      if (_localSelectedCity != null && _localSelectedCity!.isNotEmpty) {
        filteredRequests = filteredRequests.where((request) => 
          request.city.toLowerCase().contains(_localSelectedCity!.toLowerCase())
        ).toList();
      }
      
      // Partner type filter
      if (_localSelectedPartnerType != null) {
        filteredRequests = filteredRequests.where((request) => 
          request.partnerType == _localSelectedPartnerType
        ).toList();
      }
      
      // Business type filter
      if (_localSelectedBusinessType != null) {
        filteredRequests = filteredRequests.where((request) => 
          request.businessType == _localSelectedBusinessType
        ).toList();
      }
      
      // Industry filter
      if (_localSelectedIndustry != null && _localSelectedIndustry!.isNotEmpty) {
        filteredRequests = filteredRequests.where((request) => 
          request.industry?.toLowerCase().contains(_localSelectedIndustry!.toLowerCase()) ?? false
        ).toList();
      }
      
      print('📊 After LOCAL filters: ${filteredRequests.length} requests');
    }
    
    return filteredRequests;
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
        if (mounted) {
          _showSuccessSnackBar('Opening phone dialer...');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Could not launch phone dialer');
      }
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Business Partnership Inquiry',
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        if (mounted) {
          _showSuccessSnackBar('Opening email app...');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Could not launch email app');
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
            SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: _primaryGreen,
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
            SizedBox(width: 10),
            Expanded(child: Text(message, style: GoogleFonts.inter(fontSize: 13))),
          ],
        ),
        backgroundColor: _primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(12),
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
          child: Stack(
            children: [
              // Animated Background Particles
              ...List.generate(30, (index) => _buildAnimatedParticle(index)),
              
              // Floating Bubbles
              ...List.generate(8, (index) => _buildFloatingBubble(index)),
              
              // Main Content
              RefreshIndicator(
                color: _secondaryGold,
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
                          
                          _buildContent(),
                        ],
                      ),
              ),
              
              // Premium Floating Action Button
              Positioned(
                bottom: 30,
                right: 30,
                child: _buildPremiumFloatingActionButton(),
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
                              gradient: _royalGradient,
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
                            prefixIcon: Icon(Icons.location_city_rounded, color: _primaryGreen, size: 20),
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
                      
                      SizedBox(height: 16),
                      
                      // Partner Type Dropdown
                      _buildDropdown<PartnerType?>(
                        value: _localSelectedPartnerType,
                        label: 'Partner Type',
                        icon: Icons.people_rounded,
                        items: [
                          DropdownMenuItem<PartnerType?>(value: null, child: Text('All Types')),
                          ...PartnerType.values.map((type) => 
                            DropdownMenuItem<PartnerType?>(
                              value: type,
                              child: Text(type.displayName),
                            )
                          ),
                        ],
                        onChanged: (PartnerType? newValue) {
                          setState(() => _localSelectedPartnerType = newValue);
                        },
                        isTablet: isTablet,
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Business Type Dropdown
                      _buildDropdown<BusinessType?>(
                        value: _localSelectedBusinessType,
                        label: 'Business Type',
                        icon: Icons.business_rounded,
                        items: [
                          DropdownMenuItem<BusinessType?>(value: null, child: Text('All Types')),
                          ...BusinessType.values.map((type) => 
                            DropdownMenuItem<BusinessType?>(
                              value: type,
                              child: Text(type.displayName),
                            )
                          ),
                        ],
                        onChanged: (BusinessType? newValue) {
                          setState(() => _localSelectedBusinessType = newValue);
                        },
                        isTablet: isTablet,
                      ),
                      
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
                            labelText: 'Industry',
                            labelStyle: GoogleFonts.poppins(fontSize: 13),
                            prefixIcon: Icon(Icons.category_rounded, color: _primaryGreen, size: 20),
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
          gradient: _hasLocalFilters ? _royalGradient : _greenGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withOpacity(0.3),
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
                    color: _primaryGreen,
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
          case 'local_partnerType':
            label = 'Partner: $value';
            icon = Icons.people_rounded;
            break;
          case 'local_businessType':
            label = 'Business: $value';
            icon = Icons.business_rounded;
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
            provider.clearFilter(EntrepreneurshipCategory.lookingForBusinessPartner, key);
            
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
                case 'local_partnerType':
                  _localSelectedPartnerType = null;
                  break;
                case 'local_businessType':
                  _localSelectedBusinessType = null;
                  break;
                case 'local_industry':
                  _localSelectedIndustry = null;
                  break;
              }
            });
            
            provider.loadPartnerRequests();
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
                  color: _primaryGreen,
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
        gradient: _greenGradient,
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
          prefixIcon: Icon(icon, color: _primaryGreen, size: 20),
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
        icon: Icon(Icons.arrow_drop_down, color: _primaryGreen),
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
          gradient: isPrimary ? _royalGradient : null,
          color: isPrimary ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isPrimary ? null : Border.all(color: _primaryGreen, width: 2),
          boxShadow: isPrimary
              ? [BoxShadow(color: _primaryGreen.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 6))]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isPrimary ? Colors.white : _primaryGreen,
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
              colors: [_primaryGreen, _darkGreen, _softGreen],
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
                      'Find Business Partner',
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
                    '🤝 Connect with Potential Business Partners',
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
                      final verifiedCount = provider.partnerRequests
                          .where((r) => r.isVerified)
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
                                Icon(Icons.people_alt_rounded, color: _secondaryGold, size: isTablet ? 18 : 16),
                                SizedBox(width: isTablet ? 8 : 6),
                                Text(
                                  '$verifiedCount Active Partners',
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
        icon: Icon(
          Icons.arrow_back_rounded, 
          color: Colors.white, 
          fontWeight: FontWeight.bold, 
          size: isTablet ? 28 : 24,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
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
                      _primaryGreen.withOpacity(0.5),
                      _softGreen.withOpacity(0.3),
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
                      _lightGreen.withOpacity(0.3),
                      _softGreen.withOpacity(0.2),
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

  Widget _buildPremiumFloatingActionButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    Widget button = Container(
      decoration: BoxDecoration(
        gradient: _royalGradient,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withOpacity(0.5),
            blurRadius: 25,
            offset: Offset(0, 12),
            spreadRadius: 3,
          ),
          BoxShadow(
            color: _softGreen.withOpacity(0.4),
            blurRadius: 30,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            if (authProvider.isGuestMode) {
              _showLoginRequiredDialog(context, 'Add Business Partner Request');
              return;
            }
            _showAddRequestDialog(context);
          },
          borderRadius: BorderRadius.circular(35),
          splashColor: Colors.white.withOpacity(0.3),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 28 : 24,
              vertical: isTablet ? 16 : 14,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                shouldAnimate
                    ? RotationTransition(
                        turns: _rotateController,
                        child: Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: isTablet ? 26 : 22,
                        ),
                      )
                    : Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: isTablet ? 26 : 22,
                      ),
                SizedBox(width: isTablet ? 12 : 10),
                Text(
                  'Find Partner',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: isTablet ? 18 : 16,
                    color: Colors.white,
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

        final filteredRequests = _getFilteredRequests(provider.partnerRequests, locationProvider);

        if (filteredRequests.isEmpty) {
          return _buildEmptyState(locationProvider);
        }

        return SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final request = filteredRequests[index];
                
                // Only animate if app is visible
                Widget card = Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: _buildPremiumRequestCard(request, index),
                );
                
                if (_appLifecycleState == AppLifecycleState.resumed) {
                  card = FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: card,
                    ),
                  );
                }
                
                return card;
              },
              childCount: filteredRequests.length,
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
                      gradient: _royalGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryGreen.withOpacity(0.3),
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
                              color: _primaryGreen,
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
                'Loading Partners...',
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
                      'Finding best partnership opportunities',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 15 : 13,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : Text(
                    'Finding best partnership opportunities',
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
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    String emptyMessage = 'No partner requests found';
    if (locationProvider.isFilterActive && _hasLocalFilters) {
      emptyMessage = 'No requests in ${locationProvider.selectedState} with your local filters';
    } else if (locationProvider.isFilterActive) {
      emptyMessage = 'No requests in ${locationProvider.selectedState}';
    } else if (_hasLocalFilters) {
      emptyMessage = 'No requests match your local filters';
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
                        gradient: LinearGradient(
                          colors: [_lightGreen, _softGreen.withOpacity(0.3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.people_alt_rounded,
                        size: isTablet ? 60 : 50,
                        color: _primaryGreen,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: isTablet ? 24 : 16),
              ShaderMask(
                shaderCallback: (bounds) => _gemstoneGradient.createShader(bounds),
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
              shouldAnimate
                  ? ScaleTransition(
                      scale: _pulseAnimation,
                      child: Text(
                        'Try adjusting your filters or be the first to post!',
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 15 : 13,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Text(
                      'Try adjusting your filters or be the first to post!',
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
                            gradient: _greenGradient,
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
                            gradient: _royalGradient,
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

  // UPDATED: Now uses request's own user info fields instead of separate UserModel
  Widget _buildPremiumRequestCard(BusinessPartnerRequest request, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    Widget cardContent = Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withOpacity(0.2),
            blurRadius: 20,
            offset: Offset(0, 10),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: _softGreen.withOpacity(0.1),
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
                  _lightGreen.withOpacity(0.3),
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
                    _showLoginRequiredDialog(context, 'View Business Partner Request');
                    return;
                  }
                  _showRequestDetails(request);
                },
                borderRadius: BorderRadius.circular(30),
                splashColor: _secondaryGold.withOpacity(0.15),
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info Row - Using request's stored user info
                      Row(
                        children: [
                          // User Profile Image from request.postedByProfileImageBase64
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
                                    gradient: _royalGradient,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _secondaryGold.withOpacity(0.4),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(2),
                                    child: ClipOval(
                                      child: _buildRequesterPosterImage(request),
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
                                // User Name from request.postedByName
                                ShaderMask(
                                  shaderCallback: (bounds) => _gemstoneGradient.createShader(bounds),
                                  child: Text(
                                    request.postedByName ?? 'Business Seeker',
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
                                        gradient: _gemstoneGradient,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Looking for Partner',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: _secondaryGold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Verified Badge
                          if (request.isVerified)
                            Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: _preciousGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _secondaryGold.withOpacity(0.4),
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
                      
                      // Partner Type and Business Type
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => _gemstoneGradient.createShader(bounds),
                                  child: Text(
                                    request.partnerType.displayName,
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
                                SizedBox(height: 6),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: _greenGradient,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryGreen.withOpacity(0.3),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    request.businessType.displayName,
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 14 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Urgent Badge
                          if (request.isUrgent)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_primaryGreen, _darkGreen],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryGreen.withOpacity(0.3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.priority_high_rounded, color: Colors.white, size: 12),
                                  SizedBox(width: 3),
                                  Text(
                                    'URGENT',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      
                      SizedBox(height: 14),
                      
                      // Tags
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildPremiumTag(request.partnerType.displayName, Icons.person_rounded, isTablet),
                          _buildPremiumTag(request.city, Icons.location_on_rounded, isTablet),
                          if (request.industry != null && request.industry!.isNotEmpty && request.industry != 'Not specified')
                            _buildPremiumTag(request.industry!, Icons.category_rounded, isTablet),
                        ],
                      ),
                      
                      SizedBox(height: 14),
                      
                      // Distance Badge - Add if location available
                      if (request.latitude != null && request.longitude != null)
                        Consumer<LocationFilterProvider>(
                          builder: (context, locationProvider, _) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: DistanceBadge(
                                latitude: request.latitude!,
                                longitude: request.longitude!,
                                isTablet: isTablet,
                              ),
                            );
                          },
                        ),
                      
                      // Budget and Duration Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _primaryGreen.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Budget',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: _textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '\$${request.budgetMin.toStringAsFixed(0)} - \$${request.budgetMax.toStringAsFixed(0)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 13 : 12,
                                      fontWeight: FontWeight.w700,
                                      color: _primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _softGreen.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Duration',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: _textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    request.investmentDuration,
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 13 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: _softGreen,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 14),
                      
                      // Description preview
                      Text(
                        request.description.length > 80
                            ? '${request.description.substring(0, 80)}...'
                            : request.description,
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 13 : 12,
                          color: _textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: 14),
                      
                      // Stats Row
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.remove_red_eye_rounded, size: 12, color: _primaryGreen),
                                SizedBox(width: 3),
                                Text(
                                  '${request.totalViews} views',
                                  style: GoogleFonts.inter(
                                    color: _primaryGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                                  _showLoginRequiredDialog(context, 'View Business Partner Request');
                                  return;
                                }
                                _showRequestDetails(request);
                              },
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 14 : 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: _royalGradient,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryGreen.withOpacity(0.3),
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
              ),
            ),
          ),
        ),
      ),
    );
    
    // Apply scale animation if app is visible
    if (shouldAnimate) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 500 + (index * 100)),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          final clampedValue = value.clamp(0.0, 1.0);
          return Transform.scale(
            scale: 0.92 + (0.08 * clampedValue),
            child: Opacity(
              opacity: clampedValue,
              child: cardContent,
            ),
          );
        },
      );
    }
    
    return cardContent;
  }

  // NEW: Build poster image from request.postedByProfileImageBase64
  Widget _buildRequesterPosterImage(BusinessPartnerRequest request) {
    if (request.postedByProfileImageBase64 != null && request.postedByProfileImageBase64!.isNotEmpty) {
      try {
        String base64String = request.postedByProfileImageBase64!;
        
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

  // Updated helper method for tags
  Widget _buildPremiumTag(String text, IconData icon, [bool isTablet = false]) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 8,
        vertical: isTablet ? 5 : 4,
      ),
      decoration: BoxDecoration(
        gradient: _glassMorphismGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _secondaryGold.withOpacity(0.25)),
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
          Icon(icon, size: isTablet ? 11 : 10, color: _secondaryGold),
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
        gradient: _gemstoneGradient,
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

  // UPDATED: Now only passes request, not user
  void _showRequestDetails(BusinessPartnerRequest request) async {
    HapticFeedback.mediumImpact();
    
    // Increment view count
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    await provider.incrementViewCount(EntrepreneurshipCategory.lookingForBusinessPartner, request.id!);
    
    // Refresh to show updated view count
    await provider.loadPartnerRequests();
    
    if (!mounted) return;
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PartnerRequestDetailsScreen(
          request: request,
          scrollController: ScrollController(),
          onLaunchPhone: _launchPhone,
          onLaunchEmail: _launchEmail,
          primaryGreen: _primaryGreen,
          secondaryGold: _secondaryGold,
          softGreen: _softGreen,
          lightGreen: _lightGreen,
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

  void _showAddRequestDialog(BuildContext context) {
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
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: AddPartnerRequestDialog(
              scrollController: scrollController,
              onRequestAdded: _loadData,
              primaryGreen: _primaryGreen,
              secondaryGold: _secondaryGold,
              accentRed: _primaryGreen,
              lightGreen: _lightGreen,
              softGreen: _softGreen,
            ),
          );
        },
      ),
    );
  }
}


// ====================== ADD PARTNER REQUEST DIALOG ======================
class AddPartnerRequestDialog extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback? onRequestAdded;
  final Color primaryGreen;
  final Color secondaryGold;
  final Color accentRed;
  final Color lightGreen;
  final Color softGreen;

  const AddPartnerRequestDialog({
    Key? key,
    required this.scrollController,
    this.onRequestAdded,
    required this.primaryGreen,
    required this.secondaryGold,
    required this.accentRed,
    required this.lightGreen,
    required this.softGreen,
  }) : super(key: key);

  @override
  _AddPartnerRequestDialogState createState() => _AddPartnerRequestDialogState();
}

class _AddPartnerRequestDialogState extends State<AddPartnerRequestDialog> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _budgetMinController = TextEditingController();
  final TextEditingController _budgetMaxController = TextEditingController();
  final TextEditingController _investmentDurationController = TextEditingController();
  final TextEditingController _skillController = TextEditingController();
  final TextEditingController _responsibilityController = TextEditingController();
  final TextEditingController _preferredMeetingController = TextEditingController();

  // State variables
  String? _selectedState;
  PartnerType? _selectedPartnerType = PartnerType.investor;
  BusinessType? _selectedBusinessType = BusinessType.startup;
  List<String> _skillsRequired = [];
  List<String> _responsibilities = [];
  bool _isUrgent = false;
  
  // Location picking for partner request - ADDED
  double? _partnerLatitude;
  double? _partnerLongitude;
  String? _partnerFullAddress;

  final List<String> _states = CommunityStates.states;
  
  late TabController _tabController;
  late AnimationController _animationController;
  
  // Track completed tabs
  bool _isBasicInfoValid = false;
  bool _isDetailsValid = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animationController.forward();
    
    // Add listeners to validate on change
    _descriptionController.addListener(_validateDetails);
    _locationController.addListener(_validateBasicInfo);
    _cityController.addListener(_validateBasicInfo);
    _contactNameController.addListener(_validateBasicInfo);
    _contactEmailController.addListener(_validateBasicInfo);
    _contactPhoneController.addListener(_validateBasicInfo);
    _budgetMinController.addListener(_validateDetails);
    _budgetMaxController.addListener(_validateDetails);
    _investmentDurationController.addListener(_validateDetails);
  }

  void _validateBasicInfo() {
    setState(() {
      _isBasicInfoValid = 
          _selectedPartnerType != null &&
          _selectedBusinessType != null &&
          _locationController.text.isNotEmpty &&
          _cityController.text.isNotEmpty &&
          _selectedState != null &&
          _contactNameController.text.isNotEmpty &&
          _contactEmailController.text.isNotEmpty &&
          _contactPhoneController.text.isNotEmpty &&
          _partnerLatitude != null && // ADDED: Check location coordinates
          _partnerLongitude != null; // ADDED: Check location coordinates
    });
  }

  void _validateDetails() {
    setState(() {
      _isDetailsValid = 
          _descriptionController.text.isNotEmpty &&
          _budgetMinController.text.isNotEmpty &&
          _budgetMaxController.text.isNotEmpty &&
          _investmentDurationController.text.isNotEmpty &&
          _skillsRequired.isNotEmpty &&
          _responsibilities.isNotEmpty;
    });
  }

  bool get _isSubmitEnabled => _isBasicInfoValid && _isDetailsValid;

  void _goToPreviousTab() {
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
    }
  }

  void _goToNextTab() {
    if (_tabController.index < 1) {
      if (_tabController.index == 0 && !_isBasicInfoValid) {
        _showErrorSnackBar('Please complete all required fields');
        return;
      }
      _tabController.animateTo(_tabController.index + 1);
    }
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_validateDetails);
    _locationController.removeListener(_validateBasicInfo);
    _cityController.removeListener(_validateBasicInfo);
    _contactNameController.removeListener(_validateBasicInfo);
    _contactEmailController.removeListener(_validateBasicInfo);
    _contactPhoneController.removeListener(_validateBasicInfo);
    _budgetMinController.removeListener(_validateDetails);
    _budgetMaxController.removeListener(_validateDetails);
    _investmentDurationController.removeListener(_validateDetails);
    
    _descriptionController.dispose();
    _industryController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _investmentDurationController.dispose();
    _skillController.dispose();
    _responsibilityController.dispose();
    _preferredMeetingController.dispose();
    
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return FadeTransition(
      opacity: _animationController,
      child: Column(
        children: [
          // Premium Header
          Container(
            padding: EdgeInsets.all(screenWidth > 600 ? 24 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.primaryGreen, widget.primaryGreen.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryGreen.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth > 600 ? 12 : 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person_add_rounded, color: widget.secondaryGold, size: screenWidth > 600 ? 28 : 22),
                ),
                SizedBox(width: screenWidth > 600 ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find a Business Partner',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth > 600 ? 20 : 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Describe what you\'re looking for',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: screenWidth > 600 ? 13 : 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: screenWidth > 600 ? 24 : 20,
                ),
              ],
            ),
          ),
          
          // Premium Tab Indicators
          Container(
            margin: EdgeInsets.symmetric(horizontal: screenWidth > 600 ? 20 : 16, vertical: 16),
            height: screenWidth > 600 ? 60 : 50,
            child: Row(
              children: [
                _buildPremiumTabIndicator(0, 'Basic Info', _isBasicInfoValid),
                _buildPremiumTabConnector(_isBasicInfoValid),
                _buildPremiumTabIndicator(1, 'Details', _isDetailsValid),
              ],
            ),
          ),
          
          // Form Content
          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPremiumBasicInfoTab(),
                  _buildPremiumDetailsTab(),
                ],
              ),
            ),
          ),
          
          // Navigation Buttons
          Container(
            padding: EdgeInsets.all(screenWidth > 600 ? 20 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_tabController.index > 0)
                  Expanded(
                    child: _buildPremiumNavButton(
                      label: 'Previous',
                      onPressed: _goToPreviousTab,
                      isPrimary: false,
                    ),
                  ),
                if (_tabController.index > 0) const SizedBox(width: 12),
                Expanded(
                  child: _tabController.index < 1
                      ? _buildPremiumNavButton(
                          label: 'Next',
                          onPressed: _goToNextTab,
                          isPrimary: true,
                        )
                      : _buildPremiumSubmitButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTabIndicator(int index, String label, bool isValid) {
    final isSelected = _tabController.index == index;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 0) {
            _tabController.animateTo(0);
          } else if (index == 1 && _isBasicInfoValid) {
            _tabController.animateTo(1);
          } else {
            _showErrorSnackBar('Complete previous steps first');
          }
        },
        child: Container(
          height: screenWidth > 600 ? 60 : 50,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [widget.secondaryGold, widget.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isValid ? widget.primaryGreen : Colors.grey[300]!,
              width: isValid ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: screenWidth > 600 ? 24 : 20,
                height: screenWidth > 600 ? 24 : 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isValid ? widget.primaryGreen : (isSelected ? Colors.white : Colors.grey[400]),
                ),
                child: isValid
                    ? Icon(Icons.check, color: Colors.white, size: screenWidth > 600 ? 14 : 12)
                    : Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isSelected ? widget.primaryGreen : Colors.white,
                            fontSize: screenWidth > 600 ? 12 : 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : (isValid ? widget.primaryGreen : Colors.grey[600]),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: screenWidth > 600 ? 10 : 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTabConnector(bool isCompleted) {
    return Container(
      width: MediaQuery.of(context).size.width > 600 ? 20 : 12,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: isCompleted
            ? LinearGradient(
                colors: [widget.primaryGreen, widget.secondaryGold],
              )
            : LinearGradient(
                colors: [Colors.grey[300]!, Colors.grey[400]!],
              ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildPremiumNavButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: screenWidth > 600 ? 50 : 44,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [widget.primaryGreen, widget.primaryGreen.withOpacity(0.8)],
              )
            : null,
        color: isPrimary ? null : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPrimary ? null : Border.all(color: widget.primaryGreen),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: widget.primaryGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: isPrimary ? Colors.white : widget.primaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: screenWidth > 600 ? 15 : 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumSubmitButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: screenWidth > 600 ? 50 : 44,
      decoration: BoxDecoration(
        gradient: _isSubmitEnabled
            ? LinearGradient(
                colors: [widget.secondaryGold, widget.accentRed],
              )
            : null,
        color: _isSubmitEnabled ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isSubmitEnabled
            ? [
                BoxShadow(
                  color: widget.secondaryGold.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitEnabled ? _submitForm : null,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              'Post Request',
              style: GoogleFonts.poppins(
                color: _isSubmitEnabled ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w700,
                fontSize: screenWidth > 600 ? 15 : 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ADDED: Location Picker Field similar to CommunityServicesListScreen
  Widget _buildLocationPickerField(StateSetter setState, bool isTablet) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => OSMLocationPicker(
            initialLatitude: _partnerLatitude,
            initialLongitude: _partnerLongitude,
            initialAddress: _partnerFullAddress,
            initialState: _selectedState,
            initialCity: _cityController.text,
            onLocationSelected: (lat, lng, address, state, city) {
              setState(() {
                _partnerLatitude = lat;
                _partnerLongitude = lng;
                _partnerFullAddress = address;
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
            color: _partnerLatitude != null ? widget.primaryGreen : Colors.grey.shade300,
            width: _partnerLatitude != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: _partnerLatitude != null ? widget.lightGreen.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.primaryGreen, widget.softGreen],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _partnerLatitude != null ? Icons.location_on : Icons.add_location,
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
                      color: widget.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _partnerFullAddress ?? 'Tap to select location on map',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 14 : 12,
                      color: _partnerFullAddress != null ? Colors.black87 : Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: widget.primaryGreen,
              size: isTablet ? 16 : 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBasicInfoTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Urgent checkbox
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isUrgent ? widget.accentRed.withOpacity(0.1) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isUrgent ? widget.accentRed : Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _isUrgent,
                  onChanged: (value) {
                    setState(() {
                      _isUrgent = value ?? false;
                    });
                  },
                  activeColor: widget.accentRed,
                  checkColor: Colors.white,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mark as Urgent',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: _isUrgent ? widget.accentRed : Colors.black87,
                        ),
                      ),
                      Text(
                        'Urgent requests will be highlighted',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          _buildPremiumSectionHeader('Partner Information', Icons.people_rounded),
          const SizedBox(height: 16),
          
          _buildPremiumDropdown<PartnerType>(
            value: _selectedPartnerType,
            hint: 'Partner Type *',
            items: PartnerType.values.map((type) {
              return DropdownMenuItem<PartnerType>(
                value: type,
                child: Text(type.displayName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPartnerType = value;
                _validateBasicInfo();
              });
            },
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 12),
          
          _buildPremiumDropdown<BusinessType>(
            value: _selectedBusinessType,
            hint: 'Business Type *',
            items: BusinessType.values.map((type) {
              return DropdownMenuItem<BusinessType>(
                value: type,
                child: Text(type.displayName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBusinessType = value;
                _validateBasicInfo();
              });
            },
            icon: Icons.business_rounded,
          ),
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _industryController,
            label: 'Industry (Optional)',
            icon: Icons.category_rounded,
          ),
          
          const SizedBox(height: 20),
          
          _buildPremiumSectionHeader('Location', Icons.location_on_rounded),
          const SizedBox(height: 16),
          
          // REPLACED: Street name field with location picker
          StatefulBuilder(
            builder: (context, setState) {
              return _buildLocationPickerField(setState, isTablet);
            },
          ),
          const SizedBox(height: 12),
          
          const SizedBox(height: 20),
          
          _buildPremiumSectionHeader('Contact Information', Icons.contact_phone_rounded),
          const SizedBox(height: 16),
          
          _buildPremiumTextField(
            controller: _contactNameController,
            label: 'Your Name *',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _contactEmailController,
            label: 'Your Email *',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _contactPhoneController,
            label: 'Your Phone *',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _preferredMeetingController,
            label: 'Preferred Meeting Method (Optional)',
            icon: Icons.video_call_rounded,
          ),
          const SizedBox(height: 4),
          Text(
            'Example: Zoom, In-person, Phone call',
            style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumDetailsTab() {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumSectionHeader('Description', Icons.description_rounded),
          const SizedBox(height: 16),
          
          _buildPremiumTextField(
            controller: _descriptionController,
            label: 'Description *',
            icon: Icons.description_rounded,
            maxLines: 4,
          ),
          
          const SizedBox(height: 24),
          
          _buildPremiumSectionHeader('Budget & Duration', Icons.attach_money_rounded),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildPremiumTextField(
                  controller: _budgetMinController,
                  label: 'Min Budget *',
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPremiumTextField(
                  controller: _budgetMaxController,
                  label: 'Max Budget *',
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _investmentDurationController,
            label: 'Investment Duration *',
            icon: Icons.schedule_rounded,
          ),
          
          const SizedBox(height: 24),
          
          _buildPremiumSectionHeader('Skills Required *', Icons.code_rounded),
          const SizedBox(height: 8),
          Text(
            'Add at least one required skill',
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 16),
          
          _buildPremiumTagInput(
            controller: _skillController,
            tags: _skillsRequired,
            hint: 'Add a required skill',
            onAdd: () {
              if (_skillController.text.trim().isNotEmpty) {
                setState(() {
                  _skillsRequired.add(_skillController.text.trim());
                  _skillController.clear();
                  _validateDetails();
                });
              }
            },
            onRemove: (index) {
              setState(() {
                _skillsRequired.removeAt(index);
                _validateDetails();
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          _buildPremiumSectionHeader('Responsibilities *', Icons.task_rounded),
          const SizedBox(height: 8),
          Text(
            'Add at least one responsibility',
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 16),
          
          _buildPremiumTagInput(
            controller: _responsibilityController,
            tags: _responsibilities,
            hint: 'Add a responsibility',
            onAdd: () {
              if (_responsibilityController.text.trim().isNotEmpty) {
                setState(() {
                  _responsibilities.add(_responsibilityController.text.trim());
                  _responsibilityController.clear();
                  _validateDetails();
                });
              }
            },
            onRemove: (index) {
              setState(() {
                _responsibilities.removeAt(index);
                _validateDetails();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSectionHeader(String title, IconData icon) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth > 600 ? 8 : 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.primaryGreen, widget.secondaryGold],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: screenWidth > 600 ? 18 : 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: screenWidth > 600 ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: widget.primaryGreen,
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
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
          prefixIcon: Icon(icon, color: widget.primaryGreen, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.primaryGreen, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines > 1 ? 14 : 12),
        ),
        validator: (value) {
          if (label.contains('*') && (value == null || value.isEmpty)) {
            return 'Required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPremiumDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
          prefixIcon: Icon(icon, color: widget.primaryGreen, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.primaryGreen, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        ),
        items: items,
        onChanged: (value) {
          onChanged(value);
          _validateBasicInfo();
        },
        validator: (value) {
          if (value == null && hint.contains('*')) {
            return 'Required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPremiumTagInput({
    required TextEditingController controller,
    required List<String> tags,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    String hint = 'Add item',
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
                  hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.primaryGreen, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.primaryGreen, widget.secondaryGold],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryGreen.withOpacity(0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(tags.length, (index) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.lightGreen, Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: widget.primaryGreen.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tags[index],
                      style: GoogleFonts.inter(
                        color: widget.primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => onRemove(index),
                      child: Icon(
                        Icons.close_rounded,
                        color: widget.accentRed,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedState == null) {
      _showErrorSnackBar('Please select a state');
      return;
    }

    // ADDED: Check location coordinates
    if (_partnerLatitude == null || _partnerLongitude == null) {
      _showErrorSnackBar('Please select a location on the map');
      return;
    }

    if (_skillsRequired.isEmpty) {
      _showErrorSnackBar('Please add at least one required skill');
      return;
    }

    if (_responsibilities.isEmpty) {
      _showErrorSnackBar('Please add at least one responsibility');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    
    if (currentUser == null) {
      _showErrorSnackBar('You must be logged in to post a request');
      return;
    }

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);

    // Get user's profile image
    String? userProfileImage;
    if (currentUser.profileImageUrl != null && currentUser.profileImageUrl!.isNotEmpty) {
      userProfileImage = currentUser.profileImageUrl;
    }

    final newRequest = BusinessPartnerRequest(
      title: _selectedPartnerType!.displayName,
      description: _descriptionController.text,
      partnerType: _selectedPartnerType!,
      businessType: _selectedBusinessType!,
      industry: _industryController.text.isNotEmpty ? _industryController.text : 'Not specified',
      location: _locationController.text,
      state: _selectedState!,
      city: _cityController.text,
      budgetMin: double.tryParse(_budgetMinController.text) ?? 0,
      budgetMax: double.tryParse(_budgetMaxController.text) ?? 0,
      investmentDuration: _investmentDurationController.text,
      skillsRequired: _skillsRequired,
      responsibilities: _responsibilities,
      contactName: _contactNameController.text,
      contactEmail: _contactEmailController.text,
      contactPhone: _contactPhoneController.text,
      preferredMeetingMethod: _preferredMeetingController.text.isNotEmpty ? _preferredMeetingController.text : null,
      isUrgent: _isUrgent,
      createdBy: currentUser.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      
      // Store user info directly in the request document
      postedByUserId: currentUser.id,
      postedByName: currentUser.fullName,
      postedByEmail: currentUser.email,
      postedByProfileImageBase64: userProfileImage,
      
      // ADDED: Location coordinates
      latitude: _partnerLatitude,
      longitude: _partnerLongitude,
      
      isVerified: false,
      isActive: true,
      isDeleted: false,
      totalViews: 0,
      totalResponses: 0,
      category: EntrepreneurshipCategory.lookingForBusinessPartner,
      tags: [],
      additionalInfo: {},
    );

    final success = await provider.addPartnerRequest(newRequest);
    
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Request posted successfully! Pending admin approval.',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: widget.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ),
      );
      
      if (widget.onRequestAdded != null) {
        widget.onRequestAdded!();
      }
    } else {
      _showErrorSnackBar('Failed to post request. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: GoogleFonts.inter(fontSize: 13))),
          ],
        ),
        backgroundColor: widget.accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }
}