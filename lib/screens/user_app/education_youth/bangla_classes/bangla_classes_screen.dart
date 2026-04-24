import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:bangla_hub/models/community_services_models.dart';
import 'package:bangla_hub/models/education_models.dart';
import 'package:bangla_hub/models/user_model.dart';
import 'package:bangla_hub/providers/education_provider.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/location_filter_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/auth/signup_screen.dart';
import 'package:bangla_hub/screens/user_app/education_youth/bangla_classes/bangla_class_details_screen.dart';
import 'package:bangla_hub/widgets/common/distance_widget.dart';
import 'package:bangla_hub/widgets/common/global_location_filter_bar.dart';
import 'package:bangla_hub/widgets/common/global_location_guard.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class BanglaClassesScreen extends StatefulWidget {
  @override
  _BanglaClassesScreenState createState() => _BanglaClassesScreenState();
}

class _BanglaClassesScreenState extends State<BanglaClassesScreen> 
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin, WidgetsBindingObserver {
  
  // Premium Color Palette - Bangla Theme
  final Color _primaryOrange = Color(0xFFFF9800);
  final Color _darkOrange = Color(0xFFF57C00);
  final Color _lightOrange = Color(0xFFFFF3E0);
  final Color _redAccent = Color(0xFFE53935);
  final Color _greenAccent = Color(0xFF43A047);
  final Color _goldAccent = Color(0xFFFFB300);
  final Color _purpleAccent = Color(0xFF8E24AA);
  final Color _tealAccent = Color(0xFF00897B);
  final Color _creamWhite = Color(0xFFFAF7F2);
  final Color _textPrimary = Color(0xFF1E2A3A);
  final Color _textSecondary = Color(0xFF5D6D7E);
  final Color _borderLight = Color(0xFFE0E7E9);
  final Color _successGreen = Color(0xFF4CAF50);
  final Color _infoBlue = Color(0xFF2196F3);
  
  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rotateController;
  
  // Particle animation controllers
  late List<AnimationController> _particleControllers;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  bool _isLoading = false;
  String? _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Beginner', 'Intermediate', 'Advanced', 'Conversational', 'Cultural'];

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
      return AnimationController(vsync: this, duration: Duration(seconds: 3 + (index % 3)))
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
          EducationCategory.banglaLanguageCulture,
          'state',
          locationProvider.selectedState,
        );
        educationProvider.loadBanglaClasses();
      }
    });
  }

  @override
  void dispose() {
    print('🗑️ BanglaClassesScreen disposing...');
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
    print('🔍 Loading Bangla classes...');
    
    final provider = Provider.of<EducationProvider>(context, listen: false);
    await provider.loadBanglaClasses();
    
    print('📊 Total Bangla classes loaded: ${provider.banglaClasses.length}');
    print('✅ Verified classes: ${provider.banglaClasses.where((c) => c.isVerified).length}');
    
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
                      content: Text('Showing classes from all states'), 
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
                            content: Text('Showing classes in $state'), 
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
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 10, vertical: isTablet ? 6 : 4),
            decoration: BoxDecoration(
              gradient: hasFilter ? LinearGradient(colors: [_primaryOrange, _darkOrange]) : LinearGradient(colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)]),
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

  List<BanglaClass> _getFilteredClasses(
    List<BanglaClass> classes,
    LocationFilterProvider locationProvider,
  ) {
    var verifiedClasses = classes.where((banglaClass) => banglaClass.isVerified == true && banglaClass.isActive == true).toList();
    
    print('✅ Verified classes: ${verifiedClasses.length} out of ${classes.length} total');
    
    if (locationProvider.isFilterActive && locationProvider.selectedState != null) {
      verifiedClasses = verifiedClasses.where((banglaClass) => banglaClass.state == locationProvider.selectedState).toList();
      print('📍 After state filter (${locationProvider.selectedState}): ${verifiedClasses.length} classes');
    }
    
    if (_selectedFilter != 'All') {
      verifiedClasses = verifiedClasses.where((banglaClass) {
        return banglaClass.classTypes.any((type) => type.toLowerCase().contains(_selectedFilter!.toLowerCase()));
      }).toList();
    }
    
    return verifiedClasses;
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
        body: Stack(
          children: [
            ...List.generate(8, (index) => _buildAnimatedParticle(index, screenWidth, MediaQuery.of(context).size.height)),
            CustomScrollView(
              slivers: [
                _buildPremiumAppBar(isTablet),
                SliverToBoxAdapter(
                  child: Consumer<LocationFilterProvider>(
                    builder: (context, locationProvider, _) {
                      return GlobalLocationFilterBar(
                        isTablet: isTablet,
                        onClearTap: () {
                          final educationProvider = Provider.of<EducationProvider>(context, listen: false);
                          educationProvider.clearFilter(EducationCategory.banglaLanguageCulture, 'state');
                          educationProvider.loadBanglaClasses();
                        },
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(child: _buildFilterChips(isTablet)),
                _buildContent(),
              ],
            ),
          ],
        ),
        floatingActionButton: _buildPremiumFloatingActionButton(isTablet),
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
            opacity: (0.05 + (value * 0.1)) * (0.5 + (index % 3) * 0.1),
            child: Transform.rotate(
              angle: value * 6.28,
              child: Container(
                width: 2 + (index % 3) * 2,
                height: 2 + (index % 3) * 2,
                decoration: BoxDecoration(
                  gradient: RadialGradient(colors: [_primaryOrange.withOpacity(0.1), _redAccent.withOpacity(0.05), Colors.transparent]),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
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
                        colors: [_goldAccent, _greenAccent, _goldAccent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  
                  Text(
                    'Bangla Language & Culture Classes',
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
                          '🌟 Learn Bengali language and cultural heritage',
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
                      final verifiedCount = provider.banglaClasses
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
                                  '$verifiedCount Verified Classes',
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
            colors: [_primaryOrange, _darkOrange, _redAccent],
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
                      colors: [_goldAccent, _greenAccent, _goldAccent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: isTablet ? 12 : 8),
                
                Text(
                  'Bangla Language & Culture Classes',
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
                        '🌟 Learn Bengali language and cultural heritage',
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
                    final verifiedCount = provider.banglaClasses
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
                                '$verifiedCount Verified Classes',
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
                      Icons.language_rounded,
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


  Widget _buildFilterChips(bool isTablet) {
    return Container(
      height: 44,
      margin: EdgeInsets.only(top: 8, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: EdgeInsets.only(right: 10),
            child: FilterChip(
              selected: isSelected,
              label: Text(filter, style: GoogleFonts.poppins(color: isSelected ? Colors.white : _textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: isTablet ? 12 : 11)),
              onSelected: (selected) { setState(() { _selectedFilter = filter; }); HapticFeedback.lightImpact(); },
              backgroundColor: Colors.white,
              selectedColor: _primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: BorderSide(color: isSelected ? _primaryOrange : Color(0xFFE0E7E9), width: 0.8)),
            ),
          );
        },
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
            _showLoginRequiredDialog(context, 'Add New Class');
          } else {
            _showAddClassDialog(context);
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 12,
        label: Container(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: isTablet ? 12 : 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_primaryOrange, _redAccent, _greenAccent]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: _primaryOrange.withOpacity(0.4), blurRadius: 15, offset: Offset(0, 8))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_rounded, color: Colors.white, size: isTablet ? 20 : 18),
              SizedBox(width: isTablet ? 8 : 6),
              Text('Add Class', style: GoogleFonts.poppins(fontSize: isTablet ? 14 : 12, fontWeight: FontWeight.w700, color: Colors.white)),
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

        final filteredClasses = _getFilteredClasses(provider.banglaClasses, locationProvider);

        if (filteredClasses.isEmpty) return _buildEmptyState(locationProvider);

        return SliverPadding(
          padding: EdgeInsets.all(12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final banglaClass = filteredClasses[index];
                return Padding(padding: EdgeInsets.only(bottom: 12), child: _buildCompactClassCard(banglaClass, index));
              },
              childCount: filteredClasses.length,
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
            Text('Loading Classes...', style: GoogleFonts.poppins(color: _textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(LocationFilterProvider locationProvider) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.language_rounded, size: 60, color: _primaryOrange.withOpacity(0.5)),
            SizedBox(height: 16),
            Text(
              locationProvider.isFilterActive ? 'No Classes in ${locationProvider.selectedState}' : 'No Classes Found',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary),
            ),
            SizedBox(height: 8),
            Text(
              locationProvider.isFilterActive ? 'Try clearing the location filter!' : 'Be the first to offer Bangla classes!',
              style: GoogleFonts.inter(fontSize: 12, color: _textSecondary),
            ),
            if (locationProvider.isFilterActive) ...[
              SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  locationProvider.clearLocationFilter();
                  final educationProvider = Provider.of<EducationProvider>(context, listen: false);
                  educationProvider.clearFilter(EducationCategory.banglaLanguageCulture, 'state');
                  educationProvider.loadBanglaClasses();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [_primaryOrange, _redAccent]), borderRadius: BorderRadius.circular(25)),
                  child: Text('Clear Filter', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // UPDATED: Build instructor poster image with URL and Base64 support
  Widget _buildInstructorPosterImage(BanglaClass banglaClass) {
    final imageData = banglaClass.postedByProfileImageBase64;
    
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
              print('Error loading instructor poster image: $error');
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
                print('Error decoding instructor poster image: $error');
                return _buildDefaultProfileImage();
              },
            ),
          );
        } catch (e) {
          print('Error processing instructor poster image: $e');
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

  // Compact Class Card
 
/*  Widget _buildCompactClassCard(BanglaClass banglaClass, int index) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final isFull = banglaClass.enrolledStudents >= banglaClass.maxStudents;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
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
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: _primaryOrange.withOpacity(0.1), blurRadius: 12, offset: Offset(0, 4), spreadRadius: -1)],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    if (authProvider.isGuestMode) {
                      _showLoginRequiredDialog(context, 'View Class Details');
                    } else {
                      _showClassDetails(banglaClass);
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 14 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          children: [
                            Container(
                              width: isTablet ? 40 : 36,
                              height: isTablet ? 40 : 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [_primaryOrange, _redAccent]),
                                border: Border.all(color: _goldAccent, width: 1),
                              ),
                              child: ClipOval(child: _buildInstructorPosterImage(banglaClass)),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    banglaClass.instructorName,
                                    style: GoogleFonts.poppins(fontSize: isTablet ? 14 : 13, fontWeight: FontWeight.w800, color: _textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    banglaClass.organizationName ?? 'Independent',
                                    style: GoogleFonts.poppins(fontSize: isTablet ? 11 : 10, fontWeight: FontWeight.w500, color: _primaryOrange),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(gradient: LinearGradient(colors: [_goldAccent, _greenAccent]), shape: BoxShape.circle),
                              child: shouldAnimate
                                  ? RotationTransition(
                                      turns: _rotateController,
                                      child: Icon(Icons.verified_rounded, color: Colors.white, size: isTablet ? 12 : 10),
                                    )
                                  : Icon(Icons.verified_rounded, color: Colors.white, size: isTablet ? 12 : 10),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 10),
                        
                        // Class Types Preview
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: banglaClass.classTypes.take(2).map((type) {
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 6, vertical: isTablet ? 4 : 3),
                              decoration: BoxDecoration(color: _primaryOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                type,
                                style: GoogleFonts.poppins(fontSize: isTablet ? 10 : 9, fontWeight: FontWeight.w500, color: _primaryOrange),
                              ),
                            );
                          }).toList(),
                        ),
                        
                        if (banglaClass.classTypes.length > 2)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '+${banglaClass.classTypes.length - 2} more',
                              style: GoogleFonts.inter(fontSize: 9, color: _textSecondary),
                            ),
                          ),
                        
                        SizedBox(height: 10),
                        
                        // Location and Fee
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: isTablet ? 12 : 10, color: _primaryOrange),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${banglaClass.city}, ${banglaClass.state}',
                                      style: GoogleFonts.inter(fontSize: isTablet ? 10 : 9, color: _textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (banglaClass.latitude != null && banglaClass.longitude != null)
                              DistanceBadge(
                                latitude: banglaClass.latitude!,
                                longitude: banglaClass.longitude!,
                                isTablet: isTablet,
                              ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(color: _successGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                banglaClass.formattedFee,
                                style: GoogleFonts.poppins(fontSize: isTablet ? 9 : 8, fontWeight: FontWeight.w700, color: _successGreen),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 10),
                        
                        // Duration and Seats
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: isTablet ? 12 : 10, color: _infoBlue),
                            SizedBox(width: 4),
                            Text(
                              banglaClass.formattedDuration,
                              style: GoogleFonts.inter(fontSize: isTablet ? 10 : 9, fontWeight: FontWeight.w500, color: _infoBlue),
                            ),
                            SizedBox(width: 12),
                            Icon(Icons.people_rounded, size: isTablet ? 12 : 10, color: isFull ? Colors.red : _greenAccent),
                            SizedBox(width: 4),
                            Text(
                              isFull ? 'Full' : '${banglaClass.maxStudents - banglaClass.enrolledStudents} seats',
                              style: GoogleFonts.inter(fontSize: isTablet ? 10 : 9, fontWeight: FontWeight.w500, color: isFull ? Colors.red : _greenAccent),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 10),
                        
                        // View Details Button
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: isTablet ? 8 : 7),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [_primaryOrange, _redAccent]), borderRadius: BorderRadius.circular(16)),
                          child: Center(
                            child: Text(
                              'View Details',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: isTablet ? 12 : 11, fontWeight: FontWeight.w700),
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
      },
    );
  }

 */



Widget _buildCompactClassCard(BanglaClass banglaClass, int index) {
  final isTablet = MediaQuery.of(context).size.width >= 600;
  final isFull = banglaClass.enrolledStudents >= banglaClass.maxStudents;
  final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
  
  // Same margin as other cards (16 for tablet, 12 for mobile)
  final horizontalMargin = isTablet ? 16.0 : 12.0;
  
  // Premium gradient - Orange to Red to Green (matching app bar)
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
                _showLoginRequiredDialog(context, 'View Class Details');
              } else {
                _showClassDetails(banglaClass);
              }
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
                      Container(
                        width: isTablet ? 44 : 38,
                        height: isTablet ? 44 : 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFFB300).withOpacity(0.4),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(1.5),
                          child: ClipOval(
                            child: _buildInstructorPosterImage(banglaClass),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 10),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banglaClass.instructorName,
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
                                    color: Color(0xFFFFD700),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  banglaClass.organizationName ?? 'Independent Instructor',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: Color(0xFFFFD700),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Verified Badge - Compact
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
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
                  
                  // Class Types Tags - Compact
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: banglaClass.classTypes.take(2).map((type) {
                      return Container(
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
                          type,
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 10 : 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  if (banglaClass.classTypes.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${banglaClass.classTypes.length - 2} more',
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 10 : 9,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  SizedBox(height: 10),
                  
                  // Location and Fee Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFFFFD700),
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${banglaClass.city}, ${banglaClass.state}',
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 11 : 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Distance Badge
                      if (banglaClass.latitude != null && banglaClass.longitude != null)
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: DistanceBadge(
                            latitude: banglaClass.latitude!,
                            longitude: banglaClass.longitude!,
                            isTablet: isTablet,
                          ),
                        ),
                      
                  /*    Container(
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
                            Icon(
                              Icons.attach_money_rounded,
                              color: Color(0xFFFFD700),
                              size: 10,
                            ),
                            SizedBox(width: 2),
                            Text(
                              banglaClass.formattedFee,
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 10 : 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    */
                    
                    ],
                  ),
                  
                  SizedBox(height: 10),
                  
                  // Duration and Seats Row - Compact
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded, 
                              size: 10,
                              color: Color(0xFFFFD700)
                            ),
                            SizedBox(width: 4),
                            Text(
                              banglaClass.formattedDuration,
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 10 : 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4,),
                                
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
                            Icon(
                              Icons.attach_money_rounded,
                              color: Color(0xFFFFD700),
                              size: 10,
                            ),
                            SizedBox(width: 2),
                            Text(
                              banglaClass.formattedFee,
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 10 : 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                          ],
                        ),
                      ),
                      
                      SizedBox(width: 8),
                      
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
                            Icon(Icons.people_rounded, 
                              size: 10,
                              color: isFull ? Color(0xFFE53935) : Color(0xFFFFD700)
                            ),
                            SizedBox(width: 4),
                            Text(
                              isFull ? 'Full' : '${banglaClass.maxStudents - banglaClass.enrolledStudents} seats',
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 10 : 9,
                                color: isFull ? Color(0xFFE53935) : Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // View Details Button - Compact
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      final buttonClampedValue = value.clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: 0.97 + (0.03 * buttonClampedValue),
                        child: GestureDetector(
                          onTap: () {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            if (authProvider.isGuestMode) {
                              _showLoginRequiredDialog(context, 'View Class Details');
                            } else {
                              _showClassDetails(banglaClass);
                            }
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





 
  void _showClassDetails(BanglaClass banglaClass) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BanglaClassDetailsScreen(
          banglaClass: banglaClass,
          scrollController: ScrollController(),
          primaryOrange: _primaryOrange,
          successGreen: _successGreen,
          redAccent: _redAccent,
          greenAccent: _greenAccent,
          tealAccent: _tealAccent,
          purpleAccent: _purpleAccent,
          goldAccent: _goldAccent,
          lightOrange: _lightOrange,
        ),
      ),
    );
  }

  void _showAddClassDialog(BuildContext context) {
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
            child: PremiumAddBanglaClassDialog(
              scrollController: scrollController,
              onClassAdded: _loadData,
              primaryOrange: _primaryOrange,
              successGreen: _successGreen,
              redAccent: _redAccent,
              greenAccent: _greenAccent,
            ),
          );
        },
      ),
    );
  }
}



// ====================== PREMIUM ADD BANGLA CLASS DIALOG ======================

 class PremiumAddBanglaClassDialog extends StatefulWidget {
  final VoidCallback? onClassAdded;
  final ScrollController scrollController;
  final Color primaryOrange;
  final Color successGreen;
  final Color redAccent;
  final Color greenAccent;

  const PremiumAddBanglaClassDialog({
    Key? key,
    this.onClassAdded,
    required this.scrollController,
    required this.primaryOrange,
    required this.successGreen,
    required this.redAccent,
    required this.greenAccent,
  }) : super(key: key);

  @override
  _PremiumAddBanglaClassDialogState createState() => _PremiumAddBanglaClassDialogState();
}

class _PremiumAddBanglaClassDialogState extends State<PremiumAddBanglaClassDialog> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _instructorNameController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _classFeeController = TextEditingController();
  final TextEditingController _scheduleController = TextEditingController();
  final TextEditingController _classDurationController = TextEditingController();
  final TextEditingController _maxStudentsController = TextEditingController();
  final TextEditingController _qualificationsController = TextEditingController();
  final TextEditingController _classTypeController = TextEditingController();
  final TextEditingController _culturalActivityController = TextEditingController();

  // Location picking
  double? _latitude;
  double? _longitude;
  String? _fullAddress;
  String? _selectedState;

  List<String> _classTypes = [];
  List<TeachingMethod> _selectedMethods = [];
  List<String> _culturalActivities = [];

  final Color _textPrimary = const Color(0xFF1A2B3C);

  final List<String> _states = CommunityStates.states;
  
  late TabController _tabController;
  late AnimationController _animationController;
  
  // Track app lifecycle and keyboard
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  bool _isKeyboardVisible = false;

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
    print('🗑️ PremiumAddBanglaClassDialog disposing...');
    
    WidgetsBinding.instance.removeObserver(this);
    
    _instructorNameController.dispose();
    _organizationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _classFeeController.dispose();
    _scheduleController.dispose();
    _classDurationController.dispose();
    _maxStudentsController.dispose();
    _qualificationsController.dispose();
    _classTypeController.dispose();
    _culturalActivityController.dispose();
    
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
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    return Container(
      height: screenHeight * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: shouldAnimate
          ? FadeTransition(
              opacity: _animationController,
              child: _buildContent(isTablet),
            )
          : _buildContent(isTablet),
    );
  }

  Widget _buildContent(bool isTablet) {
    return Column(
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
                child: Icon(Icons.language_rounded, color: widget.successGreen, size: isTablet ? 28 : 22),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Bangla Language Class',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your class will be visible after admin approval',
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
              Tab(text: 'Class Details'),
              Tab(text: 'Culture & Methods'),
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
                _buildClassDetailsTab(isTablet),
                _buildCultureMethodsTab(isTablet),
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
                            if (_validateClassDetails()) {
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
          _buildSectionHeader('Instructor Information', Icons.person_rounded, widget.primaryOrange, isTablet),
           SizedBox(height: isTablet ? 20 : 16),
          
          _buildPremiumTextField(
            controller: _instructorNameController,
            label: 'Instructor Name *',
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
            color: _latitude != null ? widget.primaryOrange : Colors.grey[300]!,
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
                  colors: [widget.primaryOrange, widget.redAccent],
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
                      color: widget.primaryOrange,
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
                        color: widget.primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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

  Widget _buildClassDetailsTab(bool isTablet) {
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
          _buildSectionHeader('Class Details', Icons.class_rounded, widget.redAccent, isTablet),
           SizedBox(height: isTablet ? 20 : 16),
          
          _buildPremiumTextField(
            controller: _descriptionController,
            label: 'Class Description *',
            icon: Icons.description_rounded,
            maxLines: 3,
            isRequired: true,
            isTablet: isTablet,
          ),
           SizedBox(height: isTablet ? 16 : 12),
          
          Row(
            children: [
              Expanded(
                child: _buildPremiumTextField(
                  controller: _classFeeController,
                  label: 'Class Fee (\$) *',
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Expanded(
                child: _buildPremiumTextField(
                  controller: _classDurationController,
                  label: 'Duration (min) *',
                  icon: Icons.schedule_rounded,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                  isTablet: isTablet,
                ),
              ),
            ],
          ),
           SizedBox(height: isTablet ? 16 : 12),
          
          Row(
            children: [
              Expanded(
                child: _buildPremiumTextField(
                  controller: _maxStudentsController,
                  label: 'Max Students *',
                  icon: Icons.people_rounded,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Expanded(
                child: _buildPremiumTextField(
                  controller: _scheduleController,
                  label: 'Schedule (Optional)',
                  icon: Icons.calendar_today_rounded,
                  isRequired: false,
                  isTablet: isTablet,
                ),
              ),
            ],
          ),
           SizedBox(height: isTablet ? 16 : 12),
          
          _buildSectionHeader('Class Types', Icons.category_rounded, widget.successGreen, isTablet),
           SizedBox(height: isTablet ? 12 : 8),
          
          _buildPremiumTagInput(
            controller: _classTypeController,
            tags: _classTypes,
            hint: 'Add class type (e.g., Beginner, Conversational)',
            onAdd: () {
              if (_classTypeController.text.trim().isNotEmpty) {
                setState(() {
                  _classTypes.add(_classTypeController.text.trim());
                  _classTypeController.clear();
                });
              }
            },
            onRemove: (index) {
              setState(() {
                _classTypes.removeAt(index);
              });
            },
            isRequired: true,
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildCultureMethodsTab(bool isTablet) {
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
          _buildSectionHeader('Teaching Methods', Icons.video_call_rounded, widget.greenAccent, isTablet),
           SizedBox(height: isTablet ? 16 : 12),
          
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
                  activeColor: widget.greenAccent,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: 4),
                );
              }).toList(),
            ),
          ),
          
           SizedBox(height: isTablet ? 24 : 20),
          
          _buildSectionHeader('Instructor Qualifications', Icons.school_rounded, widget.primaryOrange, isTablet),
           SizedBox(height: isTablet ? 12 : 8),
          
          _buildPremiumTextField(
            controller: _qualificationsController,
            label: 'Qualifications (Optional)',
            icon: Icons.school_rounded,
            maxLines: 2,
            isRequired: false,
            isTablet: isTablet,
          ),
          
           SizedBox(height: isTablet ? 24 : 20),
          
          _buildSectionHeader('Cultural Activities', Icons.celebration_rounded, widget.redAccent, isTablet),
           SizedBox(height: isTablet ? 12 : 8),
          
          _buildPremiumTagInput(
            controller: _culturalActivityController,
            tags: _culturalActivities,
            hint: 'Add cultural activity (e.g., Poetry, Music)',
            onAdd: () {
              if (_culturalActivityController.text.trim().isNotEmpty) {
                setState(() {
                  _culturalActivities.add(_culturalActivityController.text.trim());
                  _culturalActivityController.clear();
                });
              }
            },
            onRemove: (index) {
              setState(() {
                _culturalActivities.removeAt(index);
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
                  colors: [widget.primaryOrange, widget.primaryOrange.withOpacity(0.7)],
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

  Widget _buildSubmitButton(bool isTablet) {
    return GestureDetector(
      onTap: _submitForm,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 16 : 14,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.successGreen, widget.greenAccent],
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
    if (_instructorNameController.text.isEmpty) {
      _showErrorSnackBar('Please enter instructor name');
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

  bool _validateClassDetails() {
    if (_descriptionController.text.isEmpty) {
      _showErrorSnackBar('Please enter class description');
      return false;
    }
    if (_descriptionController.text.length < 20) {
      _showErrorSnackBar('Description should be at least 20 characters');
      return false;
    }
    if (_classFeeController.text.isEmpty) {
      _showErrorSnackBar('Please enter class fee');
      return false;
    }
    final fee = double.tryParse(_classFeeController.text);
    if (fee == null || fee <= 0) {
      _showErrorSnackBar('Please enter a valid class fee');
      return false;
    }
    if (_classDurationController.text.isEmpty) {
      _showErrorSnackBar('Please enter class duration');
      return false;
    }
    final duration = int.tryParse(_classDurationController.text);
    if (duration == null || duration <= 0) {
      _showErrorSnackBar('Please enter a valid duration in minutes');
      return false;
    }
    if (_maxStudentsController.text.isEmpty) {
      _showErrorSnackBar('Please enter maximum students');
      return false;
    }
    final maxStudents = int.tryParse(_maxStudentsController.text);
    if (maxStudents == null || maxStudents <= 0) {
      _showErrorSnackBar('Please enter a valid maximum number of students');
      return false;
    }
    if (_classTypes.isEmpty) {
      _showErrorSnackBar('Please add at least one class type');
      return false;
    }
    return true;
  }

  void _submitForm() async {
    if (!_validateBasicInfo()) return;
    if (!_validateClassDetails()) return;
    
    if (_selectedMethods.isEmpty) {
      _showErrorSnackBar('Please select at least one teaching method');
      return;
    }

    // Get current user from AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    
    if (currentUser == null) {
      _showErrorSnackBar('You must be logged in to add a Bangla class');
      return;
    }

    print('📝 Current user: ${currentUser.fullName} (ID: ${currentUser.id})');

    final provider = Provider.of<EducationProvider>(context, listen: false);

    // Get user's profile image
    String? userProfileImage;
    if (currentUser.profileImageUrl != null && currentUser.profileImageUrl!.isNotEmpty) {
      userProfileImage = currentUser.profileImageUrl;
    }

    final newClass = BanglaClass(
      instructorName: _instructorNameController.text,
      organizationName: _organizationController.text.isNotEmpty ? _organizationController.text : null,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _fullAddress ?? _addressController.text,
      state: _selectedState!,
      city: _cityController.text,
      classTypes: _classTypes,
      teachingMethods: _selectedMethods,
      description: _descriptionController.text,
      classFee: double.tryParse(_classFeeController.text) ?? 0,
      schedule: _scheduleController.text.isNotEmpty ? _scheduleController.text : null,
      classDuration: int.tryParse(_classDurationController.text) ?? 60,
      maxStudents: int.tryParse(_maxStudentsController.text) ?? 10,
      qualifications: _qualificationsController.text.isNotEmpty ? _qualificationsController.text : null,
      culturalActivities: _culturalActivities,
      
      // Location coordinates
      latitude: _latitude,
      longitude: _longitude,
      
      // Store user info directly in the class document
      postedByUserId: currentUser.id,
      postedByName: currentUser.fullName,
      postedByEmail: currentUser.email,
      postedByProfileImageBase64: userProfileImage,
      
      createdBy: currentUser.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      isVerified: false,
      enrolledStudents: 0,
    );

    print('📝 Creating Bangla class with createdBy: ${newClass.createdBy} (user ID)');
    print('📍 Location: $_latitude, $_longitude in $_selectedState');
    print('📝 Class will be hidden until admin verification (isVerified: false)');

    // Show loading
    if (!mounted) return;
    
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

    final success = await provider.addBanglaClass(newClass);
    
    if (mounted) Navigator.pop(context); // Close loading
    
    if (success && mounted) {
      Navigator.pop(context); // Close dialog
      _showSuccessSnackBar('Bangla class added successfully! Pending admin approval. ✨');
      
      if (widget.onClassAdded != null) {
        widget.onClassAdded!();
      }
    } else if (mounted) {
      _showErrorSnackBar('Failed to add Bangla class. Please try again.');
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
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }
}