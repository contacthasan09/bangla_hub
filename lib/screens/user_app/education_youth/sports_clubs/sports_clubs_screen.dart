// screens/user_app/education_youth/sports_clubs/sports_clubs_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:bangla_hub/models/community_services_models.dart';
import 'package:bangla_hub/models/education_models.dart';
import 'package:bangla_hub/providers/education_provider.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/location_filter_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/auth/signup_screen.dart';
import 'package:bangla_hub/screens/user_app/education_youth/sports_clubs/sports_club_details_screen.dart';
import 'package:bangla_hub/widgets/common/distance_widget.dart';
import 'package:bangla_hub/widgets/common/global_location_filter_bar.dart';
import 'package:bangla_hub/widgets/common/global_location_guard.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SportsClubsScreen extends StatefulWidget {
  @override
  _SportsClubsScreenState createState() => _SportsClubsScreenState();
}

class _SportsClubsScreenState extends State<SportsClubsScreen> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin, WidgetsBindingObserver {
  // Premium Color Palette - Sports Theme
  final Color _primaryRed = Color(0xFFF44336);
  final Color _darkRed = Color(0xFFD32F2F);
  final Color _lightRed = Color(0xFFFFEBEE);
  final Color _goldAccent = Color(0xFFFFB300);
  final Color _orangeAccent = Color(0xFFF57C00);
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
  final Color _royalPurple = Color(0xFF6B4E71);
  
  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rotateController;
  
  // Particle animation controllers for background
  late List<AnimationController> _particleControllers;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  bool _isLoading = false;
  SportsType? _selectedSportType;
  
  final List<SportsType> _sportTypes = [
    SportsType.cricket,
    SportsType.soccer,
    SportsType.basketball,
    SportsType.volleyball,
    SportsType.badminton,
    SportsType.tableTennis,
    SportsType.swimming,
    SportsType.martialArts,
    SportsType.yoga,
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize animations
    _fadeController = AnimationController(vsync: this, duration: Duration(milliseconds: 1000));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    
    _slideController = AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _pulseController = AnimationController(vsync: this, duration: Duration(milliseconds: 1500));
    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
    
    _rotateController = AnimationController(vsync: this, duration: Duration(milliseconds: 1500));
    
    // Initialize particle controllers
    _particleControllers = List.generate(8, (index) {
      return AnimationController(vsync: this, duration: Duration(seconds: 4 + (index % 3)))
        ..repeat(reverse: true);
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
      final educationProvider = Provider.of<EducationProvider>(context, listen: false);
      
      if (locationProvider.isFilterActive && locationProvider.selectedState != null) {
        educationProvider.setFilter(
          EducationCategory.localSports,
          'state',
          locationProvider.selectedState,
        );
        educationProvider.loadSportsClubs();
      }
    });
  }
  
  @override
  void dispose() {
    print('🗑️ SportsClubsScreen disposing...');
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    for (var controller in _particleControllers) { controller.dispose(); }
    super.dispose();
  }

  // Helper function to check if string is a URL
  bool _isUrlString(String str) {
    return str.startsWith('http://') || str.startsWith('https://');
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    print('🔍 Loading sports clubs...');
    
    final provider = Provider.of<EducationProvider>(context, listen: false);
    await provider.loadSportsClubs();
    
    print('📊 Total sports clubs loaded: ${provider.sportsClubs.length}');
    print('✅ Verified clubs: ${provider.sportsClubs.where((s) => s.isVerified).length}');
    
    if (mounted) setState(() => _isLoading = false);
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
                      color: _primaryRed
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
                      content: Text('Showing clubs from all states'), 
                      backgroundColor: Color(0xFFF44336), 
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
                      Icon(Icons.public, color: _primaryRed),
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
                            content: Text('Showing clubs in $state'), 
                            backgroundColor: _primaryRed, 
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? _primaryRed.withOpacity(0.1) : null,
                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: isSelected ? _primaryRed : Colors.grey),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                state, 
                                style: GoogleFonts.poppins(
                                  fontSize: 16, 
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, 
                                  color: isSelected ? _primaryRed : Colors.black87
                                ),
                              ),
                            ),
                            if (isSelected) Icon(Icons.check_circle, color: _primaryRed),
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
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 10, vertical: isTablet ? 6 : 4),
            decoration: BoxDecoration(
              gradient: hasFilter ? LinearGradient(colors: [_primaryRed, _darkRed]) : LinearGradient(colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: hasFilter ? _goldAccent.withOpacity(0.5) : _goldAccent.withOpacity(0.4), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(hasFilter ? Icons.edit_location_rounded : Icons.location_on_rounded, size: isTablet ? 14 : 12, color: hasFilter ? _goldAccent : _goldAccent),
                const SizedBox(width: 4),
                Text(hasFilter ? "Change Location" : "Select Location", style: GoogleFonts.poppins(fontSize: isTablet ? 11 : 10, fontWeight: hasFilter ? FontWeight.w600 : FontWeight.w500, color: Colors.white)),
                if (hasFilter) ...[
                  const SizedBox(width: 4),
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFFFB300), shape: BoxShape.circle)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<SportsClub> _getFilteredClubs(
    List<SportsClub> clubs,
    LocationFilterProvider locationProvider,
  ) {
    var verifiedClubs = clubs.where((club) => club.isVerified == true && club.isActive == true).toList();
    
    print('✅ Verified clubs: ${verifiedClubs.length} out of ${clubs.length} total');
    
    if (locationProvider.isFilterActive && locationProvider.selectedState != null) {
      verifiedClubs = verifiedClubs.where((club) => club.state == locationProvider.selectedState).toList();
      print('📍 After state filter (${locationProvider.selectedState}): ${verifiedClubs.length} clubs');
    }
    
    if (_selectedSportType != null) {
      verifiedClubs = verifiedClubs.where((club) => club.sportType == _selectedSportType).toList();
    }
    
    return verifiedClubs;
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
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _creamWhite,
        body: CustomScrollView(
          slivers: [
            _buildPremiumAppBar(isTablet),
            
            SliverToBoxAdapter(
              child: Consumer<LocationFilterProvider>(
                builder: (context, locationProvider, _) {
                  return GlobalLocationFilterBar(
                    isTablet: isTablet,
                    onClearTap: () {
                      final educationProvider = Provider.of<EducationProvider>(context, listen: false);
                      educationProvider.clearFilter(EducationCategory.localSports, 'state');
                      educationProvider.loadSportsClubs();
                    },
                  );
                },
              ),
            ),
            
            SliverToBoxAdapter(
              child: _buildFilterBar(isTablet),
            ),
            _buildContent(),
          ],
        ),
        floatingActionButton: _buildPremiumFloatingActionButton(isTablet),
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
              colors: [_primaryRed, _darkRed, _royalPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 20,
                vertical: isTablet ? 20 : 12,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 3,
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_goldAccent, _orangeAccent, _goldAccent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  
                  Text(
                    'Local Sports Clubs',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 32 : 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: isTablet ? 12 : 8),
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '🏆 Join sports clubs and stay active',
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
                  
                  SizedBox(height: isTablet ? 12 : 8),
                  
                  Consumer<EducationProvider>(
                    builder: (context, provider, child) {
                      final verifiedCount = provider.sportsClubs
                          .where((c) => c.isVerified && c.isActive)
                          .length;
                      
                      return Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 12 : 8,
                              vertical: isTablet ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.verified_rounded, color: _goldAccent, size: isTablet ? 14 : 12),
                                SizedBox(width: isTablet ? 6 : 4),
                                Text(
                                  '$verifiedCount Verified Clubs',
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
        icon: Icon(Icons.arrow_back_rounded, color: Colors.white, fontWeight: FontWeight.bold, size: isTablet ? 28 : 24),
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
            colors: [_primaryRed, _darkRed, _royalPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 20,
              vertical: isTablet ? 20 : 12,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 3,
                  width: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_goldAccent, _orangeAccent, _goldAccent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: isTablet ? 12 : 8),
                
                Text(
                  'Local Sports Clubs',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 32 : 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: isTablet ? 12 : 8),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '🏆 Join sports clubs and stay active',
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
                
                SizedBox(height: isTablet ? 12 : 8),
                
                Consumer<EducationProvider>(
                  builder: (context, provider, child) {
                    final verifiedCount = provider.sportsClubs
                        .where((c) => c.isVerified && c.isActive)
                        .length;
                    
                    return Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 12 : 8,
                            vertical: isTablet ? 6 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.verified_rounded, color: _goldAccent, size: isTablet ? 14 : 12),
                              SizedBox(width: isTablet ? 6 : 4),
                              Text(
                                '$verifiedCount Verified Clubs',
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
                      Icons.sports_soccer_rounded,
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




  Widget _buildFilterBar(bool isTablet) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 20 : 16),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.filter_list_rounded, color: _primaryRed, size: isTablet ? 22 : 18),
              ),
              SizedBox(width: 12),
              Text(
                'Filter by Sport',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Container(
            height: isTablet ? 50 : 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _sportTypes.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(
                        'All Sports',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          fontWeight: _selectedSportType == null ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      selected: _selectedSportType == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedSportType = null;
                        });
                        HapticFeedback.lightImpact();
                      },
                      backgroundColor: Colors.white,
                      selectedColor: _primaryRed,
                      checkmarkColor: _goldAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(
                          color: _selectedSportType == null ? _primaryRed : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 16 : 12,
                        vertical: isTablet ? 12 : 10,
                      ),
                    ),
                  );
                }
                
                final sport = _sportTypes[index - 1];
                final isSelected = _selectedSportType == sport;
                
                return Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(
                      sport.displayName,
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSportType = selected ? sport : null;
                      });
                      HapticFeedback.lightImpact();
                    },
                    backgroundColor: Colors.white,
                    selectedColor: _primaryRed,
                    checkmarkColor: _goldAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(
                        color: isSelected ? _primaryRed : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 16 : 12,
                      vertical: isTablet ? 12 : 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFloatingActionButton(bool isTablet) {
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    Widget button = Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      child: FloatingActionButton.extended(
        onPressed: () {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.isGuestMode) {
            _showLoginRequiredDialog(context, 'Add New Club');
          } else {
            _showAddClubDialog(context);
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 12,
        label: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 12 : 10,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryRed, _purpleAccent, _tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _primaryRed.withOpacity(0.4),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: isTablet ? 20 : 18),
              SizedBox(width: isTablet ? 8 : 6),
              Text('Add Club', style: GoogleFonts.poppins(fontSize: isTablet ? 14 : 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
    
    return shouldAnimate ? ScaleTransition(scale: _pulseAnimation, child: button) : button;
  }

  Widget _buildContent() {
    return Consumer2<EducationProvider, LocationFilterProvider>(
      builder: (context, provider, locationProvider, child) {
        if (provider.isLoading || _isLoading) return _buildLoadingState();

        final filteredClubs = _getFilteredClubs(provider.sportsClubs, locationProvider);

        if (filteredClubs.isEmpty) return _buildEmptyState(locationProvider);

        return SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final club = filteredClubs[index];
                
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 500 + (index * 100)),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.95 + (0.05 * value),
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: _buildPremiumClubCard(club, index),
                );
              },
              childCount: filteredClubs.length,
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
                        colors: [_primaryRed, _purpleAccent, _tealAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryRed.withOpacity(0.3),
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
                              color: _primaryRed,
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
                colors: [_primaryRed, _purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Loading Clubs...',
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
                      'Finding sports clubs for you 🏃',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 15 : 13,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : Text(
                    'Finding sports clubs for you 🏃',
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
                          colors: [_lightRed, _primaryRed.withOpacity(0.3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sports_rounded,
                        size: isTablet ? 60 : 50,
                        color: _primaryRed,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: isTablet ? 24 : 16),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [_primaryRed, _purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  locationProvider.isFilterActive
                      ? 'No Clubs in ${locationProvider.selectedState}'
                      : _selectedSportType != null 
                          ? 'No ${_selectedSportType!.displayName} Clubs'
                          : 'No Clubs Found',
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
                    ? 'Try clearing the location filter'
                    : _selectedSportType != null 
                        ? 'No clubs for ${_selectedSportType!.displayName} yet'
                        : 'Check back later for clubs',
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
                    educationProvider.clearFilter(EducationCategory.localSports, 'state');
                    educationProvider.loadSportsClubs();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24 : 20,
                      vertical: isTablet ? 12 : 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryRed, _purpleAccent],
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

  // UPDATED: Build club poster image with URL and Base64 support
  Widget _buildClubPosterImage(SportsClub club) {
    final imageData = club.postedByProfileImageBase64;
    
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
              print('Error loading club poster image: $error');
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
                print('Error decoding club poster image: $error');
                return _buildDefaultProfileImage();
              },
            ),
          );
        } catch (e) {
          print('Error processing club poster image: $e');
          return _buildDefaultProfileImage();
        }
      }
    }
    
    return _buildDefaultProfileImage();
  }

  Widget _buildDefaultProfileImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryRed, _purpleAccent],
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

  Widget _buildPremiumTag({
    required IconData icon,
    required String text,
    required Color color,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 8,
        vertical: isTablet ? 5 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isTablet ? 14 : 12),
          SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 12 : 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSportIcon(SportsType sportType) {
    switch (sportType) {
      case SportsType.cricket:
        return Icons.sports_cricket_rounded;
      case SportsType.soccer:
        return Icons.sports_soccer_rounded;
      case SportsType.basketball:
        return Icons.sports_basketball_rounded;
      case SportsType.volleyball:
        return Icons.sports_volleyball_rounded;
      case SportsType.badminton:
        return Icons.sports_tennis_rounded;
      case SportsType.tableTennis:
        return Icons.sports_tennis_rounded;
      case SportsType.swimming:
        return Icons.pool_rounded;
      case SportsType.martialArts:
        return Icons.sports_martial_arts_rounded;
      case SportsType.yoga:
        return Icons.self_improvement_rounded;
      default:
        return Icons.sports_rounded;
    }
  }

/*  Widget _buildPremiumClubCard(SportsClub club, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isFull = club.currentMembers >= club.maxMembers;
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
                    color: _primaryRed.withOpacity(0.2),
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
                          _lightRed.withOpacity(0.3),
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
                            _showLoginRequiredDialog(context, 'View Club Details');
                          } else {
                            _showClubDetails(club);
                          }
                        },
                        borderRadius: BorderRadius.circular(30),
                        splashColor: _goldAccent.withOpacity(0.15),
                        highlightColor: Colors.transparent,
                        child: Padding(
                          padding: EdgeInsets.all(isTablet ? 20 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with User Profile and Name - Using club's stored user info
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
                                              colors: [_primaryRed, _purpleAccent, _tealAccent],
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
                                              child: _buildClubPosterImage(club),
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
                                            colors: [_primaryRed, _purpleAccent],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ).createShader(bounds),
                                          child: Text(
                                            club.postedByName ?? 'Club Owner',
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
                                        Text(
                                          'added this club',
                                          style: TextStyle(
                                            fontSize: isTablet ? 12 : 11,
                                            color: _textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_successGreen, _tealAccent],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _successGreen.withOpacity(0.4),
                                          blurRadius: 10,
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
                                      colors: [_primaryRed, _purpleAccent],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds),
                                    child: Text(
                                      club.clubName,
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
                                  Row(
                                    children: [
                                      Icon(
                                        _getSportIcon(club.sportType),
                                        color: _primaryRed,
                                        size: isTablet ? 18 : 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        club.sportType.displayName,
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 14 : 12,
                                          fontWeight: FontWeight.w600,
                                          color: _primaryRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 14),
                              
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildPremiumTag(
                                    icon: Icons.attach_money_rounded,
                                    text: club.formattedFee,
                                    color: _successGreen,
                                    isTablet: isTablet,
                                  ),
                                  
                                  _buildPremiumTag(
                                    icon: isFull ? Icons.warning_rounded : Icons.people_rounded,
                                    text: club.membershipStatus,
                                    color: isFull ? Colors.red : _infoBlue,
                                    isTablet: isTablet,
                                  ),
                                  
                                  if (club.ageGroups.isNotEmpty)
                                    _buildPremiumTag(
                                      icon: Icons.cake_rounded,
                                      text: club.ageGroups[0],
                                      color: _orangeAccent,
                                      isTablet: isTablet,
                                    ),
                                ],
                              ),
                              
                              if (club.ageGroups.length > 1)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '+${club.ageGroups.length - 1} more age groups',
                                    style: GoogleFonts.inter(
                                      fontSize: isTablet ? 12 : 10,
                                      color: _textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              
                              SizedBox(height: 14),
                              
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(isTablet ? 6 : 5),
                                          decoration: BoxDecoration(
                                            color: _primaryRed.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.location_on_rounded,
                                            color: _primaryRed,
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
                                                '${club.city}, ${club.state}',
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
                                  
                                  if (club.latitude != null && club.longitude != null)
                                    Padding(
                                      padding: EdgeInsets.only(right: isTablet ? 10 : 8),
                                      child: DistanceBadge(
                                        latitude: club.latitude!,
                                        longitude: club.longitude!,
                                        isTablet: isTablet,
                                      ),
                                    ),
                                  
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 12 : 10,
                                      vertical: isTablet ? 8 : 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isFull 
                                            ? [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)]
                                            : [_infoBlue.withOpacity(0.1), _infoBlue.withOpacity(0.05)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isFull ? Colors.red.withOpacity(0.3) : _infoBlue.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.people_rounded,
                                          color: isFull ? Colors.red : _infoBlue,
                                          size: isTablet ? 18 : 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '${club.currentMembers}/${club.maxMembers}',
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 14 : 12,
                                            fontWeight: FontWeight.w700,
                                            color: isFull ? Colors.red : _infoBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
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
                                          _showLoginRequiredDialog(context, 'View Club Details');
                                        } else {
                                          _showClubDetails(club);
                                        }
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          vertical: isTablet ? 14 : 12,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [_primaryRed, _purpleAccent, _tealAccent],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
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
                                            SizedBox(width: 8),
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
            ),
          ),
        );
      },
    );
  }


*/

/*Widget _buildPremiumClubCard(SportsClub club, int index) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isTablet = screenWidth >= 600;
  final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
  
  // Inspired gradient from app bar - lighter, cleaner version
  final LinearGradient _cardGradient = LinearGradient(
    colors: [
      Color(0xFFFFF5F5), // Very light pink/red
      Color(0xFFFFF8E1), // Light gold
      Color(0xFFFCE4EC), // Light rose
      Color(0xFFE8F5E9), // Light green tint
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  final horizontalMargin = isTablet ? 16.0 : 12.0;
  
  Widget cardContent = Container(
    margin: EdgeInsets.symmetric(
      horizontal: horizontalMargin,
      vertical: 6,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 15,
          offset: Offset(0, 5),
          spreadRadius: -1,
        ),
        BoxShadow(
          color: _primaryRed.withOpacity(0.15),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: _cardGradient,
          border: Border.all(
            color: _primaryRed.withOpacity(0.15),
            width: 0.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.isGuestMode) {
                _showLoginRequiredDialog(context, 'View Club Details');
                return;
              }
              _showClubDetails(club);
            },
            borderRadius: BorderRadius.circular(20),
            splashColor: _primaryRed.withOpacity(0.1),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 14 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Row
                  Row(
                    children: [
                      Container(
                        width: isTablet ? 44 : 38,
                        height: isTablet ? 44 : 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [_goldAccent, _orangeAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _goldAccent.withOpacity(0.4),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(1.5),
                          child: ClipOval(
                            child: _buildClubPosterImage(club),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 10),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              club.postedByName ?? 'Club Owner',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 14 : 13,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'added this club',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: _textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Verified Badge
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_goldAccent, _orangeAccent],
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
                  
                  // Club Name
                  Text(
                    club.clubName,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 4),
                  
                  // Sport Type
                  Text(
                    club.sportType.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 11 : 10,
                      fontWeight: FontWeight.w600,
                      color: _primaryRed,
                    ),
                  ),
                  
                  SizedBox(height: 10),
                  
                  // Age Groups Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: club.ageGroups.take(3).map((ageGroup) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _primaryRed.withOpacity(0.25),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          ageGroup,
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 10 : 9,
                            fontWeight: FontWeight.w600,
                            color: _primaryRed,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  if (club.ageGroups.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${club.ageGroups.length - 3} more',
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 10 : 9,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  SizedBox(height: 10),
                  
                  // Location and Distance Badge ONLY (same row)
                  Row(
                    children: [
                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: _primaryRed,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${club.city}, ${club.state}',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 11 : 10,
                              fontWeight: FontWeight.w500,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                      
                      // Spacer
                      Spacer(),
                      
                      // Distance Badge (mandatory)
                      if (club.latitude != null && club.longitude != null)
                        DistanceBadge(
                          latitude: club.latitude!,
                          longitude: club.longitude!,
                          isTablet: isTablet,
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // View Details Button
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      final buttonClampedValue = value.clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: 0.97 + (0.03 * buttonClampedValue),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 8 : 7,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryRed, _purpleAccent],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryRed.withOpacity(0.3),
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
                              shouldAnimate
                                  ? RotationTransition(
                                      turns: _rotateController,
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: isTablet ? 14 : 12,
                                      ),
                                    )
                                  : Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 14 : 12,
                                    ),
                            ],
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


/* Widget _buildPremiumClubCard(SportsClub club, int index) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isTablet = screenWidth >= 600;
  final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
  
  // Colorful gradient - 60% intensity of appbar colors
  // Appbar uses: _primaryRed (0xFFF44336), _purpleAccent (0xFF8E24AA), _tealAccent (0xFF00897B)
  // 60% intensity means more pastel/softer versions
  final LinearGradient _cardGradient = LinearGradient(
    colors: [
      const Color(0xFFFCE4EC), // Soft pink (60% of red)
      const Color(0xFFF3E5F5), // Soft purple (60% of purple)
      const Color(0xFFE0F2F1), // Soft teal (60% of teal)
      const Color(0xFFFFF3E0), // Soft orange (warm accent)
      const Color(0xFFE8EAF6), // Soft indigo
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
  );
  
  final horizontalMargin = isTablet ? 16.0 : 12.0;
  
  Widget cardContent = Container(
    margin: EdgeInsets.symmetric(
      horizontal: horizontalMargin,
      vertical: 6,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 15,
          offset: Offset(0, 5),
          spreadRadius: -1,
        ),
        BoxShadow(
          color: _primaryRed.withOpacity(0.15),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: _cardGradient,
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.isGuestMode) {
                _showLoginRequiredDialog(context, 'View Club Details');
                return;
              }
              _showClubDetails(club);
            },
            borderRadius: BorderRadius.circular(20),
            splashColor: _primaryRed.withOpacity(0.1),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 14 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Row
                  Row(
                    children: [
                      Container(
                        width: isTablet ? 44 : 38,
                        height: isTablet ? 44 : 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [_goldAccent, _orangeAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _goldAccent.withOpacity(0.4),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(1.5),
                          child: ClipOval(
                            child: _buildClubPosterImage(club),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 10),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              club.postedByName ?? 'Club Owner',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 14 : 13,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'added this club',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: _textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Verified Badge
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_goldAccent, _orangeAccent],
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
                  
                  // Club Name
                  Text(
                    club.clubName,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 4),
                  
                  // Sport Type
                  Text(
                    club.sportType.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 11 : 10,
                      fontWeight: FontWeight.w600,
                      color: _primaryRed,
                    ),
                  ),
                  
                  SizedBox(height: 10),
                  
                  // Age Groups Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: club.ageGroups.take(3).map((ageGroup) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _primaryRed.withOpacity(0.25),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          ageGroup,
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 10 : 9,
                            fontWeight: FontWeight.w600,
                            color: _primaryRed,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  if (club.ageGroups.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${club.ageGroups.length - 3} more',
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 10 : 9,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  SizedBox(height: 10),
                  
                  // Location and Distance Badge ONLY (same row)
                  Row(
                    children: [
                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: _primaryRed,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${club.city}, ${club.state}',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 11 : 10,
                              fontWeight: FontWeight.w500,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                      
                      // Spacer
                      Spacer(),
                      
                      // Distance Badge (mandatory)
                      if (club.latitude != null && club.longitude != null)
                        DistanceBadge(
                          latitude: club.latitude!,
                          longitude: club.longitude!,
                          isTablet: isTablet,
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // View Details Button
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      final buttonClampedValue = value.clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: 0.97 + (0.03 * buttonClampedValue),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 8 : 7,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryRed, _purpleAccent],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryRed.withOpacity(0.3),
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
                              shouldAnimate
                                  ? RotationTransition(
                                      turns: _rotateController,
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: isTablet ? 14 : 12,
                                      ),
                                    )
                                  : Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 14 : 12,
                                    ),
                            ],
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

/* Widget _buildPremiumClubCard(SportsClub club, int index) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isTablet = screenWidth >= 600;
  final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
  
  // Dark theme gradient - rich, deep colors
  final LinearGradient _cardGradient = LinearGradient(
    colors: [
      const Color(0xFF2D2D2D), // Dark gray
      const Color(0xFF1A1A2E), // Deep dark blue
      const Color(0xFF16213E), // Dark navy
      const Color(0xFF0F3460), // Deep blue
      const Color(0xFF1B1B2F), // Dark purple-gray
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
  );
  
  final horizontalMargin = isTablet ? 16.0 : 12.0;
  
  Widget cardContent = Container(
    margin: EdgeInsets.symmetric(
      horizontal: horizontalMargin,
      vertical: 6,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 15,
          offset: Offset(0, 6),
          spreadRadius: -1,
        ),
        BoxShadow(
          color: _primaryRed.withOpacity(0.3),
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
            color: _primaryRed.withOpacity(0.3),
            width: 0.8,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.isGuestMode) {
                _showLoginRequiredDialog(context, 'View Club Details');
                return;
              }
              _showClubDetails(club);
            },
            borderRadius: BorderRadius.circular(20),
            splashColor: _primaryRed.withOpacity(0.2),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 14 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Row
                  Row(
                    children: [
                      Container(
                        width: isTablet ? 44 : 38,
                        height: isTablet ? 44 : 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [_goldAccent, _orangeAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _goldAccent.withOpacity(0.5),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(1.5),
                          child: ClipOval(
                            child: _buildClubPosterImage(club),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 10),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              club.postedByName ?? 'Club Owner',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 14 : 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'added this club',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Verified Badge
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_goldAccent, _orangeAccent],
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
                  
                  // Club Name
                  Text(
                    club.clubName,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 4),
                  
                  // Sport Type
                  Text(
                    club.sportType.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 11 : 10,
                      fontWeight: FontWeight.w600,
                      color: _goldAccent,
                    ),
                  ),
                  
                  SizedBox(height: 10),
                  
                  // Age Groups Tags - Dark theme
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: club.ageGroups.take(3).map((ageGroup) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _goldAccent.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          ageGroup,
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 10 : 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  if (club.ageGroups.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${club.ageGroups.length - 3} more',
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 10 : 9,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  SizedBox(height: 10),
                  
                  // Location and Distance Badge
                  Row(
                    children: [
                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: _goldAccent,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${club.city}, ${club.state}',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 11 : 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                      
                      Spacer(),
                      
                      // Distance Badge
                      if (club.latitude != null && club.longitude != null)
                        DistanceBadge(
                          latitude: club.latitude!,
                          longitude: club.longitude!,
                          isTablet: isTablet,
                          color: Colors.grey.shade300,
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // View Details Button - Dark theme
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      final buttonClampedValue = value.clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: 0.97 + (0.03 * buttonClampedValue),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 8 : 7,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryRed, _purpleAccent],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryRed.withOpacity(0.5),
                                blurRadius: 8,
                                offset: Offset(0, 3),
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
                              shouldAnimate
                                  ? RotationTransition(
                                      turns: _rotateController,
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: isTablet ? 14 : 12,
                                      ),
                                    )
                                  : Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 14 : 12,
                                    ),
                            ],
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

Widget _buildPremiumClubCard(SportsClub club, int index) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isTablet = screenWidth >= 600;
  final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
  
  // Dark red inspired gradient - rich, deep burgundy/crimson tones
  final LinearGradient _cardGradient = LinearGradient(
    colors: [
      const Color(0xFFD32F2F), // Dark Red (primary inspiration)
      const Color(0xFFB71C1C), // Deep Red
      const Color(0xFF880E4F), // Deep Purple-Red
      const Color(0xFF4A148C), // Dark Purple
      const Color(0xFF311B92), // Deep Indigo
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
  );
  
  final horizontalMargin = isTablet ? 16.0 : 12.0;
  
  Widget cardContent = Container(
    margin: EdgeInsets.symmetric(
      horizontal: horizontalMargin,
      vertical: 6,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 15,
          offset: Offset(0, 6),
          spreadRadius: -1,
        ),
        BoxShadow(
          color: const Color(0xFFD32F2F).withOpacity(0.3),
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
            color: const Color(0xFFD32F2F).withOpacity(0.4),
            width: 0.8,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.isGuestMode) {
                _showLoginRequiredDialog(context, 'View Club Details');
                return;
              }
              _showClubDetails(club);
            },
            borderRadius: BorderRadius.circular(20),
            splashColor: const Color(0xFFD32F2F).withOpacity(0.2),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 14 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Row
                  Row(
                    children: [
                      Container(
                        width: isTablet ? 44 : 38,
                        height: isTablet ? 44 : 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [_goldAccent, _orangeAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _goldAccent.withOpacity(0.5),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(1.5),
                          child: ClipOval(
                            child: _buildClubPosterImage(club),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 10),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              club.postedByName ?? 'Club Owner',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 14 : 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'added this club',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Verified Badge
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_goldAccent, _orangeAccent],
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
                  
                  // Club Name
                  Text(
                    club.clubName,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 4),
                  
                  // Sport Type
                  Text(
                    club.sportType.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 11 : 10,
                      fontWeight: FontWeight.w600,
                      color: _goldAccent,
                    ),
                  ),
                  
                  SizedBox(height: 10),
                  
                  // Age Groups Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: club.ageGroups.take(3).map((ageGroup) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _goldAccent.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          ageGroup,
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 10 : 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  if (club.ageGroups.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${club.ageGroups.length - 3} more',
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 10 : 9,
                          color: Colors.white.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  SizedBox(height: 10),
                  
                  // Location and Distance Badge
                  Row(
                    children: [
                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: _goldAccent,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${club.city}, ${club.state}',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 11 : 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                      
                      Spacer(),
                      
                      // Distance Badge
                      if (club.latitude != null && club.longitude != null)
                        DistanceBadge(
                          latitude: club.latitude!,
                          longitude: club.longitude!,
                          isTablet: isTablet,
                          color: Colors.white.withOpacity(0.9),
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // View Details Button - WHITE BACKGROUND
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      final buttonClampedValue = value.clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: 0.97 + (0.03 * buttonClampedValue),
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
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'View Details',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFD32F2F),
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
                                        color: const Color(0xFFD32F2F),
                                        size: isTablet ? 14 : 12,
                                      ),
                                    )
                                  : Icon(
                                      Icons.arrow_forward_rounded,
                                      color: const Color(0xFFD32F2F),
                                      size: isTablet ? 14 : 12,
                                    ),
                            ],
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


  void _showClubDetails(SportsClub club) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SportsClubDetailsScreen(
          club: club,
          scrollController: ScrollController(),
          primaryRed: _primaryRed,
          successGreen: _successGreen,
          warningOrange: _warningOrange,
          infoBlue: _infoBlue,
          purpleAccent: _purpleAccent,
          goldAccent: _goldAccent,
          tealAccent: _tealAccent,
          lightRed: _lightRed,
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

  void _showAddClubDialog(BuildContext context) {
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
            child: PremiumAddClubDialog(
              scrollController: scrollController,
              onClubAdded: _loadData,
              primaryRed: _primaryRed,
              successGreen: _successGreen,
              infoBlue: _infoBlue,
              purpleAccent: _purpleAccent,
            ),
          );
        },
      ),
    );
  }
}




// ====================== PREMIUM ADD CLUB DIALOG ======================


class PremiumAddClubDialog extends StatefulWidget {
  final VoidCallback? onClubAdded;
  final ScrollController scrollController;
  final Color primaryRed;
  final Color successGreen;
  final Color infoBlue;
  final Color purpleAccent;

  const PremiumAddClubDialog({
    Key? key,
    this.onClubAdded,
    required this.scrollController,
    required this.primaryRed,
    required this.successGreen,
    required this.infoBlue,
    required this.purpleAccent,
  }) : super(key: key);

  @override
  _PremiumAddClubDialogState createState() => _PremiumAddClubDialogState();
}

class _PremiumAddClubDialogState extends State<PremiumAddClubDialog> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clubNameController = TextEditingController();
  final TextEditingController _coachNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _membershipFeeController = TextEditingController();
  final TextEditingController _scheduleController = TextEditingController();
  final TextEditingController _coachQualificationsController = TextEditingController();
  final TextEditingController _maxMembersController = TextEditingController();
  final TextEditingController _ageGroupController = TextEditingController();
  final TextEditingController _skillLevelController = TextEditingController();
  final TextEditingController _equipmentController = TextEditingController();
  final TextEditingController _amenityController = TextEditingController();
  final TextEditingController _tournamentController = TextEditingController();

  String? _selectedState;
  SportsType? _selectedSportType = SportsType.cricket;
  List<String> _ageGroups = [];
  List<String> _skillLevels = [];
  List<String> _equipmentProvided = [];
  List<String> _amenities = [];
  List<String> _tournaments = [];

  final Color _textPrimary = const Color(0xFF1A2B3C);

  // Location picking
  double? _latitude;
  double? _longitude;
  String? _fullAddress;

  final List<String> _states = CommunityStates.states;
  
  late TabController _tabController;
  late AnimationController _animationController;
  
  // Track app lifecycle and keyboard
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  bool _isKeyboardVisible = false;

  // Track validation errors
  String? _validationError;

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

  @override
  void dispose() {
    print('🗑️ PremiumAddClubDialog disposing...');
    
    WidgetsBinding.instance.removeObserver(this);
    
    _clubNameController.dispose();
    _coachNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _venueController.dispose();
    _descriptionController.dispose();
    _membershipFeeController.dispose();
    _scheduleController.dispose();
    _coachQualificationsController.dispose();
    _maxMembersController.dispose();
    _ageGroupController.dispose();
    _skillLevelController.dispose();
    _equipmentController.dispose();
    _amenityController.dispose();
    _tournamentController.dispose();
    
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _animationController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;
    
    return Container(
      height: screenHeight * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: FadeTransition(
        opacity: _animationController,
        child: Column(
          children: [
            // Premium Header
            Container(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.primaryRed, widget.purpleAccent, widget.infoBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryRed.withOpacity(0.3),
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
                    child: Icon(Icons.sports_rounded, color: widget.successGreen, size: isTablet ? 28 : 22),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Sports Club',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your club will be visible after admin approval',
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
                    colors: [widget.primaryRed, widget.purpleAccent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: widget.primaryRed,
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: isTablet ? 14 : 12),
                unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: isTablet ? 13 : 11),
                tabs: const [
                  Tab(text: 'Basic Info'),
                  Tab(text: 'Club Details'),
                  Tab(text: 'Facilities'),
                ],
              ),
            ),

            // Error Message Display
            if (_validationError != null)
              Container(
                margin: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: GoogleFonts.inter(
                          color: Colors.red[700],
                          fontSize: isTablet ? 14 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _validationError = null;
                        });
                      },
                      icon: Icon(Icons.close_rounded, color: Colors.red, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
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
                    _buildClubDetailsTab(isTablet),
                    _buildFacilitiesTab(isTablet),
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
                        onPressed: () {
                          setState(() {
                            _validationError = null;
                            _tabController.animateTo(_tabController.index - 1);
                          });
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
                              setState(() {
                                _validationError = null;
                              });
                              
                              if (_tabController.index == 0) {
                                if (_validateBasicInfo()) {
                                  _tabController.animateTo(_tabController.index + 1);
                                }
                              } else if (_tabController.index == 1) {
                                if (_validateClubDetailsOnly()) {
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
          _buildSectionHeader('Club Information', Icons.sports_rounded, widget.primaryRed, isTablet),
           SizedBox(height: isTablet ? 20 : 16),
          
          _buildPremiumTextField(
            controller: _clubNameController,
            label: 'Club Name *',
            icon: Icons.sports_rounded,
            isRequired: true,
            isTablet: isTablet,
          ),
           SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumDropdown<SportsType>(
            value: _selectedSportType,
            label: 'Sport Type *',
            icon: Icons.sports_soccer_rounded,
            isRequired: true,
            isTablet: isTablet,
            items: SportsType.values.map((sport) {
              return DropdownMenuItem<SportsType>(
                value: sport,
                child: Text(sport.displayName, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              );
            }).toList(),
            onChanged: (SportsType? newValue) {
              setState(() {
                _selectedSportType = newValue;
              });
            },
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
          builder: (context) => GoogleMapsLocationPicker(
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
            color: _latitude != null ? widget.primaryRed : Colors.grey[300]!,
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
                  colors: [widget.primaryRed, widget.purpleAccent],
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
                      color: widget.primaryRed,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                    const SizedBox(height: 4),
                    Text(
                      'Lat: ${_latitude!.toStringAsFixed(4)}, Lng: ${_longitude!.toStringAsFixed(4)}',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 11 : 10,
                        color: widget.primaryRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: widget.primaryRed,
              size: isTablet ? 16 : 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubDetailsTab(bool isTablet) {
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
          _buildSectionHeader('Club Details', Icons.info_rounded, widget.infoBlue, isTablet),
           SizedBox(height: isTablet ? 20 : 16),
          
          _buildPremiumTextField(
            controller: _venueController,
            label: 'Venue Name/Location *',
            icon: Icons.location_on_rounded,
            isRequired: true,
            isTablet: isTablet,
          ),
           SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTextField(
            controller: _descriptionController,
            label: 'Club Description *',
            icon: Icons.description_rounded,
            maxLines: 4,
            isRequired: true,
            isTablet: isTablet,
          ),
           SizedBox(height: isTablet ? 16 : 12),
          
          Row(
            children: [
              Expanded(
                child: _buildPremiumTextField(
                  controller: _membershipFeeController,
                  label: 'Monthly Fee (\$) *',
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: _buildPremiumTextField(
                  controller: _maxMembersController,
                  label: 'Max Members *',
                  icon: Icons.people_rounded,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                  isTablet: isTablet,
                ),
              ),
            ],
          ),
           SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTextField(
            controller: _scheduleController,
            label: 'Schedule (Optional)',
            icon: Icons.calendar_today_rounded,
            isRequired: false,
            isTablet: isTablet,
          ),
           SizedBox(height: isTablet ? 16 : 12),
          
          _buildSectionHeader('Coach Information', Icons.person_rounded, widget.successGreen, isTablet),
           SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTextField(
            controller: _coachNameController,
            label: 'Coach Name (Optional)',
            icon: Icons.person_rounded,
            isRequired: false,
            isTablet: isTablet,
          ),
           SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTextField(
            controller: _coachQualificationsController,
            label: 'Coach Qualifications (Optional)',
            icon: Icons.school_rounded,
            isRequired: false,
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesTab(bool isTablet) {
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
          _buildSectionHeader('Age Groups', Icons.people_outline_rounded, widget.infoBlue, isTablet),
           SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTagInput(
            controller: _ageGroupController,
            tags: _ageGroups,
            hint: 'Add age group (e.g., Kids 5-12, Adults 18+)',
            onAdd: () {
              if (_ageGroupController.text.trim().isNotEmpty) {
                setState(() {
                  _ageGroups.add(_ageGroupController.text.trim());
                  _ageGroupController.clear();
                });
              }
            },
            onRemove: (index) {
              setState(() {
                _ageGroups.removeAt(index);
              });
            },
            isRequired: true,
            isTablet: isTablet,
          ),
          
           SizedBox(height: isTablet ? 24 : 20),
          
          _buildSectionHeader('Skill Levels', Icons.star_rounded, widget.successGreen, isTablet),
           SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTagInput(
            controller: _skillLevelController,
            tags: _skillLevels,
            hint: 'Add skill level (e.g., Beginner, Intermediate)',
            onAdd: () {
              if (_skillLevelController.text.trim().isNotEmpty) {
                setState(() {
                  _skillLevels.add(_skillLevelController.text.trim());
                  _skillLevelController.clear();
                });
              }
            },
            onRemove: (index) {
              setState(() {
                _skillLevels.removeAt(index);
              });
            },
            isRequired: true,
            isTablet: isTablet,
          ),
          
           SizedBox(height: isTablet ? 24 : 20),
          
          _buildSectionHeader('Equipment Provided', Icons.sports_handball_rounded, widget.primaryRed, isTablet),
           SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTagInput(
            controller: _equipmentController,
            tags: _equipmentProvided,
            hint: 'Add equipment (e.g., Bats, Balls, Nets)',
            onAdd: () {
              if (_equipmentController.text.trim().isNotEmpty) {
                setState(() {
                  _equipmentProvided.add(_equipmentController.text.trim());
                  _equipmentController.clear();
                });
              }
            },
            onRemove: (index) {
              setState(() {
                _equipmentProvided.removeAt(index);
              });
            },
            isRequired: true,
            isTablet: isTablet,
          ),
          
           SizedBox(height: isTablet ? 24 : 20),
          
          _buildSectionHeader('Amenities (Optional)', Icons.room_service_rounded, widget.purpleAccent, isTablet),
           SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTagInput(
            controller: _amenityController,
            tags: _amenities,
            hint: 'Add amenity (e.g., Changing rooms, Parking)',
            onAdd: () {
              if (_amenityController.text.trim().isNotEmpty) {
                setState(() {
                  _amenities.add(_amenityController.text.trim());
                  _amenityController.clear();
                });
              }
            },
            onRemove: (index) {
              setState(() {
                _amenities.removeAt(index);
              });
            },
            isRequired: false,
            isTablet: isTablet,
          ),
          
           SizedBox(height: isTablet ? 24 : 20),
          
          _buildSectionHeader('Tournaments (Optional)', Icons.emoji_events_rounded, const Color(0xFFFFB300), isTablet),
           SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTagInput(
            controller: _tournamentController,
            tags: _tournaments,
            hint: 'Add tournament (e.g., Annual Cricket Cup)',
            onAdd: () {
              if (_tournamentController.text.trim().isNotEmpty) {
                setState(() {
                  _tournaments.add(_tournamentController.text.trim());
                  _tournamentController.clear();
                });
              }
            },
            onRemove: (index) {
              setState(() {
                _tournaments.removeAt(index);
              });
            },
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
          color: widget.primaryRed,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: widget.primaryRed, size: isTablet ? 22 : 18),
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
          borderSide: BorderSide(color: widget.primaryRed, width: 2),
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
      labelStyle: GoogleFonts.poppins(
        fontSize: isTablet ? 14 : 12,
        color: widget.primaryRed,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icon, color: widget.primaryRed, size: isTablet ? 22 : 18),
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
        borderSide: BorderSide(color: widget.primaryRed, width: 2),
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


  Widget _buildPremiumDropdown<T>({
    required T? value,
    required String label,
    required IconData icon,
    required bool isRequired,
    required bool isTablet,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: isTablet ? 14 : 12,
          color: widget.primaryRed,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: widget.primaryRed, size: isTablet ? 22 : 18),
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
          borderSide: BorderSide(color: widget.primaryRed, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 14 : 12,
        ),
      ),
      items: items,
      onChanged: onChanged,
      style: GoogleFonts.inter(
        fontSize: isTablet ? 16 : 14,
        color: Colors.grey[800],
        fontWeight: FontWeight.w600,
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      icon: Icon(Icons.arrow_drop_down_circle_rounded, color: widget.primaryRed, size: isTablet ? 24 : 20),
      isExpanded: true,
      validator: isRequired
          ? (value) {
              if (value == null) {
                return 'Please select an option';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildPremiumTagInput({
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
                    borderSide: BorderSide(color: widget.primaryRed, width: 2),
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
                  colors: [widget.primaryRed, widget.primaryRed.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryRed.withOpacity(0.3),
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
                    colors: [widget.primaryRed.withOpacity(0.1), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: widget.primaryRed.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tags[index],
                      style: GoogleFonts.poppins(
                        color: widget.primaryRed,
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
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.red,
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
                color: Colors.red,
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
                  colors: [widget.primaryRed, widget.purpleAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isPrimary ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: widget.primaryRed, width: 2),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: widget.primaryRed.withOpacity(0.3),
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
              color: isPrimary ? Colors.white : widget.primaryRed,
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
            colors: [widget.successGreen, widget.infoBlue],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.successGreen.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
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
    if (_clubNameController.text.isEmpty) {
      setState(() => _validationError = 'Please enter club name');
      return false;
    }
    if (_selectedSportType == null) {
      setState(() => _validationError = 'Please select sport type');
      return false;
    }
    if (_emailController.text.isEmpty) {
      setState(() => _validationError = 'Please enter email address');
      return false;
    }
    if (!_emailController.text.contains('@')) {
      setState(() => _validationError = 'Please enter a valid email address');
      return false;
    }
    if (_phoneController.text.isEmpty) {
      setState(() => _validationError = 'Please enter phone number');
      return false;
    }
    if (_phoneController.text.length < 10) {
      setState(() => _validationError = 'Please enter a valid phone number (at least 10 digits)');
      return false;
    }
    if (_latitude == null || _longitude == null) {
      setState(() => _validationError = 'Please select a location on the map');
      return false;
    }
    if (_selectedState == null) {
      setState(() => _validationError = 'Location must include a valid state');
      return false;
    }
    if (_cityController.text.isEmpty) {
      setState(() => _validationError = 'Please enter city');
      return false;
    }
    return true;
  }

  bool _validateClubDetailsOnly() {
    if (_venueController.text.isEmpty) {
      setState(() => _validationError = 'Please enter venue name/location');
      return false;
    }
    if (_descriptionController.text.isEmpty) {
      setState(() => _validationError = 'Please enter club description');
      return false;
    }
    if (_descriptionController.text.length < 20) {
      setState(() => _validationError = 'Description should be at least 20 characters');
      return false;
    }
    if (_membershipFeeController.text.isEmpty) {
      setState(() => _validationError = 'Please enter membership fee');
      return false;
    }
    final fee = double.tryParse(_membershipFeeController.text);
    if (fee == null) {
      setState(() => _validationError = 'Please enter a valid number for membership fee');
      return false;
    }
    if (fee < 0) {
      setState(() => _validationError = 'Membership fee cannot be negative');
      return false;
    }
    if (_maxMembersController.text.isEmpty) {
      setState(() => _validationError = 'Please enter maximum members');
      return false;
    }
    final maxMembers = int.tryParse(_maxMembersController.text);
    if (maxMembers == null) {
      setState(() => _validationError = 'Please enter a valid number for maximum members');
      return false;
    }
    if (maxMembers <= 0) {
      setState(() => _validationError = 'Maximum members must be greater than 0');
      return false;
    }
    return true;
  }

  bool _validateAllFields() {
    if (!_validateBasicInfo()) return false;
    if (!_validateClubDetailsOnly()) return false;
    
    if (_ageGroups.isEmpty) {
      setState(() => _validationError = 'Please add at least one age group');
      return false;
    }
    if (_skillLevels.isEmpty) {
      setState(() => _validationError = 'Please add at least one skill level');
      return false;
    }
    if (_equipmentProvided.isEmpty) {
      setState(() => _validationError = 'Please add at least one equipment item');
      return false;
    }
    return true;
  }

  void _submitForm() async {
    print('🔵 Submit button clicked');

    setState(() => _validationError = null);
    
    if (!_validateAllFields()) {
      print('🔴 Validation failed');
      return;
    }

    print('🟢 Validation passed');

    // Get current user from AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    
    if (currentUser == null) {
      setState(() => _validationError = 'You must be logged in to add a sports club');
      return;
    }

    print('📝 Current user: ${currentUser.fullName} (ID: ${currentUser.id})');

    // Get user's profile image
    String? userProfileImage;
    if (currentUser.profileImageUrl != null && currentUser.profileImageUrl!.isNotEmpty) {
      userProfileImage = currentUser.profileImageUrl;
    }

    final provider = Provider.of<EducationProvider>(context, listen: false);

    final newClub = SportsClub(
      clubName: _clubNameController.text,
      sportType: _selectedSportType!,
      coachName: _coachNameController.text.isNotEmpty ? _coachNameController.text : null,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _fullAddress ?? _addressController.text,
      state: _selectedState!,
      city: _cityController.text,
      venue: _venueController.text,
      description: _descriptionController.text,
      ageGroups: _ageGroups,
      skillLevels: _skillLevels,
      membershipFee: double.tryParse(_membershipFeeController.text) ?? 0,
      schedule: _scheduleController.text.isNotEmpty ? _scheduleController.text : null,
      equipmentProvided: _equipmentProvided,
      coachQualifications: _coachQualificationsController.text.isNotEmpty ? _coachQualificationsController.text : null,
      amenities: _amenities,
      tournaments: _tournaments,
      maxMembers: int.tryParse(_maxMembersController.text) ?? 50,
      
      // Location coordinates
      latitude: _latitude,
      longitude: _longitude,
      
      // Store user info directly in the club document
      postedByUserId: currentUser.id,
      postedByName: currentUser.fullName,
      postedByEmail: currentUser.email,
      postedByProfileImageBase64: userProfileImage,
      
      createdBy: currentUser.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      isVerified: false,
      currentMembers: 0,
      logoImageBase64: null,
    );

    print('📝 Creating sports club with createdBy: ${newClub.createdBy} (user ID)');
    print('📍 Location: $_latitude, $_longitude in $_selectedState');
    print('📝 Club will be hidden until admin verification (isVerified: false)');

    // Show loading dialog
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
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
                  child: CircularProgressIndicator(color: widget.primaryRed),
                ),
                const SizedBox(height: 20),
                Text('Submitting...', style: GoogleFonts.poppins()),
              ],
            ),
          ),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 100));
    
    final success = await provider.addSportsClub(newClub);
    
    if (mounted) {
      Navigator.pop(context); // Close loading
    }
    
    if (success && mounted) {
      Navigator.pop(context); // Close dialog
      _showSuccessSnackBar('Sports club added successfully! Pending admin approval. 🏆');
      
      if (widget.onClubAdded != null) {
        widget.onClubAdded!();
      }
    } else if (mounted) {
      setState(() => _validationError = 'Failed to add sports club. Please try again.');
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
        backgroundColor: widget.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}