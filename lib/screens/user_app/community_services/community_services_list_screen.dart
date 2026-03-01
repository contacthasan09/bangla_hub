import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:bangla_hub/models/community_services_models.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/service_provider_provider.dart';
import 'package:bangla_hub/screens/user_app/community_services/service_provider_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CommunityServicesListScreen extends StatefulWidget {
  const CommunityServicesListScreen({super.key});

  @override
  State<CommunityServicesListScreen> createState() => _CommunityServicesListScreenState();
}

class _CommunityServicesListScreenState extends State<CommunityServicesListScreen> with TickerProviderStateMixin {
  // Color scheme matching HomeScreen
  final Color _primaryRed = Color(0xFFF42A41);
  final Color _primaryGreen = Color(0xFF006A4E);
  final Color _darkGreen = Color(0xFF004D38);
  final Color _goldAccent = Color(0xFFFFD700);
  final Color _offWhite = Color(0xFFF8F8F8);
  
  // Extended vibrant colors that complement the theme
  final Color _coralRed = Color(0xFFFF6B6B);
  final Color _mintGreen = Color(0xFF98D8C8);
  final Color _softGold = Color(0xFFFFD966);
  final Color _creamWhite = Color(0xFFFFF9E6);
  final Color _lightGreen = Color(0xFFE8F5E9);
  final Color _lightRed = Color(0xFFFFEBEE);

    // Additional colors needed for success dialog
  final Color _emeraldGreen = Color(0xFF2ECC71);
  final Color _sapphireBlue = Color(0xFF3498DB);
  final Color _amethystPurple = Color(0xFF9B59B6);
  final Color _mintCream = Color(0xFFDCF8C6);
  final Color _peachBlossom = Color(0xFFFFC0CB);
  
  // Background Gradient using HomeScreen colors
  final LinearGradient _premiumBgGradient = LinearGradient(
    colors: [
      Color(0xFF006A4E), // _primaryGreen
      Color(0xFF004D38), // _darkGreen
      Color(0xFFF42A41), // _primaryRed
      Color(0xFFD32F2F), // darker red
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  final LinearGradient _sunsetGradient = LinearGradient(
    colors: [
      Color(0xFFF42A41), // _primaryRed
      Color(0xFFFF6B6B), // _coralRed
      Color(0xFFFFD966), // _softGold
      Color(0xFF006A4E), // _primaryGreen
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _oceanGradient = LinearGradient(
    colors: [
      Color(0xFF006A4E), // _primaryGreen
      Color(0xFF004D38), // _darkGreen
      Color(0xFF98D8C8), // _mintGreen
      Color(0xFFE8F5E9), // _lightGreen
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _royalGradient = LinearGradient(
    colors: [
      Color(0xFFF42A41), // _primaryRed
      Color(0xFFD32F2F), // darker red
      Color(0xFFFFD966), // _softGold
      Color(0xFF006A4E), // _primaryGreen
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _neonGradient = LinearGradient(
    colors: [
      Color(0xFFF42A41), // _primaryRed
      Color(0xFFFF6B6B), // _coralRed
      Color(0xFF006A4E), // _primaryGreen
      Color(0xFF98D8C8), // _mintGreen
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

    final LinearGradient _auroraGradient = LinearGradient(
    colors: [
      Color(0xFF00F5A0),
      Color(0xFF00D9F5),
      Color(0xFF9D50BB),
      Color(0xFF6E48AA),
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

  // Text Colors
  final Color _textPrimary = Color(0xFF1A1A2E);
  final Color _textSecondary = Color(0xFF4A4A4A);
  final Color _textLight = Color(0xFF6C757D);

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  
  // Filter State
  String? _tempSelectedState;
  String? _tempSelectedCity;
  ServiceCategory? _tempSelectedCategory;
  String? _tempSelectedServiceProvider;
  bool _showFilters = false;
  bool _hasTempFilters = false;
  
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
  late Animation<double> _rotateAnimation;
  
  // Scroll Controllers
  final ScrollController _scrollController = ScrollController();
  final ScrollController _filterScrollController = ScrollController();
  
  // Suggestion Dialog Controllers
  final TextEditingController _suggestFullNameController = TextEditingController();
  final TextEditingController _suggestCompanyNameController = TextEditingController();
  final TextEditingController _suggestPhoneController = TextEditingController();
  final TextEditingController _suggestEmailController = TextEditingController();
  final TextEditingController _suggestCityController = TextEditingController();
  
  // Stream subscription
  StreamSubscription<List<ServiceProviderModel>>? _serviceProvidersStreamSubscription;
  final GlobalKey _refreshIndicatorKey = GlobalKey();
  
  // Suggestion Dialog State
  String? _suggestSelectedState;
  ServiceCategory? _suggestSelectedCategory;
  String? _suggestSelectedServiceProvider;
  List<String> _suggestAvailableServiceProviders = [];
  bool _isSubmittingSuggestion = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // UI State
  int _selectedTabIndex = 0;
//  final List<String> _categories = ['All', 'Popular', 'Nearby', 'New', 'Top Rated'];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController, 
      curve: Curves.easeInOut,
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
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
    
    _rotateAnimation = CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeInOut,
    );
    
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    _rotateController.repeat();
    
    // Initialize data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ServiceProviderProvider>(context, listen: false);
      _subscribeToServiceProviders(provider);
      provider.loadServiceProviders();
    });
  }
  
  void _subscribeToServiceProviders(ServiceProviderProvider provider) {
    _serviceProvidersStreamSubscription?.cancel();
    
    _serviceProvidersStreamSubscription = provider.serviceProvidersStream().listen(
      (providers) {
        if (mounted) {
          setState(() {});
        }
      },
      onError: (error) {
        print('❌ Stream error: $error');
      },
    );
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<ServiceProviderProvider>(context, listen: false);
    _subscribeToServiceProviders(provider);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _filterScrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    _serviceProvidersStreamSubscription?.cancel();
    _suggestFullNameController.dispose();
    _suggestCompanyNameController.dispose();
    _suggestPhoneController.dispose();
    _suggestEmailController.dispose();
    _suggestCityController.dispose();
    super.dispose();
  }

  void _clearTempFilters() {
    setState(() {
      _tempSelectedState = null;
      _tempSelectedCity = null;
      _tempSelectedCategory = null;
      _tempSelectedServiceProvider = null;
      _hasTempFilters = false;
    });
  }

  void _syncTempWithAppliedFilters(ServiceProviderProvider provider) {
    setState(() {
      _tempSelectedState = provider.selectedState;
      _tempSelectedCity = provider.selectedCity;
      _tempSelectedCategory = provider.selectedCategory;
      _tempSelectedServiceProvider = provider.selectedServiceProvider;
      _hasTempFilters = provider.hasActiveFilters;
    });
  }

  void _applyFilters(ServiceProviderProvider provider) {
    provider.setSelectedState(_tempSelectedState);
    provider.setSelectedCity(_tempSelectedCity);
    provider.setSelectedCategory(_tempSelectedCategory);
    provider.setSelectedServiceProvider(_tempSelectedServiceProvider);
    setState(() {
      _showFilters = false;
      _hasTempFilters = provider.hasActiveFilters;
    });
  }

  void _cancelFilters() {
    _clearTempFilters();
    setState(() {
      _showFilters = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ServiceProviderProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;

    final availableProviders = provider.serviceProviders.where((p) => p.isAvailable).toList();

    if (!_showFilters) {
      _syncTempWithAppliedFilters(provider);
    }

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
            gradient: _premiumBgGradient, // Using HomeScreen colors
          ),
          child: Stack(
            children: [
              // Animated Background Particles
              ...List.generate(30, (index) => _buildAnimatedParticle(index, screenWidth, screenHeight)),
              
              // Animated Gradient Overlay
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: 0.3,
                  duration: Duration(seconds: 2),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                          _primaryRed.withOpacity(0.1),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Floating Bubbles
              ...List.generate(8, (index) => _buildFloatingBubble(index, screenWidth, screenHeight)),
              
              // Main Content
              RefreshIndicator(
                key: _refreshIndicatorKey,
                color: _goldAccent,
                backgroundColor: Colors.white,
                strokeWidth: 3,
                displacement: 40,
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  await provider.loadServiceProviders();
                },
                child: _showFilters
                    ? _buildFiltersView(provider, isTablet)
                    : _buildMainView(provider, availableProviders, isTablet),
              ),
              
              // Premium Floating Action Button
              Positioned(
                bottom: isTablet ? 40 : 30,
                right: isTablet ? 40 : 30,
                child: _buildPremiumFloatingActionButton(isTablet),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingBubble(int index, double width, double height) {
    final size = 50 + (index * 15).toDouble();
    return Positioned(
      left: (index * 73) % width,
      top: (index * 47) % height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(seconds: 8 + (index * 2)),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
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
                      Colors.white.withOpacity(0.2),
                      _primaryRed.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
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

  Widget _buildAnimatedParticle(int index, double width, double height) {
    final random = index * 0.1;
    return Positioned(
      left: (index * 37) % width,
      top: (index * 53) % height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(seconds: 3 + (index % 3)),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
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
                      _goldAccent.withOpacity(0.5),
                      _primaryGreen.withOpacity(0.3),
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

  Widget _buildPremiumAppBar(bool isTablet) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          isTablet ? 32 : 24,
          MediaQuery.of(context).padding.top + (isTablet ? 30 : 20),
          isTablet ? 32 : 24,
          isTablet ? 20 : 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medium Title with Premium Style
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  _goldAccent,
                  _primaryRed,
                  _primaryGreen,
                  _softGold,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Community  Services',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: isTablet ? 40 : 32,
                  height: 1.2,
                  color: Colors.white,
                  letterSpacing: -1,
                  shadows: [
                    Shadow(
                      color: _darkGreen.withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            
            // Animated Subtitle
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 1200),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 15 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 18 : 14,
                  vertical: isTablet ? 10 : 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primaryGreen.withOpacity(0.2),
                      _primaryRed.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: _goldAccent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: _goldAccent,
                      size: isTablet ? 22 : 20,
                    ),
                    SizedBox(width: isTablet ? 10 : 8),
                    Text(
                      'Find trusted professionals near you',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFloatingActionButton(bool isTablet) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryRed, _primaryGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: _primaryRed.withOpacity(0.5),
              blurRadius: 25,
              offset: Offset(0, 12),
              spreadRadius: 3,
            ),
            BoxShadow(
              color: _primaryGreen.withOpacity(0.4),
              blurRadius: 30,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showSuggestionDialog(context, isTablet),
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
                  RotationTransition(
                    turns: _rotateAnimation,
                    child: Icon(
                      Icons.add_circle_rounded,
                      color: Colors.white,
                      size: isTablet ? 26 : 22,
                    ),
                  ),
                  SizedBox(width: isTablet ? 12 : 10),
                  Text(
                    'Suggest',
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
      ),
    );
  }

  Widget _buildFiltersView(ServiceProviderProvider provider, bool isTablet) {
    return CustomScrollView(
      controller: _filterScrollController,
      physics: BouncingScrollPhysics(),
      slivers: [
        _buildPremiumAppBar(isTablet),
        
        // Premium Filters Card
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.all(isTablet ? 24 : 16),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.9 + (0.1 * value),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(45),
                  boxShadow: [
                    BoxShadow(
                      color: _darkGreen.withOpacity(0.3),
                      blurRadius: 35,
                      offset: Offset(0, 18),
                      spreadRadius: -5,
                    ),
                    BoxShadow(
                      color: _primaryRed.withOpacity(0.2),
                      blurRadius: 45,
                      offset: Offset(0, -8),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.7),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(45),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: EdgeInsets.all(isTablet ? 28 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Premium Header
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isTablet ? 16 : 14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryRed, _primaryGreen],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryRed.withOpacity(0.4),
                                      blurRadius: 18,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: RotationTransition(
                                  turns: _rotateAnimation,
                                  child: Icon(
                                    Icons.tune_rounded,
                                    color: Colors.white,
                                    size: isTablet ? 30 : 26,
                                  ),
                                ),
                              ),
                              SizedBox(width: isTablet ? 20 : 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (bounds) => LinearGradient(
                                        colors: [_primaryRed, _primaryGreen],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                      child: Text(
                                        'Premium Filters',
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 24 : 22,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Find your perfect match',
                                      style: GoogleFonts.inter(
                                        fontSize: isTablet ? 14 : 13,
                                        color: _textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: isTablet ? 28 : 24),

                          // State Filter
                          _buildPremiumDropdown<String>(
                            value: _tempSelectedState,
                            label: 'Select State',
                            icon: Icons.location_on_rounded,
                            isTablet: isTablet,
                            gradient: LinearGradient(
                              colors: [_primaryGreen, _darkGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text('All States', style: GoogleFonts.inter(color: _textSecondary, fontWeight: FontWeight.w600)),
                              ),
                              ...CommunityStates.states.map((state) {
                                return DropdownMenuItem<String>(
                                  value: state,
                                  child: Text(state, style: GoogleFonts.inter(color: _textPrimary, fontWeight: FontWeight.w700)),
                                );
                              }).toList(),
                            ],
                            onChanged: (String? newValue) async {
                              setState(() {
                                _tempSelectedState = newValue;
                                _tempSelectedCity = null;
                                _hasTempFilters = true;
                              });
                              
                              if (newValue != null) {
                                final cities = await provider.getCitiesForState(newValue);
                                if (cities.isEmpty) {
                                  _showNoCitiesDialog(context, isTablet);
                                  setState(() {
                                    _tempSelectedState = null;
                                    _hasTempFilters = false;
                                  });
                                }
                              }
                            },
                          ),

                          // City Filter
                          if (_tempSelectedState != null) ...[
                            SizedBox(height: isTablet ? 20 : 16),
                            FutureBuilder<List<String>>(
                              future: provider.getCitiesForState(_tempSelectedState!),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return _buildLoadingIndicator(isTablet);
                                }
                                
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return SizedBox.shrink();
                                }

                                return _buildPremiumDropdown<String>(
                                  value: _tempSelectedCity,
                                  label: 'Select City',
                                  icon: Icons.location_city_rounded,
                                  isTablet: isTablet,
                                  gradient: LinearGradient(
                                    colors: [_primaryGreen, _mintGreen],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('All Cities', style: GoogleFonts.inter(color: _textSecondary, fontWeight: FontWeight.w600)),
                                    ),
                                    ...snapshot.data!.map((city) {
                                      return DropdownMenuItem<String>(
                                        value: city,
                                        child: Text(city, style: GoogleFonts.inter(color: _textPrimary, fontWeight: FontWeight.w700)),
                                      );
                                    }).toList(),
                                  ],
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _tempSelectedCity = newValue;
                                      _hasTempFilters = true;
                                    });
                                  },
                                );
                              },
                            ),
                          ],

                          // Category Filter
                          SizedBox(height: isTablet ? 20 : 16),
                          _buildPremiumDropdown<ServiceCategory>(
                            value: _tempSelectedCategory,
                            label: 'Select Category',
                            icon: Icons.category_rounded,
                            isTablet: isTablet,
                            gradient: LinearGradient(
                              colors: [_primaryRed, _coralRed],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            items: [
                              DropdownMenuItem<ServiceCategory>(
                                value: null,
                                child: Text('All Categories', style: GoogleFonts.inter(color: _textSecondary, fontWeight: FontWeight.w600)),
                              ),
                              ...ServiceCategory.values.map((category) {
                                return DropdownMenuItem<ServiceCategory>(
                                  value: category,
                                  child: Row(
                                    children: [
                                      Icon(category.icon, color: _primaryRed, size: isTablet ? 22 : 20),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          category.displayName,
                                          style: GoogleFonts.inter(
                                            color: _textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: isTablet ? 15 : 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (ServiceCategory? newValue) {
                              setState(() {
                                _tempSelectedCategory = newValue;
                                _tempSelectedServiceProvider = null;
                                _hasTempFilters = true;
                              });
                            },
                          ),

                          // Service Provider Filter
                          if (_tempSelectedCategory != null) ...[
                            SizedBox(height: isTablet ? 20 : 16),
                            _buildPremiumDropdown<String>(
                              value: _tempSelectedServiceProvider,
                              label: 'Select Service Type',
                              icon: Icons.work_rounded,
                              isTablet: isTablet,
                              gradient: LinearGradient(
                                colors: [_goldAccent, _softGold],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Types', style: GoogleFonts.inter(color: _textSecondary, fontWeight: FontWeight.w600)),
                                ),
                                ..._tempSelectedCategory!.serviceProviders.map((provider) {
                                  return DropdownMenuItem<String>(
                                    value: provider,
                                    child: Text(
                                      provider,
                                      style: GoogleFonts.inter(
                                        color: _textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                              onChanged: (String? newValue) {
                                setState(() {
                                  _tempSelectedServiceProvider = newValue;
                                  _hasTempFilters = true;
                                });
                              },
                            ),
                          ],

                          SizedBox(height: isTablet ? 32 : 28),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: _buildPremiumActionButton(
                                  label: 'Apply',
                                  icon: Icons.check_circle_rounded,
                                  gradient: LinearGradient(
                                    colors: [_primaryGreen, _darkGreen],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  onTap: () => _applyFilters(provider),
                                  isTablet: isTablet,
                                ),
                              ),
                              SizedBox(width: isTablet ? 14 : 12),
                              Expanded(
                                child: _buildPremiumActionButton(
                                  label: 'Cancel',
                                  icon: Icons.cancel_rounded,
                                  gradient: _hasTempFilters 
                                      ? LinearGradient(colors: [_primaryRed, _coralRed])
                                      : LinearGradient(colors: [_textLight, _textSecondary]),
                                  onTap: _cancelFilters,
                                  isTablet: isTablet,
                                  isOutlined: true,
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: isTablet ? 14 : 12),
                          
                          // Clear All Button
                          AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: GestureDetector(
                              onTap: _clearTempFilters,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 16 : 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: _hasTempFilters 
                                      ? LinearGradient(colors: [_primaryRed, _coralRed])
                                      : null,
                                  color: _hasTempFilters ? null : Colors.transparent,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: _hasTempFilters ? Colors.transparent : _textLight.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.clear_all_rounded,
                                      color: _hasTempFilters ? Colors.white : _textLight,
                                      size: isTablet ? 22 : 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Clear All',
                                      style: GoogleFonts.poppins(
                                        color: _hasTempFilters ? Colors.white : _textLight,
                                        fontSize: isTablet ? 16 : 15,
                                        fontWeight: _hasTempFilters ? FontWeight.w700 : FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
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
          ),
        ),
        
        SliverToBoxAdapter(
          child: SizedBox(height: isTablet ? 120 : 100),
        ),
      ],
    );
  }

  Widget _buildMainView(ServiceProviderProvider provider, List<ServiceProviderModel> availableProviders, bool isTablet) {
    return CustomScrollView(
      controller: _scrollController,
      physics: BouncingScrollPhysics(),
      slivers: [
        _buildPremiumAppBar(isTablet),
        
        // Premium Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 14),
            child: _buildPremiumSearchField(provider, isTablet),
          ),
        ),

        // Category Tabs
    /*    SliverToBoxAdapter(
          child: Container(
            height: isTablet ? 60 : 50,
            margin: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 14),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return _buildCategoryTab(index, isTablet);
              },
            ),
          ),
        ),  */

        // Filter Toggle Button
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 20 : 14,
              isTablet ? 14 : 10,
              isTablet ? 20 : 14,
              isTablet ? 12 : 8,
            ),
            child: _buildFilterToggleButton(isTablet, provider.hasActiveFilters),
          ),
        ),

        // Active Filters
        _buildActiveFilters(provider, isTablet),

        // Results Header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 14,
              vertical: isTablet ? 14 : 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: _goldAccent,
                      size: isTablet ? 24 : 22,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Available',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 14 : 12,
                    vertical: isTablet ? 6 : 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: _glassMorphismGradient,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    '${availableProviders.length}',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 15 : 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (provider.isLoading && provider.serviceProviders.isEmpty)
          _buildLoadingState(isTablet)
        else if (provider.error.isNotEmpty)
          _buildErrorState(isTablet, provider.error, () {
            provider.loadServiceProviders();
          })
        else if (availableProviders.isEmpty)
          _buildEmptyState(isTablet, provider)
        else
          _buildServiceProvidersList(provider, availableProviders, isTablet),
        
        SliverToBoxAdapter(
          child: SizedBox(height: isTablet ? 140 : 120),
        ),
      ],
    );
  }

/*  Widget _buildCategoryTab(int index, bool isTablet) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        margin: EdgeInsets.only(right: isTablet ? 14 : 10),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 20,
          vertical: isTablet ? 14 : 12,
        ),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(colors: [_primaryRed, _primaryGreen])
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: _primaryRed.withOpacity(0.3),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            _categories[index],
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 16 : 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  } */

  Widget _buildLoadingIndicator(bool isTablet) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(isTablet ? 18 : 14),
        decoration: BoxDecoration(
          gradient: _glassMorphismGradient,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: isTablet ? 24 : 20,
              height: isTablet ? 24 : 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(_goldAccent),
              ),
            ),
            SizedBox(width: isTablet ? 14 : 10),
            Text(
              'Loading...',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 16 : 14,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumActionButton({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
    required bool isTablet,
    bool isOutlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 16 : 14,
        ),
        decoration: BoxDecoration(
          gradient: isOutlined ? null : gradient,
          color: isOutlined ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(22),
          border: isOutlined ? Border.all(color: Colors.white.withOpacity(0.4), width: 1.5) : null,
          boxShadow: isOutlined ? null : [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isOutlined ? Colors.white : Colors.white,
              size: isTablet ? 22 : 20,
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSearchField(ServiceProviderProvider provider, bool isTablet) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.96 + (0.04 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withOpacity(0.25),
              blurRadius: 25,
              offset: Offset(0, 12),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: _primaryRed.withOpacity(0.15),
              blurRadius: 30,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 16 : 14,
                  color: _textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  hintStyle: GoogleFonts.inter(
                    color: _textLight.withOpacity(0.7),
                    fontSize: isTablet ? 15 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Container(
                    margin: EdgeInsets.all(isTablet ? 14 : 12),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryGreen, _darkGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryGreen.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: isTablet ? 24 : 22,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _primaryRed.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: _primaryRed,
                              size: isTablet ? 22 : 20,
                            ),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            provider.setSearchQuery('');
                            HapticFeedback.lightImpact();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 28 : 24,
                    vertical: isTablet ? 22 : 18,
                  ),
                ),
                onChanged: (value) {
                  provider.setSearchQuery(value);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterToggleButton(bool isTablet, bool hasActiveFilters) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showFilters = true;
          _syncTempWithAppliedFilters(Provider.of<ServiceProviderProvider>(context, listen: false));
        });
        HapticFeedback.lightImpact();
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.96 + (0.04 * value),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 20,
            vertical: isTablet ? 18 : 15,
          ),
          decoration: BoxDecoration(
            gradient: hasActiveFilters 
                ? LinearGradient(colors: [_primaryRed, _primaryGreen])
                : LinearGradient(colors: [_primaryGreen, _darkGreen]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: (hasActiveFilters ? _primaryRed : _primaryGreen).withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: (hasActiveFilters ? _goldAccent : _darkGreen).withOpacity(0.2),
                blurRadius: 28,
                offset: Offset(0, 0),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotationTransition(
                turns: _rotateAnimation,
                child: Icon(
                  hasActiveFilters ? Icons.filter_alt_rounded : Icons.tune_rounded,
                  color: Colors.white,
                  size: isTablet ? 26 : 22,
                ),
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Text(
                hasActiveFilters ? 'Edit Filters' : 'Show Filters',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              if (hasActiveFilters) ...[
                SizedBox(width: isTablet ? 12 : 8),
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${_getActiveFilterCount(Provider.of<ServiceProviderProvider>(context, listen: false))}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isTablet ? 15 : 13,
                      fontWeight: FontWeight.w800,
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

  int _getActiveFilterCount(ServiceProviderProvider provider) {
    int count = 0;
    if (provider.selectedState != null) count++;
    if (provider.selectedCity != null) count++;
    if (provider.selectedCategory != null) count++;
    if (provider.selectedServiceProvider != null) count++;
    return count;
  }

  Widget _buildPremiumDropdown<T>({
    required T? value,
    required String label,
    required IconData icon,
    required bool isTablet,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required LinearGradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.15),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: gradient.colors.first,
            fontSize: isTablet ? 14 : 13,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(isTablet ? 12 : 10),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: isTablet ? 22 : 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 20,
            vertical: isTablet ? 18 : 14,
          ),
        ),
        items: items,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: isTablet ? 16 : 14,
          color: _textPrimary,
          fontWeight: FontWeight.w700,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(20),
        icon: RotationTransition(
          turns: _rotateAnimation,
          child: Icon(
            Icons.arrow_drop_down_circle_rounded,
            color: gradient.colors.first,
            size: isTablet ? 26 : 22,
          ),
        ),
        isExpanded: true,
      ),
    );
  }

  Widget _buildActiveFilters(ServiceProviderProvider provider, bool isTablet) {
    final activeFilters = <Widget>[];
    
    if (provider.selectedState != null) {
      activeFilters.add(
        _buildFilterChip(
          label: provider.selectedState!,
          icon: Icons.location_on_rounded,
          gradient: LinearGradient(
            colors: [_primaryGreen, _darkGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onRemove: () => provider.setSelectedState(null),
          isTablet: isTablet,
        ),
      );
    }
    
    if (provider.selectedCity != null) {
      activeFilters.add(
        _buildFilterChip(
          label: provider.selectedCity!,
          icon: Icons.location_city_rounded,
          gradient: LinearGradient(
            colors: [_primaryGreen, _mintGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onRemove: () => provider.setSelectedCity(null),
          isTablet: isTablet,
        ),
      );
    }
    
    if (provider.selectedCategory != null) {
      activeFilters.add(
        _buildFilterChip(
          label: provider.selectedCategory!.displayName,
          icon: provider.selectedCategory!.icon,
          gradient: LinearGradient(
            colors: [_primaryRed, _coralRed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onRemove: () => provider.setSelectedCategory(null),
          isTablet: isTablet,
        ),
      );
    }
    
    if (provider.selectedServiceProvider != null) {
      activeFilters.add(
        _buildFilterChip(
          label: provider.selectedServiceProvider!,
          icon: Icons.work_rounded,
          gradient: LinearGradient(
            colors: [_goldAccent, _softGold],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onRemove: () => provider.setSelectedServiceProvider(null),
          isTablet: isTablet,
        ),
      );
    }

    if (activeFilters.isEmpty) {
      return SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 14,
          vertical: isTablet ? 10 : 6,
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: activeFilters,
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onRemove,
    required bool isTablet,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.85 + (0.15 * value),
          child: child,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 14,
          vertical: isTablet ? 8 : 6,
        ),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: isTablet ? 20 : 18),
            SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: isTablet ? 16 : 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumServiceProviderCard(
    ServiceProviderModel provider,
    String? userId,
    bool isTablet,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 80)),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.92 + (0.08 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withOpacity(0.25),
              blurRadius: 30,
              offset: Offset(0, 16),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: _primaryRed.withOpacity(0.15),
              blurRadius: 40,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceProviderDetailScreen(providerId: provider.id!),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(40),
                  splashColor: _primaryGreen.withOpacity(0.15),
                  highlightColor: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          isTablet ? 24 : 20,
                          isTablet ? 20 : 16,
                          isTablet ? 24 : 20,
                          isTablet ? 14 : 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _primaryGreen.withOpacity(0.08),
                              _primaryRed.withOpacity(0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (provider.isVerified)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 6 : 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_goldAccent, _softGold],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _goldAccent.withOpacity(0.3),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded, color: Colors.white, size: isTablet ? 18 : 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: isTablet ? 12 : 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            _buildPremiumLikeButton(provider, userId, isTablet),
                          ],
                        ),
                      ),

                      // Main Content
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isTablet ? 24 : 20,
                          0,
                          isTablet ? 24 : 20,
                          isTablet ? 24 : 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Section
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: Duration(milliseconds: 700 + (index * 80)),
                                  curve: Curves.elasticOut,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: 0.85 + (0.15 * value),
                                      child: child,
                                    );
                                  },
                                  child: Container(
                                    width: isTablet ? 100 : 80,
                                    height: isTablet ? 100 : 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [_primaryRed, _primaryGreen],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _primaryGreen.withOpacity(0.3),
                                          blurRadius: 18,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(2),
                                      child: ClipOval(
                                        child: _buildProviderImage(provider, isTablet),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: isTablet ? 20 : 16),
                                
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: [_primaryRed, _primaryGreen],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ).createShader(bounds),
                                        child: Text(
                                          provider.fullName,
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 22 : 20,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isTablet ? 10 : 8,
                                          vertical: isTablet ? 4 : 2,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [_primaryGreen, _darkGreen],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Text(
                                          provider.companyName,
                                          style: GoogleFonts.inter(
                                            fontSize: isTablet ? 16 : 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: isTablet ? 20 : 16),

                            // Category and Service Type
                            Container(
                              padding: EdgeInsets.all(isTablet ? 18 : 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _primaryGreen.withOpacity(0.08),
                                    _primaryRed.withOpacity(0.08),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [_primaryGreen, _darkGreen],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          provider.serviceCategory.icon,
                                          color: Colors.white,
                                          size: isTablet ? 22 : 20,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Category',
                                              style: GoogleFonts.inter(
                                                fontSize: isTablet ? 12 : 10,
                                                color: _textLight,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              provider.serviceCategory.displayName,
                                              style: GoogleFonts.poppins(
                                                fontSize: isTablet ? 18 : 16,
                                                fontWeight: FontWeight.w700,
                                                color: _primaryGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isTablet ? 14 : 10),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [_primaryRed, _coralRed],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          Icons.work_rounded,
                                          color: Colors.white,
                                          size: isTablet ? 22 : 20,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Service Type',
                                              style: GoogleFonts.inter(
                                                fontSize: isTablet ? 12 : 10,
                                                color: _textLight,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              provider.serviceProvider,
                                              style: GoogleFonts.poppins(
                                                fontSize: isTablet ? 18 : 16,
                                                fontWeight: FontWeight.w700,
                                                color: _primaryRed,
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

                            SizedBox(height: isTablet ? 16 : 12),

                            // Location and Contact
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPremiumInfoTile(
                                    icon: Icons.location_on_rounded,
                                    label: 'Location',
                                    value: '${provider.city}',
                                    gradient: LinearGradient(
                                      colors: [_primaryGreen, _darkGreen],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    isTablet: isTablet,
                                  ),
                                ),
                                SizedBox(width: isTablet ? 12 : 8),
                                Expanded(
                                  child: _buildPremiumInfoTile(
                                    icon: Icons.phone_rounded,
                                    label: 'Contact',
                                    value: provider.phone,
                                    gradient: LinearGradient(
                                      colors: [_primaryRed, _coralRed],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    isTablet: isTablet,
                                    isClickable: true,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: isTablet ? 16 : 12),

                            // Status and Rating
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 18 : 14,
                                    vertical: isTablet ? 8 : 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: provider.isAvailable
                                        ? LinearGradient(colors: [_primaryGreen, _darkGreen])
                                        : LinearGradient(colors: [_primaryRed, _coralRed]),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (provider.isAvailable ? _primaryGreen : _primaryRed).withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        provider.isAvailable
                                            ? Icons.check_circle_rounded
                                            : Icons.remove_circle_rounded,
                                        color: Colors.white,
                                        size: isTablet ? 20 : 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        provider.isAvailable ? 'Available' : 'Not Available',
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 14 : 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 14 : 10,
                                    vertical: isTablet ? 6 : 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_goldAccent, _softGold],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _goldAccent.withOpacity(0.3),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        color: Colors.white,
                                        size: isTablet ? 22 : 20,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        provider.rating.toStringAsFixed(1),
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: isTablet ? 20 : 16),

                            // View Details Button
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ServiceProviderDetailScreen(providerId: provider.id!),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 16 : 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryRed, _primaryGreen],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryRed.withOpacity(0.3),
                                      blurRadius: 18,
                                      offset: Offset(0, 8),
                                      spreadRadius: -2,
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
                                        fontSize: isTablet ? 18 : 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: isTablet ? 12 : 8),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 20 : 18,
                                    ),
                                  ],
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required LinearGradient gradient,
    required bool isTablet,
    bool isClickable = false,
  }) {
    return GestureDetector(
      onTap: isClickable ? () {
        // Implement call functionality
      } : null,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 14 : 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradient.colors.first.withOpacity(0.1),
              gradient.colors.last.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: gradient.colors.first.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: isTablet ? 20 : 18),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 11 : 9,
                      color: _textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 16 : 14,
                      color: gradient.colors.first,
                      fontWeight: FontWeight.w700,
                      decoration: isClickable ? TextDecoration.underline : null,
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
    );
  }

  Widget _buildPremiumLikeButton(ServiceProviderModel provider, String? userId, bool isTablet) {
    final serviceProviderProvider = Provider.of<ServiceProviderProvider>(context, listen: false);
    bool isLiked = provider.isLikedByUser(userId ?? '');
    
    return GestureDetector(
      onTap: () {
        if (userId == null || userId.isEmpty) {
          _showPremiumSnackBar(
            'Please login to like',
            isError: true,
          );
          return;
        }
        
        HapticFeedback.lightImpact();
        serviceProviderProvider.toggleLike(provider.id!, userId);
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: isLiked ? 1.15 : 1),
        duration: Duration(milliseconds: 250),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 14 : 12,
            vertical: isTablet ? 6 : 4,
          ),
          decoration: BoxDecoration(
            gradient: isLiked
                ? LinearGradient(colors: [_primaryRed, _coralRed])
                : LinearGradient(colors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.15)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLiked ? Colors.transparent : Colors.white.withOpacity(0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isLiked ? _primaryRed.withOpacity(0.3) : Colors.transparent,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.white : Colors.white,
                size: isTablet ? 18 : 16,
              ),
              if (provider.totalLikes > 0) ...[
                SizedBox(width: 4),
                Text(
                  '${provider.totalLikes}',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderImage(ServiceProviderModel provider, bool isTablet) {
    if (provider.profileImageBase64 != null && provider.profileImageBase64!.isNotEmpty) {
      try {
        String base64String = provider.profileImageBase64!;
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
            return _buildDefaultProfileImage(isTablet);
          },
        );
      } catch (e) {
        return _buildDefaultProfileImage(isTablet);
      }
    }
    return _buildDefaultProfileImage(isTablet);
  }

  Widget _buildDefaultProfileImage(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_lightGreen, _creamWhite],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: _primaryGreen,
          size: isTablet ? 45 : 40,
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isTablet) {
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
                    width: isTablet ? 140 : 120,
                    height: isTablet ? 140 : 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryRed, _primaryGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryRed.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: isTablet ? 110 : 90,
                        height: isTablet ? 110 : 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: isTablet ? 60 : 50,
                            height: isTablet ? 60 : 50,
                            child: CircularProgressIndicator(
                              color: _primaryGreen,
                              strokeWidth: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: isTablet ? 40 : 30),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [_primaryRed, _primaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Loading...',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 30 : 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: isTablet ? 16 : 12),
            ScaleTransition(
              scale: _pulseAnimation,
              child: Text(
                'Finding best services for you',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 18 : 16,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isTablet, String error, VoidCallback onRetry) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 40 : 30),
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
                      padding: EdgeInsets.all(isTablet ? 32 : 28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryRed.withOpacity(0.15), _primaryRed.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: isTablet ? 80 : 70,
                        color: _primaryRed,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: isTablet ? 40 : 30),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [_primaryRed, _coralRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  'Oops!',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 32 : 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 16 : 12),
              Text(
                error,
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 18 : 16,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 40 : 30),
              GestureDetector(
                onTap: onRetry,
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
                          gradient: LinearGradient(
                            colors: [_primaryRed, _primaryGreen],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryRed.withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded, color: Colors.white, size: isTablet ? 26 : 22),
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
      ),
    );
  }

  Widget _buildEmptyState(bool isTablet, ServiceProviderProvider provider) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 40 : 30),
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
                      padding: EdgeInsets.all(isTablet ? 32 : 28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryGreen.withOpacity(0.15), _primaryRed.withOpacity(0.15)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.search_off_rounded,
                        size: isTablet ? 80 : 70,
                        color: _primaryGreen,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: isTablet ? 40 : 30),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [_primaryGreen, _darkGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  'No Services Found',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 30 : 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 16 : 12),
              Text(
                'Try adjusting filters or suggest a new service',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 18 : 16,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (provider.hasActiveFilters) ...[
                SizedBox(height: isTablet ? 30 : 24),
                GestureDetector(
                  onTap: () {
                    provider.clearFilters();
                    HapticFeedback.lightImpact();
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
                            gradient: LinearGradient(
                              colors: [_primaryRed, _coralRed],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryRed.withOpacity(0.3),
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

  Widget _buildServiceProvidersList(
    ServiceProviderProvider provider,
    List<ServiceProviderModel> availableProviders,
    bool isTablet,
  ) {
    final userId = Provider.of<AuthProvider>(context).user?.id;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return _buildPremiumServiceProviderCard(
            availableProviders[index],
            userId,
            isTablet,
            index,
          );
        },
        childCount: availableProviders.length,
      ),
    );
  }

  void _showNoCitiesDialog(BuildContext context, bool isTablet) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(isTablet ? 40 : 20),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.85 + (0.15 * value),
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, _creamWhite, _lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 40,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 48 : 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isTablet ? 24 : 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryRed.withOpacity(0.1), _primaryRed.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_off_rounded,
                        color: _primaryRed,
                        size: isTablet ? 70 : 60,
                      ),
                    ),
                    SizedBox(height: isTablet ? 30 : 24),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [_primaryRed, _coralRed],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'Not Available',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 32 : 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    Text(
                      'No providers in this state yet. Please select another.',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 18 : 16,
                        color: _textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 30 : 24),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 18 : 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryRed, _coralRed],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryRed.withOpacity(0.3),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'OK',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: isTablet ? 22 : 20,
                              fontWeight: FontWeight.w700,
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
      },
    );
  }

  void _showSuggestionDialog(BuildContext context, bool isTablet) {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(isTablet ? 40 : 20),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.85 + (0.15 * value),
                  child: child,
                );
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 700,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, _creamWhite, _lightGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 50,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(isTablet ? 30 : 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryRed, _primaryGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryRed.withOpacity(0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isTablet ? 16 : 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: RotationTransition(
                              turns: _rotateAnimation,
                              child: Icon(
                                Icons.add_circle_rounded,
                                color: Colors.white,
                                size: isTablet ? 32 : 28,
                              ),
                            ),
                          ),
                          SizedBox(width: isTablet ? 20 : 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Suggest Service',
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 30 : 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Help us grow! 🌟',
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 18 : 16,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close_rounded, color: Colors.white, size: isTablet ? 28 : 24),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isTablet ? 30 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Info Card
                            Container(
                              padding: EdgeInsets.all(isTablet ? 20 : 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_primaryGreen.withOpacity(0.1), _primaryRed.withOpacity(0.1)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: _primaryGreen.withOpacity(0.25),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_primaryGreen, _darkGreen],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _primaryGreen.withOpacity(0.3),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.info_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 28 : 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pending Review',
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.w700,
                                            color: _primaryGreen,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Admin will verify your suggestion',
                                          style: GoogleFonts.inter(
                                            fontSize: isTablet ? 14 : 12,
                                            color: _textLight,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: isTablet ? 30 : 24),

                            // Form Fields
                            _buildPremiumSuggestionTextField(
                              controller: _suggestFullNameController,
                              label: 'Full Name',
                              isRequired: true,
                              icon: Icons.person_rounded,
                              gradient: LinearGradient(
                                colors: [_primaryGreen, _darkGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              isTablet: isTablet,
                            ),
                            SizedBox(height: isTablet ? 20 : 16),

                            _buildPremiumSuggestionTextField(
                              controller: _suggestCompanyNameController,
                              label: 'Company',
                              isRequired: false,
                              icon: Icons.business_rounded,
                              gradient: LinearGradient(
                                colors: [_primaryRed, _coralRed],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              isTablet: isTablet,
                            ),
                            SizedBox(height: isTablet ? 20 : 16),

                            _buildPremiumSuggestionTextField(
                              controller: _suggestPhoneController,
                              label: 'Phone',
                              isRequired: true,
                              icon: Icons.phone_rounded,
                              gradient: LinearGradient(
                                colors: [_primaryGreen, _mintGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              keyboardType: TextInputType.phone,
                              isTablet: isTablet,
                            ),
                            SizedBox(height: isTablet ? 20 : 16),

                            _buildPremiumSuggestionTextField(
                              controller: _suggestEmailController,
                              label: 'Email',
                              isRequired: true,
                              icon: Icons.email_rounded,
                              gradient: LinearGradient(
                                colors: [_goldAccent, _softGold],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              isTablet: isTablet,
                            ),
                            SizedBox(height: isTablet ? 20 : 16),

                            // State Dropdown
                            _buildPremiumSuggestionDropdown(
                              value: _suggestSelectedState,
                              label: 'State',
                              isRequired: true,
                              icon: Icons.location_on_rounded,
                              gradient: LinearGradient(
                                colors: [_primaryGreen, _darkGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              isTablet: isTablet,
                              items: [
                                ...CommunityStates.states.map((state) {
                                  return DropdownMenuItem<String>(
                                    value: state,
                                    child: Text(state, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: isTablet ? 15 : 14)),
                                  );
                                }).toList(),
                              ],
                              onChanged: (String? newValue) {
                                setState(() {
                                  _suggestSelectedState = newValue;
                                });
                              },
                            ),
                            SizedBox(height: isTablet ? 20 : 16),

                            _buildPremiumSuggestionTextField(
                              controller: _suggestCityController,
                              label: 'City',
                              isRequired: true,
                              icon: Icons.location_city_rounded,
                              gradient: LinearGradient(
                                colors: [_primaryGreen, _mintGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              isTablet: isTablet,
                            ),
                            SizedBox(height: isTablet ? 20 : 16),

                            // Category Dropdown
                            _buildPremiumSuggestionDropdown<ServiceCategory>(
                              value: _suggestSelectedCategory,
                              label: 'Category',
                              isRequired: true,
                              icon: Icons.category_rounded,
                              gradient: LinearGradient(
                                colors: [_primaryRed, _coralRed],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              isTablet: isTablet,
                              items: ServiceCategory.values.map((category) {
                                return DropdownMenuItem<ServiceCategory>(
                                  value: category,
                                  child: Row(
                                    children: [
                                      Icon(category.icon, color: _primaryRed, size: isTablet ? 22 : 20),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          category.displayName,
                                          style: GoogleFonts.inter(
                                            fontSize: isTablet ? 16 : 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (ServiceCategory? newValue) {
                                setState(() {
                                  _suggestSelectedCategory = newValue;
                                  _suggestSelectedServiceProvider = null;
                                  _suggestAvailableServiceProviders = newValue?.serviceProviders ?? [];
                                });
                              },
                            ),

                            // Service Provider Dropdown
                            if (_suggestSelectedCategory != null) ...[
                              SizedBox(height: isTablet ? 20 : 16),
                              _buildPremiumSuggestionDropdown(
                                value: _suggestSelectedServiceProvider,
                                label: 'Service Type',
                                isRequired: true,
                                icon: Icons.work_rounded,
                                gradient: LinearGradient(
                                  colors: [_goldAccent, _softGold],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                isTablet: isTablet,
                                items: _suggestAvailableServiceProviders.map((provider) {
                                  return DropdownMenuItem<String>(
                                    value: provider,
                                    child: Text(
                                      provider,
                                      style: GoogleFonts.inter(
                                        fontSize: isTablet ? 16 : 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _suggestSelectedServiceProvider = newValue;
                                  });
                                },
                              ),
                            ],

                            SizedBox(height: isTablet ? 30 : 24),
                          ],
                        ),
                      ),
                    ),

                    // Footer Buttons
                    Container(
                      padding: EdgeInsets.all(isTablet ? 30 : 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
                        border: Border(top: BorderSide(color: _primaryGreen.withOpacity(0.15), width: 1.5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 18 : 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(color: _primaryRed, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryRed.withOpacity(0.15),
                                      blurRadius: 15,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.poppins(
                                      color: _primaryRed,
                                      fontSize: isTablet ? 20 : 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: isTablet ? 16 : 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _isSubmittingSuggestion ? null : () => _submitSuggestion(context, isTablet, setState),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 18 : 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: _isSubmittingSuggestion 
                                      ? LinearGradient(colors: [_textLight, _textSecondary])
                                      : LinearGradient(colors: [_primaryGreen, _darkGreen]),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryGreen.withOpacity(0.3),
                                      blurRadius: 18,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isSubmittingSuggestion
                                      ? SizedBox(
                                          width: isTablet ? 30 : 26,
                                          height: isTablet ? 30 : 26,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.send_rounded, color: Colors.white, size: isTablet ? 24 : 22),
                                            SizedBox(width: 8),
                                            Text(
                                              'Submit',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: isTablet ? 20 : 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
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
        },
      ),
    );
  }

  Widget _buildPremiumSuggestionTextField({
    required TextEditingController controller,
    required String label,
    required bool isRequired,
    required IconData icon,
    required LinearGradient gradient,
    TextInputType keyboardType = TextInputType.text,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.15),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
          fontSize: isTablet ? 16 : 14,
          color: _textPrimary,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          labelStyle: GoogleFonts.poppins(
            fontSize: isTablet ? 14 : 13,
            color: gradient.colors.first,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(isTablet ? 14 : 12),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.25),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: isTablet ? 22 : 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 20,
            vertical: isTablet ? 18 : 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumSuggestionDropdown<T>({
    required T? value,
    required String label,
    required bool isRequired,
    required IconData icon,
    required LinearGradient gradient,
    required bool isTablet,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.15),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          labelStyle: GoogleFonts.poppins(
            fontSize: isTablet ? 14 : 13,
            color: gradient.colors.first,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(isTablet ? 14 : 12),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.25),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: isTablet ? 22 : 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 20,
            vertical: isTablet ? 14 : 12,
          ),
        ),
        items: items,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: isTablet ? 16 : 14,
          color: _textPrimary,
          fontWeight: FontWeight.w600,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(20),
        icon: RotationTransition(
          turns: _rotateAnimation,
          child: Icon(
            Icons.arrow_drop_down_circle_rounded,
            color: gradient.colors.first,
            size: isTablet ? 26 : 22,
          ),
        ),
        isExpanded: true,
      ),
    );
  }

  Future<void> _submitSuggestion(BuildContext context, bool isTablet, StateSetter setState) async {
    // Validation
    if (_suggestFullNameController.text.isEmpty) {
      _showPremiumSnackBar('Enter full name', isError: true);
      return;
    }

    if (_suggestPhoneController.text.isEmpty) {
      _showPremiumSnackBar('Enter phone number', isError: true);
      return;
    }

    if (_suggestEmailController.text.isEmpty) {
      _showPremiumSnackBar('Enter email', isError: true);
      return;
    }

    if (_suggestSelectedState == null) {
      _showPremiumSnackBar('Select state', isError: true);
      return;
    }

    if (_suggestCityController.text.isEmpty) {
      _showPremiumSnackBar('Enter city', isError: true);
      return;
    }

    if (_suggestSelectedCategory == null) {
      _showPremiumSnackBar('Select category', isError: true);
      return;
    }

    if (_suggestSelectedServiceProvider == null) {
      _showPremiumSnackBar('Select service type', isError: true);
      return;
    }

    setState(() => _isSubmittingSuggestion = true);

    try {
      final currentUser = _auth.currentUser;
      final providerProvider = Provider.of<ServiceProviderProvider>(context, listen: false);
      
      final suggestedServiceProvider = ServiceProviderModel(
        fullName: _suggestFullNameController.text.trim(),
        companyName: _suggestCompanyNameController.text.trim(),
        phone: _suggestPhoneController.text.trim(),
        email: _suggestEmailController.text.trim(),
        address: '',
        state: _suggestSelectedState!,
        city: _suggestCityController.text.trim(),
        serviceCategory: _suggestSelectedCategory!,
        serviceProvider: _suggestSelectedServiceProvider!,
        subServiceProvider: null,
        profileImageBase64: null,
        description: 'Suggested by user - pending admin review',
        website: '',
        businessHours: '',
        yearsOfExperience: '',
        languagesSpoken: ['English'],
        serviceTags: [],
        serviceAreas: [],
        isVerified: false,
        isAvailable: false,
        isDeleted: false,
        createdBy: currentUser?.uid ?? 'anonymous',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        licenseNumber: '',
        specialties: '',
        consultationFee: null,
        acceptsInsurance: false,
        acceptedPaymentMethods: [],
      );

      final success = await providerProvider.addServiceProvider(suggestedServiceProvider);
      
      if (success) {
        Navigator.pop(context);
        _showPremiumSuccessDialog(context, isTablet);
        
        // Clear form
        _suggestFullNameController.clear();
        _suggestCompanyNameController.clear();
        _suggestPhoneController.clear();
        _suggestEmailController.clear();
        _suggestCityController.clear();
        setState(() {
          _suggestSelectedState = null;
          _suggestSelectedCategory = null;
          _suggestSelectedServiceProvider = null;
        });
      } else {
        _showPremiumSnackBar('Failed to submit', isError: true);
      }
    } catch (e) {
      _showPremiumSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isSubmittingSuggestion = false);
    }
  }

  void _showPremiumSuccessDialog(BuildContext context, bool isTablet) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(isTablet ? 40 : 20),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, _mintCream, _peachBlossom],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: _emeraldGreen.withOpacity(0.3),
                    blurRadius: 40,
                    offset: Offset(0, 20),
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 50 : 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success Animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.85 + (0.15 * value),
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 28 : 24),
                            decoration: BoxDecoration(
                              gradient: _auroraGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _emeraldGreen.withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: RotationTransition(
                              turns: _rotateAnimation,
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: isTablet ? 80 : 70,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: isTablet ? 40 : 30),
                    
                    // Welcome Text
                    ShaderMask(
                      shaderCallback: (bounds) => _auroraGradient.createShader(bounds),
                      child: Text(
                        'Thank You! 🎉',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 40 : 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    
                    // Success Message
                    Text(
                      'Your suggestion has been submitted!',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 22 : 20,
                        fontWeight: FontWeight.w700,
                        color: _sapphireBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Admin Contact Card
                    Container(
                      padding: EdgeInsets.all(isTablet ? 24 : 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_sapphireBlue.withOpacity(0.1), _amethystPurple.withOpacity(0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(
                          color: _sapphireBlue.withOpacity(0.25),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: _royalGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _amethystPurple.withOpacity(0.3),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.admin_panel_settings_rounded,
                              color: Colors.white,
                              size: isTablet ? 40 : 35,
                            ),
                          ),
                          SizedBox(height: isTablet ? 16 : 12),
                          Text(
                            'Admin will contact you soon',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.w700,
                              color: _sapphireBlue,
                            ),
                          ),
                          SizedBox(height: isTablet ? 6 : 4),
                          Text(
                            'for verification steps',
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 16 : 14,
                              color: _textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    
                    Text(
                      'Thank you for contributing! 🌟',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 18 : 16,
                        color: _amethystPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: isTablet ? 40 : 30),
                    
                    // Close Button
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 20 : 18,
                        ),
                        decoration: BoxDecoration(
                          gradient: _auroraGradient,
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: _emeraldGreen.withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Awesome!',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: isTablet ? 24 : 22,
                              fontWeight: FontWeight.w800,
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
      },
    );
  }

  void _showPremiumSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isError
                ? LinearGradient(colors: [_primaryRed, _coralRed])
                : LinearGradient(colors: [_primaryGreen, _darkGreen]),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: (isError ? _primaryRed : _primaryGreen).withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_rounded : Icons.check_circle_rounded,
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
}