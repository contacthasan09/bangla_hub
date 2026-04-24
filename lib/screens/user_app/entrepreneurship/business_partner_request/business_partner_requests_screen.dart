
import 'dart:convert';
import 'dart:ui';

import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';
import 'package:bangla_hub/providers/location_filter_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/auth/signup_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/business_partner_request/partner_request_details_screen.dart';
import 'package:bangla_hub/widgets/common/distance_widget.dart';
import 'package:bangla_hub/widgets/common/global_location_filter_bar.dart';
import 'package:bangla_hub/widgets/common/global_location_guard.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BusinessPartnerRequestsScreen extends StatefulWidget {
  @override
  _BusinessPartnerRequestsScreenState createState() => _BusinessPartnerRequestsScreenState();
}

class _BusinessPartnerRequestsScreenState extends State<BusinessPartnerRequestsScreen> 
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin, WidgetsBindingObserver {
  
  // Premium Color Palette - Soft Green Accent Theme
  final Color _softGreen = Color(0xFF98D8C8);
  final Color _lightGreen = Color(0xFFE0F2F1);
  final Color _lightGreenBg = Color(0x80E0F2F1);
  final Color _darkGreen = Color(0xFF2E7D32);
  final Color _deepGreen = Color(0xFF1B5E20);
  
  final Color _primaryGreen = Color(0xFF2E7D32);
  final Color _secondaryGold = Color(0xFFFFB300);
  final Color _softGold = Color(0xFFFFD966);
  
  final Color _textPrimary = Color(0xFF1A2B3C);
  final Color _textSecondary = Color(0xFF5D6D7E);
  final Color _borderLight = Color(0xFFE0E7E9);
  final Color _shadowColor = Color(0x1A000000);
  
  final LinearGradient _bodyBgGradient = LinearGradient(
    colors: [
      Color(0xFFE0F2F1),
      Color(0xFFE8F5E9),
      Color(0xFFF1F8E9),
      Color(0xFFF9FBE7),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.4, 0.7, 1.0],
  );

  final LinearGradient _appBarGradient = LinearGradient(
    colors: [
      Color(0xFF2E7D32),
      Color(0xFF1B5E20),
      Color(0xFF98D8C8),
      Color(0xFF81C784),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.4, 0.7, 1.0],
  );

  final LinearGradient _preciousGradient = LinearGradient(
    colors: [
      Color(0xFFFFB300),
      Color(0xFF2E7D32),
      Color(0xFF98D8C8),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _gemstoneGradient = LinearGradient(
    colors: [
      Color(0xFF2E7D32),
      Color(0xFF98D8C8),
      Color(0xFFFFB300),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _royalGradient = LinearGradient(
    colors: [
      Color(0xFF2E7D32),
      Color(0xFFFFB300),
      Color(0xFF98D8C8),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _greenGradient = LinearGradient(
    colors: [
      Color(0xFF2E7D32),
      Color(0xFF98D8C8),
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
  
  late List<AnimationController> _particleControllers;
  late List<AnimationController> _bubbleControllers;

  // LOCAL FILTER STATE - NO STATE, NO CITY (removed)
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
    
    if (_appLifecycleState == AppLifecycleState.resumed) {
      _startAnimations();
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      
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
      _startAnimations();
    } else {
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    
    for (var controller in _particleControllers) {
      controller.dispose();
    }
    
    for (var controller in _bubbleControllers) {
      controller.dispose();
    }
    
    _filterScrollController.dispose();
    super.dispose();
  }

  // Helper function to check if string is a URL
  bool _isUrlString(String str) {
    return str.startsWith('http://') || str.startsWith('https://');
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
      
      if (_hasLocalFilters) {
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

  void _showLocationFilterDialog(BuildContext context) {
    final filterProvider = Provider.of<LocationFilterProvider>(context, listen: false);
    final screenHeight = MediaQuery.of(context).size.height;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (context) => SafeArea(
        child: Container(
          height: screenHeight * 0.8,
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
              
              GestureDetector(
                onTap: () {
                  filterProvider.clearLocationFilter();
                  _loadData();
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Showing requests from all states'),
                      backgroundColor: Color(0xFF2E7D32),
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
              
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: CommunityStates.states.length,
                  itemBuilder: (context, index) {
                    final state = CommunityStates.states[index];
                    final isSelected = filterProvider.selectedState == state;
                    
                    return GestureDetector(
                      onTap: () {
                        filterProvider.setLocationFilter(state, fromEvents: true);
                        _loadData();
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Showing requests in $state'),
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

  Widget _buildChangeLocationButton(bool isTablet) {
    return Consumer<LocationFilterProvider>(
      builder: (context, filterProvider, child) {
        final hasFilter = filterProvider.isFilterActive;
        
        return GestureDetector(
          onTap: () => _showLocationFilterDialog(context),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 12 : 10,
              vertical: isTablet ? 6 : 4,
            ),
            decoration: BoxDecoration(
              gradient: hasFilter
                  ? const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasFilter 
                    ? const Color(0xFFFFB300).withOpacity(0.5)
                    : _secondaryGold.withOpacity(0.4),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasFilter ? Icons.edit_location_rounded : Icons.location_on_rounded,
                  size: isTablet ? 14 : 12,
                  color: hasFilter ? const Color(0xFFFFB300) : _secondaryGold,
                ),
                const SizedBox(width: 4),
                Text(
                  hasFilter ? "Change Location" : "Select Location",
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 11 : 10,
                    fontWeight: hasFilter ? FontWeight.w600 : FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                if (hasFilter) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFB300),
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

  Future<void> _applyLocalFilters() async {
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    provider.clearAllFilters(EntrepreneurshipCategory.lookingForBusinessPartner);
    
    Map<String, dynamic> newActiveFilters = {};
    
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
    
    provider.clearAllFilters(EntrepreneurshipCategory.lookingForBusinessPartner);
    
    setState(() {
      _localSelectedPartnerType = null;
      _localSelectedBusinessType = null;
      _localSelectedIndustry = null;
      _hasLocalFilters = false;
      _activeLocalFilters.clear();
      _isFilterView = false;
    });
    
    provider.loadPartnerRequests();
  }

  List<BusinessPartnerRequest> _getFilteredRequests(
    List<BusinessPartnerRequest> requests,
    LocationFilterProvider locationProvider,
  ) {
    var filteredRequests = requests.where((r) => 
      r.isVerified && r.isActive && !r.isDeleted
    ).toList();
    
    if (locationProvider.isFilterActive && locationProvider.selectedState != null) {
      filteredRequests = filteredRequests.where((request) {
        return request.state == locationProvider.selectedState;
      }).toList();
    }
    
    if (_hasLocalFilters) {
      if (_localSelectedPartnerType != null) {
        filteredRequests = filteredRequests.where((request) => 
          request.partnerType == _localSelectedPartnerType
        ).toList();
      }
      if (_localSelectedBusinessType != null) {
        filteredRequests = filteredRequests.where((request) => 
          request.businessType == _localSelectedBusinessType
        ).toList();
      }
      if (_localSelectedIndustry != null && _localSelectedIndustry!.isNotEmpty) {
        filteredRequests = filteredRequests.where((request) => 
          request.industry?.toLowerCase().contains(_localSelectedIndustry!.toLowerCase()) ?? false
        ).toList();
      }
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
  Widget build(BuildContext context) {
    super.build(context);

    return LocationGuard(
      required: true, 
      showBackButton: true,
      child: _buildMainContent(context),
    );
  }

  Widget _buildMainContent(BuildContext context) {
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
              ...List.generate(30, (index) => _buildAnimatedParticle(index)),
              ...List.generate(8, (index) => _buildFloatingBubble(index)),
              
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
                          
                          // Global Location Filter Bar
                          SliverToBoxAdapter(
                            child: Consumer<LocationFilterProvider>(
                              builder: (context, locationProvider, _) {
                                return GlobalLocationFilterBar(
                                  isTablet: isTablet,
                                  onClearTap: () {
                                    locationProvider.clearLocationFilter();
                                    _loadData();
                                  },
                                );
                              },
                            ),
                          ),
                          
                          // Local Filter Toggle Button
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
        
        // Global Location Filter Bar
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
                                  'Local Filters',
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 24 : 20,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                  ),
                                ),
                                Text(
                                  'Apply screen-specific filters (State/City are global)',
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
              _hasLocalFilters ? 'Edit Local Filters' : 'Local Filters',
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
            final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
            provider.clearFilter(EntrepreneurshipCategory.lookingForBusinessPartner, key);
            
            setState(() {
              _activeLocalFilters.remove(key);
              _hasLocalFilters = _activeLocalFilters.isNotEmpty;
              
              switch (key) {
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
                'Active Local Filters:',
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

/*  SliverAppBar _buildPremiumAppBar(bool isTablet) {
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
                  
                  // Title - Single line only
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.white, _secondaryGold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'Find Business Partner',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 32 : 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  SizedBox(height: isTablet ? 12 : 8),
                  
                  // Subtitle and Change Location Button in same row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '🤝 Connect with Potential Business Partners',
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 14 : 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      SizedBox(width: isTablet ? 12 : 8),
                      
                      _buildChangeLocationButton(isTablet),
                    ],
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
                                    fontSize: isTablet ? 12 : 10,
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

*/

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
                
                // Title - Single line only
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.white, _secondaryGold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'Find Business Partner',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 32 : 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                SizedBox(height: isTablet ? 12 : 8),
                
                // Subtitle and Change Location Button in same row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '🤝 Connect with Potential Business Partners',
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 14 : 12,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    SizedBox(width: isTablet ? 12 : 8),
                    
                    _buildChangeLocationButton(isTablet),
                  ],
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
                                  fontSize: isTablet ? 12 : 10,
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
    // ✅ Back button on LEFT side
    leading: IconButton(
      icon: Icon(
        Icons.arrow_back_rounded, 
        color: Colors.white, 
        size: isTablet ? 28 : 24,
      ),
      onPressed: () => Navigator.pop(context),
      padding: EdgeInsets.only(left: isTablet ? 16 : 12),
    ),
    // ✅ Logo as Circle Avatar on RIGHT side with controlled spacing
    actions: [
      Padding(
        padding: EdgeInsets.only(right: isTablet ? 40 : 24), // Controlled right spacing
        child: Container(
          width: isTablet ? 44 : 36,
          height: isTablet ? 44 : 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
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
                      Icons.business_center_rounded,
                      color: Colors.white,
                      size: isTablet ? 24 : 20,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ],
    title: null,
    centerTitle: false,
    automaticallyImplyLeading: true,
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(LocationFilterProvider locationProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
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

  // UPDATED: Build requester poster image with URL and Base64 support
  Widget _buildRequesterPosterImage(BusinessPartnerRequest request) {
    final imageData = request.postedByProfileImageBase64;
    
    if (imageData != null && imageData.isNotEmpty) {
      // Check if it's a URL
      if (_isUrlString(imageData)) {
        return ClipOval(
          child: Image.network(
            imageData,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading requester image: $error');
              return _buildDefaultProfileImage();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_secondaryGold),
                ),
              );
            },
          ),
        );
      } else {
        // It's Base64 data
        try {
          String base64String = imageData;
          
          if (base64String.contains('base64,')) {
            base64String = base64String.split('base64,').last;
          }
          
          base64String = base64String.replaceAll(RegExp(r'\s'), '');
          
          while (base64String.length % 4 != 0) {
            base64String += '=';
          }
          
          final bytes = base64Decode(base64String);
          return ClipOval(
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                print('Error decoding requester image: $error');
                return _buildDefaultProfileImage();
              },
            ),
          );
        } catch (e) {
          print('Error processing requester image: $e');
          return _buildDefaultProfileImage();
        }
      }
    }
    
    return _buildDefaultProfileImage();
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

 /* Widget _buildPremiumRequestCard(BusinessPartnerRequest request, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    Widget cardContent = Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: Offset(0, 5),
            spreadRadius: -1,
          ),
          BoxShadow(
            color: _primaryGreen.withOpacity(0.25),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.white,
                _lightGreen.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: _secondaryGold.withOpacity(0.25),
              width: 1,
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
              borderRadius: BorderRadius.circular(20),
              splashColor: _secondaryGold.withOpacity(0.15),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 14 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info Row - Compact
                    Row(
                      children: [
                        Container(
                          width: isTablet ? 44 : 38,
                          height: isTablet ? 44 : 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _royalGradient,
                            border: Border.all(
                              color: _secondaryGold,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _secondaryGold.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(1.5),
                            child: ClipOval(
                              child: _buildRequesterPosterImage(request),
                            ),
                          ),
                        ),
                        
                        SizedBox(width: 10),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.postedByName ?? 'Business Seeker',
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 14 : 13,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: _secondaryGold,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Looking for Partner',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      color: _secondaryGold,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        if (request.isVerified)
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              gradient: _preciousGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.verified_rounded, 
                              color: Colors.white, 
                              size: isTablet ? 14 : 12,
                            ),
                          ),
                      ],
                    ),
                    
                    SizedBox(height: 10),
                    
                    // Partner Type and Business Type - Compact
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            request.partnerType.displayName,
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w800,
                              color: _primaryGreen,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        if (request.isUrgent)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryGreen, _darkGreen],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'URGENT',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    SizedBox(height: 6),
                    
                    // Business Type Badge - Compact
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: _greenGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        request.businessType.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 11 : 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 10),
                    
                    // Tags - Compact
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildCompactTag(request.city, Icons.location_on_rounded, isTablet),
                        if (request.industry != null && request.industry!.isNotEmpty && request.industry != 'Not specified')
                          _buildCompactTag(request.industry!, Icons.category_rounded, isTablet),
                      ],
                    ),
                    
                    // Distance Badge - Compact
                    if (request.latitude != null && request.longitude != null)
                      Consumer<LocationFilterProvider>(
                        builder: (context, locationProvider, _) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: DistanceBadge(
                              latitude: request.latitude!,
                              longitude: request.longitude!,
                              isTablet: isTablet,
                            ),
                          );
                        },
                      ),
                    
                    SizedBox(height: 8),
                    
                    // Budget and Duration Row - Compact
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryGreen.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Budget',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    color: _primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '\$${request.budgetMin.toStringAsFixed(0)}-\$${request.budgetMax.toStringAsFixed(0)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 11 : 10,
                                    fontWeight: FontWeight.w700,
                                    color: _primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _softGreen.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Duration',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    color: _primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  request.investmentDuration,
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 10 : 9,
                                    fontWeight: FontWeight.w600,
                                    color: _primaryGreen,
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
                    
                    SizedBox(height: 10),
                    
                    // View Details Button - Compact
                    GestureDetector(
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
                          vertical: isTablet ? 8 : 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: _royalGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryGreen.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
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
                                fontSize: isTablet ? 12 : 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: isTablet ? 14 : 12,
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
      ),
    );
    
    if (shouldAnimate) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 400 + (index * 80)),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          final clampedValue = value.clamp(0.0, 1.0);
          return Transform.scale(
            scale: 0.96 + (0.04 * clampedValue),
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

*/

  // Compact Tag
/*  Widget _buildCompactTag(String text, IconData icon, [bool isTablet = false]) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 8 : 6,
        vertical: isTablet ? 4 : 3,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _secondaryGold.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isTablet ? 10 : 9, color: _secondaryGold),
          SizedBox(width: isTablet ? 4 : 3),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: _textSecondary,
              fontSize: isTablet ? 10 : 9,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

*/


Widget _buildPremiumRequestCard(BusinessPartnerRequest request, int index) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isTablet = screenWidth >= 600;
  final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
  
  // Same margin as original
  final horizontalMargin = isTablet ? 16.0 : 12.0;
  
  // Premium gradient - Green to Teal
  final LinearGradient _cardGradient = LinearGradient(
    colors: [
      Color(0xFF1B5E20), // Deep Forest Green
      Color(0xFF2E7D32), // Dark Green
      Color(0xFF388E3C), // Medium Green
      Color(0xFF43A047), // Vibrant Green
      Color(0xFF4CAF50), // Classic Green
      Color(0xFF66BB6A), // Light Green
      Color(0xFF00897B), // Teal Green
      Color(0xFF00796B), // Deep Teal
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.12, 0.25, 0.38, 0.5, 0.62, 0.75, 1.0],
  );
  
  Widget cardContent = Container(
    margin: EdgeInsets.symmetric(
      horizontal: horizontalMargin,
      vertical: 6,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 15,
          offset: Offset(0, 5),
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Color(0xFF2E7D32).withOpacity(0.3),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: _cardGradient,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 0.5,
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
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.white.withOpacity(0.15),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 14 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Row - Compact
                  Row(
                    children: [
                      Container(
                        width: isTablet ? 44 : 38,
                        height: isTablet ? 44 : 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF66BB6A).withOpacity(0.4),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(1.5),
                          child: ClipOval(
                            child: _buildRequesterPosterImage(request),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 10),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.postedByName ?? 'Business Seeker',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 14 : 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFA5D6A7),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Looking for Partner',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: Color(0xFFA5D6A7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      if (request.isVerified)
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: shouldAnimate
                              ? RotationTransition(
                                  turns: _rotateController,
                                  child: Icon(
                                    Icons.verified_rounded, 
                                    color: Colors.white, 
                                    size: isTablet ? 14 : 12,
                                  ),
                                )
                              : Icon(
                                  Icons.verified_rounded, 
                                  color: Colors.white, 
                                  size: isTablet ? 14 : 12,
                                ),
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 10),
                  
                  // Partner Type and Business Type - Compact
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          request.partnerType.displayName,
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      if (request.isUrgent)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'URGENT',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 6),
                  
                  // Business Type Badge - Compact
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      request.businessType.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 11 : 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 10),
                  
                  // Tags - Compact
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildPremiumCompactTag(request.city, Icons.location_on_rounded, isTablet),
                      if (request.industry != null && request.industry!.isNotEmpty && request.industry != 'Not specified')
                        _buildPremiumCompactTag(request.industry!, Icons.category_rounded, isTablet),
                    ],
                  ),
                  
                  // Distance Badge - Compact
                  if (request.latitude != null && request.longitude != null)
                    Consumer<LocationFilterProvider>(
                      builder: (context, locationProvider, _) {
                        return Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: DistanceBadge(
                            latitude: request.latitude!,
                            longitude: request.longitude!,
                            isTablet: isTablet,
                          ),
                        );
                      },
                    ),
                  
                  SizedBox(height: 8),
                  
                  // Budget and Duration Row - Compact
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Budget',
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: Color(0xFFA5D6A7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '\$${request.budgetMin.toStringAsFixed(0)}-\$${request.budgetMax.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 11 : 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Duration',
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: Color(0xFFA5D6A7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                request.investmentDuration,
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 10 : 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
                  
                  SizedBox(height: 10),
                  
                  // View Details Button - Compact
                  GestureDetector(
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
                        vertical: isTablet ? 8 : 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'View Details',
                            style: GoogleFonts.poppins(
                              color: Color(0xFF2E7D32),
                              fontSize: isTablet ? 12 : 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 6),
                          shouldAnimate
                              ? RotationTransition(
                                  turns: _rotateController,
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Color(0xFF2E7D32),
                                    size: isTablet ? 14 : 12,
                                  ),
                                )
                              : Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF2E7D32),
                                  size: isTablet ? 14 : 12,
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
    ),
  );
  
  if (shouldAnimate) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 80)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final clampedValue = value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.96 + (0.04 * clampedValue),
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

Widget _buildPremiumCompactTag(String text, IconData icon, [bool isTablet = false]) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: isTablet ? 8 : 6,
      vertical: isTablet ? 4 : 3,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.white.withOpacity(0.25),
        width: 0.5,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: isTablet ? 10 : 9, color: Colors.white),
        SizedBox(width: isTablet ? 4 : 3),
        Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: isTablet ? 10 : 9,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}







  void _showRequestDetails(BusinessPartnerRequest request) async {
    HapticFeedback.mediumImpact();
    
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    await provider.incrementViewCount(EntrepreneurshipCategory.lookingForBusinessPartner, request.id!);
    
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

class _AddPartnerRequestDialogState extends State<AddPartnerRequestDialog> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
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
  
  // Location picking for partner request
  double? _partnerLatitude;
  double? _partnerLongitude;
  String? _partnerFullAddress;

  final List<String> _states = CommunityStates.states;
  
  late TabController _tabController;
  late AnimationController _animationController;
  
  // Track keyboard and lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  bool _isKeyboardVisible = false;
  
  // Track completed tabs
  bool _isBasicInfoValid = false;
  bool _isDetailsValid = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    
    _setupKeyboardListeners();
    
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
  
  void _setupKeyboardListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.addListener(() {
        final hasFocus = FocusManager.instance.primaryFocus != null;
        if (mounted && _isKeyboardVisible != hasFocus) {
          setState(() {
            _isKeyboardVisible = hasFocus;
          });
          if (hasFocus) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted && widget.scrollController.hasClients) {
                widget.scrollController.animateTo(
                  widget.scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        }
      });
    });
  }
  
  void _handleTabChange() {
    if (mounted) {
      setState(() {});
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });
  }

  void _validateBasicInfo() {
    if (mounted) {
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
            _partnerLatitude != null &&
            _partnerLongitude != null;
      });
    }
  }

  void _validateDetails() {
    if (mounted) {
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
  }

  bool get _isSubmitEnabled => _isBasicInfoValid && _isDetailsValid;

  void _goToPreviousTab() {
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _goToNextTab() {
    if (_tabController.index < 1) {
      if (_tabController.index == 0 && !_isBasicInfoValid) {
        _showErrorSnackBar('Please complete all required fields including location');
        return;
      }
      _tabController.animateTo(_tabController.index + 1);
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
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
    
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    
    return Container(
      height: screenHeight * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Premium Header
          Container(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
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
                  padding: EdgeInsets.all(isTablet ? 12 : 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person_add_rounded, color: widget.secondaryGold, size: isTablet ? 28 : 22),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find a Business Partner',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Describe what you\'re looking for',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: isTablet ? 13 : 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: isTablet ? 24 : 20,
                ),
              ],
            ),
          ),
          
          // Premium Tab Indicators
          Container(
            margin: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: 16),
            height: isTablet ? 60 : 50,
            child: Row(
              children: [
                _buildPremiumTabIndicator(0, 'Basic Info', _isBasicInfoValid, isTablet),
                _buildPremiumTabConnector(_isBasicInfoValid, isTablet),
                _buildPremiumTabIndicator(1, 'Details', _isDetailsValid, isTablet),
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
                  _buildPremiumBasicInfoTab(isTablet),
                  _buildPremiumDetailsTab(isTablet),
                ],
              ),
            ),
          ),
          
          // Navigation Buttons
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
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
                      isTablet: isTablet,
                    ),
                  ),
                if (_tabController.index > 0) const SizedBox(width: 12),
                Expanded(
                  child: _tabController.index < 1
                      ? _buildPremiumNavButton(
                          label: 'Next',
                          onPressed: _goToNextTab,
                          isPrimary: true,
                          isTablet: isTablet,
                        )
                      : _buildPremiumSubmitButton(isTablet),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
Widget _buildPremiumTabIndicator(int index, String label, bool isValid, bool isTablet) {
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
      child: Container(  // Fixed: Removed the comma and added opening parenthesis
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
              width: isTablet ? 24 : 20,
              height: isTablet ? 24 : 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isValid ? widget.primaryGreen : (isSelected ? Colors.white : Colors.grey[400]),
              ),
              child: isValid
                  ? Icon(Icons.check, color: Colors.white, size: isTablet ? 14 : 12)
                  : Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isSelected ? widget.primaryGreen : Colors.white,
                          fontSize: isTablet ? 12 : 10,
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
                fontSize: isTablet ? 10 : 9,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildPremiumTabConnector(bool isCompleted, bool isTablet) {
    return Container(
      width: isTablet ? 20 : 12,
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
    required bool isTablet,
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
                fontSize: isTablet ? 15 : 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumSubmitButton(bool isTablet) {
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
                fontSize: isTablet ? 15 : 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Location Picker Field
  Widget _buildLocationPickerField(StateSetter setState, bool isTablet) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => GoogleMapsLocationPicker(
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

  Widget _buildPremiumBasicInfoTab(bool isTablet) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.only(
        left: isTablet ? 24 : 16,
        right: isTablet ? 24 : 16,
        top: isTablet ? 24 : 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
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
          
          _buildPremiumSectionHeader('Partner Information', Icons.people_rounded, isTablet),
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
            isTablet: isTablet,
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
            isTablet: isTablet,
          ),
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _industryController,
            label: 'Industry (Optional)',
            icon: Icons.category_rounded,
            isRequired: false,
            isTablet: isTablet,
          ),
          
          const SizedBox(height: 20),
          
          _buildPremiumSectionHeader('Location', Icons.location_on_rounded, isTablet),
          const SizedBox(height: 16),
          
          // Location picker
          StatefulBuilder(
            builder: (context, setState) {
              return _buildLocationPickerField(setState, isTablet);
            },
          ),
          const SizedBox(height: 12),
          
          const SizedBox(height: 20),
          
          _buildPremiumSectionHeader('Contact Information', Icons.contact_phone_rounded, isTablet),
          const SizedBox(height: 16),
          
          _buildPremiumTextField(
            controller: _contactNameController,
            label: 'Your Name *',
            icon: Icons.person_rounded,
            isRequired: true,
            isTablet: isTablet,
          ),
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _contactEmailController,
            label: 'Your Email *',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            isRequired: true,
            isTablet: isTablet,
          ),
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _contactPhoneController,
            label: 'Your Phone *',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            isRequired: true,
            isTablet: isTablet,
          ),
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _preferredMeetingController,
            label: 'Preferred Meeting Method (Optional)',
            icon: Icons.video_call_rounded,
            isRequired: false,
            isTablet: isTablet,
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

  Widget _buildPremiumDetailsTab(bool isTablet) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.only(
        left: isTablet ? 24 : 16,
        right: isTablet ? 24 : 16,
        top: isTablet ? 24 : 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumSectionHeader('Description', Icons.description_rounded, isTablet),
          const SizedBox(height: 16),
          
          _buildPremiumTextField(
            controller: _descriptionController,
            label: 'Description *',
            icon: Icons.description_rounded,
            maxLines: 4,
            isRequired: true,
            isTablet: isTablet,
          ),
          
          const SizedBox(height: 24),
          
          _buildPremiumSectionHeader('Budget & Duration', Icons.attach_money_rounded, isTablet),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildPremiumTextField(
                  controller: _budgetMinController,
                  label: 'Min Budget *',
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                  isTablet: isTablet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPremiumTextField(
                  controller: _budgetMaxController,
                  label: 'Max Budget *',
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                  isTablet: isTablet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _investmentDurationController,
            label: 'Investment Duration *',
            icon: Icons.schedule_rounded,
            isRequired: true,
            isTablet: isTablet,
          ),
          
          const SizedBox(height: 24),
          
          _buildPremiumSectionHeader('Skills Required *', Icons.code_rounded, isTablet),
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
            isTablet: isTablet,
          ),
          
          const SizedBox(height: 24),
          
          _buildPremiumSectionHeader('Responsibilities *', Icons.task_rounded, isTablet),
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
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSectionHeader(String title, IconData icon, bool isTablet) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 8 : 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.primaryGreen, widget.secondaryGold],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: isTablet ? 18 : 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: widget.primaryGreen,
          ),
        ),
      ],
    );
  }


 /* Widget _buildPremiumTextField({
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
      textInputAction: maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
      style: GoogleFonts.inter(
        fontSize: isTablet ? 16 : 14,
        color: Colors.grey[800],
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: isTablet ? 13 : 12),
        prefixIcon: Icon(icon, color: widget.primaryGreen, size: isTablet ? 20 : 18),
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
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 14,
          vertical: maxLines > 1 ? (isTablet ? 16 : 14) : (isTablet ? 14 : 12),
        ),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Required';
        }
        return null;
      },
    );
  }

 */

Widget _buildPremiumTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
  required bool isRequired,
  required bool isTablet,
}) {
  // ✅ Fix: For multiline fields, use multiline keyboard type
  final bool isMultiline = maxLines > 1;
  final TextInputType effectiveKeyboardType = isMultiline 
      ? TextInputType.multiline 
      : keyboardType;
  
  return TextFormField(
    controller: controller,
    keyboardType: effectiveKeyboardType, // ✅ Fixed: Use multiline for multiline fields
    maxLines: maxLines,
    textInputAction: maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
    style: GoogleFonts.inter(
      fontSize: isTablet ? 16 : 14,
      color: Colors.grey[800],
      fontWeight: FontWeight.w500,
    ),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: isTablet ? 13 : 12),
      prefixIcon: Icon(icon, color: widget.primaryGreen, size: isTablet ? 20 : 18),
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
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 14,
        vertical: maxLines > 1 ? (isTablet ? 16 : 14) : (isTablet ? 14 : 12),
      ),
    ),
    validator: (value) {
      if (isRequired && (value == null || value.isEmpty)) {
        return 'Required';
      }
      return null;
    },
  );
}
 
 
  Widget _buildPremiumDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required IconData icon,
    required bool isTablet,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: isTablet ? 13 : 12),
        prefixIcon: Icon(icon, color: widget.primaryGreen, size: isTablet ? 20 : 18),
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
        contentPadding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 14, vertical: 6),
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
    );
  }

  Widget _buildPremiumTagInput({
    required TextEditingController controller,
    required List<String> tags,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    String hint = 'Add item',
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
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onAdd(),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: isTablet ? 13 : 12),
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16 : 14,
                    vertical: isTablet ? 14 : 12,
                  ),
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
                padding: EdgeInsets.all(isTablet ? 12 : 10),
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
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 14 : 12,
                  vertical: isTablet ? 8 : 6,
                ),
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
                        fontSize: isTablet ? 12 : 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => onRemove(index),
                      child: Icon(
                        Icons.close_rounded,
                        color: widget.accentRed,
                        size: isTablet ? 16 : 14,
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
      
      // Location coordinates
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

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
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
                child: CircularProgressIndicator(color: widget.primaryGreen),
              ),
              const SizedBox(height: 20),
              Text('Posting request...', style: GoogleFonts.poppins()),
            ],
          ),
        ),
      ),
    );

    final success = await provider.addPartnerRequest(newRequest);
    
    if (mounted) {
      Navigator.pop(context); // Close loading
    }
    
    if (success && mounted) {
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
    } else if (mounted) {
      _showErrorSnackBar('Failed to post request. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
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