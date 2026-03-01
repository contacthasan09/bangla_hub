// screens/user_app/entrepreneurship/partner_requests/partner_requests_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:bangla_hub/models/business_model.dart' hide BusinessPartnerRequest;
import 'package:bangla_hub/models/community_services_models.dart';
import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/models/user_model.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/business_partner_request/partner_request_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class BusinessPartnerRequestsScreen extends StatefulWidget {
  @override
  _BusinessPartnerRequestsScreenState createState() => _BusinessPartnerRequestsScreenState();
}

class _BusinessPartnerRequestsScreenState extends State<BusinessPartnerRequestsScreen> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  // Premium Color Palette - Soft Green Accent Theme
  final Color _softGreen = Color(0xFF98D8C8); // Main soft green accent
  final Color _lightGreen = Color(0xFFE0F2F1); // Light green
  final Color _lightGreenBg = Color(0x80E0F2F1); // Light green with 50% opacity
  final Color _darkGreen = Color(0xFF2E7D32); // Dark green
  final Color _deepGreen = Color(0xFF1B5E20); // Deep green
  
  final Color _primaryGreen = Color(0xFF2E7D32); // Primary green
  final Color _secondaryGold = Color(0xFFFFB300); // Gold accent
  final Color _softGold = Color(0xFFFFD966); // Soft gold
  
  // Supporting colors
  final Color _textPrimary = Color(0xFF1A2B3C);
  final Color _textSecondary = Color(0xFF5D6D7E);
  final Color _borderLight = Color(0xFFE0E7E9);
  final Color _shadowColor = Color(0x1A000000);
  
  // Background Gradient - Light Green Priority
  final LinearGradient _bodyBgGradient = LinearGradient(
    colors: [
      Color(0xFFE0F2F1), // Light green
      Color(0xFFE8F5E9), // Very light green
      Color(0xFFF1F8E9), // Light mint
      Color(0xFFF9FBE7), // Light lime
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.4, 0.7, 1.0],
  );

  final LinearGradient _appBarGradient = LinearGradient(
    colors: [
      Color(0xFF2E7D32), // Primary Green
      Color(0xFF1B5E20), // Dark Green
      Color(0xFF98D8C8), // Soft Green
      Color(0xFF81C784), // Light Green
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.4, 0.7, 1.0],
  );

  // Gradients for accents
  final LinearGradient _preciousGradient = LinearGradient(
    colors: [
      Color(0xFFFFB300), // gold
      Color(0xFF2E7D32), // green
      Color(0xFF98D8C8), // soft green
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _gemstoneGradient = LinearGradient(
    colors: [
      Color(0xFF2E7D32), // green
      Color(0xFF98D8C8), // soft green
      Color(0xFFFFB300), // gold
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _royalGradient = LinearGradient(
    colors: [
      Color(0xFF2E7D32), // green
      Color(0xFFFFB300), // gold
      Color(0xFF98D8C8), // soft green
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _greenGradient = LinearGradient(
    colors: [
      Color(0xFF2E7D32), // green
      Color(0xFF98D8C8), // soft green
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
      await provider.loadPartnerRequests();
      
      // Load user profiles immediately for all requests
      if (provider.partnerRequests.isNotEmpty) {
        await _loadAllUserProfiles(provider.partnerRequests);
        _setupUserProfileListeners(provider.partnerRequests);
      }
      
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading partner requests: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAllUserProfiles(List<BusinessPartnerRequest> requests) async {
    final Map<String, Future<UserModel?>> futures = {};
    
    for (var request in requests) {
      final userId = request.createdBy;
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

  void _setupUserProfileListeners(List<BusinessPartnerRequest> requests) {
    _userSubscriptions.values.forEach((sub) => sub?.cancel());
    _userSubscriptions.clear();
    
    for (var request in requests) {
      final userId = request.createdBy;
      
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
      query: 'subject=Business Partnership Inquiry',
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
        backgroundColor: _primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.all(16),
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
              
              // Main Content
              CustomScrollView(
                physics: BouncingScrollPhysics(),
                slivers: [
                  _buildPremiumAppBar(isTablet),
                  _buildContent(),
                ],
              ),
              
              // Premium Floating Action Button
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
                  // Premium Pattern Line
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
                  
                  // Title with Gradient
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.white, _secondaryGold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'Find Business Partner',
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
                    '🤝 Connect with Potential Business Partners',
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
          border: Border.all(color: _secondaryGold.withOpacity(0.3), width: 1.5),
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
    
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
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
            BoxShadow(
              color: _softGreen.withOpacity(0.4),
              blurRadius: 30,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAddRequestDialog(context),
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
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: isTablet ? 26 : 22,
                    ),
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
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<EntrepreneurshipProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading || _isLoading) {
          return _buildLoadingState();
        }

        final verifiedRequests = provider.partnerRequests
            .where((r) => r.isVerified && r.isActive && !r.isDeleted)
            .toList();

        if (verifiedRequests.isEmpty) {
          return _buildEmptyState();
        }

        return SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final request = verifiedRequests[index];
                final user = _userCache[request.createdBy];
                
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: _buildPremiumRequestCard(request, user, index),
                    ),
                  ),
                );
              },
              childCount: verifiedRequests.length,
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
                      gradient: _royalGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryGreen.withOpacity(0.3),
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
                              color: _primaryGreen,
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
              shaderCallback: (bounds) => _gemstoneGradient.createShader(bounds),
              child: Text(
                'Loading Partners...',
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
                'Finding the best partnership opportunities',
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
                          colors: [_lightGreen, _softGreen.withOpacity(0.3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.people_alt_rounded,
                        size: isTablet ? 80 : 70,
                        color: _primaryGreen,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: isTablet ? 40 : 30),
              ShaderMask(
                shaderCallback: (bounds) => _gemstoneGradient.createShader(bounds),
                child: Text(
                  'No Partner Requests',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 30 : 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 16 : 12),
              Text(
                'Be the first to look for a business partner',
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

  Widget _buildPremiumRequestCard(BusinessPartnerRequest request, UserModel? user, int index) {
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
                    color: _primaryGreen.withOpacity(0.25),
                    blurRadius: 30,
                    offset: Offset(0, 16),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: _softGreen.withOpacity(0.15),
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
                          _lightGreen.withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showRequestDetails(request, user),
                        borderRadius: BorderRadius.circular(40),
                        splashColor: _secondaryGold.withOpacity(0.15),
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
                                            gradient: _royalGradient,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _secondaryGold.withOpacity(0.4),
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
                                                  shaderCallback: (bounds) => _gemstoneGradient.createShader(bounds),
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
                                                        valueColor: AlwaysStoppedAnimation<Color>(_primaryGreen.withOpacity(0.3)),
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
                                                gradient: _gemstoneGradient,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              user != null ? 'Looking for Partner' : 'Loading...',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: user != null ? _secondaryGold : Colors.grey,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Verified Badge
                                  if (request.isVerified)
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: _preciousGradient,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: _secondaryGold.withOpacity(0.4),
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
                              
                              // Partner Type and Business Type
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
                                            request.partnerType.displayName,
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
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            gradient: _greenGradient,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _primaryGreen.withOpacity(0.3),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            request.businessType.displayName,
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 15 : 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Urgent Badge
                                  if (request.isUrgent)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [_primaryGreen, _darkGreen],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _primaryGreen.withOpacity(0.3),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.priority_high_rounded, color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            'URGENT',
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
                              
                              SizedBox(height: 16),
                              
                              // Tags
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildPremiumTag(request.partnerType.displayName, Icons.person_rounded),
                                  _buildPremiumTag(request.city, Icons.location_on_rounded),
                                  if (request.industry != null && request.industry!.isNotEmpty && request.industry != 'Not specified')
                                    _buildPremiumTag(request.industry!, Icons.category_rounded),
                                ],
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Budget and Duration Row
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: _primaryGreen.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Budget',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: _textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            '\$${request.budgetMin.toStringAsFixed(0)} - \$${request.budgetMax.toStringAsFixed(0)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 14 : 13,
                                              fontWeight: FontWeight.w700,
                                              color: _primaryGreen,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: _softGreen.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Duration',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: _textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            request.investmentDuration,
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 14 : 13,
                                              fontWeight: FontWeight.w600,
                                              color: _softGreen,
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
                              
                              SizedBox(height: 16),
                              
                              // Description preview
                              Text(
                                request.description.length > 100
                                    ? '${request.description.substring(0, 100)}...'
                                    : request.description,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 14 : 13,
                                  color: _textSecondary,
                                  height: 1.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Stats Row
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _primaryGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.remove_red_eye_rounded, size: 14, color: _primaryGreen),
                                        SizedBox(width: 4),
                                        Text(
                                          '${request.totalViews} views',
                                          style: GoogleFonts.inter(
                                            color: _primaryGreen,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
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
                                      onTap: () => _showRequestDetails(request, user),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          vertical: isTablet ? 18 : 16,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: _royalGradient,
                                          borderRadius: BorderRadius.circular(30),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _primaryGreen.withOpacity(0.3),
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
        gradient: _glassMorphismGradient,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _secondaryGold.withOpacity(0.25)),
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
          Icon(icon, size: 12, color: _secondaryGold),
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
            valueColor: AlwaysStoppedAnimation<Color>(_primaryGreen),
          ),
        ),
      ),
    );
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

  void _showRequestDetails(BusinessPartnerRequest request, UserModel? user) async {
    HapticFeedback.mediumImpact();
    
    // Increment view count
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    await provider.incrementViewCount(EntrepreneurshipCategory.lookingForBusinessPartner, request.id!);
    
    // Refresh to show updated view count
    await provider.loadPartnerRequests();
    
    if (!mounted) return;
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PartnerRequestDetailsScreen(
          request: request,
          user: user,
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

class _AddPartnerRequestDialogState extends State<AddPartnerRequestDialog> with TickerProviderStateMixin {
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

  final List<String> _states = CommunityStates.states;
  
  late TabController _tabController;
  late AnimationController _animationController;
  
  // Track completed tabs
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

  void _validateBasicInfo() {
    setState(() {
      _isBasicInfoValid = 
          _selectedPartnerType != null &&
          _selectedBusinessType != null &&
          _locationController.text.isNotEmpty &&
          _cityController.text.isNotEmpty &&
          _selectedState != null &&
          _contactNameController.text.isNotEmpty &&
          _contactEmailController.text.isNotEmpty &&
          _contactPhoneController.text.isNotEmpty;
    });
  }

  void _validateDetails() {
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

  bool get _isSubmitEnabled => _isBasicInfoValid && _isDetailsValid;

  void _goToPreviousTab() {
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
    }
  }

  void _goToNextTab() {
    if (_tabController.index < 1) {
      if (_tabController.index == 0 && !_isBasicInfoValid) {
        _showErrorSnackBar('Please complete all required fields');
        return;
      }
      _tabController.animateTo(_tabController.index + 1);
    }
  }

  @override
  void dispose() {
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
                  padding: EdgeInsets.all(screenWidth > 600 ? 12 : 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person_add_rounded, color: widget.secondaryGold, size: screenWidth > 600 ? 28 : 22),
                ),
                SizedBox(width: screenWidth > 600 ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find a Business Partner',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth > 600 ? 20 : 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Describe what you\'re looking for',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: screenWidth > 600 ? 13 : 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
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
                _buildPremiumTabIndicator(0, 'Basic Info', _isBasicInfoValid),
                _buildPremiumTabConnector(_isBasicInfoValid),
                _buildPremiumTabIndicator(1, 'Details', _isDetailsValid),
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
                    ),
                  ),
                if (_tabController.index > 0) const SizedBox(width: 12),
                Expanded(
                  child: _tabController.index < 1
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
              'Post Request',
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
      padding: const EdgeInsets.all(16),
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
          
          _buildPremiumSectionHeader('Partner Information', Icons.people_rounded),
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
          ),
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _industryController,
            label: 'Industry (Optional)',
            icon: Icons.category_rounded,
          ),
          
          const SizedBox(height: 20),
          
          _buildPremiumSectionHeader('Location', Icons.location_on_rounded),
          const SizedBox(height: 16),
          
          _buildPremiumTextField(
            controller: _locationController,
            label: 'Street Name *',
            icon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 12),
          
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
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _cityController,
            label: 'City *',
            icon: Icons.location_city_rounded,
          ),
          
          const SizedBox(height: 20),
          
          _buildPremiumSectionHeader('Contact Information', Icons.contact_phone_rounded),
          const SizedBox(height: 16),
          
          _buildPremiumTextField(
            controller: _contactNameController,
            label: 'Your Name *',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _contactEmailController,
            label: 'Your Email *',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _contactPhoneController,
            label: 'Your Phone *',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _preferredMeetingController,
            label: 'Preferred Meeting Method (Optional)',
            icon: Icons.video_call_rounded,
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

  Widget _buildPremiumDetailsTab() {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumSectionHeader('Description', Icons.description_rounded),
          const SizedBox(height: 16),
          
          _buildPremiumTextField(
            controller: _descriptionController,
            label: 'Description *',
            icon: Icons.description_rounded,
            maxLines: 4,
          ),
          
          const SizedBox(height: 24),
          
          _buildPremiumSectionHeader('Budget & Duration', Icons.attach_money_rounded),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildPremiumTextField(
                  controller: _budgetMinController,
                  label: 'Min Budget *',
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPremiumTextField(
                  controller: _budgetMaxController,
                  label: 'Max Budget *',
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _investmentDurationController,
            label: 'Investment Duration *',
            icon: Icons.schedule_rounded,
          ),
          
          const SizedBox(height: 24),
          
          _buildPremiumSectionHeader('Skills Required *', Icons.code_rounded),
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
          ),
          
          const SizedBox(height: 24),
          
          _buildPremiumSectionHeader('Responsibilities *', Icons.task_rounded),
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
              colors: [widget.primaryGreen, widget.secondaryGold],
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
            color: widget.primaryGreen,
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
          prefixIcon: Icon(icon, color: widget.primaryGreen, size: 18),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
          prefixIcon: Icon(icon, color: widget.primaryGreen, size: 18),
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
          _validateBasicInfo();
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
                  hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                padding: const EdgeInsets.all(10),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => onRemove(index),
                      child: Icon(
                        Icons.close_rounded,
                        color: widget.accentRed,
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

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedState == null) {
      _showErrorSnackBar('Please select a state');
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
      isVerified: false,
      isActive: true,
      isDeleted: false,
      totalViews: 0,
      totalResponses: 0,
      category: EntrepreneurshipCategory.lookingForBusinessPartner,
      tags: [],
      additionalInfo: {},
    );

    final success = await provider.addPartnerRequest(newRequest);
    
    if (success) {
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
    } else {
      _showErrorSnackBar('Failed to post request. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
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