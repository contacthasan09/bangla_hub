// screens/user_app/community_services/community_services_list_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:bangla_hub/main.dart';
import 'package:bangla_hub/models/community_services_models.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/location_filter_provider.dart';
import 'package:bangla_hub/providers/service_provider_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/auth/signup_screen.dart';
import 'package:bangla_hub/screens/user_app/community_services/add_service_screen.dart';
import 'package:bangla_hub/screens/user_app/community_services/service_provider_detail_screen.dart';
import 'package:bangla_hub/widgets/common/distance_widget.dart';
import 'package:bangla_hub/widgets/common/global_location_filter_bar.dart';
import 'package:bangla_hub/widgets/common/global_location_guard.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommunityServicesListScreen extends StatefulWidget {
  const CommunityServicesListScreen({super.key});

  @override
  State<CommunityServicesListScreen> createState() => _CommunityServicesListScreenState();
}

class _CommunityServicesListScreenState extends State<CommunityServicesListScreen> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  
  @override
  bool get wantKeepAlive => true;

  // Color scheme - Lighter red for app bar
  static const Color _primaryRed = Color(0xFFF42A41);
  final Color _lightRed = Color(0xFFFFE5E9);
  final Color _lightGreen = Color(0xFFE0F2F1);
  final Color _mintGreen = const Color(0xFF2E7D32);
  final Color _creamWhite = const Color(0xFFFFF9E6);

  static const Color _primaryGreen = Color(0xFF006A4E);
  static const Color _darkGreen = Color(0xFF004D38);
  static const Color _goldAccent = Color(0xFFFFD700);
  static const Color _softGold = Color(0xFFFFD966);
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _textSecondary = Color(0xFF4A4A4A);
  static const Color _textLight = Color(0xFF6C757D);
  static const Color _successGreen = Color(0xFF2ECC71);
  static const Color _cardBgStart = Color(0xFFF8F9FA);
  static const Color _cardBgEnd = Color(0xFFE9ECEF);
  static const Color _coralRed = Color(0xFFFF6B6B);
  
  // Lighter gradient for app bar
  static const LinearGradient _appBarGradient = LinearGradient(
    colors: [
      Color(0xFFE03C32), // Lighter red
      Color(0xFFF55B4F), // Even lighter
      Color(0xFF006A4E),
      Color(0xFF2E8B57),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  // Original gradient for background
  static const LinearGradient _premiumBgGradient = LinearGradient(
    colors: [
      Color(0xFF006A4E),
      Color(0xFF004D38),
      Color(0xFFF42A41),
      Color(0xFFD32F2F),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  // Controllers
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  late final ScrollController _filterScrollController;
  final Map<String, Uint8List?> _imageCache = {};
  Timer? _searchDebounce;
  bool _isFilterView = false;
  bool _isInitialized = false;
  
  // Suggestion Dialog Controllers
  late final TextEditingController _suggestFullNameController;
  late final TextEditingController _suggestCompanyNameController;
  late final TextEditingController _suggestPhoneController;
  late final TextEditingController _suggestEmailController;
  late final TextEditingController _suggestAddressController;
  
  // LOCAL FILTER STATE - NO STATE filter (removed)
  String? _localTempSelectedCity;
  ServiceCategory? _localTempSelectedCategory;
  String? _localTempSelectedServiceProvider;
  
  // Applied LOCAL filters - NO STATE filter
  String? _localAppliedCity;
  ServiceCategory? _localAppliedCategory;
  String? _localAppliedServiceProvider;
  
  // Track which local filters are active (for display)
  bool _hasLocalFilters = false;
  Map<String, dynamic> _activeLocalFilters = {};
  
  // Suggestion Dialog State with Location
  String? _suggestSelectedState;
  String? _suggestSelectedCity;
  ServiceCategory? _suggestSelectedCategory;
  String? _suggestSelectedServiceProvider;
  List<String> _suggestAvailableServiceProviders = [];
  bool _isSubmittingSuggestion = false;
  
  // Location picking for suggestion
  double? _suggestLatitude;
  double? _suggestLongitude;
  String? _suggestFullAddress;
  
  // Animation Controllers
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _rotateController;
  late final Animation<double> _rotateAnimation;
  
  // Stream subscription
  StreamSubscription<List<ServiceProviderModel>>? _serviceProvidersStreamSubscription;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize controllers
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    _filterScrollController = ScrollController();
    _suggestFullNameController = TextEditingController();
    _suggestCompanyNameController = TextEditingController();
    _suggestPhoneController = TextEditingController();
    _suggestEmailController = TextEditingController();
    _suggestAddressController = TextEditingController();
    
    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController, 
      curve: Curves.easeInOut,
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    
    _rotateAnimation = CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeInOut,
    );

    // Add scroll listener
    _scrollController.addListener(_onScroll);

    // Load data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        _isInitialized = true;
        final provider = Provider.of<ServiceProviderProvider>(context, listen: false);
        final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
        
        // FIX: Use post-frame callback for initial sync
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.syncWithLocationFilter(locationProvider);
        });
        
        _setupStreamSubscription(provider);
        provider.loadServiceProviders();
        
        // Get user location if not already
        if (locationProvider.currentUserLocation == null) {
          locationProvider.getUserLocation(showLoading: false);
        }
      }
    });
  }
  
  void _onScroll() {
    if (_scrollController.offset > 100) {
      // User scrolled down - you can add animations here if needed
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final provider = Provider.of<ServiceProviderProvider>(context, listen: false);
      _setupStreamSubscription(provider);
    }
  }
  
  void _setupStreamSubscription(ServiceProviderProvider provider) {
    _serviceProvidersStreamSubscription?.cancel();
    _serviceProvidersStreamSubscription = provider.serviceProvidersStream().listen(
      (providers) {
        if (mounted) {
          setState(() {
            _imageCache.clear();
          });
          print('✅ Stream received ${providers.length} providers');
        }
      },
      onError: (error) => print('Stream error: $error'),
    );
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serviceProvidersStreamSubscription?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _filterScrollController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _searchDebounce?.cancel();
    _suggestFullNameController.dispose();
    _suggestCompanyNameController.dispose();
    _suggestPhoneController.dispose();
    _suggestEmailController.dispose();
    _suggestAddressController.dispose();
    _imageCache.clear();
    super.dispose();
  }

  // ✅ FIXED: Robust drawer opening method
  void _openDrawer(BuildContext context) {
    try {
      final ScaffoldState? scaffoldState = Scaffold.maybeOf(
        Navigator.of(context, rootNavigator: true).context
      );
      
      if (scaffoldState != null && scaffoldState.hasDrawer) {
        scaffoldState.openDrawer();
        return;
      }
      
      final ScaffoldState? currentScaffold = Scaffold.maybeOf(context);
      if (currentScaffold != null && currentScaffold.hasDrawer) {
        currentScaffold.openDrawer();
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Menu is available from the home screen'),
          duration: Duration(milliseconds: 800),
          backgroundColor: _primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('Could not open drawer: $e');
    }
  }


Widget _buildProviderImage(ServiceProviderModel provider) {
  // Check if there's an image
  if (provider.profileImageBase64 == null || provider.profileImageBase64!.isEmpty) {
    return _buildDefaultAvatar();
  }

  // Check cache
  if (_imageCache.containsKey(provider.id)) {
    final bytes = _imageCache[provider.id];
    if (bytes != null) {
      return ClipOval(
        child: Image.memory(
          bytes, 
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        ),
      );
    }
  }

  try {
    String base64String = provider.profileImageBase64!;
    if (base64String.contains('base64,')) {
      base64String = base64String.split('base64,').last;
    }
    base64String = base64String.replaceAll(RegExp(r'\s'), '');
    while (base64String.length % 4 != 0) base64String += '=';
    
    final bytes = base64Decode(base64String);
    _imageCache[provider.id!] = bytes;
    return ClipOval(
      child: Image.memory(
        bytes, 
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar();
        },
      ),
    );
  } catch (e) {
    print('Error decoding image: $e');
    return _buildDefaultAvatar();
  }
}

Widget _buildDefaultAvatar() {
  return ClipOval(
    child: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _primaryGreen.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded, 
          color: _primaryGreen, 
          size: 30,
        ),
      ),
    ),
  );
}


  // Get filtered providers - applying BOTH global and local filters (NO STATE from local)
  List<ServiceProviderModel> _getFilteredProviders(
    List<ServiceProviderModel> providers,
    LocationFilterProvider locationProvider,
  ) {
    // Start with all providers
    var filteredProviders = List<ServiceProviderModel>.from(providers);
    
    print('📊 Initial providers: ${filteredProviders.length}');
    
    // Apply GLOBAL location filter if active (from LocationFilterProvider)
    if (locationProvider.isFilterActive && locationProvider.selectedState != null) {
      filteredProviders = filteredProviders.where((provider) {
        return provider.state == locationProvider.selectedState;
      }).toList();
      print('📍 After GLOBAL filter (${locationProvider.selectedState}): ${filteredProviders.length} providers');
    }
    
    // Apply LOCAL filters if any (from this screen's filter view) - NO STATE FILTER
    if (_hasLocalFilters) {
      // City filter (local only)
      if (_localAppliedCity != null && _localAppliedCity!.isNotEmpty) {
        filteredProviders = filteredProviders.where((provider) => 
          provider.city.toLowerCase().contains(_localAppliedCity!.toLowerCase())
        ).toList();
        print('🏙️ After LOCAL city filter (${_localAppliedCity}): ${filteredProviders.length} providers');
      }
      
      // Category filter (local only)
      if (_localAppliedCategory != null) {
        filteredProviders = filteredProviders.where((provider) => 
          provider.serviceCategory == _localAppliedCategory
        ).toList();
        print('📁 After LOCAL category filter (${_localAppliedCategory!.displayName}): ${filteredProviders.length} providers');
      }
      
      // Service Provider filter (local only)
      if (_localAppliedServiceProvider != null && _localAppliedServiceProvider!.isNotEmpty) {
        filteredProviders = filteredProviders.where((provider) => 
          provider.serviceProvider == _localAppliedServiceProvider
        ).toList();
        print('🔧 After LOCAL service provider filter (${_localAppliedServiceProvider}): ${filteredProviders.length} providers');
      }
    }
    
    return filteredProviders;
  }



void _showLocationFilterDialog(BuildContext context) {
  final filterProvider = Provider.of<LocationFilterProvider>(context, listen: false);
  final screenHeight = MediaQuery.of(context).size.height;
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Add this to allow the bottom sheet to be scrollable
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20))
    ),
    builder: (context) => SafeArea(
      child: Container(
        height: screenHeight * 0.8, // Limit height to 80% of screen
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter by State', 
                  style: GoogleFonts.poppins(
                    fontSize: 20, 
                    fontWeight: FontWeight.w700, 
                    color: _primaryGreen
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close), 
                  onPressed: () => Navigator.pop(context)
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // All States option
            GestureDetector(
              onTap: () {
                print('📍 Services: Clearing filter - All States selected');
                
                filterProvider.clearLocationFilter();
                
                final serviceProvider = Provider.of<ServiceProviderProvider>(context, listen: false);
                serviceProvider.setSelectedState(null);
                
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _imageCache.clear();
                    });
                  }
                });
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Showing services from all states'),
                    backgroundColor: Color(0xFF006A4E),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.public, color: _primaryGreen),
                    const SizedBox(width: 15),
                    Text(
                      'All States', 
                      style: GoogleFonts.poppins(
                        fontSize: 16, 
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // States List - Make it flexible
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: CommunityStates.states.length,
                itemBuilder: (context, index) {
                  final state = CommunityStates.states[index];
                  final isSelected = filterProvider.selectedState == state;
                  
                  return GestureDetector(
                    onTap: () {
                      print('📍 Services: Setting filter to: $state');
                      
                      filterProvider.setLocationFilter(state, fromEvents: true);
                      
                      final serviceProvider = Provider.of<ServiceProviderProvider>(context, listen: false);
                      serviceProvider.setSelectedState(state);
                      
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _imageCache.clear();
                          });
                        }
                      });
                      
                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Showing services in $state'),
                          backgroundColor: _primaryGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? _primaryGreen.withOpacity(0.1) : null,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: isSelected ? _primaryGreen : Colors.grey),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              state,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? _primaryGreen : Colors.black87,
                              ),
                            ),
                          ),
                          if (isSelected) Icon(Icons.check_circle, color: _primaryGreen),
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


  @override
  Widget build(BuildContext context) {
    super.build(context);

    return LocationGuard(
      required: true, // Community Services require location selection
      showBackButton: false,
      child: _buildMainContent(context),
    );
  }

 
/*  Widget _buildMainContent(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    // Get auth state to conditionally show drawer
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isLoggedIn = authProvider.isLoggedIn && authProvider.user != null;
    
    return Consumer2<ServiceProviderProvider, LocationFilterProvider>(
      builder: (context, provider, locationProvider, _) {
        // FIX: Use WidgetsBinding to schedule the sync after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (provider.stateFilter != locationProvider.selectedState) {
            provider.syncWithLocationFilter(locationProvider);
          }
        });
        
        final allProviders = provider.serviceProviders;
        final filteredProviders = _getFilteredProviders(allProviders, locationProvider);
        
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(isTablet ? 160 : 130),
              child: Container(
                decoration: BoxDecoration(
                  gradient: _appBarGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20 : 16,
                      vertical: isTablet ? 12 : 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row with drawer button and title
                        Row(
                          children: [
                            if (isLoggedIn)
                              IconButton(
                                icon: Icon(
                                  Icons.menu_rounded,
                                  color: Colors.white,
                                  size: isTablet ? 28 : 24,
                                ),
                                onPressed: () => _openDrawer(context),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            Expanded(
                              child: Text(
                                'Community Services',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: isTablet ? 24 : 20,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: isLoggedIn ? 40 : 0), // Balance the layout
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Subtitle
                        Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 14 : 10,
                              vertical: isTablet ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  color: _goldAccent,
                                  size: isTablet ? 16 : 14,
                                ),
                                SizedBox(width: isTablet ? 6 : 4),
                                Text(
                                  'Find trusted professionals near you',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: isTablet ? 13 : 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: Container(
              decoration: const BoxDecoration(gradient: _premiumBgGradient),
              child: Stack(
                children: [
                  // Background overlay
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [Colors.white, _primaryGreen, _primaryRed],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Main Content
                  RefreshIndicator(
                    color: _goldAccent,
                    backgroundColor: Colors.white,
                    onRefresh: () async {
                      HapticFeedback.mediumImpact();
                      _imageCache.clear();
                      await provider.loadServiceProviders();
                    },
                    child: _isFilterView
                        ? _buildFiltersView(provider, isTablet)
                        : _buildMainView(provider, filteredProviders, locationProvider, isTablet),
                  ),
                  
                  // Animated Floating Action Button
                  Positioned(
                    bottom: isTablet ? 30 : 20,
                    right: isTablet ? 30 : 20,
                    child: _buildAnimatedSuggestButton(isTablet),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

*/

Widget _buildMainContent(BuildContext context) {
  final isTablet = MediaQuery.of(context).size.width >= 600;
  final screenHeight = MediaQuery.of(context).size.height;
  final isSmallScreen = screenHeight < 700;
  
  // Get auth state to conditionally show drawer
  final authProvider = Provider.of<AuthProvider>(context);
  final bool isLoggedIn = authProvider.isLoggedIn && authProvider.user != null;
  
  return Consumer2<ServiceProviderProvider, LocationFilterProvider>(
    builder: (context, provider, locationProvider, _) {
      // FIX: Use WidgetsBinding to schedule the sync after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (provider.stateFilter != locationProvider.selectedState) {
          provider.syncWithLocationFilter(locationProvider);
        }
      });
      
      final allProviders = provider.serviceProviders;
      final filteredProviders = _getFilteredProviders(allProviders, locationProvider);
      
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(isTablet ? 160 : 130),
            child: Container(
              decoration: BoxDecoration(
                gradient: _appBarGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 20 : 16,
                    vertical: isTablet ? 12 : 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row with drawer button, title, and logo
                      Row(
                        children: [
                          if (isLoggedIn)
                            IconButton(
                              icon: Icon(
                                Icons.menu_rounded,
                                color: Colors.white,
                                size: isTablet ? 28 : 24,
                              ),
                              onPressed: () => _openDrawer(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          // Title text
                          Expanded(
                            child: Text(
                              'Community Services',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: isTablet ? 22 : 18,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          // Bigger Logo on the right side with extra margin
                          Container(
                            margin: EdgeInsets.only(right: isTablet ? 16 : 12),
                            width: isTablet ? 50 : 42,
                            height: isTablet ? 50 : 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _goldAccent, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                                BoxShadow(
                                  color: _goldAccent.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/logo/logo.png',
                                width: isTablet ? 40 : 32,
                                height: isTablet ? 40 : 32,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.white.withOpacity(0.2),
                                    child: Center(
                                      child: Icon(
                                        Icons.handyman_rounded,
                                        color: Colors.white,
                                        size: isTablet ? 28 : 24,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Subtitle
                      Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 14 : 10,
                            vertical: isTablet ? 6 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: _goldAccent,
                                size: isTablet ? 16 : 14,
                              ),
                              SizedBox(width: isTablet ? 6 : 4),
                              Text(
                                'Find trusted professionals near you',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: isTablet ? 13 : 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(gradient: _premiumBgGradient),
            child: Stack(
              children: [
                // Background overlay
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [Colors.white, _primaryGreen, _primaryRed],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Main Content
                RefreshIndicator(
                  color: _goldAccent,
                  backgroundColor: Colors.white,
                  onRefresh: () async {
                    HapticFeedback.mediumImpact();
                    _imageCache.clear();
                    await provider.loadServiceProviders();
                  },
                  child: _isFilterView
                      ? _buildFiltersView(provider, isTablet)
                      : _buildMainView(provider, filteredProviders, locationProvider, isTablet),
                ),
                
                // Animated Floating Action Button
                Positioned(
                  bottom: isTablet ? 30 : 20,
                  right: isTablet ? 30 : 20,
                  child: _buildAnimatedSuggestButton(isTablet),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}


Widget _buildAnimatedSuggestButton(bool isTablet) {
  return ScaleTransition(
    scale: _pulseAnimation,
    child: Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF42A41), Color(0xFF006A4E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFF42A41),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Check if user is logged in
            if (FirebaseAuth.instance.currentUser == null) {
              _showLoginRequiredDialog(context, 'add a service');
            } else {
              // Navigate to AddServiceScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddServiceScreen(),
                ),
              ).then((_) {
                // Optional: Refresh the service list when returning from AddServiceScreen
                if (mounted) {
                  // You can add a refresh callback here if needed
                  // For example: _refreshServices();
                }
              });
            }
          },
          borderRadius: BorderRadius.circular(30),
          splashColor: Colors.white30,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 12 : 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RotationTransition(
                  turns: _rotateAnimation,
                  child: const Icon(
                    Icons.add_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                SizedBox(width: isTablet ? 8 : 6),
                Text(
                  'Add Service',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.white,
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
    // Initialize temp filters with current LOCAL applied values (NO STATE)
    _localTempSelectedCity ??= _localAppliedCity;
    _localTempSelectedCategory ??= _localAppliedCategory;
    _localTempSelectedServiceProvider ??= _localAppliedServiceProvider;
    
    return CustomScrollView(
      controller: _filterScrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: isTablet ? 180 : 150)), // Space for app bar
        
        // Add global location filter bar
        SliverToBoxAdapter(
          child: Consumer<LocationFilterProvider>(
            builder: (context, locationProvider, _) {
              return GlobalLocationFilterBar(
                isTablet: isTablet,
                onClearTap: () {
                  // This only clears GLOBAL filter
                  locationProvider.clearLocationFilter();
                },
              );
            },
          ),
        ),
        
        // Change Location Button (like Events screen)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12, vertical: 8),
            child: _buildChangeLocationButton(isTablet),
          ),
        ),
        
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.all(isTablet ? 20 : 16),
            child: _buildLocalFilterCard(provider, isTablet),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: isTablet ? 80 : 60)),
      ],
    );
  }

  // Change Location Button (similar to Events screen)
  Widget _buildChangeLocationButton(bool isTablet) {
    return Consumer<LocationFilterProvider>(
      builder: (context, filterProvider, child) {
        final hasFilter = filterProvider.isFilterActive;
        final selectedState = filterProvider.selectedState ?? '';
        
        return GestureDetector(
          onTap: () => _showLocationFilterDialog(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 14 : 10, vertical: isTablet ? 8 : 6),
            decoration: BoxDecoration(
              gradient: hasFilter
                  ? const LinearGradient(
                      colors: [Color(0xFF006A4E), Color(0xFF004D38)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: hasFilter 
                    ? const Color(0xFFFFD700).withOpacity(0.6)
                    : _goldAccent.withOpacity(0.4),
                width: 1,
              ),
              boxShadow: hasFilter
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasFilter ? Icons.edit_location_rounded : Icons.location_on_rounded,
                  size: isTablet ? 16 : 14,
                  color: hasFilter ? const Color(0xFFFFD700) : _goldAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  hasFilter ? "Change Location" : "Select Location",
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 12 : 11,
                    fontWeight: hasFilter ? FontWeight.w600 : FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                if (!hasFilter) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: isTablet ? 18 : 16,
                    color: _goldAccent,
                  ),
                ],
                if (hasFilter) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD700),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }




Widget _buildLocalFilterCard(ServiceProviderProvider provider, bool isTablet) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
      ],
    ),
    child: Padding(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryRed, _primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local Filters',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      'Apply screen-specific filters (State filter is global)',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 13 : 11,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // City Dropdown (uses GLOBAL state from LocationFilterProvider)
          Consumer<LocationFilterProvider>(
            builder: (context, locationProvider, _) {
              final globalState = locationProvider.selectedState;
              
              if (globalState == null) {
                return Container(
                  padding: EdgeInsets.all(isTablet ? 12 : 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: _primaryGreen, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Select a state from global filter first to see cities',
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 12 : 11,
                            color: _textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return FutureBuilder<List<String>>(
                future: provider.getCitiesForState(globalState),
                builder: (context, snapshot) {
                  final cities = snapshot.data ?? [];
                  if (cities.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      _buildDropdown<String?>(
                        value: _localTempSelectedCity,
                        label: 'City',
                        icon: Icons.location_city_rounded,
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('All Cities')),
                          ...cities.map((city) => 
                            DropdownMenuItem<String?>(value: city, child: Text(city))
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() => _localTempSelectedCity = newValue);
                        },
                      ),
                      if (_localTempSelectedCity != null) const SizedBox(height: 12),
                    ],
                  );
                },
              );
            },
          ),
          
          // Category Dropdown
          _buildDropdown<ServiceCategory?>(
            value: _localTempSelectedCategory,
            label: 'Category',
            icon: Icons.category_rounded,
            items: [
              const DropdownMenuItem<ServiceCategory?>(value: null, child: Text('All Categories')),
              ...ServiceCategory.values.map((category) => 
                DropdownMenuItem<ServiceCategory?>(
                  value: category,
                  child: Row(
                    children: [
                      Icon(category.icon, color: _primaryRed, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          category.displayName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                )
              ),
            ],
            onChanged: (ServiceCategory? newValue) {
              setState(() {
                _localTempSelectedCategory = newValue;
                _localTempSelectedServiceProvider = null;
              });
            },
          ),
          
          if (_localTempSelectedCategory != null) ...[
            const SizedBox(height: 12),
            _buildDropdown<String?>(
              value: _localTempSelectedServiceProvider,
              label: 'Service Type',
              icon: Icons.work_rounded,
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('All Types')),
                ..._localTempSelectedCategory!.serviceProviders.map((provider) => 
                  DropdownMenuItem<String?>(
                    value: provider,
                    child: Text(
                      provider,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  )
                ),
              ],
              onChanged: (String? newValue) {
                setState(() => _localTempSelectedServiceProvider = newValue);
              },
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Apply',
                  onTap: _applyLocalFilters,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  label: 'Clear',
                  onTap: _clearLocalFilters,
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Future<void> _applyLocalFilters() async {
    final provider = Provider.of<ServiceProviderProvider>(context, listen: false);
    
    // Build active filters map for display (NO STATE)
    Map<String, dynamic> newActiveFilters = {};
    
    // Apply new local filters (NO STATE)
    setState(() {
      _localAppliedCity = _localTempSelectedCity;
      _localAppliedCategory = _localTempSelectedCategory;
      _localAppliedServiceProvider = _localTempSelectedServiceProvider;
      
      if (_localAppliedCity != null && _localAppliedCity!.isNotEmpty) {
        newActiveFilters['local_city'] = _localAppliedCity;
      }
      if (_localAppliedCategory != null) {
        newActiveFilters['local_category'] = _localAppliedCategory!.displayName;
      }
      if (_localAppliedServiceProvider != null && _localAppliedServiceProvider!.isNotEmpty) {
        newActiveFilters['local_service'] = _localAppliedServiceProvider;
      }
      
      _hasLocalFilters = newActiveFilters.isNotEmpty;
      _activeLocalFilters = newActiveFilters;
      _isFilterView = false;
    });
    
    // Reload data with new local filters
    await provider.loadServiceProviders();
  }

 void _clearLocalFilters() {
  setState(() {
    _localTempSelectedCity = null;
    _localTempSelectedCategory = null;
    _localTempSelectedServiceProvider = null;
    _localAppliedCity = null;
    _localAppliedCategory = null;
    _localAppliedServiceProvider = null;
    _hasLocalFilters = false;
    _activeLocalFilters.clear();
    _isFilterView = false;
  });
  
  // Reload data without local filters
  final provider = Provider.of<ServiceProviderProvider>(context, listen: false);
  provider.loadServiceProviders();
}


  Widget _buildDropdown<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 12),
          prefixIcon: Icon(icon, color: _primaryGreen, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(colors: [_primaryGreen, _darkGreen])
              : const LinearGradient(colors: [Colors.white, Colors.white]),
          borderRadius: BorderRadius.circular(15),
          border: isPrimary ? null : Border.all(color: _primaryRed, width: 1.5),
          boxShadow: isPrimary
              ? [BoxShadow(color: _primaryGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isPrimary ? Colors.white : _primaryRed,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainView(
    ServiceProviderProvider provider,
    List<ServiceProviderModel> availableProviders,
    LocationFilterProvider locationProvider,
    bool isTablet,
  ) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: isTablet ? 180 : 150)), // Space for app bar
        
        // Add global location filter bar
        SliverToBoxAdapter(
          child: Consumer<LocationFilterProvider>(
            builder: (context, locationProvider, _) {
              return GlobalLocationFilterBar(
                isTablet: isTablet,
                onClearTap: () {
                  // This only clears GLOBAL filter
                  locationProvider.clearLocationFilter();
                },
              );
            },
          ),
        ),
        
        // Change Location Button (like Events screen)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12, vertical: 8),
            child: _buildChangeLocationButton(isTablet),
          ),
        ),
        
        // LOCAL Filter Toggle Button
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 12,
              vertical: 8,
            ),
            child: _buildLocalFilterToggleButton(isTablet),
          ),
        ),
        
        // Active LOCAL Filters Display
        _buildActiveLocalFilters(isTablet),
        
        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            child: _buildSearchField(provider, isTablet),
          ),
        ),

        // Category Row
        SliverToBoxAdapter(
          child: _buildCategoryRow(provider, isTablet),
        ),
      
        // Results Header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Services',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 12 : 8,
                    vertical: isTablet ? 4 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '${availableProviders.length}',
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
        ),

        // Content based on state
        if (provider.isLoading && availableProviders.isEmpty)
          _buildLoadingState(isTablet)
        else if (provider.error.isNotEmpty)
          _buildErrorState(isTablet, provider.error)
        else if (availableProviders.isEmpty && !provider.isLoading)
          _buildEmptyState(isTablet, provider, locationProvider)
        else
          _buildProvidersList(availableProviders, locationProvider, isTablet),
        
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
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 10 : 8,
        ),
        decoration: BoxDecoration(
          gradient: _hasLocalFilters
              ? const LinearGradient(colors: [_primaryRed, _primaryGreen])
              : const LinearGradient(colors: [_primaryGreen, _darkGreen]),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: (_hasLocalFilters ? _primaryRed : _primaryGreen).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _hasLocalFilters ? Icons.filter_alt_rounded : Icons.tune_rounded,
              color: Colors.white,
              size: isTablet ? 18 : 16,
            ),
            const SizedBox(width: 6),
            Text(
              _hasLocalFilters ? 'Edit Filters' : 'Filters',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_hasLocalFilters) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${_activeLocalFilters.length}',
                  style: GoogleFonts.poppins(
                    color: _primaryGreen,
                    fontSize: isTablet ? 10 : 8,
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
    if (_activeLocalFilters.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final filters = <Widget>[];
    
    _activeLocalFilters.forEach((key, value) {
      IconData icon = Icons.filter_alt_rounded;
      String label = value.toString();
      
      switch (key) {
        case 'local_city':
          icon = Icons.location_city_rounded;
          label = 'City: $value';
          break;
        case 'local_category':
          icon = Icons.category_rounded;
          label = 'Category: $value';
          break;
        case 'local_service':
          icon = Icons.work_rounded;
          label = 'Service: $value';
          break;
      }
      
      filters.add(_buildLocalFilterChip(
        label: label,
        icon: icon,
        onRemove: () {
          // Remove this specific local filter
          setState(() {
            switch (key) {
              case 'local_city':
                _localAppliedCity = null;
                _localTempSelectedCity = null;
                break;
              case 'local_category':
                _localAppliedCategory = null;
                _localTempSelectedCategory = null;
                _localAppliedServiceProvider = null;
                _localTempSelectedServiceProvider = null;
                break;
              case 'local_service':
                _localAppliedServiceProvider = null;
                _localTempSelectedServiceProvider = null;
                break;
            }
            _activeLocalFilters.remove(key);
            _hasLocalFilters = _activeLocalFilters.isNotEmpty;
          });
          
          // Reload data
          final provider = Provider.of<ServiceProviderProvider>(context, listen: false);
          provider.loadServiceProviders();
        },
      ));
    });

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12, vertical: 4),
        child: Wrap(spacing: 6, runSpacing: 6, children: filters),
      ),
    );
  }

  Widget _buildLocalFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_primaryGreen, _darkGreen]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, color: Colors.white, size: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ServiceProviderProvider provider, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(fontSize: isTablet ? 14 : 12),
        decoration: InputDecoration(
          hintText: 'Search services...',
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: isTablet ? 14 : 12),
          prefixIcon: Icon(Icons.search_rounded, color: _primaryGreen, size: isTablet ? 20 : 18),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    provider.setSearchQuery('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 12,
            vertical: isTablet ? 12 : 8,
          ),
        ),
        onChanged: (value) {
          _searchDebounce?.cancel();
          _searchDebounce = Timer(const Duration(milliseconds: 300), () {
            provider.setSearchQuery(value);
          });
        },
      ),
    );
  }

  Widget _buildCategoryRow(ServiceProviderProvider provider, bool isTablet) {
    return SizedBox(
      height: isTablet ? 40 : 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12),
        itemCount: ServiceCategory.values.length,
        itemBuilder: (context, index) {
          final category = ServiceCategory.values[index];
          final isSelected = provider.selectedCategory == category;
          
          return Padding(
            padding: EdgeInsets.only(right: isTablet ? 6 : 4),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                provider.setSelectedCategory(isSelected ? null : category);
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 12 : 8,
                  vertical: isTablet ? 6 : 4,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: [_primaryRed, _primaryGreen])
                      : null,
                  color: isSelected ? null : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                  border: isSelected ? null : Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    _getCategoryShortName(category),
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 12 : 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getCategoryShortName(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.accountantsAndTaxPreparers:
        return 'Tax';
      case ServiceCategory.legalServices:
        return 'Legal';
      case ServiceCategory.healthcareNeeds:
        return 'Health';
      case ServiceCategory.religious:
        return 'Religious';
      case ServiceCategory.halalGroceryStores:
        return 'Grocery';
      case ServiceCategory.halalDeshiRestaurants:
        return 'Restaurant';
      case ServiceCategory.realEstateAgents:
        return 'Real Estate';
      case ServiceCategory.handymanServices:
        return 'Handyman';
    }
  }

  Widget _buildProvidersList(
    List<ServiceProviderModel> providers,
    LocationFilterProvider locationProvider,
    bool isTablet,
  ) {
    final userId = Provider.of<AuthProvider>(context).user?.id;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return _buildProviderCard(providers[index], userId, locationProvider, isTablet, index);
        },
        childCount: providers.length,
      ),
    );
  }



Widget _buildProviderCard(
    ServiceProviderModel provider,
    String? userId,
    LocationFilterProvider locationProvider,
    bool isTablet,
    int index,
  ) {
    final categoryGradient = _getCategoryGradient(provider.serviceCategory);
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: 6,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.95, end: 1.0),
        duration: Duration(milliseconds: 200 + (index * 30)),
        curve: Curves.easeOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: GestureDetector(
              onTap: () {
                if (userId == null || userId.isEmpty) {
                  _showLoginRequiredDialog(context, 'view details');
                  return;
                }
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
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                  child: Stack(
                    children: [
                      // Premium Green Gradient Background (NO RED)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _primaryGreen,
                              _darkGreen,
                              const Color(0xFF2E7D32), // Darker green
                              const Color(0xFF1B5E20), // Even darker green
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Profile Image (Circle Avatar Only)
                                  Container(
                                    width: isTablet ? 70 : 60,
                                    height: isTablet ? 70 : 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: _buildProviderImage(provider),
                                  ),
                                  
                                  const SizedBox(width: 12),
                                  
                                  // Name and Company
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                provider.fullName,
                                                style: GoogleFonts.poppins(
                                                  fontSize: isTablet ? 18 : 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (provider.isVerified)
                                              Container(
                                                margin: const EdgeInsets.only(left: 4),
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  color: Colors.blue,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 10,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                  /*      Text(
                                          provider.companyName,
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 13 : 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),  */

                                        Text(
  provider.companyName ?? 'Not Provided', // ✅ Provide default value when null
  style: GoogleFonts.poppins(
    fontSize: isTablet ? 13 : 11,
    fontWeight: FontWeight.w500,
    color: Colors.white.withOpacity(0.9),
  ),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Location and Distance
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: _goldAccent,
                                    size: isTablet ? 16 : 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      provider.city ?? provider.state ?? 'Location',
                                      style: GoogleFonts.inter(
                                        fontSize: isTablet ? 13 : 11,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (provider.latitude != null && provider.longitude != null) ...[
                                    const Spacer(),
                                    DistanceBadge(
                                      latitude: provider.latitude!,
                                      longitude: provider.longitude!,
                                      isTablet: isTablet,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ],
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Category and Service Type
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      provider.serviceCategory.icon,
                                      color: _goldAccent,
                                      size: isTablet ? 16 : 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        provider.serviceProvider ?? 'Service',
                                        style: GoogleFonts.inter(
                                          fontSize: isTablet ? 12 : 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Contact Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildContactButton(
                                      icon: Icons.phone,
                                      label: 'Call',
                                      onTap: () {
                                        // Add phone call functionality
                                      },
                                      isTablet: isTablet,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildContactButton(
                                      icon: Icons.email,
                                      label: 'Email',
                                      onTap: () {
                                        // Add email functionality
                                      },
                                      isTablet: isTablet,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Like Button
                                  _buildCompactLikeButton(provider, userId, isTablet),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // View Details Button (Green gradient only)
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 10 : 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryGreen, _darkGreen],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: Text(
                                    'View Details',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isTablet ? 13 : 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }


  // Helper method for contact buttons


  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _goldAccent, size: isTablet ? 14 : 12),
            SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 11 : 9,
                fontWeight: FontWeight.w500,
                color: _goldAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated Like Button with proper 100+ formatting
  Widget _buildCompactLikeButton(ServiceProviderModel provider, String? userId, bool isTablet) {
    return Consumer<ServiceProviderProvider>(
      builder: (context, providerState, _) {
        final currentProvider = providerState.allProviders.firstWhere(
          (p) => p.id == provider.id,
          orElse: () => provider,
        );
        
        final isLiked = currentProvider.isLikedByUser(userId ?? '');
        final totalLikes = currentProvider.totalLikes;
        
        return GestureDetector(
          onTap: () {
            if (userId == null || userId.isEmpty) {
              _showLoginRequiredDialog(context, 'like');
              return;
            }
            HapticFeedback.lightImpact();
            providerState.toggleLike(provider.id!, userId);
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 10 : 8,
              vertical: isTablet ? 8 : 6,
            ),
            decoration: BoxDecoration(
              gradient: isLiked
                  ? LinearGradient(
                      colors: [_primaryRed, _coralRed],
                    )
                  : LinearGradient(
                      colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.1)],
                    ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isLiked ? Colors.transparent : Colors.white24,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.white : _goldAccent,
                  size: isTablet ? 14 : 12,
                ),
                if (totalLikes > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    _formatLikes(totalLikes),
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 11 : 10,
                      fontWeight: FontWeight.w600,
                      color: isLiked ? Colors.white : _goldAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Updated formatLikes to handle 100+ properly
  String _formatLikes(int count) {
    if (count < 1000) {
      return count.toString(); // Shows exact number for 0-999
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K'; // Shows 1.2K, 45.6K, etc.
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M'; // Shows 1.2M, 3.4M, etc.
    }
  }

  // Helper method to get gradient based on category
  LinearGradient _getCategoryGradient(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.accountantsAndTaxPreparers:
        return const LinearGradient(colors: [Color(0xFF3498DB), Color(0xFF2980B9)]);
      case ServiceCategory.legalServices:
        return const LinearGradient(colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)]);
      case ServiceCategory.healthcareNeeds:
        return const LinearGradient(colors: [Color(0xFF2ECC71), Color(0xFF27AE60)]);
      case ServiceCategory.religious:
        return const LinearGradient(colors: [Color(0xFFF1C40F), Color(0xFFF39C12)]);
      case ServiceCategory.halalGroceryStores:
        return const LinearGradient(colors: [Color(0xFFE67E22), Color(0xFFD35400)]);
      case ServiceCategory.halalDeshiRestaurants:
        return const LinearGradient(colors: [Color(0xFFE74C3C), Color(0xFFC0392B)]);
      case ServiceCategory.realEstateAgents:
        return const LinearGradient(colors: [Color(0xFF1ABC9C), Color(0xFF16A085)]);
      case ServiceCategory.handymanServices:
        return const LinearGradient(colors: [Color(0xFF95A5A6), Color(0xFF7F8C8D)]);
    }
  }

  Widget _buildLoadingState(bool isTablet) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: isTablet ? 50 : 40,
              height: isTablet ? 50 : 40,
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading services...',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isTablet, String error) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: isTablet ? 60 : 50),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.8),
                fontSize: isTablet ? 13 : 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isTablet, ServiceProviderProvider provider, LocationFilterProvider locationProvider) {
    String emptyMessage = 'No services found';
    if (locationProvider.isFilterActive && _hasLocalFilters) {
      emptyMessage = 'No services in ${locationProvider.selectedState} with your filters';
    } else if (locationProvider.isFilterActive) {
      emptyMessage = 'No services in ${locationProvider.selectedState}';
    } else if (_hasLocalFilters) {
      emptyMessage = 'No services match your filters';
    }
    
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: Colors.white, size: isTablet ? 70 : 60),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.8),
                fontSize: isTablet ? 14 : 12,
              ),
            ),
            if (provider.hasActiveFilters || locationProvider.isFilterActive || _hasLocalFilters) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (provider.hasActiveFilters)
                    _buildClearButton('Clear Search', () {
                      provider.clearFilters();
                      _searchController.clear();
                    }, isTablet),
                  if (locationProvider.isFilterActive)
                    _buildClearButton('Clear State', () {
                      locationProvider.clearLocationFilter();
                    }, isTablet),
                  if (_hasLocalFilters)
                    _buildClearButton('Clear Filters', _clearLocalFilters, isTablet),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClearButton(String label, VoidCallback onTap, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 12 : 8,
            vertical: isTablet ? 6 : 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: isTablet ? 11 : 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
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

  




}

// Helper class for states list
class CommunityStates {
  static const List<String> states = [
    'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
    'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho',
    'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
    'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
    'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada',
    'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
    'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon',
    'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
    'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
    'West Virginia', 'Wisconsin', 'Wyoming'
  ];
}