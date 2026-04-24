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
import 'package:bangla_hub/widgets/common/global_location_guard.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class SmallBusinessPromotionScreen extends StatefulWidget {
  @override
  _SmallBusinessPromotionScreenState createState() => _SmallBusinessPromotionScreenState();
}

class _SmallBusinessPromotionScreenState extends State<SmallBusinessPromotionScreen> 
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin, WidgetsBindingObserver {
  
  // Premium Color Palette
  final Color _primaryOrange = Color(0xFFFF9800);
  final Color _darkOrange = Color(0xFFF57C00);
  final Color _lightOrange = Color(0xFFFFF3E0);
  final Color _redAccent = Color(0xFFE53935);
  final Color _greenAccent = Color(0xFF43A047);
  final Color _goldAccent = Color(0xFFFFB300);
  final Color _tealAccent = Color(0xFF00897B);
  final Color _creamWhite = Color(0xFFFAF7F2);
  final Color _textPrimary = Color(0xFF1E2A3A);
  final Color _textSecondary = Color(0xFF5D6D7E);
  final Color _borderLight = Color(0xFFE0E7E9);
  final Color _successGreen = Color(0xFF4CAF50);
  
  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rotateController;
  
  late List<AnimationController> _particleControllers;
  late List<AnimationController> _bubbleControllers;

  // LOCAL FILTER STATE - NO STATE, NO CITY (removed)
  String? _localSelectedIndustry;
  bool _isFilterView = false;
  final ScrollController _filterScrollController = ScrollController();
  
  // Track which local filters are active
  bool _hasLocalFilters = false;
    bool _isInitialLoadDone = false;
    bool _hasInitialized = false;

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
    
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize animations
    _fadeController = AnimationController(vsync: this, duration: Duration(milliseconds: 1200));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    
    _slideController = AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _pulseController = AnimationController(vsync: this, duration: Duration(milliseconds: 2000));
    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
    
    _rotateController = AnimationController(vsync: this, duration: Duration(milliseconds: 1500));
    
    _particleControllers = List.generate(30, (index) {
      return AnimationController(vsync: this, duration: Duration(seconds: 3 + (index % 3)))
        ..repeat(reverse: true);
    });
    
    _bubbleControllers = List.generate(8, (index) {
      return AnimationController(vsync: this, duration: Duration(seconds: 8 + (index * 2)))
        ..repeat(reverse: true);
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      
      final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
      if (locationProvider.currentUserLocation == null) {
        locationProvider.getUserLocation(showLoading: false);
      }
      
      if (_appLifecycleState == AppLifecycleState.resumed) {
        _startAnimations();
      }
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _appLifecycleState = state);
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
      _rotateController.repeat();
    }
  }
  
  void _stopAnimations() {
    _fadeController.stop();
    _slideController.stop();
    _pulseController.stop();
    _rotateController.stop();
  }

  @override
/*  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final locationProvider = Provider.of<LocationFilterProvider>(context);
    if (locationProvider.isFilterActive != _previousGlobalFilterState) {
      _previousGlobalFilterState = locationProvider.isFilterActive;
      _loadData();
    }
  }   */

@override
void didChangeDependencies() {
  super.didChangeDependencies();

  final locationProvider =
      Provider.of<LocationFilterProvider>(context);

  final isChanged =
      locationProvider.isFilterActive != _previousGlobalFilterState;

  if ((isChanged || !_hasInitialized) && mounted) {
    _previousGlobalFilterState = locationProvider.isFilterActive;
    _hasInitialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }
}



  @override
  void dispose() {
    print('🗑️ SmallBusinessPromotionScreen disposing...');
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    for (var controller in _particleControllers) { controller.dispose(); }
    for (var controller in _bubbleControllers) { controller.dispose(); }
    _filterScrollController.dispose();
        _isInitialLoadDone = false;

    super.dispose();
  }

  // Helper function to check if string is a URL
  bool _isUrlString(String str) {
    return str.startsWith('http://') || str.startsWith('https://');
  }

/*  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
      final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
      
      if (_hasLocalFilters) {
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
  }  */

Future<void> _loadData() async {
  if (_isLoading) return;

  _isLoading = true;
  if (mounted) setState(() {});

  try {
    final provider = Provider.of<EntrepreneurshipProvider>(
      context,
      listen: false,
    );

    final locationProvider = Provider.of<LocationFilterProvider>(
      context,
      listen: false,
    );

    if (_hasLocalFilters &&
        _localSelectedIndustry != null &&
        _localSelectedIndustry!.isNotEmpty) {
      provider.setFilter(
        EntrepreneurshipCategory.smallBusinessPromotion,
        'local_industry',
        _localSelectedIndustry,
      );
    }

    await provider.loadBusinessPromotions();

  } catch (e) {
    print('Error loading promotions: $e');
  } finally {
    _isLoading = false;
    if (mounted) setState(() {});
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
                      color: _primaryOrange
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
                      content: Text('Showing promotions from all states'), 
                      backgroundColor: Color(0xFFFF9800), 
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200))
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.public, color: _primaryOrange),
                      const SizedBox(width: 15),
                      Text(
                        'All States', 
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)
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
                            content: Text('Showing promotions in $state'), 
                            backgroundColor: _primaryOrange, 
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? _primaryOrange.withOpacity(0.1) : null,
                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: isSelected ? _primaryOrange : Colors.grey),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                state, 
                                style: GoogleFonts.poppins(
                                  fontSize: 16, 
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, 
                                  color: isSelected ? _primaryOrange : Colors.black87
                                ),
                              ),
                            ),
                            if (isSelected) Icon(Icons.check_circle, color: _primaryOrange),
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
                  ? LinearGradient(colors: [_primaryOrange, _darkOrange])
                  : LinearGradient(colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasFilter ? _goldAccent.withOpacity(0.5) : _goldAccent.withOpacity(0.4),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasFilter ? Icons.edit_location_rounded : Icons.location_on_rounded,
                  size: isTablet ? 14 : 12,
                  color: hasFilter ? _goldAccent : _goldAccent,
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
    
    provider.clearAllFilters(EntrepreneurshipCategory.smallBusinessPromotion);
    
    Map<String, dynamic> newActiveFilters = {};
    
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
    
    provider.clearAllFilters(EntrepreneurshipCategory.smallBusinessPromotion);
    
    setState(() {
      _localSelectedIndustry = null;
      _hasLocalFilters = false;
      _activeLocalFilters.clear();
      _isFilterView = false;
    });
    
    provider.loadBusinessPromotions();
  }

  List<SmallBusinessPromotion> _getFilteredPromotions(
    List<SmallBusinessPromotion> promotions,
    LocationFilterProvider locationProvider,
  ) {
    var filteredPromotions = promotions.where((p) => p.isVerified && p.isActive && !p.isDeleted).toList();
    
    if (locationProvider.isFilterActive && locationProvider.selectedState != null) {
      filteredPromotions = filteredPromotions.where((promotion) => promotion.state == locationProvider.selectedState).toList();
    }
    
    if (_hasLocalFilters) {
      if (_localSelectedIndustry != null && _localSelectedIndustry!.isNotEmpty) {
        filteredPromotions = filteredPromotions.where((promotion) => 
          promotion.productsServices.any((service) => service.toLowerCase().contains(_localSelectedIndustry!.toLowerCase()))
        ).toList();
      }
    }
    
    if (_selectedCategoryFilter != 'All') {
      filteredPromotions = filteredPromotions.where((p) {
        return p.productsServices.any((service) => service.toLowerCase().contains(_selectedCategoryFilter!.toLowerCase()));
      }).toList();
    }
    
    return filteredPromotions;
  }

  Future<void> _launchPhone(String phone) async {
    String formattedPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (!formattedPhone.startsWith('1') && formattedPhone.length == 10) formattedPhone = '1$formattedPhone';
    if (!formattedPhone.startsWith('+')) formattedPhone = '+$formattedPhone';
    final Uri phoneUri = Uri(scheme: 'tel', path: formattedPhone);
    try {
      if (await canLaunchUrl(phoneUri)) await launchUrl(phoneUri);
    } catch (e) { if (mounted) _showErrorSnackBar('Could not launch phone dialer'); }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email, query: 'subject=Inquiry about your business');
    try {
      if (await canLaunchUrl(emailUri)) await launchUrl(emailUri);
    } catch (e) { if (mounted) _showErrorSnackBar('Could not launch email app'); }
  }

  Future<void> _launchUrl(String url) async {
    try {
      String finalUrl = url.startsWith('http') ? url : 'https://$url';
      if (await canLaunchUrl(Uri.parse(finalUrl))) await launchUrl(Uri.parse(finalUrl), mode: LaunchMode.externalApplication);
    } catch (e) { if (mounted) _showErrorSnackBar('Invalid URL'); }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(children: [Icon(Icons.check_circle_rounded, color: Colors.white, size: 20), SizedBox(width: 12), Expanded(child: Text(message))],), backgroundColor: _successGreen, behavior: SnackBarBehavior.floating),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(children: [Icon(Icons.error_rounded, color: Colors.white, size: 20), SizedBox(width: 12), Expanded(child: Text(message))],), backgroundColor: _redAccent, behavior: SnackBarBehavior.floating),
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
    return LocationGuard(required: true, showBackButton: true, child: _buildMainContent(context));
  }

  Widget _buildMainContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [_lightOrange.withOpacity(0.3), _creamWhite, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Stack(
            children: [
              ...List.generate(30, (index) => _buildAnimatedParticle(index, screenWidth, MediaQuery.of(context).size.height)),
              ...List.generate(8, (index) => _buildFloatingBubble(index, screenWidth, MediaQuery.of(context).size.height)),
              RefreshIndicator(
                color: _goldAccent,
                onRefresh: _loadData,
                child: _isFilterView
                    ? _buildFiltersView(isTablet)
                    : CustomScrollView(
                        physics: BouncingScrollPhysics(),
                        slivers: [
                          _buildPremiumAppBar(isTablet),
                          SliverToBoxAdapter(child: Consumer<LocationFilterProvider>(builder: (context, locationProvider, _) => GlobalLocationFilterBar(isTablet: isTablet, onClearTap: () { locationProvider.clearLocationFilter(); _loadData(); }))),
                          SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: 8), child: _buildLocalFilterToggleButton(isTablet))),
                          _buildActiveLocalFilters(isTablet),
                          SliverToBoxAdapter(child: _buildCategoryFilterChips(isTablet)),
                          _buildContent(),
                        ],
                      ),
              ),
              Positioned(bottom: 30, right: 30, child: _buildPremiumFloatingActionButton(isTablet, shouldAnimate)),
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
        SliverToBoxAdapter(child: Consumer<LocationFilterProvider>(builder: (context, locationProvider, _) => GlobalLocationFilterBar(isTablet: isTablet, onClearTap: () { locationProvider.clearLocationFilter(); }))),
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.all(isTablet ? 24 : 16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: Offset(0, 10))]),
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
                          Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(gradient: LinearGradient(colors: [_primaryOrange, _redAccent]), borderRadius: BorderRadius.circular(16)), child: Icon(Icons.tune_rounded, color: Colors.white)),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Local Filters', style: GoogleFonts.poppins(fontSize: isTablet ? 24 : 20, fontWeight: FontWeight.w700, color: _textPrimary)),
                                Text('Apply screen-specific filters (State/City are global)', style: GoogleFonts.inter(fontSize: isTablet ? 14 : 12, color: _textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 4))]),
                        child: TextFormField(
                          initialValue: _localSelectedIndustry,
                          onChanged: (value) => _localSelectedIndustry = value,
                          decoration: InputDecoration(
                            labelText: 'Industry/Category',
                            labelStyle: GoogleFonts.poppins(fontSize: 13),
                            prefixIcon: Icon(Icons.category_rounded, color: _primaryOrange, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _buildActionButton(label: 'Apply', onTap: _applyLocalFilters, isPrimary: true, isTablet: isTablet)),
                          SizedBox(width: 12),
                          Expanded(child: _buildActionButton(label: 'Clear', onTap: _clearLocalFilters, isPrimary: false, isTablet: isTablet)),
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
      onTap: () { setState(() => _isFilterView = true); HapticFeedback.lightImpact(); },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: isTablet ? 14 : 12),
        decoration: BoxDecoration(
          gradient: _hasLocalFilters ? LinearGradient(colors: [_primaryOrange, _redAccent]) : LinearGradient(colors: [_primaryOrange, _darkOrange]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _primaryOrange.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_hasLocalFilters ? Icons.filter_alt_rounded : Icons.tune_rounded, color: Colors.white, size: isTablet ? 20 : 18),
            SizedBox(width: 8),
            Text(_hasLocalFilters ? 'Edit Local Filters' : 'Local Filters', style: GoogleFonts.poppins(color: Colors.white, fontSize: isTablet ? 16 : 14, fontWeight: FontWeight.w600)),
            if (_hasLocalFilters) ...[
              SizedBox(width: 8),
              Container(padding: EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Text('${_activeLocalFilters.length}', style: GoogleFonts.poppins(color: _primaryOrange, fontSize: isTablet ? 12 : 10, fontWeight: FontWeight.w700))),
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
          case 'local_industry':
            label = 'Industry: $value';
            icon = Icons.category_rounded;
            break;
        }
        chips.add(_buildFilterChip(label: label, icon: icon, onRemove: () {
          final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
          provider.clearFilter(EntrepreneurshipCategory.smallBusinessPromotion, key);
          setState(() {
            _activeLocalFilters.remove(key);
            _hasLocalFilters = _activeLocalFilters.isNotEmpty;
            _localSelectedIndustry = null;
          });
          provider.loadBusinessPromotions();
        }));
      }
    });
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text('Active Local Filters:', style: GoogleFonts.poppins(fontSize: isTablet ? 14 : 12, fontWeight: FontWeight.w600, color: _primaryOrange))),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({required String label, required IconData icon, required VoidCallback onRemove}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [_primaryOrange, _darkOrange]), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 1),
          SizedBox(width: 6),
          GestureDetector(onTap: onRemove, child: Icon(Icons.close, color: Colors.white, size: 14)),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required VoidCallback onTap, required bool isPrimary, required bool isTablet}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isPrimary ? LinearGradient(colors: [_primaryOrange, _redAccent]) : null,
          color: isPrimary ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isPrimary ? null : Border.all(color: _primaryOrange, width: 2),
          boxShadow: isPrimary ? [BoxShadow(color: _primaryOrange.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 6))] : null,
        ),
        child: Center(child: Text(label, style: GoogleFonts.poppins(color: isPrimary ? Colors.white : _primaryOrange, fontWeight: FontWeight.w700, fontSize: 13))),
      ),
    );
  }


/*  SliverAppBar _buildPremiumAppBar(bool isTablet) {
    return SliverAppBar(
      expandedHeight: isTablet ? 260 : 200,
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
                vertical: isTablet ? 20 : 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 4,
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_goldAccent, _greenAccent, _goldAccent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                  
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.white, _goldAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'Business Promotions',
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
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '🌟 Discover and support local businesses',
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 14 : 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      SizedBox(width: isTablet ? 12 : 8),
                      
                      Align(
                        alignment: Alignment.topCenter,
                        child: _buildChangeLocationButton(isTablet),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: isTablet ? 16 : 12),
                  
                  Consumer<EntrepreneurshipProvider>(
                    builder: (context, provider, child) {
                      final verifiedCount = provider.businessPromotions
                          .where((p) => p.isVerified && p.isActive)
                          .length;
                      
                      return Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 12 : 10,
                              vertical: isTablet ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.storefront_rounded, color: _goldAccent, size: isTablet ? 14 : 12),
                                SizedBox(width: isTablet ? 6 : 4),
                                Text(
                                  '$verifiedCount Active Businesses',
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
    expandedHeight: isTablet ? 260 : 200,
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
              vertical: isTablet ? 20 : 16,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  width: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_goldAccent, _greenAccent, _goldAccent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: isTablet ? 16 : 12),
                
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.white, _goldAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'Business Promotions',
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
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '🌟 Discover and support local businesses',
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 14 : 12,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    SizedBox(width: isTablet ? 12 : 8),
                    
                    Align(
                      alignment: Alignment.topCenter,
                      child: _buildChangeLocationButton(isTablet),
                    ),
                  ],
                ),
                
                SizedBox(height: isTablet ? 16 : 12),
                
                Consumer<EntrepreneurshipProvider>(
                  builder: (context, provider, child) {
                    final verifiedCount = provider.businessPromotions
                        .where((p) => p.isVerified && p.isActive)
                        .length;
                    
                    return Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 12 : 10,
                            vertical: isTablet ? 6 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.storefront_rounded, color: _goldAccent, size: isTablet ? 14 : 12),
                              SizedBox(width: isTablet ? 6 : 4),
                              Text(
                                '$verifiedCount Active Businesses',
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
                      Icons.storefront_rounded,
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

 
  Widget _buildCategoryFilterChips(bool isTablet) {
    return Container(
      height: 44,
      margin: EdgeInsets.only(top: 16, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
        itemCount: _categoryFilters.length,
        itemBuilder: (context, index) {
          final filter = _categoryFilters[index];
          final isSelected = _selectedCategoryFilter == filter;
          return Padding(
            padding: EdgeInsets.only(right: 10),
            child: FilterChip(
              selected: isSelected,
              label: Text(filter, style: GoogleFonts.poppins(color: isSelected ? Colors.white : _textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: isTablet ? 12 : 11)),
              onSelected: (selected) { setState(() { _selectedCategoryFilter = filter; }); HapticFeedback.lightImpact(); },
              backgroundColor: Colors.white,
              selectedColor: _primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: BorderSide(color: isSelected ? _primaryOrange : _borderLight, width: 0.8)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedParticle(int index, double width, double height) {
    final controller = _particleControllers[index % _particleControllers.length];
    return Positioned(
      left: (index * 37) % width, top: (index * 53) % height,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final value = controller.value;
          return Opacity(
            opacity: (0.1 + (value * 0.2)) * (0.5 + (index % 3) * 0.1),
            child: Transform.rotate(
              angle: value * 6.28,
              child: Container(width: 2 + (index % 3) * 2, height: 2 + (index % 3) * 2, decoration: BoxDecoration(gradient: RadialGradient(colors: [_primaryOrange.withOpacity(0.5), _greenAccent.withOpacity(0.3), Colors.transparent]), shape: BoxShape.circle)),
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
      left: (index * 73) % width, top: (index * 47) % height,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final value = controller.value;
          return Transform.translate(
            offset: Offset(0, 20 * (value - 0.5)),
            child: Opacity(
              opacity: 0.1 + (value * 0.1),
              child: Container(width: size, height: size, decoration: BoxDecoration(gradient: RadialGradient(colors: [_lightOrange.withOpacity(0.3), _greenAccent.withOpacity(0.2), Colors.transparent]), shape: BoxShape.circle, border: Border.all(color: _goldAccent.withOpacity(0.1), width: 1))),
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
          if (authProvider.isGuestMode) { _showLoginRequiredDialog(context, 'Add Promotion'); return; }
          _showAddPromotionDialog(context);
        },
        backgroundColor: Colors.transparent,
        elevation: 12,
        label: Container(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: isTablet ? 12 : 10),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [_primaryOrange, _redAccent, _greenAccent]), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: _primaryOrange.withOpacity(0.4), blurRadius: 15, offset: Offset(0, 8))]),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_business_rounded, color: Colors.white, size: isTablet ? 20 : 18),
              SizedBox(width: isTablet ? 8 : 6),
              Text('Promote', style: GoogleFonts.poppins(fontSize: isTablet ? 14 : 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
    return shouldAnimate ? ScaleTransition(scale: _pulseAnimation, child: button) : button;
  }

  Widget _buildContent() {
    return Consumer2<EntrepreneurshipProvider, LocationFilterProvider>(
      builder: (context, provider, locationProvider, child) {
        if (provider.isLoading || _isLoading) return _buildLoadingState();
        final filteredPromotions = _getFilteredPromotions(provider.businessPromotions, locationProvider);
        if (filteredPromotions.isEmpty) return _buildEmptyState(locationProvider);
        return SliverPadding(
          padding: EdgeInsets.all(12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final promotion = filteredPromotions[index];
                return Padding(padding: EdgeInsets.only(bottom: 12), child: _buildPremiumPromotionCard(promotion, index));
              },
              childCount: filteredPromotions.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _primaryOrange),
            SizedBox(height: 16),
            Text('Loading businesses...', style: GoogleFonts.poppins(color: _textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(LocationFilterProvider locationProvider) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    String emptyMessage = 'No businesses found';
    if (locationProvider.isFilterActive && _hasLocalFilters) emptyMessage = 'No businesses in ${locationProvider.selectedState} with your local filters';
    else if (locationProvider.isFilterActive) emptyMessage = 'No businesses in ${locationProvider.selectedState}';
    else if (_hasLocalFilters) emptyMessage = 'No businesses match your local filters';
    
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_rounded, size: 60, color: _primaryOrange.withOpacity(0.5)),
            SizedBox(height: 16),
            Text(emptyMessage, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary)),
            SizedBox(height: 8),
            Text('Try adjusting your filters or be the first to promote!', style: GoogleFonts.inter(fontSize: 12, color: _textSecondary)),
          ],
        ),
      ),
    );
  }

  // UPDATED: Build promotion poster image with URL and Base64 support
  Widget _buildPromotionPosterImage(SmallBusinessPromotion promotion) {
    final imageData = promotion.postedByProfileImageBase64;
    
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
              print('Error loading promotion poster image: $error');
              return _buildDefaultProfileImage();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_goldAccent),
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
                print('Error decoding promotion poster image: $error');
                return _buildDefaultProfileImage();
              },
            ),
          );
        } catch (e) {
          print('Error processing promotion poster image: $e');
          return _buildDefaultProfileImage();
        }
      }
    }
    
    return _buildDefaultProfileImage();
  }

  Widget _buildDefaultProfileImage() {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [_primaryOrange, _redAccent])),
      child: Center(child: Icon(Icons.person_rounded, color: Colors.white, size: 24)),
    );
  }


  Widget _buildCompactTag(String text, IconData icon, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 6, vertical: isTablet ? 4 : 3),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: _goldAccent.withOpacity(0.3), width: 0.5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isTablet ? 10 : 9, color: _goldAccent),
          SizedBox(width: 4),
          Text(text, style: GoogleFonts.poppins(color: _textSecondary, fontSize: isTablet ? 10 : 9, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

/*  Widget _buildPremiumPromotionCard(SmallBusinessPromotion promotion, int index) {
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
                            Padding(
                              padding: EdgeInsets.all(isTablet ? 20 : 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                  
                                  Row(
                                    children: [
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
                                      
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
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
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
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
                                  
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _buildCompactTag(promotion.city, Icons.location_on_rounded, isTablet),
                                      _buildCompactTag('${promotion.productsServices.length} products', Icons.shopping_bag_rounded, isTablet),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 14),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

*/

Widget _buildPremiumPromotionCard(SmallBusinessPromotion promotion, int index) {
  final isOfferActive = promotion.specialOfferDiscount != null && promotion.specialOfferDiscount! > 0;
  final isTablet = MediaQuery.of(context).size.width >= 600;
  final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
  
  // Same margin as other cards (16 for tablet, 12 for mobile)
  final horizontalMargin = isTablet ? 16.0 : 12.0;
  
  // Premium gradient - Orange to Red to Green (keeping same colors)
  final LinearGradient _cardGradient = LinearGradient(
    colors: [
      Color(0xFFFF9800), // Orange
      Color(0xFFF57C00), // Dark Orange
      Color(0xFFE53935), // Red
      Color(0xFFD32F2F), // Dark Red
      Color(0xFF43A047), // Green
      Color(0xFF2E7D32), // Dark Green
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
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
          color: Colors.black.withOpacity(0.15),
          blurRadius: 15,
          offset: Offset(0, 5),
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Color(0xFFFF9800).withOpacity(0.25),
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
                _showLoginRequiredDialog(context, 'View Promotion Details');
                return;
              }
              _showPromotionDetails(promotion);
            },
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.white.withOpacity(0.15),
            highlightColor: Colors.white.withOpacity(0.05),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 14 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Offer Badge (if active) - Compact
                  if (isOfferActive)
                    Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFFD700).withOpacity(0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_offer_rounded, 
                            color: Colors.white, 
                            size: 10,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${promotion.specialOfferDiscount!.toStringAsFixed(0)}% OFF',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // User Info Row - Compact
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: isTablet ? 44 : 38,
                        height: isTablet ? 44 : 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFFD700).withOpacity(0.4),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(1.5),
                          child: ClipOval(
                            child: _buildPromotionPosterImage(promotion),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 10),
                      
                      // Name and Verified Badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promotion.postedByName ?? 'Business Owner',
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
                                Icon(
                                  Icons.verified_rounded,
                                  size: 12,
                                  color: Color(0xFFFFD700),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Verified Business',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: Color(0xFFFFD700).withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Verified Badge - Compact
                      if (promotion.isVerified)
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: shouldAnimate
                              ? RotationTransition(
                                  turns: _rotateController,
                                  child: Icon(
                                    Icons.verified_rounded, 
                                    color: Colors.white, 
                                    size: isTablet ? 12 : 10,
                                  ),
                                )
                              : Icon(
                                  Icons.verified_rounded, 
                                  color: Colors.white, 
                                  size: isTablet ? 12 : 10,
                                ),
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 10),
                  
                  // Distance Badge
                  if (promotion.latitude != null && promotion.longitude != null)
                    Consumer<LocationFilterProvider>(
                      builder: (context, locationProvider, _) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: DistanceBadge(
                            latitude: promotion.latitude!,
                            longitude: promotion.longitude!,
                            isTablet: isTablet,
                          ),
                        );
                      },
                    ),
                  
                  // Business Name
                  Text(
                    promotion.businessName,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 6),
                  
                  // Owner Name
                  Text(
                    promotion.ownerName,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 11 : 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                  
                  SizedBox(height: 10),
                  
                  // Tags Row - Compact
               /*   Wrap(
                    
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildCompactPromotionTag(promotion.city, Icons.location_on_rounded, isTablet),
                      _buildCompactPromotionTag('${promotion.productsServices.length} products', Icons.shopping_bag_rounded, isTablet),
                    ],
                  ),  */

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    
                    
                    children: [
                      _buildCompactPromotionTag(promotion.city, Icons.location_on_rounded, isTablet),
                      _buildCompactPromotionTag('${promotion.productsServices.length} products', Icons.shopping_bag_rounded, isTablet),
                    ],
                  ),
                  
                  SizedBox(height: 10),
                  
                  // Stats Row - Compact
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
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
                            Icon(Icons.remove_red_eye_rounded, 
                              size: 10,
                              color: Colors.white
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${promotion.totalViews}',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: isTablet ? 10 : 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                    /*  Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
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
                            Icon(Icons.share_rounded, 
                              size: 10,
                              color: Colors.white
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${promotion.totalShares}',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: isTablet ? 10 : 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),  */
                    ],
                  ),
                  
                  if (promotion.paymentMethods.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: promotion.paymentMethods.take(3).map((method) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            method,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: isTablet ? 9 : 8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  
                  SizedBox(height: 10),
                  
                  // View Details Button - Compact
                  GestureDetector(
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
                              color: Color(0xFFF57C00),
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
                                    color: Color(0xFFF57C00),
                                    size: isTablet ? 14 : 12,
                                  ),
                                )
                              : Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFFF57C00),
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

Widget _buildCompactPromotionTag(String text, IconData icon, [bool isTablet = false]) {
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

  void _showPromotionDetails(SmallBusinessPromotion promotion) async {
    HapticFeedback.mediumImpact();
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    await provider.incrementViewCount(EntrepreneurshipCategory.smallBusinessPromotion, promotion.id!);
    await provider.loadBusinessPromotions();
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => BusinessPromotionDetailsScreen(
      promotion: promotion,
      scrollController: ScrollController(),
      onLaunchPhone: _launchPhone,
      onLaunchEmail: _launchEmail,
      onLaunchUrl: _launchUrl,
      primaryOrange: _primaryOrange,
      redAccent: _redAccent,
      greenAccent: _greenAccent,
      goldAccent: _goldAccent,
    )));
  }

  void _showAddPromotionDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white, _creamWhite]), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
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
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _socialMediaController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _offerDiscountController = TextEditingController();
  final TextEditingController _offerValidityController = TextEditingController();
  final TextEditingController _paymentMethodController = TextEditingController();

  // Location variables (all from map picker)
  double? _businessLatitude;
  double? _businessLongitude;
  String? _businessFullAddress;
  String? _businessCity;
  String? _businessState;
  
  // State variables
  List<String> _productsServices = [];
  List<String> _paymentMethods = [];
  
  // Image handling with compression
  List<File> _galleryImages = [];
  List<String> _galleryBase64 = [];
  bool _isImageProcessing = false;
  
  late TabController _tabController;
  late AnimationController _animationController;
  
  // Track app lifecycle and keyboard
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  bool _isKeyboardVisible = false;
  
  // Track completed tabs
  bool _isBasicInfoValid = false;
  bool _isDetailsTabValid = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    
    _setupKeyboardListeners();
    
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();
    
    // Add listeners to validate on change
    _businessNameController.addListener(_validateBasicInfo);
    _ownerNameController.addListener(_validateBasicInfo);
    _contactEmailController.addListener(_validateBasicInfo);
    _contactPhoneController.addListener(_validateBasicInfo);
    
    _descriptionController.addListener(_validateDetailsTab);
    _productController.addListener(_validateDetailsTab);
    
    if (_appLifecycleState == AppLifecycleState.resumed) {
      _startAnimations();
    }
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
    if (mounted) {
      setState(() {
        _isBasicInfoValid = 
            _businessNameController.text.isNotEmpty &&
            _ownerNameController.text.isNotEmpty &&
            _contactEmailController.text.isNotEmpty &&
            _contactPhoneController.text.isNotEmpty &&
            _businessLatitude != null &&
            _businessLongitude != null &&
            _businessFullAddress != null &&
            _businessFullAddress!.isNotEmpty;
      });
    }
  }

  void _validateDetailsTab() {
    if (mounted) {
      setState(() {
        _isDetailsTabValid = 
            _descriptionController.text.isNotEmpty &&
            _productsServices.isNotEmpty;
      });
    }
  }

  bool get _isSubmitEnabled {
    return _isBasicInfoValid && _isDetailsTabValid;
  }

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
    if (_tabController.index < 2) {
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
    print('🗑️ PremiumAddPromotionDialog disposing...');
    WidgetsBinding.instance.removeObserver(this);
    
    _businessNameController.removeListener(_validateBasicInfo);
    _ownerNameController.removeListener(_validateBasicInfo);
    _contactEmailController.removeListener(_validateBasicInfo);
    _contactPhoneController.removeListener(_validateBasicInfo);
    _descriptionController.removeListener(_validateDetailsTab);
    
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _descriptionController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _websiteController.dispose();
    _socialMediaController.dispose();
    _productController.dispose();
    _offerDiscountController.dispose();
    _offerValidityController.dispose();
    _paymentMethodController.dispose();
    
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _animationController.dispose();
    
    super.dispose();
  }

  // ==================== IMAGE COMPRESSION FUNCTION ====================
  Future<String?> compressAndConvertImage(XFile imageFile) async {
    try {
      final file = File(imageFile.path);
      final originalSize = await file.length();

      print("Original size: ${(originalSize / 1024).toStringAsFixed(1)} KB");

      final tempDir = await getTemporaryDirectory();

      if (originalSize <= 1000000) {
        final bytes = await file.readAsBytes();
        return "data:image/jpeg;base64,${base64Encode(bytes)}";
      }

      int quality = 85;
      File? result;

      while (quality >= 30) {
        final targetPath =
            "${tempDir.path}/promo_${DateTime.now().microsecondsSinceEpoch}_$quality.jpg";

        final xfile = await FlutterImageCompress.compressAndGetFile(
          file.path,
          targetPath,
          quality: quality,
          minWidth: 800,
          minHeight: 600,
          format: CompressFormat.jpeg,
        );

        if (xfile == null) {
          quality -= 10;
          continue;
        }

        result = File(xfile.path);
        final size = await result.length();

        print("Quality $quality → ${(size / 1024).toStringAsFixed(1)} KB");

        if (size <= 1000000) {
          final bytes = await result.readAsBytes();
          return "data:image/jpeg;base64,${base64Encode(bytes)}";
        }

        quality -= 10;
      }

      if (result != null) {
        final bytes = await result.readAsBytes();
        return "data:image/jpeg;base64,${base64Encode(bytes)}";
      }

      return null;
    } catch (e) {
      print("Compression error: $e");
      return null;
    }
  }

  Future<void> _pickGalleryImage() async {
    if (_galleryImages.length >= 5) {
      _showErrorSnackBar('Maximum 5 images allowed');
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      
      if (pickedFile != null) {
        setState(() {
          _isImageProcessing = true;
        });
        
        final File originalFile = File(pickedFile.path);
        final int originalSize = await originalFile.length();
        
        if (originalSize > 5 * 1024 * 1024) {
          setState(() {
            _isImageProcessing = false;
          });
          _showErrorSnackBar('Image is too large (max 5MB). Please select a smaller image.');
          return;
        }
        
        final String? base64Data = await compressAndConvertImage(pickedFile);
        
        setState(() {
          _isImageProcessing = false;
        });
        
        if (base64Data != null) {
          final imageFile = File(pickedFile.path);
          setState(() {
            _galleryImages.add(imageFile);
            _galleryBase64.add(base64Data);
          });
          _showSuccessSnackBar('Image added successfully!');
        } else {
          _showErrorSnackBar('Failed to compress image. Please try a different image.');
        }
      }
    } catch (e) {
      setState(() {
        _isImageProcessing = false;
      });
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  // ==================== LOCATION PICKER FROM MAP ====================
  Widget _buildLocationPickerField(StateSetter setState, bool isTablet) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => GoogleMapsLocationPicker(
            initialLatitude: _businessLatitude,
            initialLongitude: _businessLongitude,
            initialAddress: _businessFullAddress,
            initialState: _businessState,
            initialCity: _businessCity,
            onLocationSelected: (lat, lng, address, state, city) {
              setState(() {
                _businessLatitude = lat;
                _businessLongitude = lng;
                _businessFullAddress = address;
                _businessState = state;
                _businessCity = city;
              });
              _validateBasicInfo();
            },
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.95),
              Colors.white.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _businessLatitude != null ? widget.primaryOrange : Colors.grey.shade300.withOpacity(0.5),
            width: _businessLatitude != null ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.primaryOrange.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.primaryOrange, widget.redAccent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.map_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business Location *',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 14 : 12,
                          fontWeight: FontWeight.w600,
                          color: widget.primaryOrange,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _businessFullAddress?.isEmpty ?? true
                            ? 'Tap to select location on map'
                            : _businessFullAddress!,
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 13 : 11,
                          color: _businessFullAddress?.isEmpty ?? true
                              ? Colors.grey[600]
                              : Colors.black87,
                          fontWeight: _businessFullAddress?.isEmpty ?? true
                              ? FontWeight.w400
                              : FontWeight.w500,
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
                  size: isTablet ? 14 : 12,
                ),
              ],
            ),
            if (_businessLatitude != null && _businessLongitude != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.my_location,
                      color: widget.primaryOrange,
                      size: isTablet ? 14 : 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_businessLatitude!.toStringAsFixed(4)}, ${_businessLongitude!.toStringAsFixed(4)}',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 11 : 10,
                        color: widget.primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_businessCity != null && _businessCity!.isNotEmpty && _businessState != null && _businessState!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_city,
                      color: widget.greenAccent,
                      size: isTablet ? 14 : 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_businessCity, $_businessState',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 11 : 10,
                        color: widget.greenAccent,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
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
                colors: [widget.primaryOrange, widget.redAccent, widget.greenAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryOrange.withOpacity(0.3),
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
                      const SizedBox(height: 4),
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
                  constraints: const BoxConstraints(),
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
              tabs: const [
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
                physics: const NeverScrollableScrollPhysics(),
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
                  offset: const Offset(0, -5),
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

  Widget _buildBasicInfoTab(bool isTablet) {
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
          SizedBox(height: isTablet ? 24 : 20),
          
          _buildSectionHeader('Location (Pick from Map)', Icons.map_rounded, widget.redAccent, isTablet),
          SizedBox(height: isTablet ? 16 : 12),
          
          // Location Picker from Map
          StatefulBuilder(
            builder: (context, setState) => _buildLocationPickerField(setState, isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTab(bool isTablet) {
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
          _buildSectionHeader('Gallery Images', Icons.photo_library_rounded, widget.greenAccent, isTablet),
          SizedBox(height: isTablet ? 8 : 4),
          Text(
            'Add up to 5 images to showcase your business (optional)',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14 : 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: isTablet ? 4 : 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.greenAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 12, color: widget.greenAccent),
                const SizedBox(width: 4),
                Text(
                  'Auto-compressed to under 1MB per image',
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.greenAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          
          if (_isImageProcessing)
            Container(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: widget.primaryOrange,
                      strokeWidth: 2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Compressing image...',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          if (!_isImageProcessing)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
            const SizedBox(height: 4),
            Text(
              'Max 1MB',
              style: GoogleFonts.inter(
                color: Colors.grey[400],
                fontSize: 8,
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

  Widget _buildDetailsTab(bool isTablet) {
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

/*  Widget _buildPremiumTextField({
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
  }   */

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
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onAdd(),
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
                constraints: const BoxConstraints(),
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
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => onRemove(index),
                      child: Container(
                        padding: const EdgeInsets.all(2),
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
                    offset: const Offset(0, 5),
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
              offset: const Offset(0, 8),
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

    if (_businessLatitude == null || _businessLongitude == null) {
      _showErrorSnackBar('Please select a location on the map');
      return;
    }

    if (_businessFullAddress == null || _businessFullAddress!.isEmpty) {
      _showErrorSnackBar('Please select a valid location address');
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

    // Check total base64 size
    int totalSize = 0;
    for (String img in _galleryBase64) {
      totalSize += img.length;
    }
    
    if (totalSize > 8 * 1024 * 1024) {
      _showErrorSnackBar('Total image size too large. Please use fewer or smaller images.');
      return;
    }

    // Get user's profile image
    String? userProfileImage;
    if (currentUser.profileImageUrl != null && currentUser.profileImageUrl!.isNotEmpty) {
      userProfileImage = currentUser.profileImageUrl;
    }

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);

    final newPromotion = SmallBusinessPromotion(
      businessName: _businessNameController.text,
      ownerName: _ownerNameController.text,
      description: _descriptionController.text,
      uniqueSellingPoints: '',
      productsServices: _productsServices,
      targetAudience: '',
      location: _businessFullAddress!,
      state: _businessState ?? '',
      city: _businessCity ?? '',
      contactEmail: _contactEmailController.text,
      contactPhone: _contactPhoneController.text,
      website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
      socialMediaLinks: _socialMediaController.text.isNotEmpty ? _socialMediaController.text : null,
      logoImageBase64: null,
      galleryImagesBase64: _galleryBase64.isNotEmpty ? _galleryBase64 : null,
      paymentMethods: _paymentMethods,
      specialOfferDiscount: _offerDiscountController.text.isNotEmpty ? double.tryParse(_offerDiscountController.text) : null,
      offerValidity: _offerValidityController.text.isNotEmpty ? _offerValidityController.text : null,
      
      // Location coordinates from map
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
                child: CircularProgressIndicator(color: widget.primaryOrange),
              ),
              const SizedBox(height: 20),
              Text('Submitting...', style: GoogleFonts.poppins()),
            ],
          ),
        ),
      ),
    );

    final success = await provider.addBusinessPromotion(newPromotion);
    
    if (mounted) {
      Navigator.pop(context);
    }
    
    if (success) {
      if (mounted) {
        Navigator.pop(context);
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
            const SizedBox(width: 10),
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
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
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
            const SizedBox(width: 10),
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
        margin: const EdgeInsets.all(12),
      ),
    );
  }
}