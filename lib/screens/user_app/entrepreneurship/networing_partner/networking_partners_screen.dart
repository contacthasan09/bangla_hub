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
import 'package:bangla_hub/screens/user_app/entrepreneurship/networing_partner/premium_partner_details_screen.dart';
import 'package:bangla_hub/widgets/common/distance_widget.dart';
import 'package:bangla_hub/widgets/common/global_location_filter_bar.dart';
import 'package:bangla_hub/widgets/common/global_location_guard.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class NetworkingPartnersScreen extends StatefulWidget {
  @override
  _NetworkingPartnersScreenState createState() => _NetworkingPartnersScreenState();
}

class _NetworkingPartnersScreenState extends State<NetworkingPartnersScreen> 
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin, WidgetsBindingObserver {
  
  // Premium Color Palette - Light Green Priority
  final Color _primaryGreen = Color(0xFF2E7D32); // Darker green for buttons
  final Color _lightGreen = Color(0xFFE8F5E9); // Light green (primary background)
  final Color _lightGreenBg = Color(0x80E8F5E9); // Light green with 50% opacity
  final Color _lightRed = Color(0xFFFFEBEE); // Light red (accent background)
  final Color _lightRedBg = Color(0x80FFEBEE); // Light red with 50% opacity
  
  final Color _primaryRed = Color(0xFFD32F2F); // Darker red for buttons
  final Color _deepRed = Color(0xFFB71C1C); // Deep red
  final Color _secondaryGold = Color(0xFFFFB300); // Gold accent
  final Color _softGold = Color(0xFFFF8F00); // Dark gold
  
  // Supporting colors
  final Color _darkGreen = Color(0xFF1B5E20);
  final Color _textPrimary = Color(0xFF1A2B3C);
  final Color _textSecondary = Color(0xFF5D6D7E);
  final Color _borderLight = Color(0xFFE0E7E9);
  final Color _shadowColor = Color(0x1A000000);
  
  // Background Gradient - Light Green Priority with Light Red Accents
  final LinearGradient _bodyBgGradient = LinearGradient(
    colors: [
      Color(0xFFE8F5E9), // Light Green
      Color(0xFFF1F8E9), // Very Light Green
      Color(0xFFFFEBEE), // Light Red (accent)
      Color(0xFFFCE4EC), // Very Light Pink (accent)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.4, 0.7, 1.0],
  );

  final LinearGradient _appBarGradient = LinearGradient(
    colors: [
      Color(0xFF2E7D32), // Primary Green
      Color(0xFF1B5E20), // Dark Green
      Color(0xFFD32F2F), // Primary Red
      Color(0xFFB71C1C), // Deep Red
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.4, 0.7, 1.0],
  );

  // Gemstone gradients for accents
  final LinearGradient _preciousGradient = LinearGradient(
    colors: [
      Color(0xFFFFB300), // gold
      Color(0xFF2E7D32), // green
      Color(0xFFD32F2F), // red
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _gemstoneGradient = LinearGradient(
    colors: [
      Color(0xFF2E7D32), // green
      Color(0xFFFFB300), // gold
      Color(0xFFD32F2F), // red
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _royalGradient = LinearGradient(
    colors: [
      Color(0xFFD32F2F), // red
      Color(0xFFFFB300), // gold
      Color(0xFF2E7D32), // green
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _oceanGradient = LinearGradient(
    colors: [
      Color(0xFF2E7D32), // green
      Color(0xFF1B5E20), // dark green
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
  String? _debugMessage;
  bool _showDebug = false;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  
  // LOCAL FILTER STATE - NO STATE, NO CITY (removed)
  BusinessType? _localSelectedBusinessType;
  String? _localSelectedIndustry;
  bool _isFilterView = false;
  final ScrollController _filterScrollController = ScrollController();
  
  // Track which local filters are active (for display)
  bool _hasLocalFilters = false;
  Map<String, dynamic> _activeLocalFilters = {};
  
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

  // Track global filter state changes
  bool _previousGlobalFilterState = false;

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
    
    // Initialize particle controllers
    _particleControllers = List.generate(30, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(seconds: 3 + (index % 3)),
      )..repeat(reverse: true);
    });
    
    // Initialize bubble controllers
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
    _scaleController.stop();
    _pulseController.stop();
    _rotateController.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
      
      if (locationProvider.isFilterActive != _previousGlobalFilterState) {
        _previousGlobalFilterState = locationProvider.isFilterActive;
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    print('🗑️ NetworkingPartnersScreen disposing...');
    
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

  // Show location filter dialog
 

void _showLocationFilterDialog(BuildContext context) {
  final filterProvider = Provider.of<LocationFilterProvider>(context, listen: false);
  final screenHeight = MediaQuery.of(context).size.height;
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // ✅ Add this to allow bottom sheet to be scrollable
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20))
    ),
    builder: (context) => SafeArea( // ✅ Wrap with SafeArea for notched phones
      child: Container(
        height: screenHeight * 0.8, // ✅ Limit height to 80% of screen
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
                    content: Text('Showing partners from all states'),
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
            
            // ✅ Replace fixed height Container with Expanded
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
                          content: Text('Showing partners in $state'),
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


  // Compact Change Location Button
  Widget _buildChangeLocationButton(bool isTablet) {
    return Consumer<LocationFilterProvider>(
      builder: (context, filterProvider, child) {
        final hasFilter = filterProvider.isFilterActive;
        
        return GestureDetector(
          onTap: () => _showLocationFilterDialog(context),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 10 : 8,
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
              borderRadius: BorderRadius.circular(20),
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
                  hasFilter ? "Change Location" : "Location",
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

  


  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _debugMessage = 'Loading business partners...';
    });

    try {
      final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
      await provider.loadVerifiedBusinessPartners();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _debugMessage = 'Loaded ${provider.businessPartners.length} verified businesses';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _debugMessage = 'Error: $e';
        });
      }
    }
  }

  Future<void> _applyLocalFilters() async {
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    // Clear any existing local filters first
    provider.clearAllFilters(EntrepreneurshipCategory.networkingBusinessPartner);
    
    // Build active filters map for display
    Map<String, dynamic> newActiveFilters = {};
    
    // Apply new local filters (NO STATE, NO CITY)
    if (_localSelectedBusinessType != null) {
      provider.setFilter(EntrepreneurshipCategory.networkingBusinessPartner, 'local_businessType', _localSelectedBusinessType);
      newActiveFilters['local_businessType'] = _localSelectedBusinessType!.displayName;
    }
    if (_localSelectedIndustry != null && _localSelectedIndustry!.isNotEmpty) {
      provider.setFilter(EntrepreneurshipCategory.networkingBusinessPartner, 'local_industry', _localSelectedIndustry);
      newActiveFilters['local_industry'] = _localSelectedIndustry;
    }
    
    if (mounted) {
      setState(() {
        _hasLocalFilters = newActiveFilters.isNotEmpty;
        _activeLocalFilters = newActiveFilters;
        _isFilterView = false;
      });
    }
    
    await provider.loadVerifiedBusinessPartners();
  }

  void _clearLocalFilters() {
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    // Clear all local filters from provider
    provider.clearAllFilters(EntrepreneurshipCategory.networkingBusinessPartner);
    
    // Reset local state (NO STATE, NO CITY)
    if (mounted) {
      setState(() {
        _localSelectedBusinessType = null;
        _localSelectedIndustry = null;
        _hasLocalFilters = false;
        _activeLocalFilters.clear();
        _isFilterView = false;
      });
    }
    
    provider.loadVerifiedBusinessPartners();
  }

  // Get filtered partners - applying BOTH global and local filters
  List<NetworkingBusinessPartner> _getFilteredPartners(
    List<NetworkingBusinessPartner> partners,
    LocationFilterProvider locationProvider,
  ) {
    // Start with all verified and active partners
    var filteredPartners = partners.where((p) => 
      p.isVerified && p.isActive && !p.isDeleted
    ).toList();
    
    print('📊 Initial verified partners: ${filteredPartners.length}');
    
    // Apply GLOBAL location filter if active (from LocationFilterProvider)
    if (locationProvider.isFilterActive && locationProvider.selectedState != null) {
      filteredPartners = filteredPartners.where((partner) {
        return partner.state == locationProvider.selectedState;
      }).toList();
      print('📍 After GLOBAL filter (${locationProvider.selectedState}): ${filteredPartners.length} partners');
    }
    
    // Apply LOCAL filters if any (from this screen's filter view) - NO STATE, NO CITY
    if (_hasLocalFilters) {
      // Business type filter
      if (_localSelectedBusinessType != null) {
        filteredPartners = filteredPartners.where((partner) => 
          partner.businessType == _localSelectedBusinessType
        ).toList();
        print('🏢 After LOCAL business type filter: ${filteredPartners.length} partners');
      }
      
      // Industry filter
      if (_localSelectedIndustry != null && _localSelectedIndustry!.isNotEmpty) {
        filteredPartners = filteredPartners.where((partner) => 
          partner.industry.toLowerCase().contains(_localSelectedIndustry!.toLowerCase())
        ).toList();
        print('🏭 After LOCAL industry filter: ${filteredPartners.length} partners');
      }
    }
    
    return filteredPartners;
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
        _showSuccessSnackBar('Opening phone dialer...');
      }
    } catch (e) {
      _showErrorSnackBar('Could not launch phone dialer');
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Inquiry about your business&body=Hello, I am interested in your business...',
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        _showSuccessSnackBar('Opening email app...');
      }
    } catch (e) {
      _showErrorSnackBar('Could not launch email app');
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
        _showSuccessSnackBar('Opening link...');
      }
    } catch (e) {
      _showErrorSnackBar('Invalid URL');
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
            SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: _primaryRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.all(16),
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
              // Animated Background Particles
              ...List.generate(30, (index) => _buildAnimatedParticle(index)),
              
              // Floating Bubbles
              ...List.generate(8, (index) => _buildFloatingBubble(index)),
              
              // Main Content with new AppBar design
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
                          
                          if (_showDebug && _debugMessage != null) _buildDebugBanner(),
                          _buildContent(),
                        ],
                      ),
              ),
              
              // Premium Floating Action Button
              Positioned(
                bottom: 30,
                right: 30,
                child: _buildPremiumFloatingActionButton(isTablet),
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
                          if (mounted) {
                            setState(() => _localSelectedBusinessType = newValue);
                          }
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
                          onChanged: (value) {
                            if (mounted) {
                              setState(() => _localSelectedIndustry = value);
                            }
                          },
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
        if (mounted) {
          setState(() => _isFilterView = true);
          HapticFeedback.lightImpact();
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 14 : 12,
        ),
        decoration: BoxDecoration(
          gradient: _hasLocalFilters ? _royalGradient : _oceanGradient,
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
            provider.clearFilter(EntrepreneurshipCategory.networkingBusinessPartner, key);
            
            if (mounted) {
              setState(() {
                _activeLocalFilters.remove(key);
                _hasLocalFilters = _activeLocalFilters.isNotEmpty;
                
                // Also clear the corresponding local state variable
                switch (key) {
                  case 'local_businessType':
                    _localSelectedBusinessType = null;
                    break;
                  case 'local_industry':
                    _localSelectedIndustry = null;
                    break;
                }
              });
            }
            
            provider.loadVerifiedBusinessPartners();
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
        gradient: _oceanGradient,
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



/* SliverAppBar _buildPremiumAppBar(bool isTablet) {
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
            colors: [_primaryGreen, _darkGreen, _primaryRed],
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
                // Premium Pattern Line
                Container(
                  height: 4,
                  width: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_secondaryGold, _softGold, _secondaryGold],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: isTablet ? 16 : 12),
                
                // Title - Single line only
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.white, _secondaryGold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'Networking Partners',
                    style: GoogleFonts.poppins(
                    //  fontSize: isTablet ? 28 : 22,
                       fontSize: isTablet ? 32 : 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                SizedBox(height: isTablet ? 12 : 8),
                
                // Subtitle and Change Location Button in same row - Subtitle can wrap
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle - Can wrap to multiple lines
                    Expanded(
                      child: Text(
                        '🤝 Connect & Grow Together',
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 14 : 12,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    SizedBox(width: isTablet ? 12 : 8),
                    
                    // Change Location Button
                    _buildChangeLocationButton(isTablet),
                  ],
                ),
                
                SizedBox(height: isTablet ? 16 : 12),
                
                // Stats Row
                Consumer<EntrepreneurshipProvider>(
                  builder: (context, provider, child) {
                    final verifiedCount = provider.businessPartners
                        .where((s) => s.isVerified && s.isActive)
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
                              Icon(Icons.verified_rounded, color: _secondaryGold, size: isTablet ? 14 : 12),
                              SizedBox(width: isTablet ? 6 : 4),
                              Text(
                                '$verifiedCount Verified Partners',
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

/* SliverAppBar _buildPremiumAppBar(bool isTablet) {
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
            colors: [_primaryGreen, _darkGreen, _primaryRed],
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
                // Premium Pattern Line
                Container(
                  height: 4,
                  width: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_secondaryGold, _softGold, _secondaryGold],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: isTablet ? 16 : 12),
                
                // Title - Single line only
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.white, _secondaryGold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'Networking Partners',
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
                
                // Subtitle and Change Location Button in same row - Subtitle can wrap
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle - Can wrap to multiple lines
                    Expanded(
                      child: Text(
                        '🤝 Connect & Grow Together',
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 14 : 12,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    SizedBox(width: isTablet ? 12 : 8),
                    
                    // Change Location Button
                    _buildChangeLocationButton(isTablet),
                  ],
                ),
                
                SizedBox(height: isTablet ? 16 : 12),
                
                // Stats Row
                Consumer<EntrepreneurshipProvider>(
                  builder: (context, provider, child) {
                    final verifiedCount = provider.businessPartners
                        .where((s) => s.isVerified && s.isActive)
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
                              Icon(Icons.verified_rounded, color: _secondaryGold, size: isTablet ? 14 : 12),
                              SizedBox(width: isTablet ? 6 : 4),
                              Text(
                                '$verifiedCount Verified Partners',
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
    leading: Padding(
      padding: EdgeInsets.only(left: isTablet ? 16 : 12),
      child: Container(
        width: isTablet ? 44 : 40,
        height: isTablet ? 44 : 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded, 
            color: Colors.white, 
            size: isTablet ? 24 : 20,
          ),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          splashRadius: isTablet ? 22 : 18,
        ),
      ),
    ),
    // ✅ Logo on RIGHT side (tappable)
    actions: [
      Padding(
        padding: EdgeInsets.only(right: isTablet ? 16 : 12),
        child: GestureDetector(
          onTap: () {
            // Optional: Navigate to home or show app info
            // Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            // Or show a dialog with app info
         //   _showAppInfoDialog(context, isTablet);
          },
          child: Container(
            width: isTablet ? 44 : 40,
            height: isTablet ? 44 : 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
              child: Image.asset(
                'assets/logo/logo.png',
                width: isTablet ? 32 : 28,
                height: isTablet ? 32 : 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.transparent,
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
      ),
    ],
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
    // ✅ Only ONE flexibleSpace - using Stack for custom positioned logo
    flexibleSpace: Stack(
      children: [
        // Background Container with Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryGreen, _darkGreen, _primaryRed],
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
                  // Premium Pattern Line
                  Container(
                    height: 4,
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_secondaryGold, _softGold, _secondaryGold],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                  
                  // Title - Single line only
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.white, _secondaryGold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'Networking Partners',
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
                  
                  // Subtitle and Change Location Button in same row - Subtitle can wrap
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle - Can wrap to multiple lines
                      Expanded(
                        child: Text(
                          '🤝 Connect & Grow Together',
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 14 : 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      SizedBox(width: isTablet ? 12 : 8),
                      
                      // Change Location Button
                      _buildChangeLocationButton(isTablet),
                    ],
                  ),
                  
                  SizedBox(height: isTablet ? 16 : 12),
                  
                  // Stats Row
                  Consumer<EntrepreneurshipProvider>(
                    builder: (context, provider, child) {
                      final verifiedCount = provider.businessPartners
                          .where((s) => s.isVerified && s.isActive)
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
                                Icon(Icons.verified_rounded, color: _secondaryGold, size: isTablet ? 14 : 12),
                                SizedBox(width: isTablet ? 6 : 4),
                                Text(
                                  '$verifiedCount Verified Partners',
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
        // ✅ Logo positioned absolutely (custom position) - Right side
        Positioned(
          top: MediaQuery.of(context).padding.top + (isTablet ? 12 : 8),
          right: isTablet ? 40 : 24, // Adjust this value to move logo left/right
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
                      _primaryRed.withOpacity(0.3),
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
                      _lightRed.withOpacity(0.2),
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

  Widget _buildDebugBanner() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: () => setState(() => _showDebug = false),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: 8),
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade50, Colors.orange.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.shade100.withOpacity(0.5),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.info_outline, color: Colors.amber.shade800, size: isTablet ? 24 : 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Info',
                      style: GoogleFonts.poppins(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _debugMessage ?? '',
                      style: GoogleFonts.inter(
                        color: Colors.amber.shade800,
                        fontSize: isTablet ? 14 : 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.close_rounded, color: Colors.amber.shade800, size: isTablet ? 24 : 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Consumer2<EntrepreneurshipProvider, LocationFilterProvider>(
      builder: (context, provider, locationProvider, child) {
        if (provider.isLoading || _isLoading) {
          return _buildLoadingState();
        }

        final filteredPartners = _getFilteredPartners(provider.businessPartners, locationProvider);

        if (filteredPartners.isEmpty) {
          return _buildEmptyState(locationProvider);
        }

        return SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final partner = filteredPartners[index];
                
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: _buildPremiumPartnerCard(partner, index),
                    ),
                  ),
                );
              },
              childCount: filteredPartners.length,
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
                    width: isTablet ? 80 : 60,
                    height: isTablet ? 80 : 60,
                    decoration: BoxDecoration(
                      gradient: _royalGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryRed.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: isTablet ? 60 : 45,
                        height: isTablet ? 60 : 45,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: isTablet ? 30 : 24,
                            height: isTablet ? 30 : 24,
                            child: CircularProgressIndicator(
                              color: _primaryGreen,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: isTablet ? 16 : 12),
            ShaderMask(
              shaderCallback: (bounds) => _gemstoneGradient.createShader(bounds),
              child: Text(
                'Loading Partners...',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: isTablet ? 8 : 6),
            ScaleTransition(
              scale: _pulseAnimation,
              child: Text(
                'Curating businesses',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 14 : 12,
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
          padding: EdgeInsets.all(isTablet ? 20 : 16),
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
                      padding: EdgeInsets.all(isTablet ? 20 : 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_lightGreen, _lightRed],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.store_rounded,
                        size: isTablet ? 50 : 40,
                        color: _primaryGreen,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: isTablet ? 16 : 12),
              ShaderMask(
                shaderCallback: (bounds) => _gemstoneGradient.createShader(bounds),
                child: Text(
                  emptyMessage,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 8 : 6),
              Text(
                'Try adjusting your filters or be the first to add',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 14 : 12,
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
                            gradient: _oceanGradient,
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

  Widget _buildPremiumFloatingActionButton(bool isTablet) {
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    Widget button = Container(
      decoration: BoxDecoration(
        gradient: _royalGradient,
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
          onTap: () {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            if (authProvider.isGuestMode) {
              _showLoginRequiredDialog(context, 'Add a Networking Partner');
              return;
            }
            _showAddPartnerDialog(context);
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
                          Icons.add_business_rounded,
                          color: Colors.white,
                          size: isTablet ? 26 : 22,
                        ),
                      )
                    : Icon(
                        Icons.add_business_rounded,
                        color: Colors.white,
                        size: isTablet ? 26 : 22,
                      ),
                SizedBox(width: isTablet ? 12 : 10),
                Text(
                  'Add Business',
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

  // KEPT ORIGINAL - No changes to card


/*  Widget _buildPremiumPartnerCard(NetworkingBusinessPartner partner, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
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
            child: Container(
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
                    color: _primaryRed.withOpacity(0.1),
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
                            _showLoginRequiredDialog(context, 'View Networking Partner Details');
                            return;
                          }
                          _showPartnerDetails(partner);
                        },
                        borderRadius: BorderRadius.circular(30),
                        splashColor: _secondaryGold.withOpacity(0.15),
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
                                  // User Info Row
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
                                                  child: _buildPartnerPosterImage(partner),
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
                                              shaderCallback: (bounds) => _gemstoneGradient.createShader(bounds),
                                              child: Text(
                                                partner.postedByName ?? 'Business Owner',
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
                                                  'Verified Business Owner',
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
                                  
                                  if (partner.latitude != null && partner.longitude != null)
                                    Consumer<LocationFilterProvider>(
                                      builder: (context, locationProvider, _) {
                                        return Padding(
                                          padding: EdgeInsets.only(bottom: 12),
                                          child: DistanceBadge(
                                            latitude: partner.latitude!,
                                            longitude: partner.longitude!,
                                            isTablet: isTablet,
                                          ),
                                        );
                                      },
                                    ),
                                  
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
                                                partner.businessName,
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
                                                gradient: _oceanGradient,
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _primaryGreen.withOpacity(0.3),
                                                    blurRadius: 8,
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                partner.industry,
                                                style: GoogleFonts.poppins(
                                                  fontSize: isTablet ? 14 : 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            if (partner.ownerName.isNotEmpty) ...[
                                              SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.person_outline_rounded, 
                                                    size: 12,
                                                    color: _secondaryGold
                                                  ),
                                                  SizedBox(width: 3),
                                                  Text(
                                                    'Owner: ${partner.ownerName}',
                                                    style: GoogleFonts.inter(
                                                      fontSize: isTablet ? 12 : 11,
                                                      color: _textSecondary,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      
                                      if (partner.rating > 0)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: _preciousGradient,
                                            borderRadius: BorderRadius.circular(24),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _secondaryGold.withOpacity(0.3),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.star_rounded, 
                                                color: Colors.white, 
                                                size: 18,
                                              ),
                                              SizedBox(width: 3),
                                              Text(
                                                partner.rating.toStringAsFixed(1),
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 16),
                                  
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _buildPremiumTag(partner.businessType.displayName, Icons.business_rounded, isTablet),
                                      _buildPremiumTag('${partner.city}, ${partner.state}', Icons.location_on_rounded, isTablet),
                                      _buildPremiumTag('${partner.yearsInBusiness} years', Icons.calendar_today_rounded, isTablet),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 20),
                                  
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
                                              _showLoginRequiredDialog(context, 'View Networking Partner Details');
                                              return;
                                            }
                                            _showPartnerDetails(partner);
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
                                                  color: _primaryRed.withOpacity(0.3),
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



/*Widget _buildPremiumPartnerCard(NetworkingBusinessPartner partner, int index) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isTablet = screenWidth >= 600;
  final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
  
  // Premium eye-catching gradient for all cards (same for consistency)
  final LinearGradient _cardGradient = LinearGradient(
    colors: [
      Color(0xFF1A237E), // Deep Indigo
      Color(0xFF283593), // Dark Indigo
      Color(0xFF3949AB), // Indigo
      Color(0xFF5C6BC0), // Light Indigo
      Color(0xFF7986CB), // Lighter Indigo
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );
  
  // Subtle overlay gradient for depth
  final LinearGradient _overlayGradient = LinearGradient(
    colors: [
      Colors.white.withOpacity(0.15),
      Colors.white.withOpacity(0.05),
      Colors.transparent,
      Colors.white.withOpacity(0.08),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
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
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 25,
                  offset: Offset(0, 12),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: _secondaryGold.withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                decoration: BoxDecoration(
                  gradient: _cardGradient,
                ),
                child: Stack(
                  children: [
                    // Decorative pattern overlay
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.05,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _overlayGradient,
                          ),
                        ),
                      ),
                    ),
                    
                    // Animated shine effect on hover
                    Positioned(
                      top: 0,
                      left: -100,
                      right: -100,
                      height: 2,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: -1.0, end: 1.0),
                        duration: Duration(milliseconds: 3000 + (index * 200)),
                        curve: Curves.easeInOut,
                        builder: (context, slideValue, child) {
                          return Transform.translate(
                            offset: Offset(slideValue * 300, 0),
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    _secondaryGold.withOpacity(0.6),
                                    _softGold.withOpacity(0.8),
                                    _secondaryGold.withOpacity(0.6),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          if (authProvider.isGuestMode) {
                            _showLoginRequiredDialog(context, 'View Networking Partner Details');
                            return;
                          }
                          _showPartnerDetails(partner);
                        },
                        borderRadius: BorderRadius.circular(30),
                        splashColor: _secondaryGold.withOpacity(0.2),
                        highlightColor: Colors.white.withOpacity(0.05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(isTablet ? 20 : 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Decorative gold accent line
                                  Container(
                                    height: 3,
                                    width: 50,
                                    margin: EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_secondaryGold, _softGold, _secondaryGold],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  
                                  // User Info Row
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
                                              width: isTablet ? 55 : 45,
                                              height: isTablet ? 55 : 45,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  colors: [_secondaryGold, _softGold],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _secondaryGold.withOpacity(0.5),
                                                    blurRadius: 15,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.all(2),
                                                child: ClipOval(
                                                  child: _buildPartnerPosterImage(partner),
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
                                            Text(
                                              partner.postedByName ?? 'Business Owner',
                                              style: GoogleFonts.poppins(
                                                fontSize: isTablet ? 16 : 14,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black.withOpacity(0.2),
                                                    blurRadius: 4,
                                                    offset: Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.verified_rounded,
                                                  size: 12,
                                                  color: _secondaryGold,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Verified Owner',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    color: _secondaryGold.withOpacity(0.9),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [_secondaryGold, _softGold],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: _secondaryGold.withOpacity(0.5),
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: shouldAnimate
                                            ? RotationTransition(
                                                turns: _rotateController,
                                                child: Icon(
                                                  Icons.star_rounded, 
                                                  color: Colors.white, 
                                                  size: isTablet ? 16 : 14,
                                                ),
                                              )
                                            : Icon(
                                                Icons.star_rounded, 
                                                color: Colors.white, 
                                                size: isTablet ? 16 : 14,
                                              ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 16),
                                  
                                  // Distance Badge
                                  if (partner.latitude != null && partner.longitude != null)
                                    Consumer<LocationFilterProvider>(
                                      builder: (context, locationProvider, _) {
                                        return Padding(
                                          padding: EdgeInsets.only(bottom: 12),
                                          child: DistanceBadge(
                                            latitude: partner.latitude!,
                                            longitude: partner.longitude!,
                                            isTablet: isTablet,
                                          ),
                                        );
                                      },
                                    ),
                                  
                                  // Business Name
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              partner.businessName,
                                              style: GoogleFonts.poppins(
                                                fontSize: isTablet ? 22 : 20,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                letterSpacing: -0.5,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black.withOpacity(0.25),
                                                    blurRadius: 6,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white.withOpacity(0.25),
                                                    Colors.white.withOpacity(0.15),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: _secondaryGold.withOpacity(0.4),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                partner.industry,
                                                style: GoogleFonts.poppins(
                                                  fontSize: isTablet ? 14 : 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: _secondaryGold,
                                                ),
                                              ),
                                            ),
                                            if (partner.ownerName.isNotEmpty) ...[
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(Icons.person_outline_rounded, 
                                                    size: 14,
                                                    color: Colors.white.withOpacity(0.7)
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    'Owner: ${partner.ownerName}',
                                                    style: GoogleFonts.inter(
                                                      fontSize: isTablet ? 13 : 12,
                                                      color: Colors.white.withOpacity(0.8),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      
                                      if (partner.rating > 0)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [_secondaryGold, _softGold],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(30),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _secondaryGold.withOpacity(0.4),
                                                blurRadius: 12,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.star_rounded, 
                                                color: Colors.white, 
                                                size: 20,
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                partner.rating.toStringAsFixed(1),
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 20),
                                  
                                  // Tags
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildPremiumTag(partner.businessType.displayName, Icons.business_rounded, isTablet),
                                      _buildPremiumTag('${partner.city}, ${partner.state}', Icons.location_on_rounded, isTablet),
                                      _buildPremiumTag('${partner.yearsInBusiness} years', Icons.calendar_today_rounded, isTablet),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 24),
                                  
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
                                              _showLoginRequiredDialog(context, 'View Networking Partner Details');
                                              return;
                                            }
                                            _showPartnerDetails(partner);
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.symmetric(
                                              vertical: isTablet ? 14 : 12,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  _secondaryGold,
                                                  _softGold,
                                                  _secondaryGold,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(28),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _secondaryGold.withOpacity(0.4),
                                                  blurRadius: 15,
                                                  offset: Offset(0, 6),
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'View Details',
                                                  style: GoogleFonts.poppins(
                                                    color: Color(0xFF1A237E), // Deep Indigo to match card
                                                    fontSize: isTablet ? 16 : 14,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                shouldAnimate
                                                    ? RotationTransition(
                                                        turns: _rotateController,
                                                        child: Icon(
                                                          Icons.arrow_forward_rounded,
                                                          color: Color(0xFF1A237E),
                                                          size: isTablet ? 18 : 16,
                                                        ),
                                                      )
                                                    : Icon(
                                                        Icons.arrow_forward_rounded,
                                                        color: Color(0xFF1A237E),
                                                        size: isTablet ? 18 : 16,
                                                      ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  SizedBox(height: 8),
                                  
                                  // Decorative bottom line
                                  Container(
                                    height: 1,
                                    margin: EdgeInsets.only(top: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          _secondaryGold.withOpacity(0.5),
                                          _softGold.withOpacity(0.3),
                                          Colors.transparent,
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
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
                  ],
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


/* Widget _buildPremiumTag(String text, IconData icon, [bool isTablet = false]) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: isTablet ? 12 : 10,
      vertical: isTablet ? 6 : 5,
    ),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.25),
          Colors.white.withOpacity(0.15),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: _secondaryGold.withOpacity(0.3),
        width: 0.8,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon, 
          size: isTablet ? 12 : 11,
          color: _secondaryGold
        ),
        SizedBox(width: isTablet ? 6 : 5),
        Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: isTablet ? 12 : 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}   */


Widget _buildPremiumPartnerCard(NetworkingBusinessPartner partner, int index) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isTablet = screenWidth >= 600;
  final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
  
  // Same margin as job card and partner request card (16 for tablet, 12 for mobile)
  final horizontalMargin = isTablet ? 16.0 : 12.0;
  
  // Premium gradient - Green to Deep Teal (keeping same colors)
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
          color: Colors.black.withOpacity(0.15),
          blurRadius: 15,
          offset: Offset(0, 5),
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Color(0xFF2E7D32).withOpacity(0.25),
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
                _showLoginRequiredDialog(context, 'View Networking Partner Details');
                return;
              }
              _showPartnerDetails(partner);
            },
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.white.withOpacity(0.15),
            highlightColor: Colors.white.withOpacity(0.05),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 14 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            child: _buildPartnerPosterImage(partner),
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
                              partner.postedByName ?? 'Business Owner',
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
                                  color: Color(0xFFA5D6A7),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Verified Partner',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: Color(0xFFC8E6C9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Rating Badge
                      if (partner.rating > 0)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star_rounded, 
                                color: Color(0xFFFFD700), 
                                size: 10,
                              ),
                              SizedBox(width: 3),
                              Text(
                                partner.rating.toStringAsFixed(1),
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
                  
                  SizedBox(height: 10),
                  
                  // Distance Badge
                  if (partner.latitude != null && partner.longitude != null)
                    Consumer<LocationFilterProvider>(
                      builder: (context, locationProvider, _) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: DistanceBadge(
                            latitude: partner.latitude!,
                            longitude: partner.longitude!,
                            isTablet: isTablet,
                          ),
                        );
                      },
                    ),
                  
                  // Business Name
                  Text(
                    partner.businessName,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 6),
                  
                  // Industry and Owner Row - Compact
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
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
                        child: Text(
                          partner.industry,
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 11 : 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      if (partner.ownerName.isNotEmpty) ...[
                        SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.person_outline_rounded, 
                                size: 10,
                                color: Colors.white.withOpacity(0.7)
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  partner.ownerName,
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 11 : 10,
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  SizedBox(height: 10),
                  
                  // Tags Row - Compact
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildCompactPartnerTag(partner.businessType.displayName, Icons.business_rounded, isTablet),
                      _buildCompactPartnerTag(partner.city, Icons.location_on_rounded, isTablet),
                      _buildCompactPartnerTag('${partner.yearsInBusiness}yrs', Icons.calendar_today_rounded, isTablet),
                    ],
                  ),
                  
                  SizedBox(height: 10),
                  
                  // View Details Button - Compact
                  GestureDetector(
                    onTap: () {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.isGuestMode) {
                        _showLoginRequiredDialog(context, 'View Networking Partner Details');
                        return;
                      }
                      _showPartnerDetails(partner);
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




Widget _buildCompactPartnerTag(String text, IconData icon, [bool isTablet = false]) {
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



 Widget _buildPartnerPosterImage(NetworkingBusinessPartner partner) {
  final imageData = partner.postedByProfileImageBase64;
  
  if (imageData != null && imageData.isNotEmpty) {
    // Check if it's a URL (starts with http:// or https://)
    if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
      // It's a Cloudinary URL - use NetworkImage
      return ClipOval(
        child: Image.network(
          imageData,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading network image: $error');
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
      // It's Base64 data - decode it
      try {
        String base64String = imageData;
        
        // Remove data:image prefix if present
        if (base64String.contains('base64,')) {
          base64String = base64String.split('base64,').last;
        }
        
        // Clean the string
        base64String = base64String.replaceAll(RegExp(r'\s'), '');
        
        // Fix padding
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
              print('Error decoding Base64 image: $error');
              return _buildDefaultProfileImage();
            },
          ),
        );
      } catch (e) {
        print('Error processing image: $e');
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

  void _showPartnerDetails(NetworkingBusinessPartner partner) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PremiumPartnerDetailsScreen(
          partner: partner,
          scrollController: ScrollController(),
          onLaunchPhone: _launchPhone,
          onLaunchEmail: _launchEmail,
          onLaunchUrl: _launchUrl,
          primaryGreen: _primaryGreen,
          secondaryGold: _secondaryGold,
          accentRed: _primaryRed,
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

  void _showAddPartnerDialog(BuildContext context) {
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
            child: PremiumAddPartnerDialog(
              scrollController: scrollController,
              onBusinessAdded: _loadData,
              primaryGreen: _primaryGreen,
              secondaryGold: _secondaryGold,
              accentRed: _primaryRed,
              lightGreen: _lightGreen,
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

// ====================== PREMIUM ADD PARTNER DIALOG ======================


class PremiumAddPartnerDialog extends StatefulWidget {
  final VoidCallback? onBusinessAdded;
  final ScrollController scrollController;
  final Color primaryGreen;
  final Color secondaryGold;
  final Color accentRed;
  final Color lightGreen;

  const PremiumAddPartnerDialog({
    Key? key,
    this.onBusinessAdded,
    required this.scrollController,
    required this.primaryGreen,
    required this.secondaryGold,
    required this.accentRed,
    required this.lightGreen,
  }) : super(key: key);

  @override
  _PremiumAddPartnerDialogState createState() => _PremiumAddPartnerDialogState();
}

class _PremiumAddPartnerDialogState extends State<PremiumAddPartnerDialog> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  final _formKey = GlobalKey<FormState>();
  
  // Track app lifecycle and keyboard visibility
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  bool _isKeyboardVisible = false;
  
  // Controllers
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _yearsController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _marketController = TextEditingController();
  final TextEditingController _socialMediaController = TextEditingController();

  // Location picking variables
  double? _partnerLatitude;
  double? _partnerLongitude;
  String? _partnerState;
  String? _partnerCity;
  String? _partnerAddress;

  // State variables
  String? _selectedState;
  BusinessType? _selectedBusinessType = BusinessType.soleProprietorship;
  List<String> _servicesOffered = [];
  List<String> _targetMarkets = [];
  List<String> _socialMediaLinks = [];
  
  // Image handling with compression
  File? _logoImage;
  String? _logoBase64;
  List<File> _galleryImages = [];
  List<String> _galleryBase64 = [];
  bool _isImageProcessing = false;
  
  final List<String> _states = CommunityStates.states;
  
  late TabController _tabController;
  late AnimationController _animationController;
  
  // Track completed tabs
  bool _isBasicInfoValid = false;
  bool _isMediaTabValid = true; // Media is optional
  bool _isDetailsTabValid = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    
    // Add keyboard listener
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
    _emailController.addListener(_validateBasicInfo);
    _phoneController.addListener(_validateBasicInfo);
    _addressController.addListener(_validateBasicInfo);
    _cityController.addListener(_validateBasicInfo);
    
    _industryController.addListener(_validateDetailsTab);
    _descriptionController.addListener(_validateDetailsTab);
    _yearsController.addListener(_validateDetailsTab);
  }
  
  void _setupKeyboardListeners() {
    // Listen to keyboard visibility changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.addListener(() {
        final hasFocus = FocusManager.instance.primaryFocus != null;
        if (mounted && _isKeyboardVisible != hasFocus) {
          setState(() {
            _isKeyboardVisible = hasFocus;
          });
          // Auto-scroll to focused field
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
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {});
      // Scroll to top when tab changes
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _validateBasicInfo() {
    if (mounted) {
      setState(() {
        _isBasicInfoValid = 
            _businessNameController.text.isNotEmpty &&
            _ownerNameController.text.isNotEmpty &&
            _emailController.text.isNotEmpty &&
            _phoneController.text.isNotEmpty &&
            _addressController.text.isNotEmpty &&
            _cityController.text.isNotEmpty &&
            (_partnerLatitude != null && _partnerLongitude != null);
      });
    }
  }

  void _validateDetailsTab() {
    if (mounted) {
      setState(() {
        _isDetailsTabValid = 
            _selectedBusinessType != null &&
            _industryController.text.isNotEmpty &&
            _descriptionController.text.isNotEmpty &&
            _yearsController.text.isNotEmpty;
      });
    }
  }

  bool get _isSubmitEnabled {
    return _isBasicInfoValid && _isDetailsTabValid;
  }

  void _goToPreviousTab() {
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
      // Scroll to top
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
      // Scroll to top
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  // ==================== IMAGE COMPRESSION FUNCTION ====================
  Future<String?> compressAndConvertImage(XFile imageFile, {int minWidth = 400, int minHeight = 400}) async {
    try {
      final file = File(imageFile.path);
      final originalSize = await file.length();

      print("Original size: ${(originalSize / 1024).toStringAsFixed(1)} KB");

      final tempDir = await getTemporaryDirectory();

      // If already small → direct Base64
      if (originalSize <= 1000000) {
        final bytes = await file.readAsBytes();
        return "data:image/jpeg;base64,${base64Encode(bytes)}";
      }

      int quality = 85;
      File? result;

      while (quality >= 30) {
        final targetPath =
            "${tempDir.path}/partner_${DateTime.now().microsecondsSinceEpoch}_$quality.jpg";

        final xfile = await FlutterImageCompress.compressAndGetFile(
          file.path,
          targetPath,
          quality: quality,
          minWidth: minWidth,
          minHeight: minHeight,
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

      // Final fallback (strong compression)
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

  // ==================== UPDATED LOGO PICKER WITH COMPRESSION ====================
  Future<void> _pickLogoImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (pickedFile != null) {
        setState(() {
          _isImageProcessing = true;
        });
        
        // Check original file size
        final File originalFile = File(pickedFile.path);
        final int originalSize = await originalFile.length();
        
        if (originalSize > 5 * 1024 * 1024) {
          setState(() {
            _isImageProcessing = false;
          });
          _showErrorSnackBar('Logo is too large (max 5MB). Please select a smaller image.');
          return;
        }
        
        // Compress and convert using your function
        final String? base64Data = await compressAndConvertImage(pickedFile, minWidth: 300, minHeight: 300);
        
        setState(() {
          _isImageProcessing = false;
        });
        
        if (base64Data != null) {
          final imageFile = File(pickedFile.path);
          setState(() {
            _logoImage = imageFile;
            _logoBase64 = base64Data;
          });
          _showSuccessSnackBar('Logo added successfully!');
        } else {
          _showErrorSnackBar('Failed to compress logo. Please try a different image.');
        }
      }
    } catch (e) {
      setState(() {
        _isImageProcessing = false;
      });
      _showErrorSnackBar('Error picking logo: $e');
    }
  }

  // ==================== UPDATED GALLERY IMAGE PICKER WITH COMPRESSION ====================
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
        
        // Check original file size
        final File originalFile = File(pickedFile.path);
        final int originalSize = await originalFile.length();
        
        if (originalSize > 5 * 1024 * 1024) {
          setState(() {
            _isImageProcessing = false;
          });
          _showErrorSnackBar('Image is too large (max 5MB). Please select a smaller image.');
          return;
        }
        
        // Compress and convert using your function
        final String? base64Data = await compressAndConvertImage(pickedFile, minWidth: 800, minHeight: 800);
        
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

  @override
  void dispose() {
    print('🗑️ PremiumAddPartnerDialog disposing...');
    
    WidgetsBinding.instance.removeObserver(this);
    
    _businessNameController.removeListener(_validateBasicInfo);
    _ownerNameController.removeListener(_validateBasicInfo);
    _emailController.removeListener(_validateBasicInfo);
    _phoneController.removeListener(_validateBasicInfo);
    _addressController.removeListener(_validateBasicInfo);
    _cityController.removeListener(_validateBasicInfo);
    
    _industryController.removeListener(_validateDetailsTab);
    _descriptionController.removeListener(_validateDetailsTab);
    _yearsController.removeListener(_validateDetailsTab);
    
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _industryController.dispose();
    _yearsController.dispose();
    _websiteController.dispose();
    _serviceController.dispose();
    _marketController.dispose();
    _socialMediaController.dispose();
    
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _animationController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        height: screenHeight * 0.9, // Fixed height to prevent overflow
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
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
                    offset: Offset(0, 10),
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
                    child: Icon(Icons.add_business_rounded, color: widget.secondaryGold, size: screenWidth > 600 ? 28 : 22),
                  ),
                  SizedBox(width: screenWidth > 600 ? 16 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Your Business',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth > 600 ? 20 : 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Join our premium network',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: screenWidth > 600 ? 13 : 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: Colors.white),
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
                  _buildPremiumTabIndicator(0, 'Basic', _isBasicInfoValid),
                  _buildPremiumTabConnector(_isBasicInfoValid),
                  _buildPremiumTabIndicator(1, 'Media', true),
                  _buildPremiumTabConnector(true),
                  _buildPremiumTabIndicator(2, 'Details', _isDetailsTabValid),
                ],
              ),
            ),
            
            // Form Content with ScrollController - Keyboard aware
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPremiumBasicInfoTab(),
                    _buildPremiumMediaTab(),
                    _buildPremiumDetailsTab(),
                  ],
                ),
              ),
            ),
            
            // Premium Navigation Buttons
            Container(
              padding: EdgeInsets.all(screenWidth > 600 ? 20 : 16),
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
                      child: _buildPremiumNavButton(
                        label: 'Previous',
                        onPressed: _goToPreviousTab,
                        isPrimary: false,
                      ),
                    ),
                  if (_tabController.index > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _tabController.index < 2
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
          } else if (index == 2 && _isBasicInfoValid) {
            _tabController.animateTo(2);
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
              'Submit',
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

  Widget _buildPremiumBasicInfoTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20, // Add bottom padding for keyboard
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumSectionHeader('Business Information', Icons.business_center_rounded),
          const SizedBox(height: 16),
          _buildPremiumTextField(
            controller: _businessNameController,
            label: 'Business Name *',
            icon: Icons.store_rounded,
          ),
          const SizedBox(height: 12),
          _buildPremiumTextField(
            controller: _ownerNameController,
            label: 'Owner Name *',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 12),
          _buildPremiumTextField(
            controller: _emailController,
            label: 'Email *',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildPremiumTextField(
            controller: _phoneController,
            label: 'Phone *',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          
          _buildPremiumSectionHeader('Location', Icons.location_on_rounded),
          const SizedBox(height: 16),
          
          // Location Picker Field with Map
          _buildLocationPickerField(isTablet),
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _addressController,
            label: 'Street Address *',
            icon: Icons.home_rounded,
          ),
          const SizedBox(height: 12),
          _buildPremiumTextField(
            controller: _cityController,
            label: 'City *',
            icon: Icons.location_city_rounded,
          ),
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
          builder: (context) => GoogleMapsLocationPicker(
            initialLatitude: _partnerLatitude,
            initialLongitude: _partnerLongitude,
            initialAddress: _partnerAddress,
            initialState: _partnerState,
            initialCity: _partnerCity,
            onLocationSelected: (lat, lng, address, state, city) {
              if (mounted) {
                setState(() {
                  _partnerLatitude = lat;
                  _partnerLongitude = lng;
                  _partnerState = state;
                  _partnerCity = city;
                  _partnerAddress = address;
                  _addressController.text = address;
                  _cityController.text = city ?? '';
                  _selectedState = state;
                  _validateBasicInfo();
                });
              }
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
            color: _partnerLatitude != null ? widget.primaryGreen : Colors.grey.shade300.withOpacity(0.5),
            width: _partnerLatitude != null ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.primaryGreen.withOpacity(0.1),
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
                      colors: [widget.primaryGreen, widget.primaryGreen.withOpacity(0.7)],
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
                        'Location on Map *',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 14 : 12,
                          fontWeight: FontWeight.w600,
                          color: widget.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _partnerAddress?.isEmpty ?? true
                            ? 'Tap to select location on map'
                            : _partnerAddress!,
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 13 : 11,
                          color: _partnerAddress?.isEmpty ?? true
                              ? Colors.grey[600]
                              : Colors.black87,
                          fontWeight: _partnerAddress?.isEmpty ?? true
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
                  color: widget.primaryGreen,
                  size: isTablet ? 14 : 12,
                ),
              ],
            ),
            if (_partnerLatitude != null && _partnerLongitude != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.lightGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.my_location,
                      color: widget.primaryGreen,
                      size: isTablet ? 14 : 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_partnerLatitude!.toStringAsFixed(4)}, ${_partnerLongitude!.toStringAsFixed(4)}',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 11 : 10,
                        color: widget.primaryGreen,
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


Widget _buildPremiumMediaTab() {
  final screenWidth = MediaQuery.of(context).size.width;
  final isTablet = screenWidth > 600;
  
  return SingleChildScrollView(  // Fixed: Changed from SingleChildScrollUp to SingleChildScrollView
    controller: widget.scrollController,
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      top: 16,
      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPremiumSectionHeader('Logo Image', Icons.image_rounded),
        const SizedBox(height: 8),
        Text(
          'Upload your business logo (optional)',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 12, color: widget.primaryGreen),
              const SizedBox(width: 4),
              Text(
                'Auto-compressed to under 1MB',
                style: TextStyle(
                  fontSize: 10,
                  color: widget.primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        Center(
          child: GestureDetector(
            onTap: _isImageProcessing ? null : _pickLogoImage,
            child: Container(
              width: isTablet ? 150 : 120,
              height: isTablet ? 150 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [widget.lightGreen, Colors.white],
                ),
                border: Border.all(color: widget.primaryGreen, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryGreen.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: _isImageProcessing
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: widget.primaryGreen,
                            strokeWidth: 2,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Compressing...',
                            style: TextStyle(
                              fontSize: 10,
                              color: widget.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _logoImage != null
                      ? ClipOval(
                          child: Image.file(
                            _logoImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_rounded,
                              size: isTablet ? 40 : 32,
                              color: widget.primaryGreen,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add Logo',
                              style: GoogleFonts.poppins(
                                color: widget.primaryGreen,
                                fontSize: isTablet ? 14 : 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Max 1MB',
                              style: GoogleFonts.inter(
                                color: Colors.grey[500],
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ),
        
        if (_logoImage != null && !_isImageProcessing)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _logoImage = null;
                    _logoBase64 = null;
                  });
                  _showSuccessSnackBar('Logo removed');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.accentRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.accentRed.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline, size: 14, color: widget.accentRed),
                      const SizedBox(width: 4),
                      Text(
                        'Remove Logo',
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.accentRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        
        const SizedBox(height: 24),
      ],
    ),
  );
}
 
 
  Widget _buildPremiumDetailsTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumSectionHeader('Business Details', Icons.info_rounded),
          const SizedBox(height: 16),
          
          _buildPremiumDropdown(
            value: _selectedBusinessType,
            hint: 'Business Type *',
            items: BusinessType.values.map((type) {
              return DropdownMenuItem<BusinessType>(
                value: type,
                child: Text(type.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (mounted) {
                setState(() {
                  _selectedBusinessType = value;
                  _validateDetailsTab();
                });
              }
            },
            icon: Icons.business_rounded,
          ),
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _industryController,
            label: 'Industry *',
            icon: Icons.category_rounded,
          ),
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _descriptionController,
            label: 'Description *',
            icon: Icons.description_rounded,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _yearsController,
            label: 'Years in Business *',
            icon: Icons.calendar_today_rounded,
            keyboardType: TextInputType.number,
          ),
          
          const SizedBox(height: 24),
          
          _buildPremiumSectionHeader('Services Offered', Icons.checklist_rounded),
          const SizedBox(height: 16),
          
          _buildPremiumTagInput(
            controller: _serviceController,
            tags: _servicesOffered,
            hint: 'Add service',
            onAdd: () {
              if (_serviceController.text.trim().isNotEmpty) {
                if (mounted) {
                  setState(() {
                    _servicesOffered.add(_serviceController.text.trim());
                    _serviceController.clear();
                  });
                }
              }
            },
            onRemove: (index) {
              if (mounted) {
                setState(() {
                  _servicesOffered.removeAt(index);
                });
              }
            },
          ),
          
          const SizedBox(height: 24),
          
          _buildPremiumSectionHeader('Additional Info', Icons.add_circle_outline_rounded),
          const SizedBox(height: 16),
          
          _buildPremiumTextField(
            controller: _websiteController,
            label: 'Website',
            icon: Icons.language_rounded,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          
          _buildPremiumTagInput(
            controller: _socialMediaController,
            tags: _socialMediaLinks,
            hint: 'Add social media URL',
            onAdd: () {
              if (_socialMediaController.text.trim().isNotEmpty) {
                if (mounted) {
                  setState(() {
                    _socialMediaLinks.add(_socialMediaController.text.trim());
                    _socialMediaController.clear();
                  });
                }
              }
            },
            onRemove: (index) {
              if (mounted) {
                setState(() {
                  _socialMediaLinks.removeAt(index);
                });
              }
            },
            isSocialMedia: true,
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
              colors: [widget.primaryGreen, widget.primaryGreen.withOpacity(0.7)],
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
            color: const Color(0xFF1E2A3A),
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
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: screenWidth > 600 ? 15 : 13),
        textInputAction: maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: screenWidth > 600 ? 13 : 12),
          prefixIcon: Icon(icon, color: widget.primaryGreen, size: screenWidth > 600 ? 20 : 18),
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

*/


Widget _buildPremiumTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  
  // ✅ Fix: For multiline fields, use multiline keyboard type
  final bool isMultiline = maxLines > 1;
  final TextInputType effectiveKeyboardType = isMultiline 
      ? TextInputType.multiline 
      : keyboardType;
  
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: TextFormField(
      controller: controller,
      keyboardType: effectiveKeyboardType, // ✅ Fixed: Use multiline for multiline fields
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: screenWidth > 600 ? 15 : 13),
      textInputAction: maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: screenWidth > 600 ? 13 : 12),
        prefixIcon: Icon(icon, color: widget.primaryGreen, size: screenWidth > 600 ? 20 : 18),
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
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: screenWidth > 600 ? 13 : 12),
          prefixIcon: Icon(icon, color: widget.primaryGreen, size: screenWidth > 600 ? 20 : 18),
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
          _validateDetailsTab();
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
    bool isSocialMedia = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
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
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: isTablet ? 13 : 12),
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: isTablet ? 14 : 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.primaryGreen, widget.primaryGreen.withOpacity(0.7)],
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
                icon: Icon(Icons.add_rounded, color: Colors.white, size: isTablet ? 22 : 20),
                padding: EdgeInsets.all(isTablet ? 10 : 8),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
        if (tags.isNotEmpty) ...[
           SizedBox(height: isTablet ? 12 : 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(tags.length, (index) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 10, vertical: isTablet ? 6 : 5),
                decoration: BoxDecoration(
                  gradient: isSocialMedia
                      ? LinearGradient(
                          colors: [_getSocialMediaColor(tags[index]), _getSocialMediaColor(tags[index]).withOpacity(0.8)],
                        )
                      : LinearGradient(
                          colors: [widget.lightGreen, Colors.white],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSocialMedia ? Colors.transparent : widget.primaryGreen.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSocialMedia) ...[
                      Icon(
                        _getSocialMediaIcon(tags[index]),
                        color: Colors.white,
                        size: isTablet ? 14 : 12,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      isSocialMedia ? _getSocialMediaName(tags[index]) : tags[index],
                      style: TextStyle(
                        color: isSocialMedia ? Colors.white : widget.primaryGreen,
                        fontSize: isTablet ? 12 : 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => onRemove(index),
                      child: Icon(
                        Icons.close_rounded,
                        color: isSocialMedia ? Colors.white70 : widget.accentRed,
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

  String _getSocialMediaName(String url) {
    if (url.contains('facebook.com') || url.contains('fb.com')) return 'Facebook';
    if (url.contains('instagram.com')) return 'Instagram';
    if (url.contains('twitter.com') || url.contains('x.com')) return 'Twitter';
    if (url.contains('linkedin.com')) return 'LinkedIn';
    if (url.contains('youtube.com')) return 'YouTube';
    return 'Link';
  }

  Color _getSocialMediaColor(String url) {
    if (url.contains('facebook.com') || url.contains('fb.com')) return const Color(0xFF1877F2);
    if (url.contains('instagram.com')) return const Color(0xFFE4405F);
    if (url.contains('twitter.com') || url.contains('x.com')) return const Color(0xFF1DA1F2);
    if (url.contains('linkedin.com')) return const Color(0xFF0A66C2);
    if (url.contains('youtube.com')) return const Color(0xFFFF0000);
    return widget.primaryGreen;
  }

  IconData _getSocialMediaIcon(String url) {
    if (url.contains('facebook.com') || url.contains('fb.com')) return Icons.facebook;
    if (url.contains('instagram.com')) return Icons.camera_alt;
    if (url.contains('twitter.com') || url.contains('x.com')) return Icons.flutter_dash;
    if (url.contains('linkedin.com')) return Icons.work;
    if (url.contains('youtube.com')) return Icons.play_circle_filled;
    return Icons.link;
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_partnerLatitude == null || _partnerLongitude == null) {
      _showErrorSnackBar('Please select location on map');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    
    if (currentUser == null) {
      _showErrorSnackBar('You must be logged in to add a business');
      return;
    }

    final userId = currentUser.id;
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);

    // Get user's profile image
    String? userProfileImage;
    if (currentUser.profileImageUrl != null && currentUser.profileImageUrl!.isNotEmpty) {
      userProfileImage = currentUser.profileImageUrl;
    }

    int totalSize = 0;
    if (_logoBase64 != null) totalSize += _logoBase64!.length;
    for (var img in _galleryBase64) totalSize += img.length;
    
    if (totalSize > 8 * 1024 * 1024) { // 8MB total limit
      _showErrorSnackBar('Total image size too large. Please use fewer or smaller images.');
      return;
    }

    final newPartner = NetworkingBusinessPartner(
      businessName: _businessNameController.text,
      ownerName: _ownerNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      state: _partnerState ?? '',
      city: _partnerCity ?? _cityController.text,
      businessType: _selectedBusinessType!,
      industry: _industryController.text,
      description: _descriptionController.text,
      yearsInBusiness: int.tryParse(_yearsController.text) ?? 0,
      servicesOffered: _servicesOffered,
      targetMarkets: _targetMarkets,
      businessHours: const ['Mon-Fri: 9 AM - 6 PM'],
      logoImageBase64: _logoBase64,
      galleryImagesBase64: _galleryBase64.isNotEmpty ? _galleryBase64 : null,
      website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
      socialMediaLinks: _socialMediaLinks.isNotEmpty ? _socialMediaLinks : null,
      
      // Add location coordinates
      latitude: _partnerLatitude,
      longitude: _partnerLongitude,
      
      // Store user info directly in the partner document
      postedByUserId: userId,
      postedByName: currentUser.fullName,
      postedByEmail: currentUser.email,
      postedByProfileImageBase64: userProfileImage,
      
      createdBy: userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      rating: 0.0,
      totalReviews: 0,
      isVerified: false,
      isActive: true,
      isDeleted: false,
      likedByUsers: const [],
      languagesSpoken: const ['English', 'Bengali'],
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
              Text('Submitting...', style: GoogleFonts.poppins()),
            ],
          ),
        ),
      ),
    );

    final success = await provider.addBusinessPartner(newPartner);
    
    if (mounted) {
      Navigator.pop(context); // Close loading
    }
    
    if (success && mounted) {
      Navigator.pop(context);
      _showSuccessSnackBar('Business added successfully! Pending admin approval.');
      
      if (widget.onBusinessAdded != null) {
        widget.onBusinessAdded!();
      }
    } else if (mounted) {
      _showErrorSnackBar('Failed to add business. Please try again.');
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
        backgroundColor: widget.primaryGreen,
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
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: widget.accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}