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
import 'package:bangla_hub/widgets/common/global_location_guard.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class JobPostingsScreen extends StatefulWidget {
  @override
  _JobPostingsScreenState createState() => _JobPostingsScreenState();
}

class _JobPostingsScreenState extends State<JobPostingsScreen> 
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin, WidgetsBindingObserver {
  
  // Premium Color Palette
  final Color _primaryRed = Color(0xFFF44336);
  final Color _darkRed = Color(0xFFD32F2F);
  final Color _lightRed = Color(0xFFFFEBEE);
  final Color _goldAccent = Color(0xFFFFB300);
  final Color _orangeAccent = Color(0xFFF57C00);
  final Color _purpleAccent = Color(0xFF8E24AA);
  final Color _tealAccent = Color(0xFF00897B);
  final Color _royalPurple = Color(0xFF6B4E71);
  final Color _creamWhite = Color(0xFFFAF7F2);
  final Color _textPrimary = Color(0xFF1E2A3A);
  final Color _textSecondary = Color(0xFF5D6D7E);
  final Color _borderLight = Color(0xFFE0E7E9);
  final Color _successGreen = Color(0xFF4CAF50);
  final Color _warningOrange = Color(0xFFFF9800);
  final Color _infoBlue = Color(0xFF2196F3);
  
  // App Bar Gradient
  final LinearGradient _appBarGradient = LinearGradient(
    colors: [
      Color(0xFFF44336),
      Color(0xFFD32F2F),
      Color(0xFF8E24AA),
      Color(0xFF6B4E71),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _bodyBgGradient = LinearGradient(
    colors: [
      Color(0xFFFFEBEE),
      Color(0xFFFCE4EC),
      Color(0xFFE8F5E9),
      Color(0xFFF1F8E9),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
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
  
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  bool _isLoading = false;
  String? _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Full Time', 'Part Time', 'Contract', 'Internship', 'Urgent'];
  
  final ScrollController _mainScrollController = ScrollController();
  LocationFilterProvider? _locationProvider;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    print('🔵 JobPostingsScreen initState called');
    
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
      _locationProvider = locationProvider;
      if (locationProvider.currentUserLocation == null) {
        locationProvider.getUserLocation(showLoading: false);
      }
      
      // Start animations
      _startAnimations();
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
  void dispose() {
    print('🗑️ JobPostingsScreen disposing...');
    if (_locationProvider != null) {
      _locationProvider!.removeListener(() {});
    }
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    for (var controller in _particleControllers) { controller.dispose(); }
    for (var controller in _bubbleControllers) { controller.dispose(); }
    _mainScrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Helper function to check if string is a URL
  bool _isUrlString(String str) {
    return str.startsWith('http://') || str.startsWith('https://');
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
      await provider.loadJobPostings();
      print('📊 Total jobs loaded: ${provider.jobPostings.length}');
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading jobs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<JobPosting> _getFilteredJobs(List<JobPosting> jobs, LocationFilterProvider locationProvider) {
    var filteredJobs = jobs.where((job) => job.isVerified && job.isActive && !job.isDeleted).toList();
    
    if (locationProvider.isFilterActive && locationProvider.selectedState != null) {
      filteredJobs = filteredJobs.where((job) => job.state == locationProvider.selectedState).toList();
    }
    
    if (_selectedFilter == 'Urgent') {
      filteredJobs = filteredJobs.where((job) => job.isUrgent).toList();
    } else if (_selectedFilter != 'All') {
      filteredJobs = filteredJobs.where((job) => job.jobType.displayName == _selectedFilter).toList();
    }
    
    return filteredJobs;
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
                      content: Text('Showing jobs from all states'),
                      backgroundColor: Color(0xFFF44336),
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
                      Icon(Icons.public, color: _primaryRed),
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
                            content: Text('Showing jobs in $state'),
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
                                  color: isSelected ? _primaryRed : Colors.black87,
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
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 12 : 10,
              vertical: isTablet ? 6 : 4,
            ),
            decoration: BoxDecoration(
              gradient: hasFilter
                  ? const LinearGradient(
                      colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
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
                    : _goldAccent.withOpacity(0.4),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasFilter ? Icons.edit_location_rounded : Icons.location_on_rounded,
                  size: isTablet ? 14 : 12,
                  color: hasFilter ? const Color(0xFFFFB300) : _goldAccent,
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
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        floatingActionButton: _buildAnimatedFloatingActionButton(isTablet, shouldAnimate),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: Container(
          decoration: BoxDecoration(gradient: _bodyBgGradient),
          child: Stack(
            children: [
              ...List.generate(30, (index) => _buildAnimatedParticle(index)),
              ...List.generate(8, (index) => _buildFloatingBubble(index)),
              
              RefreshIndicator(
                color: _goldAccent,
                onRefresh: _loadData,
                child: CustomScrollView(
                  controller: _mainScrollController,
                  physics: BouncingScrollPhysics(),
                  slivers: [
                    _buildPremiumAppBar(isTablet),
                    SliverToBoxAdapter(
                      child: Consumer<LocationFilterProvider>(
                        builder: (context, locationProvider, _) => GlobalLocationFilterBar(
                          isTablet: isTablet,
                          onClearTap: () {
                            locationProvider.clearLocationFilter();
                            _loadData();
                          },
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildFilterChips(isTablet)),
                    _buildContent(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildPremiumAppBar(bool isTablet) {
    return SliverAppBar(
      expandedHeight: isTablet ? 260 : 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(gradient: _appBarGradient),
          child: SafeArea(
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
                      gradient: LinearGradient(colors: [_goldAccent, _orangeAccent]),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                  
                  // Title - Single line only
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.white, _goldAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'Job Postings',
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
                      // Subtitle - Can wrap to multiple lines
                      Expanded(
                        child: Text(
                          '💼 Find Your Dream Job Today',
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
                  Consumer2<EntrepreneurshipProvider, LocationFilterProvider>(
                    builder: (context, provider, locationProvider, child) {
                      final filteredJobs = _getFilteredJobs(provider.jobPostings, locationProvider);
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
                                Icon(Icons.work_rounded, color: _goldAccent, size: isTablet ? 14 : 12),
                                SizedBox(width: isTablet ? 6 : 4),
                                Text(
                                  '${filteredJobs.length} Active Jobs',
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
          size: isTablet ? 28 : 24,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildContent() {
    return Consumer2<EntrepreneurshipProvider, LocationFilterProvider>(
      builder: (context, provider, locationProvider, child) {
        if (provider.isLoading || _isLoading) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _primaryRed),
                  SizedBox(height: 16),
                  Text('Loading jobs...', style: GoogleFonts.poppins(color: _textSecondary)),
                ],
              ),
            ),
          );
        }

        final filteredJobs = _getFilteredJobs(provider.jobPostings, locationProvider);

        if (filteredJobs.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_off_rounded, size: 60, color: _primaryRed.withOpacity(0.5)),
                  SizedBox(height: 16),
                  Text('No jobs available', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary)),
                  SizedBox(height: 8),
                  Text('Try adjusting your location filter or post a job!', style: GoogleFonts.inter(fontSize: 12, color: _textSecondary)),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.isGuestMode) {
                        _showLoginRequiredDialog(context, 'Post a Job');
                        return;
                      }
                      _showAddJobDialog(context);
                    },
                    icon: Icon(Icons.add_business_rounded),
                    label: Text('Post a Job'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryRed,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.all(12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final job = filteredJobs[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _buildPremiumJobCard(job, index),
                );
              },
              childCount: filteredJobs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChips(bool isTablet) {
    return Container(
      height: 44,
      margin: EdgeInsets.symmetric(vertical: 8),
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
              label: Text(filter, 
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : _textPrimary, 
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, 
                  fontSize: isTablet ? 12 : 11
                ),
              ),
              onSelected: (selected) => setState(() => _selectedFilter = filter),
              backgroundColor: Colors.white,
              selectedColor: _primaryRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25), 
                side: BorderSide(color: isSelected ? _primaryRed : _borderLight, width: 0.8)
              ),
            ),
          );
        },
      ),
    );
  }

  // UPDATED: Build job poster image with URL and Base64 support
  Widget _buildJobPosterImage(JobPosting job) {
    final imageData = job.postedByProfileImageBase64;
    
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
              print('Error loading job poster image: $error');
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
                print('Error decoding job poster image: $error');
                return _buildDefaultProfileImage();
              },
            ),
          );
        } catch (e) {
          print('Error processing job poster image: $e');
          return _buildDefaultProfileImage();
        }
      }
    }
    
    return _buildDefaultProfileImage();
  }

  Widget _buildDefaultProfileImage() {
    return Container(
      decoration: BoxDecoration(gradient: _appBarGradient),
      child: Center(child: Icon(Icons.person_rounded, color: Colors.white, size: 24)),
    );
  }

  Widget _buildPremiumJobCard(JobPosting job, int index) {
    final isDeadlineNear = job.applicationDeadline.difference(DateTime.now()).inDays <= 7;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final opacityValue = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: opacityValue,
          child: Transform.scale(
            scale: 0.95 + (0.05 * opacityValue),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: _primaryRed.withOpacity(0.15), blurRadius: 20, offset: Offset(0, 10), spreadRadius: -2),
                ],
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
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: isTablet ? 50 : 40,
                              height: isTablet ? 50 : 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _appBarGradient,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: ClipOval(child: _buildJobPosterImage(job)),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job.postedByName ?? 'Unknown User',
                                    style: GoogleFonts.poppins(fontSize: isTablet ? 16 : 14, fontWeight: FontWeight.w800, color: _textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    children: [
                                      Container(width: 6, height: 6, decoration: BoxDecoration(color: _primaryRed, shape: BoxShape.circle)),
                                      SizedBox(width: 4),
                                      Text('Job Provider', style: GoogleFonts.poppins(fontSize: 10, color: _goldAccent, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (job.isVerified)
                              shouldAnimate
                                  ? RotationTransition(
                                      turns: _rotateController,
                                      child: Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [_goldAccent, _orangeAccent]),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.verified_rounded, color: Colors.white, size: isTablet ? 16 : 14),
                                      ),
                                    )
                                  : Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [_goldAccent, _orangeAccent]),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.verified_rounded, color: Colors.white, size: isTablet ? 16 : 14),
                                    ),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        if (job.latitude != null && job.longitude != null)
                          Consumer<LocationFilterProvider>(
                            builder: (context, locationProvider, _) => Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: DistanceBadge(
                                latitude: job.latitude!,
                                longitude: job.longitude!,
                                isTablet: isTablet,
                              ),
                            ),
                          ),
                        
                        Text(
                          job.jobTitle,
                          style: GoogleFonts.poppins(fontSize: isTablet ? 20 : 18, fontWeight: FontWeight.w900, color: _textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6),
                        
                        Text(
                          job.companyName,
                          style: GoogleFonts.poppins(fontSize: isTablet ? 14 : 12, fontWeight: FontWeight.w600, color: _primaryRed),
                        ),
                        SizedBox(height: 14),
                        
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildTag(job.jobType.displayName, Icons.schedule_rounded, isTablet),
                            _buildTag(job.experienceLevel.displayName, Icons.timeline_rounded, isTablet),
                            _buildTag('${job.city}, ${job.state}', Icons.location_on_rounded, isTablet),
                            if (job.isUrgent) _buildTag('Urgent', Icons.priority_high_rounded, isTablet, isUrgent: true),
                          ],
                        ),
                        SizedBox(height: 14),
                        
                        Text(
                          job.description.length > 90 ? '${job.description.substring(0, 90)}...' : job.description,
                          style: GoogleFonts.inter(fontSize: isTablet ? 13 : 12, color: _textSecondary, height: 1.4),
                        ),
                        SizedBox(height: 14),
                        
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 12, color: isDeadlineNear ? _warningOrange : _textSecondary),
                            SizedBox(width: 4),
                            Text(
                              'Apply by: ${DateFormat('MMM d, yyyy').format(job.applicationDeadline)}',
                              style: GoogleFonts.inter(fontSize: isTablet ? 11 : 10, color: isDeadlineNear ? _warningOrange : _textSecondary),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 12),
                          decoration: BoxDecoration(
                            gradient: _appBarGradient,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Text(
                              'View Details',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: isTablet ? 16 : 14, fontWeight: FontWeight.w700),
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

  Widget _buildTag(String text, IconData icon, bool isTablet, {bool isUrgent = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 10 : 8, vertical: isTablet ? 6 : 4),
      decoration: BoxDecoration(
        color: isUrgent ? _primaryRed.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUrgent ? _primaryRed : _goldAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isTablet ? 11 : 10, color: isUrgent ? _primaryRed : _goldAccent),
          SizedBox(width: isTablet ? 5 : 4),
          Text(text, style: GoogleFonts.poppins(color: isUrgent ? _primaryRed : _textPrimary, fontSize: isTablet ? 11 : 10, fontWeight: isUrgent ? FontWeight.w700 : FontWeight.w600)),
        ],
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
                  gradient: RadialGradient(colors: [_primaryRed.withOpacity(0.5), _goldAccent.withOpacity(0.3), Colors.transparent]),
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
                  gradient: RadialGradient(colors: [_lightRed.withOpacity(0.3), _goldAccent.withOpacity(0.2), Colors.transparent]),
                  shape: BoxShape.circle,
                  border: Border.all(color: _goldAccent.withOpacity(0.1), width: 1),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedFloatingActionButton(bool isTablet, bool shouldAnimate) {
    Widget button = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_primaryRed, _purpleAccent, _tealAccent]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: _primaryRed.withOpacity(0.4), blurRadius: 15, offset: Offset(0, 8)),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.isGuestMode) {
            _showLoginRequiredDialog(context, 'Post a Job');
            return;
          }
          _showAddJobDialog(context);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: shouldAnimate
            ? RotationTransition(turns: _rotateController, child: Icon(Icons.add_business_rounded, color: Colors.white, size: isTablet ? 22 : 18))
            : Icon(Icons.add_business_rounded, color: Colors.white, size: isTablet ? 22 : 18),
        label: Text('Post a Job', style: GoogleFonts.poppins(fontSize: isTablet ? 14 : 12, fontWeight: FontWeight.w700, color: Colors.white)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
    
    return shouldAnimate
        ? Padding(padding: EdgeInsets.only(bottom: isTablet ? 20 : 16), child: ScaleTransition(scale: _pulseAnimation, child: button))
        : Padding(padding: EdgeInsets.only(bottom: isTablet ? 20 : 16), child: button);
  }

  void _showJobDetails(JobPosting job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailsScreen(
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
      ),
    );
  }

  void _showAddJobDialog(BuildContext context) {
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
    if (!formattedPhone.startsWith('1') && formattedPhone.length == 10) formattedPhone = '1$formattedPhone';
    if (!formattedPhone.startsWith('+')) formattedPhone = '+$formattedPhone';
    try {
      if (await canLaunchUrl(Uri(scheme: 'tel', path: formattedPhone))) {
        await launchUrl(Uri(scheme: 'tel', path: formattedPhone));
      }
    } catch (e) { print('Error: $e'); }
  }

  Future<void> _launchEmail(String email) async {
    try {
      if (await canLaunchUrl(Uri(scheme: 'mailto', path: email))) {
        await launchUrl(Uri(scheme: 'mailto', path: email));
      }
    } catch (e) { print('Error: $e'); }
  }

  Future<void> _launchUrl(String url) async {
    try {
      String finalUrl = url.startsWith('http') ? url : 'https://$url';
      if (await canLaunchUrl(Uri.parse(finalUrl))) {
        await launchUrl(Uri.parse(finalUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) { print('Error: $e'); }
  }
}

// Helper class for states list (if not already defined elsewhere)
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
// Keep your existing PremiumAddJobDialog class here

// Keep your existing PremiumAddJobDialog class here (same as before)
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
  
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  
  bool _isBasicInfoValid = false;
  bool _isDetailsValid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500))..forward();
    
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
    setState(() => _appLifecycleState = state);
  }

  void _validateBasicInfo() {
    setState(() {
      _isBasicInfoValid = 
          _jobTitleController.text.isNotEmpty &&
          _companyNameController.text.isNotEmpty &&
          _locationController.text.isNotEmpty &&
          _cityController.text.isNotEmpty &&
          _selectedState != null &&
          _jobLatitude != null &&
          _jobLongitude != null;
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
    final isTablet = screenWidth > 600;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    return FadeTransition(
      opacity: _animationController,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [widget.primaryRed, widget.purpleAccent, widget.primaryRed]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [BoxShadow(color: widget.primaryRed.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10))],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 12 : 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: shouldAnimate ? RotationTransition(turns: _animationController, child: Icon(Icons.work_rounded, color: widget.goldAccent, size: isTablet ? 28 : 22)) : Icon(Icons.work_rounded, color: widget.goldAccent, size: isTablet ? 28 : 22),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Post a Job', style: GoogleFonts.poppins(fontSize: isTablet ? 20 : 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      SizedBox(height: 4),
                      Text('Your job will be visible after admin approval', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: isTablet ? 13 : 12)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: Colors.white), padding: EdgeInsets.zero, constraints: BoxConstraints(), iconSize: isTablet ? 24 : 20),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: 16),
            height: isTablet ? 60 : 50,
            child: Row(
              children: [
                _buildPremiumTabIndicator(0, 'Basic Info', _isBasicInfoValid, isTablet),
                _buildPremiumTabConnector(_isBasicInfoValid, isTablet),
                _buildPremiumTabIndicator(1, 'Job Details', _isDetailsValid, isTablet),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildPremiumBasicInfoTab(isTablet),
                  _buildPremiumDetailsTab(isTablet),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: Offset(0, -5))]),
            child: Row(
              children: [
                if (_tabController.index > 0) Expanded(child: _buildPremiumNavButton(label: 'Previous', onPressed: () => _tabController.animateTo(0), isPrimary: false, isTablet: isTablet)),
                if (_tabController.index > 0) SizedBox(width: 12),
                Expanded(
                  child: _tabController.index < 1
                      ? _buildPremiumNavButton(label: 'Next', onPressed: () { if (_isBasicInfoValid) _tabController.animateTo(1); else _showErrorSnackBar('Please complete all required fields'); }, isPrimary: true, isTablet: isTablet)
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
          if (index == 0) _tabController.animateTo(0);
          else if (index == 1 && _isBasicInfoValid) _tabController.animateTo(1);
          else if (index == 1) _showErrorSnackBar('Complete previous steps first');
        },
        child: Container(
          height: screenWidth > 600 ? 60 : 50,
          decoration: BoxDecoration(
            gradient: isSelected ? LinearGradient(colors: [widget.goldAccent, widget.primaryRed]) : null,
            color: isSelected ? null : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isValid ? widget.primaryRed : Colors.grey[300]!, width: isValid ? 2 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isTablet ? 24 : 20,
                height: isTablet ? 24 : 20,
                decoration: BoxDecoration(shape: BoxShape.circle, color: isValid ? widget.primaryRed : (isSelected ? Colors.white : Colors.grey[400])),
                child: isValid ? Icon(Icons.check, color: Colors.white, size: isTablet ? 14 : 12) : Center(child: Text('${index + 1}', style: TextStyle(color: isSelected ? widget.primaryRed : Colors.white, fontSize: isTablet ? 12 : 10, fontWeight: FontWeight.bold))),
              ),
              SizedBox(height: 2),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : (isValid ? widget.primaryRed : Colors.grey[600]), fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: isTablet ? 10 : 9)),
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
      margin: EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(gradient: isCompleted ? LinearGradient(colors: [widget.primaryRed, widget.goldAccent]) : LinearGradient(colors: [Colors.grey[300]!, Colors.grey[400]!]), borderRadius: BorderRadius.circular(2)),
    );
  }

  Widget _buildPremiumNavButton({required String label, required VoidCallback onPressed, required bool isPrimary, required bool isTablet}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      height: screenWidth > 600 ? 50 : 44,
      decoration: BoxDecoration(
        gradient: isPrimary ? LinearGradient(colors: [widget.primaryRed, widget.purpleAccent]) : null,
        color: isPrimary ? null : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPrimary ? null : Border.all(color: widget.primaryRed),
        boxShadow: isPrimary ? [BoxShadow(color: widget.primaryRed.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(child: Text(label, style: GoogleFonts.poppins(color: isPrimary ? Colors.white : widget.primaryRed, fontWeight: FontWeight.w600, fontSize: screenWidth > 600 ? 15 : 13))),
        ),
      ),
    );
  }

  Widget _buildPremiumSubmitButton(bool isTablet) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      height: screenWidth > 600 ? 50 : 44,
      decoration: BoxDecoration(
        gradient: _isSubmitEnabled ? LinearGradient(colors: [widget.goldAccent, widget.primaryRed, widget.purpleAccent]) : null,
        color: _isSubmitEnabled ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isSubmitEnabled ? [BoxShadow(color: widget.primaryRed.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitEnabled ? _submitForm : null,
          borderRadius: BorderRadius.circular(12),
          child: Center(child: Text('Post Job', style: GoogleFonts.poppins(color: _isSubmitEnabled ? Colors.white : Colors.grey[600], fontWeight: FontWeight.w700, fontSize: screenWidth > 600 ? 15 : 13))),
        ),
      ),
    );
  }

  Widget _buildLocationPickerField(StateSetter setState, bool isTablet) {
    return GestureDetector(
      onTap: () async {
        await showModalBottomSheet(
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
          border: Border.all(color: _jobLatitude != null ? widget.primaryRed : Colors.grey.shade300, width: _jobLatitude != null ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          color: _jobLatitude != null ? widget.lightRed.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [widget.primaryRed, widget.purpleAccent]), borderRadius: BorderRadius.circular(10)),
              child: Icon(_jobLatitude != null ? Icons.location_on : Icons.add_location, color: Colors.white, size: isTablet ? 20 : 18),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Location *', style: GoogleFonts.poppins(fontSize: isTablet ? 14 : 12, fontWeight: FontWeight.w600, color: widget.primaryRed)),
                  SizedBox(height: 2),
                  Text(_jobFullAddress ?? 'Tap to select location on map', style: GoogleFonts.inter(fontSize: isTablet ? 14 : 12, color: _jobFullAddress != null ? Colors.black87 : Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: widget.primaryRed, size: isTablet ? 16 : 14),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBasicInfoTab(bool isTablet) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumSectionHeader('Job Information', Icons.work_rounded, isTablet),
          SizedBox(height: 16),
          _buildPremiumTextField(controller: _jobTitleController, label: 'Job Title *', icon: Icons.title_rounded, isTablet: isTablet),
          SizedBox(height: 12),
          _buildPremiumTextField(controller: _companyNameController, label: 'Company Name *', icon: Icons.business_rounded, isTablet: isTablet),
          SizedBox(height: 12),
          StatefulBuilder(builder: (context, setState) => _buildLocationPickerField(setState, isTablet)),
          SizedBox(height: 12),
          _buildPremiumDropdown<JobType>(
            value: _selectedJobType,
            hint: 'Job Type *',
            items: JobType.values.map((type) => DropdownMenuItem<JobType>(value: type, child: Text(type.displayName))).toList(),
            onChanged: (value) => setState(() { _selectedJobType = value; _validateBasicInfo(); }),
            icon: Icons.schedule_rounded,
            isTablet: isTablet,
          ),
          SizedBox(height: 12),
          _buildPremiumDropdown<ExperienceLevel>(
            value: _selectedExperienceLevel,
            hint: 'Experience Level *',
            items: ExperienceLevel.values.map((level) => DropdownMenuItem<ExperienceLevel>(value: level, child: Text(level.displayName))).toList(),
            onChanged: (value) => setState(() { _selectedExperienceLevel = value; _validateBasicInfo(); }),
            icon: Icons.timeline_rounded,
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumDetailsTab(bool isTablet) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumSectionHeader('Description & Requirements', Icons.description_rounded, isTablet),
          SizedBox(height: 16),
          _buildPremiumTextField(controller: _descriptionController, label: 'Job Description *', icon: Icons.description_rounded, maxLines: 4, isTablet: isTablet),
          SizedBox(height: 12),
          _buildPremiumTextField(controller: _requirementsController, label: 'Requirements *', icon: Icons.checklist_rounded, maxLines: 3, isTablet: isTablet),
          SizedBox(height: 12),
          _buildPremiumSectionHeader('Skills (Optional)', Icons.code_rounded, isTablet),
          SizedBox(height: 16),
          _buildPremiumTagInput(controller: _skillsController, tags: _skillsRequired, hint: 'Add required skill', onAdd: () { if (_skillsController.text.trim().isNotEmpty) setState(() { _skillsRequired.add(_skillsController.text.trim()); _skillsController.clear(); }); }, onRemove: (index) => setState(() => _skillsRequired.removeAt(index)), isTablet: isTablet),
          SizedBox(height: 16),
          _buildPremiumSectionHeader('Benefits (Optional)', Icons.card_giftcard_rounded, isTablet),
          SizedBox(height: 16),
          _buildPremiumTagInput(controller: _benefitsController, tags: _benefits, hint: 'Add benefit', onAdd: () { if (_benefitsController.text.trim().isNotEmpty) setState(() { _benefits.add(_benefitsController.text.trim()); _benefitsController.clear(); }); }, onRemove: (index) => setState(() => _benefits.removeAt(index)), isTablet: isTablet),
          SizedBox(height: 16),
          _buildPremiumSectionHeader('Contact Information', Icons.contact_mail_rounded, isTablet),
          SizedBox(height: 16),
          _buildPremiumTextField(controller: _contactEmailController, label: 'Contact Email *', icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress, isTablet: isTablet),
          SizedBox(height: 12),
          _buildPremiumTextField(controller: _contactPhoneController, label: 'Contact Phone *', icon: Icons.phone_rounded, keyboardType: TextInputType.phone, isTablet: isTablet),
          SizedBox(height: 12),
          _buildPremiumSectionHeader('Deadline', Icons.calendar_today_rounded, isTablet),
          SizedBox(height: 16),
          InkWell(
            onTap: () => _selectDeadline(context),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: widget.primaryRed),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Application Deadline *', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        Text(_selectedDeadline != null ? DateFormat('MMMM d, yyyy').format(_selectedDeadline!) : 'Select application deadline', style: TextStyle(color: _selectedDeadline != null ? Colors.black : Colors.grey[600], fontWeight: _selectedDeadline != null ? FontWeight.w500 : FontWeight.normal, fontSize: 14)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_drop_down_rounded, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: _isUrgent ? widget.primaryRed.withOpacity(0.1) : Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: _isUrgent ? widget.primaryRed : Colors.grey[200]!)),
            child: Row(
              children: [
                Checkbox(value: _isUrgent, onChanged: (value) => setState(() => _isUrgent = value ?? false), activeColor: widget.primaryRed, checkColor: Colors.white),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Mark as Urgent', style: TextStyle(fontWeight: FontWeight.w600, color: _isUrgent ? widget.primaryRed : Colors.black87)), Text('Urgent jobs will be highlighted after approval', style: TextStyle(fontSize: 12, color: Colors.grey[600]))])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSectionHeader(String title, IconData icon, bool isTablet) {
    return Row(
      children: [
        Container(padding: EdgeInsets.all(6), decoration: BoxDecoration(gradient: LinearGradient(colors: [widget.primaryRed, widget.purpleAccent]), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.white, size: 16)),
        SizedBox(width: 10),
        Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E2A3A))),
      ],
    );
  }

  Widget _buildPremiumTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text, int maxLines = 1, required bool isTablet}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        prefixIcon: Icon(icon, color: widget.primaryRed, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.primaryRed, width: 2)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines > 1 ? 14 : 12),
      ),
      validator: (value) => label.contains('*') && (value == null || value.isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildPremiumDropdown<T>({required T? value, required String hint, required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged, required IconData icon, required bool isTablet}) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        prefixIcon: Icon(icon, color: widget.primaryRed, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.primaryRed, width: 2)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),
      items: items,
      onChanged: (value) { onChanged(value); _validateBasicInfo(); },
      validator: (value) => value == null && hint.contains('*') ? 'Required' : null,
    );
  }

  Widget _buildPremiumTagInput({required TextEditingController controller, required List<String> tags, required VoidCallback onAdd, required Function(int) onRemove, String hint = 'Add item', required bool isTablet}) {
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.primaryRed, width: 2)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(gradient: LinearGradient(colors: [widget.primaryRed, widget.purpleAccent]), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: widget.primaryRed.withOpacity(0.3), blurRadius: 6)]),
              child: IconButton(onPressed: onAdd, icon: Icon(Icons.add_rounded, color: Colors.white, size: 20), padding: EdgeInsets.all(10), constraints: BoxConstraints()),
            ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(tags.length, (index) => Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [widget.lightRed, Colors.white]), borderRadius: BorderRadius.circular(20), border: Border.all(color: widget.primaryRed.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Text(tags[index], style: TextStyle(color: widget.primaryRed, fontSize: 11, fontWeight: FontWeight.w500)), SizedBox(width: 4), GestureDetector(onTap: () => onRemove(index), child: Icon(Icons.close_rounded, color: widget.primaryRed, size: 14))]),
            )),
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
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: widget.primaryRed, onPrimary: Colors.white, surface: Colors.white, onSurface: Colors.black)), child: child!),
    );
    if (picked != null) setState(() { _selectedDeadline = picked; _validateDetails(); });
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedState == null || _selectedDeadline == null) { _showErrorSnackBar('Please fill all required fields'); return; }
    if (_jobLatitude == null || _jobLongitude == null) { _showErrorSnackBar('Please select a location on the map'); return; }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null) { _showErrorSnackBar('You must be logged in to post a job'); return; }

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    String? userProfileImage = currentUser.profileImageUrl?.isNotEmpty == true ? currentUser.profileImageUrl : null;

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
      postedByUserId: currentUser.id,
      postedByName: currentUser.fullName,
      postedByEmail: currentUser.email,
      postedByProfileImageBase64: userProfileImage,
      latitude: _jobLatitude,
      longitude: _jobLongitude,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await provider.addJobPosting(newJob);
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(Icons.check_circle_rounded, color: Colors.white, size: 20), SizedBox(width: 10), Expanded(child: Text('Job posted successfully! It will be visible after admin approval.', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)))]), backgroundColor: widget.primaryRed, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: EdgeInsets.all(12)));
      widget.onJobPosted?.call();
    } else {
      _showErrorSnackBar('Failed to post job. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(Icons.error_rounded, color: Colors.white, size: 20), SizedBox(width: 10), Expanded(child: Text(message, style: TextStyle(fontSize: 13)))]), backgroundColor: widget.primaryRed, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: EdgeInsets.all(12)));
  }
}