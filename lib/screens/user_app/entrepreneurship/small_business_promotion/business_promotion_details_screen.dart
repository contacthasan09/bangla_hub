// screens/user_app/entrepreneurship/small_business/business_promotion_details_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class BusinessPromotionDetailsScreen extends StatefulWidget {
  final SmallBusinessPromotion promotion;
  final ScrollController scrollController;
  final Function(String) onLaunchPhone;
  final Function(String) onLaunchEmail;
  final Function(String) onLaunchUrl;
  final Color primaryOrange;
  final Color redAccent;
  final Color greenAccent;
  final Color goldAccent;

  const BusinessPromotionDetailsScreen({
    Key? key,
    required this.promotion,
    required this.scrollController,
    required this.onLaunchPhone,
    required this.onLaunchEmail,
    required this.onLaunchUrl,
    required this.primaryOrange,
    required this.redAccent,
    required this.greenAccent,
    required this.goldAccent,
  }) : super(key: key);

  @override
  _BusinessPromotionDetailsScreenState createState() => _BusinessPromotionDetailsScreenState();
}

class _BusinessPromotionDetailsScreenState extends State<BusinessPromotionDetailsScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  int _currentImageIndex = 0;
  late AnimationController _animationController;
  late PageController _pageController;
  
  // Particle animation controllers
  late List<AnimationController> _particleControllers;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  
  // Premium Color Palette - Orange/Red/Green Theme
  final Color _primaryOrange = Color(0xFFFF9800);
  final Color _darkOrange = Color(0xFFF57C00);
  final Color _lightOrange = Color(0xFFFFF3E0);
  final Color _redAccent = Color(0xFFE53935);
  final Color _greenAccent = Color(0xFF43A047);
  final Color _goldAccent = Color(0xFFFFB300);
  final Color _purpleAccent = Color(0xFF8E24AA);
  final Color _tealAccent = Color(0xFF00897B);
  
  // Light backgrounds
  final Color _lightOrangeBg = Color(0x80FFF3E0);
  final Color _lightYellow = Color(0xFFFFF3E0);
  final Color _lightGreen = Color(0xFFE8F5E9);
  final Color _creamWhite = Color(0xFFFFF9E6);
  
  // 50% opacity colors
  final Color _creamWhite50 = Color(0x80FFF9E6);
  final Color _lightOrange50 = Color(0x80FFF3E0);
  final Color _lightGreen50 = Color(0x80E8F5E9);
  
  // Border and shadow colors
  final Color _borderLight = Color(0xFFE0E7E9);
  final Color _shadowColor = Color(0x1A000000);
  
  // Text Colors
  final Color _textPrimary = Color(0xFF1A2B3C);
  final Color _textSecondary = Color(0xFF5D6D7E);
  
  // Additional colors
  final Color _successGreen = Color(0xFF4CAF50);
  final Color _infoBlue = Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    
    _pageController = PageController();
    
    // Initialize particle controllers (20 particles)
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
    print('🗑️ BusinessPromotionDetailsScreen disposing...');
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
                      widget.primaryOrange.withOpacity(0.1),
                      widget.greenAccent.withOpacity(0.05),
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

  // UPDATED: Build poster image from promotion.postedByProfileImageBase64 (handles both URL and Base64)
  Widget _buildPromotionPosterImage({bool isLarge = false}) {
    final imageData = widget.promotion.postedByProfileImageBase64;
    
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
              print('Error loading promotion poster image: $error');
              return _buildDefaultProfileImage(isLarge: isLarge);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.goldAccent),
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
                print('Error decoding promotion poster image: $error');
                return _buildDefaultProfileImage(isLarge: isLarge);
              },
            ),
          );
        } catch (e) {
          print('Error processing promotion poster image: $e');
          return _buildDefaultProfileImage(isLarge: isLarge);
        }
      }
    }
    
    return _buildDefaultProfileImage(isLarge: isLarge);
  }

  // UPDATED: Build gallery image from Base64
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

  bool get isOfferActive => widget.promotion.specialOfferDiscount != null && 
                            widget.promotion.specialOfferDiscount! > 0;

  @override
  Widget build(BuildContext context) {
    final promotion = widget.promotion;
    final hasImages = promotion.galleryImagesBase64 != null && promotion.galleryImagesBase64!.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;

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
              colors: [_lightOrangeBg, _lightOrange, Colors.white],
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
                        ? _buildPremiumImageGallery(promotion, isTablet, shouldAnimate)
                        : Container(
                            height: isTablet ? 300 : 250,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [widget.primaryOrange, _darkOrange, widget.redAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.storefront_rounded,
                                      color: widget.goldAccent,
                                      size: isTablet ? 70 : 60,
                                    ),
                                  ),
                                ],
                              ),
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
                          
                          // User Profile and Business Info - Using promotion's stored user info
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // User Profile Image from promotion.postedByProfileImageBase64
                              Container(
                                width: isTablet ? 80 : 70,
                                height: isTablet ? 80 : 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: widget.goldAccent, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.goldAccent.withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _buildPromotionPosterImage(isLarge: true),
                                ),
                              ),
                              
                              SizedBox(width: isTablet ? 20 : 16),
                              
                              // Business Name and User Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // User Name from promotion.postedByName
                                    if (promotion.postedByName != null && promotion.postedByName!.isNotEmpty)
                                      Container(
                                        margin: EdgeInsets.only(bottom: 8),
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _lightOrange,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.person_rounded, color: widget.primaryOrange, size: 14),
                                            SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                promotion.postedByName!,
                                                style: GoogleFonts.poppins(
                                                  color: widget.primaryOrange,
                                                  fontSize: isTablet ? 14 : 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    
                                    // Business Name
                                    Text(
                                      promotion.businessName,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 28 : 24,
                                        fontWeight: FontWeight.w800,
                                        color: _textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    
                                    // Owner Name
                                    Text(
                                      'by ${promotion.ownerName}',
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 18 : 16,
                                        fontWeight: FontWeight.w500,
                                        color: widget.primaryOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: isTablet ? 16 : 12),
                          
                          // Location and Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Location Badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 8 : 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [widget.primaryOrange, _darkOrange],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.primaryOrange.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 18 : 16,
                                    ),
                                    SizedBox(width: isTablet ? 8 : 6),
                                    Text(
                                      '${promotion.city}, ${promotion.state}',
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 14 : 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Stats Badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 6 : 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [widget.greenAccent, _greenAccent],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.greenAccent.withOpacity(0.3),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.remove_red_eye_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 16 : 14,
                                    ),
                                    SizedBox(width: isTablet ? 4 : 3),
                                    Text(
                                      '${promotion.totalViews} views',
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
                          
                          SizedBox(height: isTablet ? 20 : 16),
                          
                          // Verified and Featured Badges Row
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (promotion.isVerified)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 14 : 12,
                                    vertical: isTablet ? 6 : 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_successGreen, _successGreen.withOpacity(0.8)],
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
                              
                              if (promotion.isFeatured)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 14 : 12,
                                    vertical: isTablet ? 6 : 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [widget.goldAccent, _darkOrange],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.goldAccent.withOpacity(0.3),
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        color: Colors.white,
                                        size: isTablet ? 16 : 14,
                                      ),
                                      SizedBox(width: isTablet ? 4 : 3),
                                      Text(
                                        'FEATURED',
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
                                promotion.description.isNotEmpty ? promotion.description : 'No description provided',
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
                                  value: '${promotion.location}, ${promotion.city}, ${promotion.state}',
                                  gradientColors: [widget.primaryOrange, _darkOrange],
                                  isTablet: isTablet,
                                ),
                                SizedBox(height: isTablet ? 14 : 12),
                                
                                // Products Count Card
                                _buildPremiumDetailCard(
                                  icon: Icons.shopping_bag_rounded,
                                  title: 'Products & Services',
                                  value: '${promotion.productsServices.length} items',
                                  gradientColors: [widget.greenAccent, _greenAccent],
                                  isTablet: isTablet,
                                ),
                              ],
                            ),
                            isTablet: isTablet,
                          ),
                          
                          // Products & Services Section
                          if (promotion.productsServices.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPremiumDetailSection(
                              title: 'Products & Services',
                              icon: Icons.shopping_bag_rounded,
                              child: Column(
                                children: promotion.productsServices.map((product) {
                                  return Container(
                                    margin: EdgeInsets.only(bottom: isTablet ? 12 : 10),
                                    padding: EdgeInsets.all(isTablet ? 16 : 14),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [widget.primaryOrange.withOpacity(0.1), _lightOrange],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                                      border: Border.all(color: widget.primaryOrange.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(isTablet ? 8 : 6),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [widget.primaryOrange, _darkOrange],
                                            ),
                                            borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                                          ),
                                          child: Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.white,
                                            size: isTablet ? 20 : 18,
                                          ),
                                        ),
                                        SizedBox(width: isTablet ? 16 : 12),
                                        Expanded(
                                          child: Text(
                                            product,
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 16 : 14,
                                              fontWeight: FontWeight.w500,
                                              color: _textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Payment Methods Section
                          if (promotion.paymentMethods.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPremiumDetailSection(
                              title: 'Payment Methods',
                              icon: Icons.payment_rounded,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: promotion.paymentMethods.map((method) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 16 : 14,
                                      vertical: isTablet ? 10 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [widget.greenAccent.withOpacity(0.1), _lightGreen],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(color: widget.greenAccent.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      method,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 15 : 13,
                                        fontWeight: FontWeight.w600,
                                        color: widget.greenAccent,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Special Offer Section
                          if (isOfferActive) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPremiumDetailSection(
                              title: 'Special Offer',
                              icon: Icons.local_offer_rounded,
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 24 : 20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [widget.primaryOrange, widget.redAccent, widget.goldAccent],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.primaryOrange.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(isTablet ? 12 : 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                                          ),
                                          child: shouldAnimate
                                              ? RotationTransition(
                                                  turns: _animationController,
                                                  child: Icon(
                                                    Icons.percent_rounded,
                                                    color: Colors.white,
                                                    size: isTablet ? 28 : 24,
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.percent_rounded,
                                                  color: Colors.white,
                                                  size: isTablet ? 28 : 24,
                                                ),
                                        ),
                                        SizedBox(width: isTablet ? 16 : 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'SPECIAL OFFER',
                                                style: GoogleFonts.poppins(
                                                  fontSize: isTablet ? 14 : 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white.withOpacity(0.9),
                                                ),
                                              ),
                                              Text(
                                                '${promotion.specialOfferDiscount!.toStringAsFixed(0)}% OFF',
                                                style: GoogleFonts.poppins(
                                                  fontSize: isTablet ? 32 : 28,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (promotion.offerValidity != null && promotion.offerValidity!.isNotEmpty) ...[
                                      SizedBox(height: isTablet ? 16 : 12),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            color: Colors.white,
                                            size: isTablet ? 20 : 18,
                                          ),
                                          SizedBox(width: isTablet ? 8 : 6),
                                          Text(
                                            'Valid until: ${promotion.offerValidity}',
                                            style: GoogleFonts.inter(
                                              fontSize: isTablet ? 16 : 14,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
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
                                    icon: Icons.email_rounded,
                                    title: 'Email',
                                    value: promotion.contactEmail,
                                    isTablet: isTablet,
                                    onTap: () => widget.onLaunchEmail(promotion.contactEmail),
                                  ),
                                  SizedBox(height: isTablet ? 14 : 12),
                                  _buildPremiumContactItem(
                                    icon: Icons.phone_rounded,
                                    title: 'Phone',
                                    value: promotion.contactPhone,
                                    isTablet: isTablet,
                                    onTap: () => widget.onLaunchPhone(promotion.contactPhone),
                                  ),
                                  if (promotion.website != null && promotion.website!.isNotEmpty) ...[
                                    SizedBox(height: isTablet ? 14 : 12),
                                    _buildPremiumContactItem(
                                      icon: Icons.language_rounded,
                                      title: 'Website',
                                      value: promotion.website!,
                                      isTablet: isTablet,
                                      onTap: () => widget.onLaunchUrl(promotion.website!),
                                    ),
                                  ],
                                  if (promotion.socialMediaLinks != null && promotion.socialMediaLinks!.isNotEmpty) ...[
                                    SizedBox(height: isTablet ? 14 : 12),
                                    _buildPremiumContactItem(
                                      icon: Icons.link_rounded,
                                      title: 'Social Media',
                                      value: promotion.socialMediaLinks!,
                                      isTablet: isTablet,
                                      onTap: () => widget.onLaunchUrl(promotion.socialMediaLinks!),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            isTablet: isTablet,
                          ),
                          
                          // Share Stats Section
                          SizedBox(height: isTablet ? 32 : 24),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                                    border: Border.all(color: _borderLight, width: 1),
                                  ),
                                  child: Column(
                                    children: [
                                      shouldAnimate
                                          ? RotationTransition(
                                              turns: _animationController,
                                              child: Icon(
                                                Icons.remove_red_eye_rounded,
                                                color: widget.primaryOrange,
                                                size: isTablet ? 28 : 24,
                                              ),
                                            )
                                          : Icon(
                                              Icons.remove_red_eye_rounded,
                                              color: widget.primaryOrange,
                                              size: isTablet ? 28 : 24,
                                            ),
                                      SizedBox(height: isTablet ? 8 : 6),
                                      Text(
                                        '${promotion.totalViews}',
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 24 : 20,
                                          fontWeight: FontWeight.w800,
                                          color: _textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Views',
                                        style: GoogleFonts.inter(
                                          fontSize: isTablet ? 14 : 12,
                                          color: _textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: isTablet ? 16 : 12),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                                    border: Border.all(color: _borderLight, width: 1),
                                  ),
                                  child: Column(
                                    children: [
                                      shouldAnimate
                                          ? RotationTransition(
                                              turns: _animationController,
                                              child: Icon(
                                                Icons.share_rounded,
                                                color: widget.greenAccent,
                                                size: isTablet ? 28 : 24,
                                              ),
                                            )
                                          : Icon(
                                              Icons.share_rounded,
                                              color: widget.greenAccent,
                                              size: isTablet ? 28 : 24,
                                            ),
                                      SizedBox(height: isTablet ? 8 : 6),
                                      Text(
                                        '${promotion.totalShares}',
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 24 : 20,
                                          fontWeight: FontWeight.w800,
                                          color: _textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Shares',
                                        style: GoogleFonts.inter(
                                          fontSize: isTablet ? 14 : 12,
                                          color: _textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          // Premium Footer
                          SizedBox(height: isTablet ? 40 : 32),
                          
                          Container(
                            padding: EdgeInsets.all(isTablet ? 24 : 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_lightOrange50, _lightOrange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                              border: Border.all(color: widget.primaryOrange.withOpacity(0.2), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: isTablet ? 60 : 50,
                                  height: isTablet ? 60 : 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [widget.primaryOrange, widget.redAccent, widget.greenAccent],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.primaryOrange.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: shouldAnimate
                                        ? RotationTransition(
                                            turns: _animationController,
                                            child: Icon(
                                              Icons.storefront_rounded,
                                              color: Colors.white,
                                              size: isTablet ? 28 : 24,
                                            ),
                                          )
                                        : Icon(
                                            Icons.storefront_rounded,
                                            color: Colors.white,
                                            size: isTablet ? 28 : 24,
                                          ),
                                  ),
                                ),
                                SizedBox(width: isTablet ? 20 : 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Premium Business',
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.w700,
                                          color: widget.primaryOrange,
                                        ),
                                      ),
                                      SizedBox(height: isTablet ? 4 : 2),
                                      Text(
                                        'Verified Local Business',
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
                          
                          // Posted Date
                          SizedBox(height: isTablet ? 20 : 16),
                          Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12,
                                vertical: isTablet ? 8 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _borderLight),
                              ),
                              child: Text(
                                'Promoted on ${DateFormat('MMMM d, yyyy').format(promotion.createdAt)}',
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 13 : 11,
                                  color: _textSecondary,
                                ),
                              ),
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
                    colors: [widget.primaryOrange, _darkOrange],
                  ),
                  onPressed: () => widget.onLaunchPhone(promotion.contactPhone),
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: _buildPremiumActionButton(
                  icon: Icons.email_rounded,
                  label: 'Send Email',
                  gradient: LinearGradient(
                    colors: [widget.greenAccent, _greenAccent],
                  ),
                  onPressed: () => widget.onLaunchEmail(promotion.contactEmail),
                  isTablet: isTablet,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumImageGallery(SmallBusinessPromotion promotion, bool isTablet, bool shouldAnimate) {
    final galleryImages = promotion.galleryImagesBase64 ?? [];
    
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
        
        // Image Counter Badge
        if (galleryImages.length > 1)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.primaryOrange, widget.greenAccent],
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
                  shouldAnimate
                      ? RotationTransition(
                          turns: _animationController,
                          child: Icon(Icons.photo_library_rounded, color: Colors.white, size: 16),
                        )
                      : Icon(Icons.photo_library_rounded, color: Colors.white, size: 16),
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
                            colors: [widget.primaryOrange, widget.greenAccent],
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

  Widget _buildDefaultProfileImage({bool isLarge = false}) {
    return Container(
      color: _lightOrange,
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: widget.primaryOrange,
          size: isLarge ? 40 : 24,
        ),
      ),
    );
  }

  Widget _buildPremiumDetailSection({
    required String title,
    required IconData icon,
    required Widget child,
    required bool isTablet,
  }) {
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 8 : 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.primaryOrange, widget.greenAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
              ),
              child: shouldAnimate
                  ? RotationTransition(
                      turns: _animationController,
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: isTablet ? 18 : 16,
                      ),
                    )
                  : Icon(
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
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
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
              child: shouldAnimate
                  ? RotationTransition(
                      turns: _animationController,
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: isTablet ? 22 : 18,
                      ),
                    )
                  : Icon(
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
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
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
                      ? LinearGradient(colors: [widget.primaryOrange, widget.greenAccent])
                      : LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade300]),
                  borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                ),
                child: Center(
                  child: shouldAnimate
                      ? RotationTransition(
                          turns: _animationController,
                          child: Icon(
                            icon,
                            color: onTap != null ? Colors.white : Colors.grey.shade600,
                            size: isTablet ? 20 : 18,
                          ),
                        )
                      : Icon(
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
                        color: onTap != null ? widget.primaryOrange : _textPrimary,
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
                    color: widget.primaryOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: widget.primaryOrange,
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
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
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
                shouldAnimate
                    ? RotationTransition(
                        turns: _animationController,
                        child: Icon(icon, color: Colors.white, size: isTablet ? 22 : 18),
                      )
                    : Icon(icon, color: Colors.white, size: isTablet ? 22 : 18),
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
}