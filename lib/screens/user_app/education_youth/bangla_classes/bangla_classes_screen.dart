import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:bangla_hub/models/community_services_models.dart';
import 'package:bangla_hub/models/education_models.dart';
import 'package:bangla_hub/models/user_model.dart';
import 'package:bangla_hub/providers/education_provider.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/screens/user_app/education_youth/bangla_classes/bangla_class_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BanglaClassesScreen extends StatefulWidget {
  @override
  _BanglaClassesScreenState createState() => _BanglaClassesScreenState();
}

class _BanglaClassesScreenState extends State<BanglaClassesScreen> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  // Premium Color Palette - Bangla Theme
  final Color _primaryOrange = Color(0xFFFF9800);
  final Color _darkOrange = Color(0xFFF57C00);
  final Color _lightOrange = Color(0xFFFFF3E0);
  final Color _redAccent = Color(0xFFE53935); // For Bengali culture
  final Color _greenAccent = Color(0xFF43A047); // For cultural elements
  final Color _goldAccent = Color(0xFFFFB300);
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
  
  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Cache for user profiles
  final Map<String, UserModel?> _userCache = {};
  final Map<String, StreamSubscription?> _userSubscriptions = {};

  bool _isLoading = false;
  String? _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Beginner', 'Intermediate', 'Advanced', 'Conversational', 'Cultural'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
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
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    
    _fadeController.forward();
    _slideController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    // Cancel all user subscriptions
    _userSubscriptions.values.forEach((sub) => sub?.cancel());
    _userSubscriptions.clear();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    print('🔍 Loading Bangla classes...');
    
    final provider = Provider.of<EducationProvider>(context, listen: false);
    await provider.loadBanglaClasses();
    
    print('📊 Total Bangla classes loaded: ${provider.banglaClasses.length}');
    print('✅ Verified classes: ${provider.banglaClasses.where((c) => c.isVerified).length}');
    
    // Load user profiles for all services
    if (provider.banglaClasses.isNotEmpty) {
      await _loadAllUserProfiles(provider.banglaClasses);
      _setupUserProfileListeners(provider.banglaClasses);
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadAllUserProfiles(List<BanglaClass> classes) async {
    final Map<String, Future<UserModel?>> futures = {};
    
    for (var banglaClass in classes) {
      final userId = banglaClass.createdBy;
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

  void _setupUserProfileListeners(List<BanglaClass> classes) {
    _userSubscriptions.values.forEach((sub) => sub?.cancel());
    _userSubscriptions.clear();
    
    for (var banglaClass in classes) {
      final userId = banglaClass.createdBy;
      
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

  // Get filtered classes - ONLY SHOW VERIFIED CLASSES
  List<BanglaClass> _getFilteredClasses(List<BanglaClass> classes) {
    // Only show verified and active classes
    final verifiedClasses = classes.where((banglaClass) => 
      banglaClass.isVerified == true && banglaClass.isActive == true
    ).toList();
    
    print('✅ Verified classes: ${verifiedClasses.length} out of ${classes.length} total');
    
    if (_selectedFilter == 'All') return verifiedClasses;
    
    // Filter by class type
    return verifiedClasses.where((banglaClass) {
      return banglaClass.classTypes.any((type) => 
        type.toLowerCase().contains(_selectedFilter!.toLowerCase())
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
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
              child: _buildFilterChips(isTablet),
            ),
            _buildContent(),
          ],
        ),
        floatingActionButton: _buildPremiumFloatingActionButton(isTablet),
      ),
    );
  }

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
                  // Premium Pattern Line
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
                  
                  // Title
                  Text(
                    'Bangla Language & Culture Classes',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 20 : 18,
                      color: Colors.white.withOpacity(0.95),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isTablet ? 8 : 4),
                  
                  // Subtitle
                  Text(
                    '🌟 Learn Bengali language and cultural heritage',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 14 : 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: isTablet ? 12 : 8),
                  
                  // Stats Row
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
                                Icon(Icons.verified_rounded, color: _goldAccent, size: isTablet ? 16 : 14),
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
        icon: Icon(Icons.arrow_back_rounded, color: Colors.white, size: isTablet ? 24 : 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
            onPressed: _loadData,
            tooltip: 'Refresh',
            padding: EdgeInsets.all(8),
            constraints: BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(bool isTablet) {
    return Container(
      height: 50,
      margin: EdgeInsets.only(bottom: 8),
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
                style: TextStyle(
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
              selectedColor: _primaryOrange,
              checkmarkColor: _goldAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: isSelected ? _primaryOrange : Color(0xFFE0E7E9),
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
    return Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddClassDialog(context),
          backgroundColor: Colors.transparent,
          elevation: 12,
          label: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 20,
              vertical: isTablet ? 16 : 14,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryOrange, _redAccent, _greenAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: _primaryOrange.withOpacity(0.4),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_rounded, color: Colors.white, size: isTablet ? 24 : 20),
                SizedBox(width: isTablet ? 12 : 8),
                Text(
                  'Add Class',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<EducationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading || _isLoading) {
          return _buildLoadingState();
        }

        final filteredClasses = _getFilteredClasses(provider.banglaClasses);

        if (filteredClasses.isEmpty) {
          return _buildEmptyState();
        }

        return SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final banglaClass = filteredClasses[index];
                final user = _userCache[banglaClass.createdBy];
                
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
                  child: _buildPremiumClassCard(banglaClass, user, index),
                );
              },
              childCount: filteredClasses.length,
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
                        colors: [_primaryOrange, _redAccent, _greenAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryOrange.withOpacity(0.3),
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
                              color: _primaryOrange,
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
                colors: [_primaryOrange, _redAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Loading Classes...',
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
                'Discover the beauty of Bangla language ✨',
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
                          colors: [_lightOrange, _primaryOrange.withOpacity(0.3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.language_rounded,
                        size: isTablet ? 80 : 70,
                        color: _primaryOrange,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: isTablet ? 40 : 30),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [_primaryOrange, _redAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  'No Classes Found',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 30 : 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 16 : 12),
              Text(
                'Be the first to offer Bangla language classes! 📚',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 18 : 16,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 32 : 24),
              ElevatedButton.icon(
                onPressed: () => _showAddClassDialog(context),
                icon: Icon(Icons.add_rounded),
                label: Text('Add Bangla Class'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryOrange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumClassCard(BanglaClass banglaClass, UserModel? user, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isFull = banglaClass.enrolledStudents >= banglaClass.maxStudents;
    
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
                    color: _primaryOrange.withOpacity(0.25),
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
                          _lightOrange.withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showClassDetails(banglaClass, user),
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
                                              colors: [_primaryOrange, _redAccent, _greenAccent],
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
                                                    colors: [_primaryOrange, _redAccent],
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
                                                        valueColor: AlwaysStoppedAnimation<Color>(_primaryOrange.withOpacity(0.3)),
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
                                                  colors: [_primaryOrange, _redAccent],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              user != null ? 'Language Instructor' : 'Loading...',
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
                                        colors: [_goldAccent, _greenAccent, _goldAccent],
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
                                    child: Icon(
                                      Icons.verified_rounded, 
                                      color: Colors.white, 
                                      size: isTablet ? 18 : 16,
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 20),
                              
                              // Instructor Name and Organization
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
                                      banglaClass.instructorName,
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
                                  SizedBox(height: 8),
                                  Text(
                                    banglaClass.organizationName ?? 'Independent Instructor',
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w600,
                                      color: _primaryOrange,
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Class Types Preview
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: banglaClass.classTypes.take(3).map((type) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 14 : 12,
                                      vertical: isTablet ? 8 : 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_primaryOrange.withOpacity(0.1), _lightOrange],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(color: _primaryOrange.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      type,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 14 : 12,
                                        fontWeight: FontWeight.w600,
                                        color: _primaryOrange,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              
                              if (banglaClass.classTypes.length > 3)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '+${banglaClass.classTypes.length - 3} more types',
                                    style: GoogleFonts.inter(
                                      fontSize: isTablet ? 13 : 11,
                                      color: _textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              
                              SizedBox(height: 16),
                              
                              // Location and Fee Row
                              Row(
                                children: [
                                  // Location
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(isTablet ? 8 : 6),
                                          decoration: BoxDecoration(
                                            color: _primaryOrange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.location_on_rounded,
                                            color: _primaryOrange,
                                            size: isTablet ? 20 : 18,
                                          ),
                                        ),
                                        SizedBox(width: isTablet ? 10 : 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Location',
                                                style: GoogleFonts.inter(
                                                  fontSize: isTablet ? 12 : 11,
                                                  color: _textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                '${banglaClass.city}, ${banglaClass.state}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: isTablet ? 14 : 13,
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
                                  
                                  // Fee
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 16 : 12,
                                      vertical: isTablet ? 10 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_successGreen.withOpacity(0.1), _successGreen.withOpacity(0.05)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: _successGreen.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.attach_money_rounded,
                                          color: _successGreen,
                                          size: isTablet ? 20 : 18,
                                        ),
                                        Text(
                                          banglaClass.formattedFee,
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 16 : 14,
                                            fontWeight: FontWeight.w700,
                                            color: _successGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Teaching Methods Preview
                              Row(
                                children: banglaClass.teachingMethods.take(2).map((method) {
                                  return Container(
                                    margin: EdgeInsets.only(right: 8),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 12 : 10,
                                      vertical: isTablet ? 6 : 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_tealAccent.withOpacity(0.1), _tealAccent.withOpacity(0.05)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: _tealAccent.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          method == TeachingMethod.inPerson ? Icons.person : 
                                          method == TeachingMethod.online ? Icons.videocam_rounded :
                                          method == TeachingMethod.hybrid ? Icons.sync_rounded :
                                          method == TeachingMethod.group ? Icons.group_rounded :
                                          Icons.person_rounded,
                                          color: _tealAccent,
                                          size: isTablet ? 14 : 12,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          method.displayName,
                                          style: GoogleFonts.inter(
                                            fontSize: isTablet ? 12 : 11,
                                            fontWeight: FontWeight.w600,
                                            color: _tealAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Duration and Seats Row
                              Row(
                                children: [
                                  // Duration
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(Icons.schedule_rounded, color: _infoBlue, size: isTablet ? 18 : 16),
                                        SizedBox(width: 4),
                                        Text(
                                          banglaClass.formattedDuration,
                                          style: GoogleFonts.inter(
                                            fontSize: isTablet ? 13 : 12,
                                            color: _infoBlue,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Seats
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 12 : 10,
                                      vertical: isTablet ? 6 : 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isFull ? Colors.red.withOpacity(0.1) : _greenAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isFull ? Colors.red : _greenAccent,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.people_rounded,
                                          color: isFull ? Colors.red : _greenAccent,
                                          size: isTablet ? 16 : 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          isFull ? 'Full' : '${banglaClass.maxStudents - banglaClass.enrolledStudents} seats left',
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 13 : 11,
                                            fontWeight: FontWeight.w600,
                                            color: isFull ? Colors.red : _greenAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Cultural Activities Preview
                              if (banglaClass.culturalActivities.isNotEmpty)
                                Row(
                                  children: banglaClass.culturalActivities.take(2).map((activity) {
                                    return Container(
                                      margin: EdgeInsets.only(right: 8),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 12 : 10,
                                        vertical: isTablet ? 6 : 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [_purpleAccent.withOpacity(0.1), _purpleAccent.withOpacity(0.05)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: _purpleAccent.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.celebration_rounded,
                                            color: _purpleAccent,
                                            size: isTablet ? 14 : 12,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            activity,
                                            style: GoogleFonts.inter(
                                              fontSize: isTablet ? 12 : 11,
                                              fontWeight: FontWeight.w600,
                                              color: _purpleAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              
                              if (banglaClass.culturalActivities.length > 2)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '+${banglaClass.culturalActivities.length - 2} cultural activities',
                                    style: GoogleFonts.inter(
                                      fontSize: isTablet ? 13 : 11,
                                      color: _textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
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
                                      onTap: () => _showClassDetails(banglaClass, user),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          vertical: isTablet ? 18 : 16,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [_primaryOrange, _redAccent, _greenAccent],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(30),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _primaryOrange.withOpacity(0.3),
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
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.white,
                                              size: isTablet ? 22 : 20,
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
            valueColor: AlwaysStoppedAnimation<Color>(_primaryOrange),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultProfileImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryOrange, _redAccent],
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

  void _showClassDetails(BanglaClass banglaClass, UserModel? user) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BanglaClassDetailsScreen(
          banglaClass: banglaClass,
          user: user,
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

  void _showAddClassDialog(BuildContext context) {
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

class _PremiumAddBanglaClassDialogState extends State<PremiumAddBanglaClassDialog> with TickerProviderStateMixin {
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

  String? _selectedState;
  List<String> _classTypes = [];
  List<TeachingMethod> _selectedMethods = [];
  List<String> _culturalActivities = [];

  final List<String> _states = CommunityStates.states;
  
  late TabController _tabController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
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
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
    return FadeTransition(
      opacity: _animationController,
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
                  offset: Offset(0, 10),
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
                      SizedBox(height: 4),
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
                  constraints: BoxConstraints(),
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
              tabs: [
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
                physics: NeverScrollableScrollPhysics(),
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
                  offset: Offset(0, -5),
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
      ),
    );
  }

  Widget _buildBasicInfoTab(bool isTablet) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(isTablet ? 24 : 16),
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
          
          _buildPremiumTextField(
            controller: _addressController,
            label: 'Street Address *',
            icon: Icons.home_rounded,
            isRequired: true,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumDropdown<String>(
            value: _selectedState,
            label: 'State *',
            icon: Icons.location_on_rounded,
            isRequired: true,
            isTablet: isTablet,
            items: _states.map((state) {
              return DropdownMenuItem<String>(
                value: state,
                child: Text(state, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedState = newValue;
              });
            },
          ),
          SizedBox(height: isTablet ? 16 : 12),
          
          _buildPremiumTextField(
            controller: _cityController,
            label: 'City *',
            icon: Icons.location_city_rounded,
            isRequired: true,
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildClassDetailsTab(bool isTablet) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(isTablet ? 24 : 16),
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
      padding: EdgeInsets.all(isTablet ? 24 : 16),
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

  Widget _buildPremiumTextField({
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
      icon: Icon(Icons.arrow_drop_down_circle_rounded, color: widget.primaryOrange, size: isTablet ? 24 : 20),
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
                constraints: BoxConstraints(),
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
                    SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => onRemove(index),
                      child: Container(
                        padding: EdgeInsets.all(2),
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
                    offset: Offset(0, 5),
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
              offset: Offset(0, 8),
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
    if (_addressController.text.isEmpty) {
      _showErrorSnackBar('Please enter address');
      return false;
    }
    if (_selectedState == null) {
      _showErrorSnackBar('Please select a state');
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

    final newClass = BanglaClass(
      instructorName: _instructorNameController.text,
      organizationName: _organizationController.text.isNotEmpty ? _organizationController.text : null,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _addressController.text,
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
      createdBy: currentUser.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      isVerified: false,
      enrolledStudents: 0,
    );

    print('📝 Creating Bangla class with createdBy: ${newClass.createdBy} (user ID)');
    print('📝 Class will be hidden until admin verification (isVerified: false)');

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
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
              SizedBox(height: 20),
              Text('Submitting...', style: GoogleFonts.poppins()),
            ],
          ),
        ),
      ),
    );

    final success = await provider.addBanglaClass(newClass);
    
    Navigator.pop(context); // Close loading
    
    if (success) {
      Navigator.pop(context); // Close dialog
      _showSuccessSnackBar('Bangla class added successfully! Pending admin approval. ✨');
      
      if (widget.onClassAdded != null) {
        widget.onClassAdded!();
      }
    } else {
      _showErrorSnackBar('Failed to add Bangla class. Please try again.');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
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
        margin: EdgeInsets.all(12),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
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
        margin: EdgeInsets.all(12),
      ),
    );
  }
}