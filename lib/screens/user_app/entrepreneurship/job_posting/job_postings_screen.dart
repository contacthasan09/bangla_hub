import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:bangla_hub/models/community_services_models.dart';
import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/models/user_model.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/job_posting/job_details_screen.dart';
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

class _JobPostingsScreenState extends State<JobPostingsScreen> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  // Premium Color Palette - Sports Theme (copied from SportsClubsScreen)
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

  bool _isLoading = false;
  String? _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Full Time', 'Part Time', 'Contract', 'Internship', 'Urgent'];
  
  // Cache for user profiles
  final Map<String, UserModel?> _userCache = {};
  final Map<String, StreamSubscription?> _userSubscriptions = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
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
    )..repeat(reverse: true);
    
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    // Cancel all user subscriptions
    _userSubscriptions.values.forEach((sub) => sub?.cancel());
    _userSubscriptions.clear();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
      await provider.loadJobPostings();
      
      // Load user profiles immediately for all jobs
      if (provider.jobPostings.isNotEmpty) {
        await _loadAllUserProfiles(provider.jobPostings);
        _setupUserProfileListeners(provider.jobPostings);
      }
      
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading jobs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAllUserProfiles(List<JobPosting> jobs) async {
    final Map<String, Future<UserModel?>> futures = {};
    
    for (var job in jobs) {
      final userId = job.postedBy;
      if (!_userCache.containsKey(userId)) {
        futures[userId] = _fetchUserProfile(userId);
      }
    }
    
    if (futures.isNotEmpty) {
      await Future.wait(futures.values);
    }
  }

  Future<UserModel?> _fetchUserProfile(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists && mounted) {
        final user = UserModel.fromMap(doc.data()!, doc.id);
        setState(() {
          _userCache[userId] = user;
        });
        return user;
      }
    } catch (e) {
      print('❌ Error fetching user $userId: $e');
    }
    return null;
  }

  void _setupUserProfileListeners(List<JobPosting> jobs) {
    _userSubscriptions.values.forEach((sub) => sub?.cancel());
    _userSubscriptions.clear();
    
    for (var job in jobs) {
      final userId = job.postedBy;
      
      if (!_userSubscriptions.containsKey(userId)) {
        final subscription = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots()
            .listen((snapshot) {
              if (snapshot.exists && mounted) {
                final user = UserModel.fromMap(snapshot.data()!, snapshot.id);
                setState(() {
                  _userCache[userId] = user;
                });
              } else if (mounted) {
                setState(() {
                  _userCache[userId] = null;
                });
              }
            }, onError: (error) {
              print('❌ Error listening to user $userId: $error');
            });
        
        _userSubscriptions[userId] = subscription;
      }
    }
  }

  List<JobPosting> _getFilteredJobs(List<JobPosting> jobs) {
    final verifiedJobs = jobs.where((job) => job.isVerified).toList();
    
    if (_selectedFilter == 'All') return verifiedJobs;
    if (_selectedFilter == 'Urgent') return verifiedJobs.where((job) => job.isUrgent).toList();
    return verifiedJobs.where((job) => job.jobType.displayName == _selectedFilter).toList();
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
              CustomScrollView(
                physics: BouncingScrollPhysics(),
                slivers: [
                  _buildPremiumAppBar(isTablet),
                  SliverToBoxAdapter(
                    child: _buildFilterChips(isTablet),
                  ),
                  _buildContent(),
                ],
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
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _goldAccent.withOpacity(0.3), width: 1.5),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white, size: isTablet ? 28 : 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildAnimatedParticle(int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Positioned(
      left: (index * 37) % screenWidth,
      top: (index * 53) % screenHeight,
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
    
    return Positioned(
      left: (index * 73) % screenWidth,
      top: (index * 47) % screenHeight,
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
    height: 60, // Add fixed height
    margin: EdgeInsets.only(top: 16, bottom: 8),
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
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
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
            onTap: () => _showAddJobDialog(context),
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
                    turns: _rotateController,
                    child: Icon(
                      Icons.add_business_rounded,
                      color: Colors.white,
                      size: isTablet ? 26 : 22,
                    ),
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
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<EntrepreneurshipProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading || _isLoading) {
          return _buildLoadingState();
        }

        final filteredJobs = _getFilteredJobs(provider.jobPostings);

        if (filteredJobs.isEmpty) {
          return _buildEmptyState();
        }

        return SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final job = filteredJobs[index];
                final user = _userCache[job.postedBy];
                
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: _buildPremiumJobCard(job, user, index),
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
                    width: isTablet ? 140 : 120,
                    height: isTablet ? 140 : 120,
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
                              color: _primaryRed,
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
                colors: [_primaryRed, _purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Loading Jobs...',
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
                'Finding the best opportunities for you',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 18 : 16,
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

  Widget _buildEmptyState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
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
                          colors: [_lightRed, _primaryRed.withOpacity(0.3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.work_off_rounded,
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
                  colors: [_primaryRed, _purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  'No Jobs Available',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 30 : 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 16 : 12),
              Text(
                'Be the first to post a job opportunity',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 18 : 16,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumJobCard(JobPosting job, UserModel? user, int index) {
    final isDeadlineNear = job.applicationDeadline.difference(DateTime.now()).inDays <= 7;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.92 + (0.08 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: _primaryRed.withOpacity(0.25),
                    blurRadius: 30,
                    offset: Offset(0, 16),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: _goldAccent.withOpacity(0.15),
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
                          _lightRed.withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showJobDetails(job, user),
                        borderRadius: BorderRadius.circular(40),
                        splashColor: _goldAccent.withOpacity(0.15),
                        highlightColor: Colors.transparent,
                        child: Padding(
                          padding: EdgeInsets.all(isTablet ? 24 : 20),
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
                                      return Transform.scale(
                                        scale: 0.85 + (0.15 * value),
                                        child: Container(
                                          width: isTablet ? 60 : 50,
                                          height: isTablet ? 60 : 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [_primaryRed, _purpleAccent, _tealAccent],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _goldAccent.withOpacity(0.4),
                                                blurRadius: 15,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(2),
                                            child: ClipOval(
                                              child: AnimatedSwitcher(
                                                duration: Duration(milliseconds: 300),
                                                child: user != null
                                                    ? _buildUserProfileImage(user)
                                                    : _buildLoadingProfileImage(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  SizedBox(width: 14),
                                  
                                  // User Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AnimatedSwitcher(
                                          duration: Duration(milliseconds: 300),
                                          child: user != null
                                              ? ShaderMask(
                                                  key: ValueKey(user.fullName),
                                                  shaderCallback: (bounds) => LinearGradient(
                                                    colors: [_primaryRed, _purpleAccent],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ).createShader(bounds),
                                                  child: Text(
                                                    user.fullName,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: isTablet ? 18 : 16,
                                                      fontWeight: FontWeight.w800,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  width: 120,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.grey[300]!,
                                                        Colors.grey[200]!,
                                                        Colors.grey[300]!,
                                                      ],
                                                      begin: Alignment.centerLeft,
                                                      end: Alignment.centerRight,
                                                    ),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Center(
                                                    child: SizedBox(
                                                      width: 80,
                                                      height: 12,
                                                      child: LinearProgressIndicator(
                                                        backgroundColor: Colors.transparent,
                                                        valueColor: AlwaysStoppedAnimation<Color>(_primaryRed.withOpacity(0.3)),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [_primaryRed, _purpleAccent],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              user != null ? 'Job Provider' : 'Loading...',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: user != null ? _goldAccent : Colors.grey,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Verified Badge
                                  Container(
                                    padding: EdgeInsets.all(8),
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
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: RotationTransition(
                                      turns: _rotateController,
                                      child: Icon(
                                        Icons.verified_rounded, 
                                        color: Colors.white, 
                                        size: isTablet ? 18 : 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 20),
                              
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
                                              fontSize: isTablet ? 24 : 22,
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
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [_primaryRed, _darkRed],
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.priority_high_rounded, color: Colors.white, size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                'Urgent',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    job.companyName,
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w600,
                                      color: _primaryRed,
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Tags
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildPremiumTag(job.jobType.displayName, Icons.schedule_rounded),
                                  _buildPremiumTag(job.experienceLevel.displayName, Icons.timeline_rounded),
                                  _buildPremiumTag('${job.city}, ${job.state}', Icons.location_on_rounded),
                                ],
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Description preview
                              Text(
                                job.description.length > 100
                                    ? '${job.description.substring(0, 100)}...'
                                    : job.description,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 14 : 13,
                                  color: _textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Bottom row with deadline
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: isDeadlineNear ? _warningOrange : _textSecondary,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Apply by: ${DateFormat('MMM d, yyyy').format(job.applicationDeadline)}',
                                    style: GoogleFonts.inter(
                                      fontSize: isTablet ? 12 : 11,
                                      color: isDeadlineNear ? _warningOrange : _textSecondary,
                                      fontWeight: isDeadlineNear ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 20),
                              
                              // View Details Button
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: Duration(milliseconds: 800),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: 0.92 + (0.08 * value),
                                    child: GestureDetector(
                                      onTap: () => _showJobDetails(job, user),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          vertical: isTablet ? 18 : 16,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [_primaryRed, _purpleAccent, _tealAccent],
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
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'View Details',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: isTablet ? 20 : 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            RotationTransition(
                                              turns: _rotateController,
                                              child: Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Colors.white,
                                                size: isTablet ? 22 : 20,
                                              ),
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

  Widget _buildPremiumTag(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _goldAccent.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _goldAccent),
          SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: _textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileImage(UserModel? user) {
    if (user == null) {
      return _buildLoadingProfileImage();
    }
    
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      try {
        String base64String = user.profileImageUrl!;
        
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

  Widget _buildLoadingProfileImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[300]!, Colors.grey[100]!],
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_primaryRed),
          ),
        ),
      ),
    );
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

  void _showJobDetails(JobPosting job, UserModel? user) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => JobDetailsScreen(
          job: job,
          user: user,
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

// ====================== PREMIUM ADD JOB DIALOG ======================
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

class _PremiumAddJobDialogState extends State<PremiumAddJobDialog> with TickerProviderStateMixin {
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
    
    _jobTitleController.addListener(_validateBasicInfo);
    _companyNameController.addListener(_validateBasicInfo);
    _locationController.addListener(_validateBasicInfo);
    _cityController.addListener(_validateBasicInfo);
    
    _descriptionController.addListener(_validateDetails);
    _requirementsController.addListener(_validateDetails);
    _contactEmailController.addListener(_validateDetails);
    _contactPhoneController.addListener(_validateDetails);
  }

  void _validateBasicInfo() {
    setState(() {
      _isBasicInfoValid = 
          _jobTitleController.text.isNotEmpty &&
          _companyNameController.text.isNotEmpty &&
          _locationController.text.isNotEmpty &&
          _cityController.text.isNotEmpty &&
          _selectedState != null;
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
                  child: Icon(Icons.work_rounded, color: widget.goldAccent, size: screenWidth > 600 ? 28 : 22),
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

  Widget _buildPremiumBasicInfoTab() {
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
          _buildPremiumTextField(
            controller: _locationController,
            label: 'Street Name *',
            icon: Icons.location_on_rounded,
          ),
          SizedBox(height: 12),
          
          _buildPremiumDropdown(
            value: _selectedState,
            hint: 'Select State *',
            items: _states.map((state) {
              return DropdownMenuItem<String>(
                value: state,
                child: Text(state),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedState = value;
                _validateBasicInfo();
              });
            },
            icon: Icons.map_rounded,
          ),
          SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _cityController,
            label: 'City *',
            icon: Icons.location_city_rounded,
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
    required Function(T?) onChanged,
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    
    if (currentUser == null) {
      _showErrorSnackBar('You must be logged in to post a job');
      return;
    }

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);

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