// screens/user_app/entrepreneurship/networing_partner/premium_partner_details_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class PremiumPartnerDetailsScreen extends StatefulWidget {
  final NetworkingBusinessPartner partner;
  final ScrollController scrollController;
  final Function(String) onLaunchPhone;
  final Function(String) onLaunchEmail;
  final Function(String) onLaunchUrl;
  final Color primaryGreen;
  final Color secondaryGold;
  final Color accentRed;
  final Color lightGreen;

  const PremiumPartnerDetailsScreen({
    Key? key,
    required this.partner,
    required this.scrollController,
    required this.onLaunchPhone,
    required this.onLaunchEmail,
    required this.onLaunchUrl,
    required this.primaryGreen,
    required this.secondaryGold,
    required this.accentRed,
    required this.lightGreen,
  }) : super(key: key);

  @override
  _PremiumPartnerDetailsScreenState createState() => _PremiumPartnerDetailsScreenState();
}

class _PremiumPartnerDetailsScreenState extends State<PremiumPartnerDetailsScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  int _currentImageIndex = 0;
  late AnimationController _animationController;
  late PageController _pageController;
  
  // Particle animation controllers
  late List<AnimationController> _particleControllers;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  
  // Premium Color Palette
  final Color _primaryRed = Color(0xFFD32F2F);
  final Color _primaryGreen = Color(0xFF2E7D32);
  final Color _darkGreen = Color(0xFF1B5E20);
  final Color _goldAccent = Color(0xFFFFB300);
  final Color _softGold = Color(0xFFFF8F00);
  final Color _deepRed = Color(0xFFB71C1C);
  
  // Light backgrounds
  final Color _lightGreenBg = Color(0x80E8F5E9);
  final Color _lightGreen = Color(0xFFE8F5E9);
  final Color _lightRed = Color(0xFFFFEBEE);
  final Color _lightYellow = Color(0xFFFFF3E0);
  final Color _lightBlue = Color(0xFFE3F2FD);
  final Color _creamWhite = Color(0xFFFFF9E6);
  
  // 50% opacity colors
  final Color _lightGreen50 = Color(0x80E8F5E9);
  final Color _lightYellow50 = Color(0x80FFF3E0);
  final Color _lightBlue50 = Color(0x80E3F2FD);
  
  // Border and shadow colors
  final Color _borderLight = Color(0xFFE0E7E9);
  final Color _shadowColor = Color(0x1A000000);
  
  // Text Colors
  final Color _textPrimary = Color(0xFF1A2B3C);
  final Color _textSecondary = Color(0xFF5D6D7E);
  
  // Additional colors
  final Color _successGreen = Color(0xFF2E7D32);
  final Color _infoBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animationController.forward();
    _pageController = PageController();
    
    // Initialize particle controllers
    _particleControllers = List.generate(20, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(seconds: 3 + (index % 3)),
      )..repeat(reverse: true);
    });
    
    // Start animations if app is visible
    if (_appLifecycleState == AppLifecycleState.resumed) {
      _startAnimations();
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

  @override
  void dispose() {
    print('🗑️ PremiumPartnerDetailsScreen disposing...');
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _pageController.dispose();
    for (var controller in _particleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Helper function to check if string is a URL
  bool _isUrlString(String str) {
    return str.startsWith('http://') || str.startsWith('https://');
  }

  // Helper function to clean Base64 string
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

  // Build partner poster image (handles both URL and Base64)
  Widget _buildPartnerPosterImage({bool isLarge = false}) {
    final imageData = widget.partner.postedByProfileImageBase64;
    
    if (imageData != null && imageData.isNotEmpty) {
      // Check if it's a URL
      if (_isUrlString(imageData)) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            imageData,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading profile image: $error');
              return _buildDefaultProfileImage(isLarge: isLarge);
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
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                print('Error decoding profile image: $error');
                return _buildDefaultProfileImage(isLarge: isLarge);
              },
            ),
          );
        } catch (e) {
          print('Error processing profile image: $e');
          return _buildDefaultProfileImage(isLarge: isLarge);
        }
      }
    }
    
    return _buildDefaultProfileImage(isLarge: isLarge);
  }

  // Build logo image (handles Base64, fills entire container)
  Widget _buildLogoImage({bool fillContainer = false}) {
    final logoData = widget.partner.logoImageBase64;
    
    if (logoData != null && logoData.isNotEmpty) {
      try {
        String base64String = logoData;
        
        if (base64String.contains('base64,')) {
          base64String = base64String.split('base64,').last;
        }
        
        base64String = base64String.replaceAll(RegExp(r'\s'), '');
        
        while (base64String.length % 4 != 0) {
          base64String += '=';
        }
        
        final bytes = base64Decode(base64String);
        
        if (fillContainer) {
          // Fill entire container without any shape clipping
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultLogoImage(fillContainer: fillContainer);
            },
          );
        } else {
          // For fixed size containers
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: 60,
              height: 60,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultLogoImage(fillContainer: fillContainer);
              },
            ),
          );
        }
      } catch (e) {
        print('Error decoding logo image: $e');
        return _buildDefaultLogoImage(fillContainer: fillContainer);
      }
    }
    
    return _buildDefaultLogoImage(fillContainer: fillContainer);
  }

  // Build gallery image (handles Base64)
  Widget _buildGalleryImage(String base64Data) {
    try {
      String cleanedBase64 = _cleanBase64String(base64Data);
      final bytes = base64Decode(cleanedBase64);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: Center(
              child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
            ),
          );
        },
      );
    } catch (e) {
      print('Error decoding gallery image: $e');
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
        ),
      );
    }
  }

  Widget _buildDefaultProfileImage({bool isLarge = false}) {
    return Container(
      color: widget.lightGreen,
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: widget.primaryGreen,
          size: isLarge ? 40 : 24,
        ),
      ),
    );
  }

  Widget _buildDefaultLogoImage({bool fillContainer = false}) {
    if (fillContainer) {
      // Fill entire container with gradient background
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryGreen, _darkGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.store_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      );
    } else {
      // Fixed size container
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            Icons.store_rounded,
            size: 30,
            color: Colors.grey[600],
          ),
        ),
      );
    }
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
            opacity: (0.1 + (value * 0.2)) * (0.5 + (index % 3) * 0.1),
            child: Transform.rotate(
              angle: value * 6.28,
              child: Container(
                width: 2 + (index % 3) * 2,
                height: 2 + (index % 3) * 2,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _primaryGreen.withOpacity(0.1),
                      _primaryRed.withOpacity(0.05),
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

  @override
  Widget build(BuildContext context) {
    final partner = widget.partner;
    final hasImages = partner.galleryImagesBase64 != null && partner.galleryImagesBase64!.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded, 
              color: Colors.white, 
              fontWeight: FontWeight.bold,
              size: isTablet ? 28 : 24,
            ),
            onPressed: () => Navigator.pop(context),
            constraints: BoxConstraints.expand(),
            padding: EdgeInsets.zero,
            splashRadius: isTablet ? 18 : 14,
          ),
          leadingWidth: isTablet ? 52 : 44,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_lightGreenBg, _lightGreen, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Animated Background Particles
              ...List.generate(20, (index) => _buildAnimatedParticle(index, screenWidth, MediaQuery.of(context).size.height)),
              
              // Main Content
              CustomScrollView(
                controller: widget.scrollController,
                slivers: [
                  // Banner/Gallery Section
                  SliverToBoxAdapter(
                    child: hasImages
                        ? _buildPremiumImageGallery(partner, isTablet)
                        : Container(
                            height: isTablet ? 300 : 250,
                            width: double.infinity,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Logo image filling entire container
                                _buildLogoImage(fillContainer: true),
                                
                                // Dark overlay for better text readability
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withOpacity(0.4),
                                        Colors.black.withOpacity(0.2),
                                        Colors.black.withOpacity(0.6),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                                
                                // Business name overlay
                                Positioned(
                                  bottom: isTablet ? 30 : 20,
                                  left: isTablet ? 30 : 20,
                                  right: isTablet ? 30 : 20,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                 /*     Text(
                                        partner.businessName,
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 28 : 22,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(0.5),
                                              blurRadius: 10,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: isTablet ? 8 : 6),*/
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _goldAccent,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.verified_rounded, color: Colors.white, size: isTablet ? 16 : 14),
                                            SizedBox(width: 4),
                                            Text(
                                              'Premium Partner',
                                              style: GoogleFonts.poppins(
                                                fontSize: isTablet ? 12 : 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
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
                          ),
                  ),
                  
                  // All Information in Column Below
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.all(isTablet ? 24 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: isTablet ? 20 : 16),
                          
                          // Business Info Row with Logo
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Business Logo - RECTANGULAR
                              Container(
                                width: isTablet ? 90 : 80,
                                height: isTablet ? 90 : 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryGreen, _darkGreen],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _goldAccent, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _goldAccent.withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: _buildLogoImage(fillContainer: true),
                                ),
                              ),
                              
                              SizedBox(width: isTablet ? 20 : 16),
                              
                              // Business Name and User Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // User Name from partner.postedByName
                                    if (partner.postedByName != null && partner.postedByName!.isNotEmpty)
                                      Container(
                                        margin: EdgeInsets.only(bottom: 8),
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _lightGreen,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.person_rounded, color: _primaryGreen, size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              partner.postedByName!,
                                              style: GoogleFonts.poppins(
                                                color: _primaryGreen,
                                                fontSize: isTablet ? 14 : 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    
                                    // Business Name
                                    Text(
                                      partner.businessName,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 28 : 24,
                                        fontWeight: FontWeight.w800,
                                        color: _textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: isTablet ? 20 : 16),
                          
                          // Industry and Type Badges
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Industry Badge - DARK RED
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 8 : 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryRed, _deepRed],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryRed.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.category_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 18 : 16,
                                    ),
                                    SizedBox(width: isTablet ? 8 : 6),
                                    Text(
                                      partner.industry,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 14 : 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Business Type Badge - DARK GREEN
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 8 : 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryGreen, _darkGreen],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryGreen.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.business_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 18 : 16,
                                    ),
                                    SizedBox(width: isTablet ? 8 : 6),
                                    Text(
                                      partner.businessType.displayName,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 14 : 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: isTablet ? 20 : 16),
                          
                          // Verified Badge and Years Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Verified Badge - DARK GREEN
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 6 : 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_successGreen, _darkGreen],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _successGreen.withOpacity(0.3),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 16 : 14,
                                    ),
                                    SizedBox(width: isTablet ? 4 : 3),
                                    Text(
                                      'VERIFIED',
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 12 : 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Years in Business Badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 6 : 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_goldAccent, _softGold],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _goldAccent.withOpacity(0.3),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.timeline_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 16 : 14,
                                    ),
                                    SizedBox(width: isTablet ? 4 : 3),
                                    Text(
                                      '${partner.yearsInBusiness}+ Years',
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 12 : 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: isTablet ? 32 : 24),
                          
                          // About Section
                          _buildPremiumDetailSection(
                            title: 'About the Business',
                            icon: Icons.description_rounded,
                            child: Container(
                              padding: EdgeInsets.all(isTablet ? 20 : 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                border: Border.all(color: _borderLight, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: _shadowColor,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                partner.description,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 15 : 14,
                                  color: _textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            isTablet: isTablet,
                          ),
                          
                          SizedBox(height: isTablet ? 32 : 24),
                          
                          // Business Details Section
                          _buildPremiumDetailSection(
                            title: 'Business Details',
                            icon: Icons.business_center_rounded,
                            child: Column(
                              children: [
                                // Location Card
                                _buildPremiumDetailCard(
                                  icon: Icons.location_on_rounded,
                                  title: 'Location',
                                  value: '${partner.address}, ${partner.city}, ${partner.state}',
                                  gradientColors: [_primaryRed, _deepRed],
                                  isTablet: isTablet,
                                ),
                                SizedBox(height: isTablet ? 14 : 12),
                                
                                // Industry Card
                                _buildPremiumDetailCard(
                                  icon: Icons.category_rounded,
                                  title: 'Industry',
                                  value: partner.industry,
                                  gradientColors: [_primaryGreen, _darkGreen],
                                  isTablet: isTablet,
                                ),
                                SizedBox(height: isTablet ? 14 : 12),
                                
                                // Business Type Card
                                _buildPremiumDetailCard(
                                  icon: Icons.business_rounded,
                                  title: 'Business Type',
                                  value: partner.businessType.displayName,
                                  gradientColors: [_goldAccent, _softGold],
                                  isTablet: isTablet,
                                ),
                              ],
                            ),
                            isTablet: isTablet,
                          ),
                          
                          // Services Offered Section
                          if (partner.servicesOffered.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPremiumDetailSection(
                              title: 'Services Offered',
                              icon: Icons.checklist_rounded,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: partner.servicesOffered.map((service) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 16 : 14,
                                      vertical: isTablet ? 10 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_primaryGreen.withOpacity(0.1), _lightGreen],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(color: _primaryGreen.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      service,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 15 : 13,
                                        fontWeight: FontWeight.w600,
                                        color: _primaryGreen,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Target Markets Section
                          if (partner.targetMarkets.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPremiumDetailSection(
                              title: 'Target Markets',
                              icon: Icons.people_rounded,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: partner.targetMarkets.map((market) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 16 : 14,
                                      vertical: isTablet ? 10 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_goldAccent.withOpacity(0.1), _lightYellow],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(color: _goldAccent.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      market,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 15 : 13,
                                        fontWeight: FontWeight.w600,
                                        color: _goldAccent,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Languages Spoken Section
                          if (partner.languagesSpoken.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPremiumDetailSection(
                              title: 'Languages Spoken',
                              icon: Icons.language_rounded,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: partner.languagesSpoken.map((language) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 16 : 14,
                                      vertical: isTablet ? 10 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_infoBlue.withOpacity(0.1), _lightBlue],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(color: _infoBlue.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      language,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 15 : 13,
                                        fontWeight: FontWeight.w600,
                                        color: _infoBlue,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Contact Information Section
                          SizedBox(height: isTablet ? 32 : 24),
                          _buildPremiumDetailSection(
                            title: 'Contact Information',
                            icon: Icons.contact_phone_rounded,
                            child: Container(
                              padding: EdgeInsets.all(isTablet ? 20 : 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                border: Border.all(color: _borderLight, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: _shadowColor,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildPremiumContactItem(
                                    icon: Icons.phone_rounded,
                                    title: 'Phone',
                                    value: partner.phone,
                                    isTablet: isTablet,
                                //    onTap: () => widget.onLaunchPhone(partner.phone),
                                  ),
                                  SizedBox(height: isTablet ? 14 : 12),
                                  _buildPremiumContactItem(
                                    icon: Icons.email_rounded,
                                    title: 'Email',
                                    value: partner.email,
                                    isTablet: isTablet,
                                //    onTap: () => widget.onLaunchEmail(partner.email),
                                  ),
                                  if (partner.website != null && partner.website!.isNotEmpty) ...[
                                    SizedBox(height: isTablet ? 14 : 12),
                                    _buildPremiumContactItem(
                                      icon: Icons.language_rounded,
                                      title: 'Website',
                                      value: partner.website!,
                                      isTablet: isTablet,
                                      onTap: () => widget.onLaunchUrl(partner.website!),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            isTablet: isTablet,
                          ),
                          
                          // Social Media Section
                          if (partner.socialMediaLinks != null && partner.socialMediaLinks!.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPremiumDetailSection(
                              title: 'Social Media',
                              icon: Icons.share_rounded,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: partner.socialMediaLinks!.map((link) {
                                  return InkWell(
                                    onTap: () => widget.onLaunchUrl(link),
                                    borderRadius: BorderRadius.circular(25),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 16 : 14,
                                        vertical: isTablet ? 10 : 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [_getSocialMediaColor(link), _getSocialMediaColor(link).withOpacity(0.7)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _getSocialMediaColor(link).withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getSocialMediaIcon(link),
                                            color: Colors.white,
                                            size: isTablet ? 18 : 16,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            _getSocialMediaName(link),
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 14 : 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Premium Footer
                          SizedBox(height: isTablet ? 40 : 32),
                          Container(
                            padding: EdgeInsets.all(isTablet ? 24 : 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_lightGreen50, _lightGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                              border: Border.all(color: _primaryGreen.withOpacity(0.2), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                // Logo container - RECTANGULAR with rounded corners
                                Container(
                                  width: isTablet ? 80 : 70,
                                  height: isTablet ? 80 : 70,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_primaryRed, _primaryGreen],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryRed.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: _buildLogoImage(fillContainer: true),
                                  ),
                                ),
                                SizedBox(width: isTablet ? 20 : 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Premium Partner',
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.w700,
                                          color: _primaryGreen,
                                        ),
                                      ),
                                      SizedBox(height: isTablet ? 4 : 2),
                                      Text(
                                        'Verified Business Partner',
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
                          ),
                          
                          SizedBox(height: isTablet ? 40 : 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
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
              Expanded(
                child: _buildPremiumActionButton(
                  icon: Icons.phone_rounded,
                  label: 'Call Now',
                  gradient: LinearGradient(
                    colors: [_primaryGreen, _darkGreen],
                  ),
                  onPressed: () => widget.onLaunchPhone(partner.phone),
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: _buildPremiumActionButton(
                  icon: Icons.email_rounded,
                  label: 'Send Email',
                  gradient: LinearGradient(
                    colors: [_primaryRed, _deepRed],
                  ),
                  onPressed: () => widget.onLaunchEmail(partner.email),
                  isTablet: isTablet,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumImageGallery(NetworkingBusinessPartner partner, bool isTablet) {
    final galleryImages = partner.galleryImagesBase64 ?? [];
    
    return Stack(
      children: [
        Container(
          height: isTablet ? 350 : 280,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageController,
            itemCount: galleryImages.length,
            onPageChanged: (index) {
              if (mounted) {
                setState(() {
                  _currentImageIndex = index;
                });
              }
            },
            itemBuilder: (context, index) {
              return _buildGalleryImage(galleryImages[index]);
            },
          ),
        ),
        
        // Premium Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        
        // Business name overlay on gallery
        Positioned(
          bottom: isTablet ? 30 : 20,
          left: isTablet ? 30 : 20,
          right: isTablet ? 30 : 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                partner.businessName,
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 28 : 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isTablet ? 8 : 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _goldAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.white, size: isTablet ? 16 : 14),
                    SizedBox(width: 4),
                    Text(
                      'Premium Partner',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 12 : 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Image Counter Badge
        if (galleryImages.length > 1)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_goldAccent, _primaryGreen, _primaryRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    '${_currentImageIndex + 1} / ${galleryImages.length}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Left Navigation Arrow
        if (galleryImages.length > 1)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (_currentImageIndex > 0) {
                    _pageController.previousPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: isTablet ? 24 : 20,
                  ),
                ),
              ),
            ),
          ),
        
        // Right Navigation Arrow
        if (galleryImages.length > 1)
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (_currentImageIndex < galleryImages.length - 1) {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: isTablet ? 24 : 20,
                  ),
                ),
              ),
            ),
          ),
        
        // Dot Indicators
        if (galleryImages.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(galleryImages.length, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? (isTablet ? 24 : 20) : (isTablet ? 8 : 6),
                  height: isTablet ? 8 : 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: _currentImageIndex == index
                        ? LinearGradient(
                            colors: [_goldAccent, _primaryGreen],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    color: _currentImageIndex == index ? null : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildPremiumDetailSection({
    required String title,
    required IconData icon,
    required Widget child,
    required bool isTablet,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 8 : 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryRed, _primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: isTablet ? 18 : 16,
              ),
            ),
            SizedBox(width: isTablet ? 12 : 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : 14),
        child,
      ],
    );
  }

  Widget _buildPremiumDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required List<Color> gradientColors,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, _creamWhite],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        border: Border.all(color: gradientColors.first.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 5),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 48 : 42,
            height: isTablet ? 48 : 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: isTablet ? 22 : 18,
              ),
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 15 : 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumContactItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isTablet,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 16 : 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, _creamWhite],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
            border: Border.all(color: _borderLight, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: isTablet ? 44 : 38,
                height: isTablet ? 44 : 38,
                decoration: BoxDecoration(
                  gradient: onTap != null 
                      ? LinearGradient(colors: [_primaryRed, _primaryGreen])
                      : LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade300]),
                  borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: onTap != null ? Colors.white : Colors.grey.shade600,
                    size: isTablet ? 20 : 18,
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 13 : 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 15 : 14,
                        fontWeight: FontWeight.w600,
                        color: onTap != null ? _primaryGreen : _textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Container(
                  padding: EdgeInsets.all(isTablet ? 6 : 4),
                  decoration: BoxDecoration(
                    color: _primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: _primaryGreen,
                    size: isTablet ? 18 : 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumActionButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onPressed,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (gradient.colors.first as Color).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: isTablet ? 22 : 18),
                SizedBox(width: isTablet ? 10 : 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getSocialMediaColor(String url) {
    if (url.contains('facebook.com') || url.contains('fb.com')) return Color(0xFF1877F2);
    if (url.contains('instagram.com')) return Color(0xFFE4405F);
    if (url.contains('twitter.com') || url.contains('x.com')) return Color(0xFF1DA1F2);
    if (url.contains('linkedin.com')) return Color(0xFF0A66C2);
    if (url.contains('youtube.com')) return Color(0xFFFF0000);
    return _primaryGreen;
  }

  IconData _getSocialMediaIcon(String url) {
    if (url.contains('facebook.com') || url.contains('fb.com')) return Icons.facebook;
    if (url.contains('instagram.com')) return Icons.camera_alt;
    if (url.contains('twitter.com') || url.contains('x.com')) return Icons.flutter_dash;
    if (url.contains('linkedin.com')) return Icons.work;
    if (url.contains('youtube.com')) return Icons.play_circle_filled;
    return Icons.link;
  }

  String _getSocialMediaName(String url) {
    if (url.contains('facebook.com') || url.contains('fb.com')) return 'Facebook';
    if (url.contains('instagram.com')) return 'Instagram';
    if (url.contains('twitter.com') || url.contains('x.com')) return 'Twitter';
    if (url.contains('linkedin.com')) return 'LinkedIn';
    if (url.contains('youtube.com')) return 'YouTube';
    return 'Link';
  }
}