import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:bangla_hub/models/community_services_models.dart';
import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/auth/signup_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/networing_partner/premium_partner_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class NetworkingPartnersScreen extends StatefulWidget {
  @override
  _NetworkingPartnersScreenState createState() => _NetworkingPartnersScreenState();
}

class _NetworkingPartnersScreenState extends State<NetworkingPartnersScreen> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
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

  @override
  bool get wantKeepAlive => true;

  void _showLoginRequiredDialog(BuildContext context, String feature) {
    final Color _primaryRed = Color(0xFFF42A41);
    final Color _primaryGreen = Color(0xFF006A4E);
    final Color _goldAccent = Color(0xFFFFD700);
    
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
              // Header with gradient - reduced size
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryRed, _primaryGreen],
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
                    
                    // Login Button - reduced size
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
                          backgroundColor: _primaryGreen,
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
                    
                    // Sign Up Button - reduced size
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
                          foregroundColor: _primaryGreen,
                          side: BorderSide(color: _primaryGreen, width: 2),
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
                    
                    // Continue Browsing - slightly reduced size
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
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _debugMessage = 'Loading business partners...';
    });

    try {
      final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
      await provider.loadVerifiedBusinessPartners();
      
      setState(() {
        _isLoading = false;
        _debugMessage = 'Loaded ${provider.businessPartners.length} verified businesses';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _debugMessage = 'Error: $e';
      });
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
              CustomScrollView(
                physics: BouncingScrollPhysics(),
                slivers: [
                  _buildPremiumAppBar(isTablet),
                  if (_showDebug && _debugMessage != null) _buildDebugBanner(),
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
                      'Networking Partners',
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
                    '🤝 Connect & Grow Together',
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
                      final verifiedCount = provider.businessPartners
                          .where((s) => s.isVerified && s.isActive)
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
                                Icon(Icons.verified_rounded, color: _secondaryGold, size: isTablet ? 18 : 16),
                                SizedBox(width: isTablet ? 8 : 6),
                                Text(
                                  '$verifiedCount Verified Partners',
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
        icon: Icon(Icons.arrow_back_rounded, color: Colors.white, fontWeight: FontWeight.bold, size: isTablet ? 28 : 24,),
        onPressed: () => Navigator.pop(context),
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
    return Consumer<EntrepreneurshipProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading || _isLoading) {
          return _buildLoadingState();
        }

        final verifiedPartners = provider.businessPartners
            .where((partner) => partner.isVerified && partner.isActive && !partner.isDeleted)
            .toList();

        if (verifiedPartners.isEmpty) {
          return _buildEmptyState();
        }

        return SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final partner = verifiedPartners[index];
                
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
              childCount: verifiedPartners.length,
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

  Widget _buildEmptyState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
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
                  'No Businesses Yet',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 8 : 6),
              Text(
                'Be the first to add',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 14 : 12,
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
      ),
    );
  }

  Widget _buildPremiumPartnerCard(NetworkingBusinessPartner partner, int index) {
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
                                  // User Info Row - Using partner's stored user info
                                  Row(
                                    children: [
                                      // User Profile Image from partner.postedByProfileImageBase64
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
                                      
                                      // User Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // User Name from partner.postedByName
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
                                            // Verified badge
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
                                      
                                      // Verified Badge
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
                                        child: RotationTransition(
                                          turns: _rotateController,
                                          child: Icon(
                                            Icons.verified_rounded, 
                                            color: Colors.white, 
                                            size: isTablet ? 16 : 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 16),
                                  
                                  // Business Name and Industry
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
                                                RotationTransition(
                                                  turns: _rotateController,
                                                  child: Icon(
                                                    Icons.arrow_forward_rounded,
                                                    color: Colors.white,
                                                    size: isTablet ? 18 : 16,
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

  Widget _buildPartnerPosterImage(NetworkingBusinessPartner partner) {
    if (partner.postedByProfileImageBase64 != null && partner.postedByProfileImageBase64!.isNotEmpty) {
      try {
        String base64String = partner.postedByProfileImageBase64!;
        
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

  Widget _buildPremiumTag(String text, IconData icon, [bool isTablet = false]) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 8,
        vertical: isTablet ? 6 : 4,
      ),
      decoration: BoxDecoration(
        gradient: _glassMorphismGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _secondaryGold.withOpacity(0.25)),
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
            color: _secondaryGold
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

  String _cleanBase64String(String base64) {
    String cleaned = base64.trim();
    if (cleaned.contains('base64,')) {
      cleaned = cleaned.split('base64,').last;
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s'), '');
    while (cleaned.length % 4 != 0) {
      cleaned += '=';
    }
    return cleaned;
  }
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

class _PremiumAddPartnerDialogState extends State<PremiumAddPartnerDialog> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
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

  // State variables
  String? _selectedState;
  BusinessType? _selectedBusinessType = BusinessType.soleProprietorship;
  List<String> _servicesOffered = [];
  List<String> _targetMarkets = [];
  List<String> _socialMediaLinks = [];
  
  // Image handling
  File? _logoImage;
  String? _logoBase64;
  List<File> _galleryImages = [];
  List<String> _galleryBase64 = [];
  
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
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
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

  void _handleTabChange() {
    setState(() {});
  }

  void _validateBasicInfo() {
    setState(() {
      _isBasicInfoValid = 
          _businessNameController.text.isNotEmpty &&
          _ownerNameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty &&
          _addressController.text.isNotEmpty &&
          _cityController.text.isNotEmpty &&
          _selectedState != null;
    });
  }

  void _validateDetailsTab() {
    setState(() {
      _isDetailsTabValid = 
          _selectedBusinessType != null &&
          _industryController.text.isNotEmpty &&
          _descriptionController.text.isNotEmpty &&
          _yearsController.text.isNotEmpty;
    });
  }

  bool get _isSubmitEnabled {
    return _isBasicInfoValid && _isDetailsTabValid;
  }

  void _goToPreviousTab() {
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
    }
  }

  void _goToNextTab() {
    if (_tabController.index < 2) {
      if (_tabController.index == 0 && !_isBasicInfoValid) {
        _showErrorSnackBar('Please complete all required fields');
        return;
      }
      _tabController.animateTo(_tabController.index + 1);
    }
  }

  @override
  void dispose() {
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
                _buildPremiumTabIndicator(0, 'Basic', _isBasicInfoValid),
                _buildPremiumTabConnector(_isBasicInfoValid),
                _buildPremiumTabIndicator(1, 'Media', true),
                _buildPremiumTabConnector(true),
                _buildPremiumTabIndicator(2, 'Details', _isDetailsTabValid),
              ],
            ),
          ),
          
          // Form Content with ScrollController
          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                physics: NeverScrollableScrollPhysics(),
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
                if (_tabController.index > 0) SizedBox(width: 12),
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
              SizedBox(height: 2),
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
      margin: EdgeInsets.symmetric(horizontal: 2),
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
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumSectionHeader('Business Information', Icons.business_center_rounded),
          SizedBox(height: 16),
          _buildPremiumTextField(
            controller: _businessNameController,
            label: 'Business Name *',
            icon: Icons.store_rounded,
          ),
          SizedBox(height: 12),
          _buildPremiumTextField(
            controller: _ownerNameController,
            label: 'Owner Name *',
            icon: Icons.person_rounded,
          ),
          SizedBox(height: 12),
          _buildPremiumTextField(
            controller: _emailController,
            label: 'Email *',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 12),
          _buildPremiumTextField(
            controller: _phoneController,
            label: 'Phone *',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 20),
          _buildPremiumSectionHeader('Location', Icons.location_on_rounded),
          SizedBox(height: 16),
          _buildPremiumTextField(
            controller: _addressController,
            label: 'Street Name *',
            icon: Icons.home_rounded,
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
        ],
      ),
    );
  }

  Widget _buildPremiumMediaTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumSectionHeader('Logo Image', Icons.image_rounded),
          SizedBox(height: 8),
          Text(
            'Upload your business logo (optional)',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          SizedBox(height: 16),
          
          Center(
            child: GestureDetector(
              onTap: _pickLogoImage,
              child: Container(
                width: screenWidth > 600 ? 150 : 120,
                height: screenWidth > 600 ? 150 : 120,
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
                child: _logoImage != null
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
                            size: screenWidth > 600 ? 40 : 32,
                            color: widget.primaryGreen,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add Logo',
                            style: GoogleFonts.poppins(
                              color: widget.primaryGreen,
                              fontSize: screenWidth > 600 ? 14 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          _buildPremiumSectionHeader('Gallery Images', Icons.photo_library_rounded),
          SizedBox(height: 8),
          Text(
            'Add up to 5 images to showcase your business (optional)',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: screenWidth > 600 ? 4 : 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _galleryImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _galleryImages.length) {
                return _buildPremiumAddImageButton();
              }
              return _buildPremiumGalleryImageItem(index);
            },
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
          _buildPremiumSectionHeader('Business Details', Icons.info_rounded),
          SizedBox(height: 16),
          
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
              setState(() {
                _selectedBusinessType = value;
                _validateDetailsTab();
              });
            },
            icon: Icons.business_rounded,
          ),
          SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _industryController,
            label: 'Industry *',
            icon: Icons.category_rounded,
          ),
          SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _descriptionController,
            label: 'Description *',
            icon: Icons.description_rounded,
            maxLines: 3,
          ),
          SizedBox(height: 12),
          
          _buildPremiumTextField(
            controller: _yearsController,
            label: 'Years in Business *',
            icon: Icons.calendar_today_rounded,
            keyboardType: TextInputType.number,
          ),
          
          SizedBox(height: 24),
          
          _buildPremiumSectionHeader('Services Offered', Icons.checklist_rounded),
          SizedBox(height: 16),
          
          _buildPremiumTagInput(
            controller: _serviceController,
            tags: _servicesOffered,
            hint: 'Add service',
            onAdd: () {
              if (_serviceController.text.trim().isNotEmpty) {
                setState(() {
                  _servicesOffered.add(_serviceController.text.trim());
                  _serviceController.clear();
                });
              }
            },
            onRemove: (index) {
              setState(() {
                _servicesOffered.removeAt(index);
              });
            },
          ),
          
          SizedBox(height: 24),
          
          _buildPremiumSectionHeader('Additional Info', Icons.add_circle_outline_rounded),
          SizedBox(height: 16),
          
          _buildPremiumTextField(
            controller: _websiteController,
            label: 'Website',
            icon: Icons.language_rounded,
            keyboardType: TextInputType.url,
          ),
          SizedBox(height: 12),
          
          _buildPremiumTagInput(
            controller: _socialMediaController,
            tags: _socialMediaLinks,
            hint: 'Add social media URL',
            onAdd: () {
              if (_socialMediaController.text.trim().isNotEmpty) {
                setState(() {
                  _socialMediaLinks.add(_socialMediaController.text.trim());
                  _socialMediaController.clear();
                });
              }
            },
            onRemove: (index) {
              setState(() {
                _socialMediaLinks.removeAt(index);
              });
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
        SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: screenWidth > 600 ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E2A3A),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
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
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                    borderSide: BorderSide(color: widget.primaryGreen, width: 2),
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
                        size: 12,
                      ),
                      SizedBox(width: 4),
                    ],
                    Text(
                      isSocialMedia ? _getSocialMediaName(tags[index]) : tags[index],
                      style: TextStyle(
                        color: isSocialMedia ? Colors.white : widget.primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => onRemove(index),
                      child: Icon(
                        Icons.close_rounded,
                        color: isSocialMedia ? Colors.white70 : widget.accentRed,
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

  Widget _buildPremiumAddImageButton() {
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
              color: _galleryImages.length < 5 ? widget.primaryGreen : Colors.grey[400],
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              _galleryImages.length < 5 ? 'Add' : 'Max',
              style: TextStyle(
                color: _galleryImages.length < 5 ? widget.primaryGreen : Colors.grey[500],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumGalleryImageItem(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(_galleryImages[index]),
              fit: BoxFit.cover,
            ),
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
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: widget.accentRed,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.accentRed.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(Icons.close_rounded, color: Colors.white, size: 10),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickLogoImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      maxWidth: 400, 
      maxHeight: 400, 
      imageQuality: 70,
    );
    
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      
      if (base64String.length > 100000) {
        _showErrorSnackBar('Logo is too large. Please choose a smaller image.');
        return;
      }
      
      setState(() {
        _logoImage = imageFile;
        _logoBase64 = base64String;
      });
    }
  }

  Future<void> _pickGalleryImage() async {
    if (_galleryImages.length >= 5) {
      _showErrorSnackBar('Maximum 5 images allowed');
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      maxWidth: 800, 
      maxHeight: 800, 
      imageQuality: 70,
    );
    
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      
      if (base64String.length > 200000) {
        _showErrorSnackBar('Image is too large. Please choose a smaller image.');
        return;
      }
      
      setState(() {
        _galleryImages.add(imageFile);
        _galleryBase64.add(base64String);
      });
    }
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
    if (url.contains('facebook.com') || url.contains('fb.com')) return Color(0xFF1877F2);
    if (url.contains('instagram.com')) return Color(0xFFE4405F);
    if (url.contains('twitter.com') || url.contains('x.com')) return Color(0xFF1DA1F2);
    if (url.contains('linkedin.com')) return Color(0xFF0A66C2);
    if (url.contains('youtube.com')) return Color(0xFFFF0000);
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

    if (_selectedState == null) {
      _showErrorSnackBar('Please select a state');
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
    _galleryBase64.forEach((img) => totalSize += img.length);
    
    if (totalSize > 800000) {
      _showErrorSnackBar('Total image size too large. Please use smaller images.');
      return;
    }

    final newPartner = NetworkingBusinessPartner(
      businessName: _businessNameController.text,
      ownerName: _ownerNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      state: _selectedState!,
      city: _cityController.text,
      businessType: _selectedBusinessType!,
      industry: _industryController.text,
      description: _descriptionController.text,
      yearsInBusiness: int.tryParse(_yearsController.text) ?? 0,
      servicesOffered: _servicesOffered,
      targetMarkets: _targetMarkets,
      businessHours: ['Mon-Fri: 9 AM - 6 PM'],
      logoImageBase64: _logoBase64,
      galleryImagesBase64: _galleryBase64.isNotEmpty ? _galleryBase64 : null,
      website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
      socialMediaLinks: _socialMediaLinks.isNotEmpty ? _socialMediaLinks : null,
      
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
      likedByUsers: [],
      languagesSpoken: ['English', 'Bengali'],
    );

    final success = await provider.addBusinessPartner(newPartner);
    
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
                  'Business added successfully! Pending admin approval.',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: widget.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(12),
        ),
      );
      
      if (widget.onBusinessAdded != null) {
        widget.onBusinessAdded!();
      }
    } else {
      _showErrorSnackBar('Failed to add business. Please try again.');
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
        backgroundColor: widget.accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(12),
      ),
    );
  }
}