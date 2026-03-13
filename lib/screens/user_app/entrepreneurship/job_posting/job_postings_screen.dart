// screens/user_app/entrepreneurship/job_posting/job_postings_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:bangla_hub/models/community_services_models.dart';
import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/location_filter_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/auth/signup_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/job_posting/job_details_screen.dart';
import 'package:bangla_hub/widgets/common/distance_widget.dart';
import 'package:bangla_hub/widgets/common/global_location_filter_bar.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class JobPostingsScreen extends StatefulWidget {
  @override
  _JobPostingsScreenState createState() => _JobPostingsScreenState();
}

class _JobPostingsScreenState extends State<JobPostingsScreen> 
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin, WidgetsBindingObserver {
  
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
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _rotateController;
  
  // Particle animation controllers
  late List<AnimationController> _particleControllers;
  late List<AnimationController> _bubbleControllers;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  bool _isLoading = false;
  String? _selectedFilter = 'All';
  bool _isFilterView = false;
  final ScrollController _filterScrollController = ScrollController();
  
  // LOCAL FILTER STATE - completely separate from global filter
  String? _localSelectedState;
  String? _localSelectedCity;
  JobType? _localSelectedJobType;
  ExperienceLevel? _localSelectedExperienceLevel;
  
  // Track which local filters are active (for display)
  bool _hasLocalFilters = false;
  Map<String, dynamic> _activeLocalFilters = {};
  
  final List<String> _filters = ['All', 'Full Time', 'Part Time', 'Contract', 'Internship', 'Urgent'];

  // Track previous global filter state for UI updates
  bool _previousGlobalFilterState = false;

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

  @override
  void dispose() {
    print('🗑️ JobPostingsScreen disposing...');
    
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
      
      // IMPORTANT: Do NOT apply global filter automatically to provider
      // The provider handles global filter separately
      
      // Apply LOCAL filters if any
      if (_hasLocalFilters) {
        if (_localSelectedState != null) {
          provider.setFilter(EntrepreneurshipCategory.jobPostings, 'local_state', _localSelectedState);
        }
        if (_localSelectedCity != null && _localSelectedCity!.isNotEmpty) {
          provider.setFilter(EntrepreneurshipCategory.jobPostings, 'local_city', _localSelectedCity);
        }
        if (_localSelectedJobType != null) {
          provider.setFilter(EntrepreneurshipCategory.jobPostings, 'local_jobType', _localSelectedJobType);
        }
        if (_localSelectedExperienceLevel != null) {
          provider.setFilter(EntrepreneurshipCategory.jobPostings, 'local_experienceLevel', _localSelectedExperienceLevel);
        }
      }
      
      await provider.loadJobPostings();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading jobs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _applyLocalFilters() async {
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    // Clear any existing local filters first
    provider.clearAllFilters(EntrepreneurshipCategory.jobPostings);
    
    // Build active filters map for display
    Map<String, dynamic> newActiveFilters = {};
    
    // Apply new local filters
    if (_localSelectedState != null) {
      provider.setFilter(EntrepreneurshipCategory.jobPostings, 'local_state', _localSelectedState);
      newActiveFilters['local_state'] = _localSelectedState;
    }
    if (_localSelectedCity != null && _localSelectedCity!.isNotEmpty) {
      provider.setFilter(EntrepreneurshipCategory.jobPostings, 'local_city', _localSelectedCity);
      newActiveFilters['local_city'] = _localSelectedCity;
    }
    if (_localSelectedJobType != null) {
      provider.setFilter(EntrepreneurshipCategory.jobPostings, 'local_jobType', _localSelectedJobType);
      newActiveFilters['local_jobType'] = _localSelectedJobType!.displayName;
    }
    if (_localSelectedExperienceLevel != null) {
      provider.setFilter(EntrepreneurshipCategory.jobPostings, 'local_experienceLevel', _localSelectedExperienceLevel);
      newActiveFilters['local_experienceLevel'] = _localSelectedExperienceLevel!.displayName;
    }
    
    setState(() {
      _hasLocalFilters = newActiveFilters.isNotEmpty;
      _activeLocalFilters = newActiveFilters;
      _isFilterView = false;
    });
    
    await provider.loadJobPostings();
  }

  void _clearLocalFilters() {
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    // Clear all local filters from provider
    provider.clearAllFilters(EntrepreneurshipCategory.jobPostings);
    
    // Reset local state
    setState(() {
      _localSelectedState = null;
      _localSelectedCity = null;
      _localSelectedJobType = null;
      _localSelectedExperienceLevel = null;
      _hasLocalFilters = false;
      _activeLocalFilters.clear();
      _isFilterView = false;
    });
    
    provider.loadJobPostings();
  }

  // Get filtered jobs - applying BOTH global and local filters
  List<JobPosting> _getFilteredJobs(
    List<JobPosting> jobs,
    LocationFilterProvider locationProvider,
  ) {
    // Start with all verified jobs
    var filteredJobs = jobs.where((job) => job.isVerified).toList();
    
    // Apply GLOBAL location filter if active (from LocationFilterProvider)
    if (locationProvider.isFilterActive && locationProvider.selectedState != null) {
      filteredJobs = filteredJobs.where((job) {
        return job.state == locationProvider.selectedState;
      }).toList();
      print('📍 After GLOBAL filter (${locationProvider.selectedState}): ${filteredJobs.length} jobs');
    }
    
    // Apply LOCAL filters if any (from this screen's filter view)
    if (_hasLocalFilters) {
      // State filter
      if (_localSelectedState != null) {
        filteredJobs = filteredJobs.where((job) => 
          job.state == _localSelectedState
        ).toList();
      }
      
      // City filter
      if (_localSelectedCity != null && _localSelectedCity!.isNotEmpty) {
        filteredJobs = filteredJobs.where((job) => 
          job.city.toLowerCase().contains(_localSelectedCity!.toLowerCase())
        ).toList();
      }
      
      // Job type filter
      if (_localSelectedJobType != null) {
        filteredJobs = filteredJobs.where((job) => 
          job.jobType == _localSelectedJobType
        ).toList();
      }
      
      // Experience level filter
      if (_localSelectedExperienceLevel != null) {
        filteredJobs = filteredJobs.where((job) => 
          job.experienceLevel == _localSelectedExperienceLevel
        ).toList();
      }
      
      print('📊 After LOCAL filters: ${filteredJobs.length} jobs');
    }
    
    // Apply category filter (from chips)
    if (_selectedFilter == 'Urgent') {
      filteredJobs = filteredJobs.where((job) => job.isUrgent).toList();
    } else if (_selectedFilter != 'All') {
      filteredJobs = filteredJobs.where((job) => 
        job.jobType.displayName == _selectedFilter
      ).toList();
    }
    
    return filteredJobs;
  }

  Future<List<String>> _getCitiesForState(String state) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('job_postings')
          .where('state', isEqualTo: state)
          .where('isDeleted', isEqualTo: false)
          .get();
      
      final cities = querySnapshot.docs
          .map((doc) => doc.data()['city'] as String?)
          .where((city) => city != null && city.isNotEmpty)
          .toSet()
          .toList() as List<String>;
      
      cities.sort();
      return cities;
    } catch (e) {
      print('Error getting cities: $e');
      return [];
    }
  }

  int _getActiveLocalFilterCount() {
    return _activeLocalFilters.length;
  }

  IconData _getIconForLocalFilter(String key) {
    switch (key) {
      case 'local_state': return Icons.location_on_rounded;
      case 'local_city': return Icons.location_city_rounded;
      case 'local_jobType': return Icons.schedule_rounded;
      case 'local_experienceLevel': return Icons.timeline_rounded;
      default: return Icons.filter_alt_rounded;
    }
  }

  void _showLoginRequiredDialog(BuildContext context, String feature) {
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
              // Header with gradient
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryRed, _tealAccent],
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
                    
                    // Login Button
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
                          backgroundColor: _tealAccent,
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
                    
                    // Sign Up Button
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
                          foregroundColor: _tealAccent,
                          side: BorderSide(color: _tealAccent, width: 2),
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
                    
                    // Continue Browsing
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
        backgroundColor: _creamWhite,
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_creamWhite, _lightRed, _creamWhite],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.4, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Animated Background Particles
              ...List.generate(30, (index) => _buildAnimatedParticle(index)),
              
              // Floating Bubbles
              ...List.generate(8, (index) => _buildFloatingBubble(index)),
              
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
                          
                          // Category Filter Chips (still separate)
                          SliverToBoxAdapter(
                            child: _buildFilterChips(isTablet),
                          ),
                          
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
    // Initialize temp values with current local filters
    _localSelectedState ??= _activeLocalFilters['local_state'];
    _localSelectedJobType ??= _activeLocalFilters.containsKey('local_jobType') 
        ? JobType.values.firstWhere(
            (type) => type.displayName == _activeLocalFilters['local_jobType'],
            orElse: () => JobType.fullTime,
          )
        : null;
    _localSelectedExperienceLevel ??= _activeLocalFilters.containsKey('local_experienceLevel')
        ? ExperienceLevel.values.firstWhere(
            (level) => level.displayName == _activeLocalFilters['local_experienceLevel'],
            orElse: () => ExperienceLevel.entry,
          )
        : null;
    
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
                                colors: [_primaryRed, _purpleAccent],
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
                        FutureBuilder<List<String>>(
                          future: _getCitiesForState(_localSelectedState!),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return _buildDropdown<String?>(
                              value: _localSelectedCity,
                              label: 'Select City',
                              icon: Icons.location_city_rounded,
                              items: [
                                DropdownMenuItem<String?>(value: null, child: Text('All Cities')),
                                ...snapshot.data!.map((city) => 
                                  DropdownMenuItem<String?>(value: city, child: Text(city))
                                ),
                              ],
                              onChanged: (String? newValue) {
                                setState(() => _localSelectedCity = newValue);
                              },
                              isTablet: isTablet,
                            );
                          },
                        ),
                      ],
                      
                      SizedBox(height: 16),
                      
                      // Job Type Dropdown
                      _buildDropdown<JobType?>(
                        value: _localSelectedJobType,
                        label: 'Job Type',
                        icon: Icons.schedule_rounded,
                        items: [
                          DropdownMenuItem<JobType?>(value: null, child: Text('All Types')),
                          ...JobType.values.map((type) => 
                            DropdownMenuItem<JobType?>(
                              value: type,
                              child: Text(type.displayName),
                            )
                          ),
                        ],
                        onChanged: (JobType? newValue) {
                          setState(() => _localSelectedJobType = newValue);
                        },
                        isTablet: isTablet,
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Experience Level Dropdown
                      _buildDropdown<ExperienceLevel?>(
                        value: _localSelectedExperienceLevel,
                        label: 'Experience Level',
                        icon: Icons.timeline_rounded,
                        items: [
                          DropdownMenuItem<ExperienceLevel?>(value: null, child: Text('All Levels')),
                          ...ExperienceLevel.values.map((level) => 
                            DropdownMenuItem<ExperienceLevel?>(
                              value: level,
                              child: Text(level.displayName),
                            )
                          ),
                        ],
                        onChanged: (ExperienceLevel? newValue) {
                          setState(() => _localSelectedExperienceLevel = newValue);
                        },
                        isTablet: isTablet,
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
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
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
              ? LinearGradient(colors: [_primaryRed, _purpleAccent])
              : LinearGradient(colors: [_tealAccent, _infoBlue]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (_hasLocalFilters ? _primaryRed : _tealAccent).withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            shouldAnimate
                ? RotationTransition(
                    turns: _rotateController,
                    child: Icon(
                      _hasLocalFilters ? Icons.filter_alt_rounded : Icons.tune_rounded,
                      color: Colors.white,
                      size: isTablet ? 20 : 18,
                    ),
                  )
                : Icon(
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
                  '${_getActiveLocalFilterCount()}',
                  style: GoogleFonts.poppins(
                    color: _primaryRed,
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
          case 'local_jobType':
            label = 'Job Type: $value';
            icon = Icons.schedule_rounded;
            break;
          case 'local_experienceLevel':
            label = 'Experience: $value';
            icon = Icons.timeline_rounded;
            break;
        }
        
        chips.add(_buildFilterChip(
          label: label,
          icon: icon,
          onRemove: () {
            // Remove this specific local filter
            final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
            provider.clearFilter(EntrepreneurshipCategory.jobPostings, key);
            
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
                case 'local_jobType':
                  _localSelectedJobType = null;
                  break;
                case 'local_experienceLevel':
                  _localSelectedExperienceLevel = null;
                  break;
              }
            });
            
            provider.loadJobPostings();
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
                  color: _primaryRed,
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
        gradient: LinearGradient(
          colors: [_primaryRed, _purpleAccent],
        ),
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
          prefixIcon: Icon(icon, color: _primaryRed, size: 20),
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
        icon: Icon(Icons.arrow_drop_down, color: _primaryRed),
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
              ? LinearGradient(colors: [_primaryRed, _purpleAccent])
              : null,
          color: isPrimary ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isPrimary ? null : Border.all(color: _primaryRed, width: 2),
          boxShadow: isPrimary
              ? [BoxShadow(color: _primaryRed.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 6))]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isPrimary ? Colors.white : _primaryRed,
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
              colors: [_primaryRed, _darkRed, _royalPurple],
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
                      'Job Postings',
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
                    '💼 Find Your Dream Job Today',
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
                      final verifiedCount = provider.jobPostings
                          .where((j) => j.isVerified)
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
                                Icon(Icons.work_rounded, color: _goldAccent, size: isTablet ? 18 : 16),
                                SizedBox(width: isTablet ? 8 : 6),
                                Text(
                                  '$verifiedCount Active Jobs',
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
        icon: Icon(Icons.arrow_back_rounded, color: Colors.white, size: isTablet ? 28 : 24),
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
                      _primaryRed.withOpacity(0.5),
                      _goldAccent.withOpacity(0.3),
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
                      _lightRed.withOpacity(0.3),
                      _goldAccent.withOpacity(0.2),
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

  Widget _buildFilterChips(bool isTablet) {
    return Container(
      height: 60,
      margin: EdgeInsets.only(top: 8, bottom: 8),
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
                style: GoogleFonts.poppins(
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
              selectedColor: _primaryRed,
              checkmarkColor: _goldAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: isSelected ? _primaryRed : _borderLight,
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
    
    Widget button = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryRed, _purpleAccent, _tealAccent],
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
            color: _goldAccent.withOpacity(0.4),
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
              _showLoginRequiredDialog(context, 'Post a Job');
              return;
            }
            _showAddJobDialog(context);
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
                  'Post a Job',
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

        final filteredJobs = _getFilteredJobs(provider.jobPostings, locationProvider);

        if (filteredJobs.isEmpty) {
          return _buildEmptyState(locationProvider);
        }

        return SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final job = filteredJobs[index];
                
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: _buildPremiumJobCard(job, index),
                    ),
                  ),
                );
              },
              childCount: filteredJobs.length,
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
                'Loading Jobs...',
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
                'Finding opportunities for you',
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
    
    String emptyMessage = 'No jobs available';
    if (locationProvider.isFilterActive && _hasLocalFilters) {
      emptyMessage = 'No jobs in ${locationProvider.selectedState} with your local filters';
    } else if (locationProvider.isFilterActive) {
      emptyMessage = 'No jobs in ${locationProvider.selectedState}';
    } else if (_hasLocalFilters) {
      emptyMessage = 'No jobs match your local filters';
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
                          colors: [_lightRed, _primaryRed.withOpacity(0.3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: _appLifecycleState == AppLifecycleState.resumed
                          ? RotationTransition(
                              turns: _rotateController,
                              child: Icon(
                                Icons.work_off_rounded,
                                size: isTablet ? 60 : 50,
                                color: _primaryRed,
                              ),
                            )
                          : Icon(
                              Icons.work_off_rounded,
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
                locationProvider.isFilterActive || _hasLocalFilters
                    ? 'Try adjusting your filters or post a job!'
                    : 'Be the first to post a job',
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
                              colors: [_primaryRed, _purpleAccent],
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
                              colors: [_tealAccent, _infoBlue],
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

  Widget _buildPremiumJobCard(JobPosting job, int index) {
    final isDeadlineNear = job.applicationDeadline.difference(DateTime.now()).inDays <= 7;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
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
                            _showLoginRequiredDialog(context, 'View Job Details');
                            return;
                          }
                          _showJobDetails(job);
                        },
                        borderRadius: BorderRadius.circular(30),
                        splashColor: _goldAccent.withOpacity(0.15),
                        highlightColor: Colors.transparent,
                        child: Padding(
                          padding: EdgeInsets.all(isTablet ? 20 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User Info Row
                              Row(
                                children: [
                                  // User Profile Image
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
                                              child: _buildJobPosterImage(job),
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
                                        ShaderMask(
                                          shaderCallback: (bounds) => LinearGradient(
                                            colors: [_primaryRed, _purpleAccent],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ).createShader(bounds),
                                          child: Text(
                                            job.postedByName ?? 'Unknown User',
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
                                                  colors: [_primaryRed, _purpleAccent],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'Job Provider',
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
                                  if (job.isVerified)
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
                                      child: _appLifecycleState == AppLifecycleState.resumed
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
                              
                              // Distance Badge - Add if location available
                              if (job.latitude != null && job.longitude != null)
                                Consumer<LocationFilterProvider>(
                                  builder: (context, locationProvider, _) {
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 12),
                                      child: DistanceBadge(
                                        latitude: job.latitude!,
                                        longitude: job.longitude!,
                                        isTablet: isTablet,
                                      ),
                                    );
                                  },
                                ),
                              
                              // Job Title and Company
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ShaderMask(
                                          shaderCallback: (bounds) => LinearGradient(
                                            colors: [_primaryRed, _purpleAccent],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ).createShader(bounds),
                                          child: Text(
                                            job.jobTitle,
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
                                      ),
                                      if (job.isUrgent)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [_primaryRed, _darkRed],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.priority_high_rounded, 
                                                color: Colors.white, 
                                                size: 12,
                                              ),
                                              SizedBox(width: 3),
                                              Text(
                                                'Urgent',
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
                                  SizedBox(height: 6),
                                  Text(
                                    job.companyName,
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 14 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: _primaryRed,
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
                                  _buildSmallPremiumTag(job.jobType.displayName, Icons.schedule_rounded, isTablet),
                                  _buildSmallPremiumTag(job.experienceLevel.displayName, Icons.timeline_rounded, isTablet),
                                  _buildSmallPremiumTag('${job.city}, ${job.state}', Icons.location_on_rounded, isTablet),
                                ],
                              ),
                              
                              SizedBox(height: 14),
                              
                              // Description preview
                              Text(
                                job.description.length > 90
                                    ? '${job.description.substring(0, 90)}...'
                                    : job.description,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 13 : 12,
                                  color: _textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              
                              SizedBox(height: 14),
                              
                              // Bottom row with deadline
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 12,
                                    color: isDeadlineNear ? _warningOrange : _textSecondary,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Apply by: ${DateFormat('MMM d, yyyy').format(job.applicationDeadline)}',
                                    style: GoogleFonts.inter(
                                      fontSize: isTablet ? 11 : 10,
                                      color: isDeadlineNear ? _warningOrange : _textSecondary,
                                      fontWeight: isDeadlineNear ? FontWeight.w600 : FontWeight.normal,
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
                                          _showLoginRequiredDialog(context, 'View Job Details');
                                          return;
                                        }
                                        _showJobDetails(job);
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
                                            SizedBox(width: 10),
                                            _appLifecycleState == AppLifecycleState.resumed
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

  Widget _buildSmallPremiumTag(String text, IconData icon, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 8,
        vertical: isTablet ? 6 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _goldAccent.withOpacity(0.25)),
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

  Widget _buildJobPosterImage(JobPosting job) {
    if (job.postedByProfileImageBase64 != null && job.postedByProfileImageBase64!.isNotEmpty) {
      try {
        String base64String = job.postedByProfileImageBase64!;
        
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

  void _showJobDetails(JobPosting job) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => JobDetailsScreen(
          job: job,
          scrollController: ScrollController(),
          onLaunchPhone: _launchPhone,
          onLaunchEmail: _launchEmail,
          onLaunchUrl: _launchUrl,
          primaryRed: _primaryRed,
          goldAccent: _goldAccent,
          purpleAccent: _purpleAccent,
          tealAccent: _tealAccent,
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

  void _showAddJobDialog(BuildContext context) {
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
            child: PremiumAddJobDialog(
              scrollController: scrollController,
              onJobPosted: _loadData,
              primaryRed: _primaryRed,
              goldAccent: _goldAccent,
              purpleAccent: _purpleAccent,
              lightRed: _lightRed,
            ),
          );
        },
      ),
    );
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
      query: 'subject=Job Application Inquiry',
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
        backgroundColor: _darkRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.all(16),
      ),
    );
  }
}


class PremiumAddJobDialog extends StatefulWidget {
  final VoidCallback? onJobPosted;
  final ScrollController scrollController;
  final Color primaryRed;
  final Color goldAccent;
  final Color purpleAccent;
  final Color lightRed;

  const PremiumAddJobDialog({
    Key? key,
    this.onJobPosted,
    required this.scrollController,
    required this.primaryRed,
    required this.goldAccent,
    required this.purpleAccent,
    required this.lightRed,
  }) : super(key: key);

  @override
  _PremiumAddJobDialogState createState() => _PremiumAddJobDialogState();
}

class _PremiumAddJobDialogState extends State<PremiumAddJobDialog> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _benefitsController = TextEditingController();

  // ADDED: Location picking variables
  double? _jobLatitude;
  double? _jobLongitude;
  String? _jobFullAddress;
  
  String? _selectedState;
  JobType? _selectedJobType = JobType.fullTime;
  ExperienceLevel? _selectedExperienceLevel = ExperienceLevel.entry;
  DateTime? _selectedDeadline;
  List<String> _skillsRequired = [];
  List<String> _benefits = [];
  bool _isUrgent = false;

  final List<String> _states = CommunityStates.states;
  
  late TabController _tabController;
  late AnimationController _animationController;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  
  bool _isBasicInfoValid = false;
  bool _isDetailsValid = false;

  @override
  void initState() {
    super.initState();
    
    // ✅ Add WidgetsBindingObserver
    WidgetsBinding.instance.addObserver(this);
    
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animationController.forward();
    
    _jobTitleController.addListener(_validateBasicInfo);
    _companyNameController.addListener(_validateBasicInfo);
    _locationController.addListener(_validateBasicInfo);
    _cityController.addListener(_validateBasicInfo);
    
    _descriptionController.addListener(_validateDetails);
    _requirementsController.addListener(_validateDetails);
    _contactEmailController.addListener(_validateDetails);
    _contactPhoneController.addListener(_validateDetails);
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });
  }

  void _validateBasicInfo() {
    setState(() {
      _isBasicInfoValid = 
          _jobTitleController.text.isNotEmpty &&
          _companyNameController.text.isNotEmpty &&
          _locationController.text.isNotEmpty &&
          _cityController.text.isNotEmpty &&
          _selectedState != null &&
          _jobLatitude != null && // ADDED: Check location coordinates
          _jobLongitude != null; // ADDED: Check location coordinates
    });
  }

  void _validateDetails() {
    setState(() {
      _isDetailsValid = 
          _descriptionController.text.isNotEmpty &&
          _requirementsController.text.isNotEmpty &&
          _contactEmailController.text.isNotEmpty &&
          _contactPhoneController.text.isNotEmpty &&
          _selectedDeadline != null;
    });
  }

  bool get _isSubmitEnabled => _isBasicInfoValid && _isDetailsValid;

  @override
  void dispose() {
    print('🗑️ PremiumAddJobDialog disposing...');
    
    // ✅ Remove observer
    WidgetsBinding.instance.removeObserver(this);
    
    _jobTitleController.removeListener(_validateBasicInfo);
    _companyNameController.removeListener(_validateBasicInfo);
    _locationController.removeListener(_validateBasicInfo);
    _cityController.removeListener(_validateBasicInfo);
    
    _descriptionController.removeListener(_validateDetails);
    _requirementsController.removeListener(_validateDetails);
    _contactEmailController.removeListener(_validateDetails);
    _contactPhoneController.removeListener(_validateDetails);
    
    _jobTitleController.dispose();
    _companyNameController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _skillsController.dispose();
    _benefitsController.dispose();
    _tabController.dispose();
    _animationController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    return FadeTransition(
      opacity: _animationController,
      child: Column(
        children: [
          // Premium Header
          Container(
            padding: EdgeInsets.all(screenWidth > 600 ? 24 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.primaryRed, widget.purpleAccent, widget.primaryRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryRed.withOpacity(0.3),
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
                  child: shouldAnimate
                      ? RotationTransition(
                          turns: _animationController,
                          child: Icon(Icons.work_rounded, color: widget.goldAccent, size: screenWidth > 600 ? 28 : 22),
                        )
                      : Icon(Icons.work_rounded, color: widget.goldAccent, size: screenWidth > 600 ? 28 : 22),
                ),
                SizedBox(width: screenWidth > 600 ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Post a Job',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth > 600 ? 20 : 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your job will be visible after admin approval',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: screenWidth > 600 ? 13 : 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
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
                _buildPremiumTabIndicator(1, 'Job Details', _isDetailsValid),
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
                      onPressed: () {
                        _tabController.animateTo(0);
                      },
                      isPrimary: false,
                    ),
                  ),
                if (_tabController.index > 0) SizedBox(width: 12),
                Expanded(
                  child: _tabController.index < 1
                      ? _buildPremiumNavButton(
                          label: 'Next',
                          onPressed: () {
                            if (_isBasicInfoValid) {
                              _tabController.animateTo(1);
                            } else {
                              _showErrorSnackBar('Please complete all required fields');
                            }
                          },
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
          } else if (index == 1) {
            _showErrorSnackBar('Complete previous steps first');
          }
        },
        child: Container(
          height: screenWidth > 600 ? 60 : 50,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [widget.goldAccent, widget.primaryRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isValid ? widget.primaryRed : Colors.grey[300]!,
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
                  color: isValid ? widget.primaryRed : (isSelected ? Colors.white : Colors.grey[400]),
                ),
                child: isValid
                    ? Icon(Icons.check, color: Colors.white, size: screenWidth > 600 ? 14 : 12)
                    : Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isSelected ? widget.primaryRed : Colors.white,
                            fontSize: screenWidth > 600 ? 12 : 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : (isValid ? widget.primaryRed : Colors.grey[600]),
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
      margin: EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: isCompleted
            ? LinearGradient(
                colors: [widget.primaryRed, widget.goldAccent],
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
                colors: [widget.primaryRed, widget.purpleAccent],
              )
            : null,
        color: isPrimary ? null : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPrimary ? null : Border.all(color: widget.primaryRed),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: widget.primaryRed.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
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
                color: isPrimary ? Colors.white : widget.primaryRed,
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
                colors: [widget.goldAccent, widget.primaryRed, widget.purpleAccent],
              )
            : null,
        color: _isSubmitEnabled ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isSubmitEnabled
            ? [
                BoxShadow(
                  color: widget.primaryRed.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
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
              'Post Job',
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

  // ADDED: Location Picker Field
  Widget _buildLocationPickerField(StateSetter setState, bool isTablet) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => OSMLocationPicker(
            initialLatitude: _jobLatitude,
            initialLongitude: _jobLongitude,
            initialAddress: _jobFullAddress,
            initialState: _selectedState,
            initialCity: _cityController.text,
            onLocationSelected: (lat, lng, address, state, city) {
              setState(() {
                _jobLatitude = lat;
                _jobLongitude = lng;
                _jobFullAddress = address;
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
            color: _jobLatitude != null ? widget.primaryRed : Colors.grey.shade300,
            width: _jobLatitude != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: _jobLatitude != null ? widget.lightRed.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.primaryRed, widget.purpleAccent],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _jobLatitude != null ? Icons.location_on : Icons.add_location,
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
                      color: widget.primaryRed,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _jobFullAddress ?? 'Tap to select location on map',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 14 : 12,
                      color: _jobFullAddress != null ? Colors.black87 : Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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

  Widget _buildPremiumBasicInfoTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumSectionHeader('Job Information', Icons.work_rounded),
          SizedBox(height: 16),
          _buildPremiumTextField(
            controller: _jobTitleController,
            label: 'Job Title *',
            icon: Icons.title_rounded,
          ),
          SizedBox(height: 12),
          _buildPremiumTextField(
            controller: _companyNameController,
            label: 'Company Name *',
            icon: Icons.business_rounded,
          ),
          SizedBox(height: 12),
          
          // REPLACED: Street name field with location picker
          StatefulBuilder(
            builder: (context, setState) {
              return _buildLocationPickerField(setState, isTablet);
            },
          ),
          SizedBox(height: 12),
          
          _buildPremiumDropdown<JobType>(
            value: _selectedJobType,
            hint: 'Job Type *',
            items: JobType.values.map((type) {
              return DropdownMenuItem<JobType>(
                value: type,
                child: Text(type.displayName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedJobType = value;
                _validateBasicInfo();
              });
            },
            icon: Icons.schedule_rounded,
          ),
          SizedBox(height: 12),
          
          _buildPremiumDropdown<ExperienceLevel>(
            value: _selectedExperienceLevel,
            hint: 'Experience Level *',
            items: ExperienceLevel.values.map((level) {
              return DropdownMenuItem<ExperienceLevel>(
                value: level,
                child: Text(level.displayName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedExperienceLevel = value;
                _validateBasicInfo();
              });
            },
            icon: Icons.timeline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumDetailsTab() {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumSectionHeader('Description & Requirements', Icons.description_rounded),
          SizedBox(height: 16),
          
          _buildPremiumTextField(
            controller: _descriptionController,
            label: 'Job Description *',
            icon: Icons.description_rounded,
            maxLines: 4,
          ),
          SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _requirementsController,
            label: 'Requirements *',
            icon: Icons.checklist_rounded,
            maxLines: 3,
          ),
          SizedBox(height: 12),
          
          _buildPremiumSectionHeader('Skills (Optional)', Icons.code_rounded),
          SizedBox(height: 16),
          
          _buildPremiumTagInput(
            controller: _skillsController,
            tags: _skillsRequired,
            hint: 'Add required skill',
            onAdd: () {
              if (_skillsController.text.trim().isNotEmpty) {
                setState(() {
                  _skillsRequired.add(_skillsController.text.trim());
                  _skillsController.clear();
                });
              }
            },
            onRemove: (index) {
              setState(() {
                _skillsRequired.removeAt(index);
              });
            },
          ),
          
          SizedBox(height: 16),
          
          _buildPremiumSectionHeader('Benefits (Optional)', Icons.card_giftcard_rounded),
          SizedBox(height: 16),
          
          _buildPremiumTagInput(
            controller: _benefitsController,
            tags: _benefits,
            hint: 'Add benefit',
            onAdd: () {
              if (_benefitsController.text.trim().isNotEmpty) {
                setState(() {
                  _benefits.add(_benefitsController.text.trim());
                  _benefitsController.clear();
                });
              }
            },
            onRemove: (index) {
              setState(() {
                _benefits.removeAt(index);
              });
            },
          ),
          
          SizedBox(height: 16),
          
          _buildPremiumSectionHeader('Contact Information', Icons.contact_mail_rounded),
          SizedBox(height: 16),
          
          _buildPremiumTextField(
            controller: _contactEmailController,
            label: 'Contact Email *',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _contactPhoneController,
            label: 'Contact Phone *',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 12),
          
          _buildPremiumSectionHeader('Deadline', Icons.calendar_today_rounded),
          SizedBox(height: 16),
          
          // Deadline Picker
          InkWell(
            onTap: () => _selectDeadline(context),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: widget.primaryRed),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Application Deadline *',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _selectedDeadline != null
                              ? DateFormat('MMMM d, yyyy').format(_selectedDeadline!)
                              : 'Select application deadline',
                          style: TextStyle(
                            color: _selectedDeadline != null ? Colors.black : Colors.grey[600],
                            fontWeight: _selectedDeadline != null ? FontWeight.w500 : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_drop_down_rounded, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 12),
          
          // Urgent checkbox
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isUrgent ? widget.primaryRed.withOpacity(0.1) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isUrgent ? widget.primaryRed : Colors.grey[200]!),
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
                  activeColor: widget.primaryRed,
                  checkColor: Colors.white,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mark as Urgent',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _isUrgent ? widget.primaryRed : Colors.black87,
                        ),
                      ),
                      Text(
                        'Urgent jobs will be highlighted after approval',
                        style: TextStyle(
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
        ],
      ),
    );
  }

  Widget _buildPremiumSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.primaryRed, widget.purpleAccent],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E2A3A), // Hardcode the dark text color
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        prefixIcon: Icon(icon, color: widget.primaryRed, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.primaryRed, width: 2),
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
    );
  }

  Widget _buildPremiumDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        prefixIcon: Icon(icon, color: widget.primaryRed, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.primaryRed, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.primaryRed, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.primaryRed, widget.purpleAccent],
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
                icon: Icon(Icons.add_rounded, color: Colors.white, size: 20),
                padding: EdgeInsets.all(10),
                constraints: BoxConstraints(),
              ),
            ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(tags.length, (index) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.lightRed, Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: widget.primaryRed.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tags[index],
                      style: TextStyle(
                        color: widget.primaryRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => onRemove(index),
                      child: Icon(
                        Icons.close_rounded,
                        color: widget.primaryRed,
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

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.primaryRed,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
        _validateDetails();
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedState == null || _selectedDeadline == null) {
      _showErrorSnackBar('Please fill all required fields');
      return;
    }

    // ADDED: Check location coordinates
    if (_jobLatitude == null || _jobLongitude == null) {
      _showErrorSnackBar('Please select a location on the map');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    
    if (currentUser == null) {
      _showErrorSnackBar('You must be logged in to post a job');
      return;
    }

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);

    // Get user's profile image (if available)
    String? userProfileImage;
    if (currentUser.profileImageUrl != null && currentUser.profileImageUrl!.isNotEmpty) {
      // Store the profile image as is (whether URL or base64)
      userProfileImage = currentUser.profileImageUrl;
    }

    final newJob = JobPosting(
      jobTitle: _jobTitleController.text,
      companyName: _companyNameController.text,
      description: _descriptionController.text,
      requirements: _requirementsController.text,
      jobType: _selectedJobType!,
      experienceLevel: _selectedExperienceLevel!,
      location: _locationController.text,
      state: _selectedState!,
      city: _cityController.text,
      salaryMin: null,
      salaryMax: null,
      salaryPeriod: 'monthly',
      benefits: _benefits,
      skillsRequired: _skillsRequired,
      contactEmail: _contactEmailController.text,
      contactPhone: _contactPhoneController.text,
      applicationLink: null,
      applicationDeadline: _selectedDeadline!,
      isUrgent: _isUrgent,
      responsibilities: '',
      postedBy: currentUser.id,
      
      // Store user info directly in the job document
      postedByUserId: currentUser.id,
      postedByName: currentUser.fullName,
      postedByEmail: currentUser.email,
      postedByProfileImageBase64: userProfileImage,
      
      // ADDED: Location coordinates
      latitude: _jobLatitude,
      longitude: _jobLongitude,
      
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await provider.addJobPosting(newJob);
    
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Job posted successfully! It will be visible after admin approval.',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: widget.primaryRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(12),
        ),
      );
      
      if (widget.onJobPosted != null) {
        widget.onJobPosted!();
      }
    } else {
      _showErrorSnackBar('Failed to post job. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text(message, style: TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: widget.primaryRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(12),
      ),
    );
  }
}