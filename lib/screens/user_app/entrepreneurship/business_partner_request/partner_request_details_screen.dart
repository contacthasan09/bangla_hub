// screens/user_app/entrepreneurship/partner_requests/partner_request_details_screen.dart
import 'dart:convert';
import 'package:bangla_hub/models/business_model.dart' hide BusinessPartnerRequest;
import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class PartnerRequestDetailsScreen extends StatefulWidget {
  final BusinessPartnerRequest request;
  final UserModel? user;
  final ScrollController scrollController;
  final Function(String) onLaunchPhone;
  final Function(String) onLaunchEmail;
  final Color primaryGreen;
  final Color secondaryGold;
  final Color softGreen;
  final Color lightGreen;

  const PartnerRequestDetailsScreen({
    Key? key,
    required this.request,
    this.user,
    required this.scrollController,
    required this.onLaunchPhone,
    required this.onLaunchEmail,
    required this.primaryGreen,
    required this.secondaryGold,
    required this.softGreen,
    required this.lightGreen,
  }) : super(key: key);

  @override
  _PartnerRequestDetailsScreenState createState() => _PartnerRequestDetailsScreenState();
}

class _PartnerRequestDetailsScreenState extends State<PartnerRequestDetailsScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  
  // Premium Color Palette - Soft Green Theme
  final Color _darkGreen = Color(0xFF1B5E20);
  final Color _deepGreen = Color(0xFF0A4D0A);
  final Color _goldAccent = Color(0xFFFFB300);
  final Color _softGold = Color(0xFFFFD966);
  
  // Light backgrounds
  final Color _lightGreenBg = Color(0x80E0F2F1);
  final Color _lightGreen = Color(0xFFE0F2F1);
  final Color _lightYellow = Color(0xFFFFF3E0);
  final Color _lightBlue = Color(0xFFE3F2FD);
  final Color _creamWhite = Color(0xFFFFF9E6);
  
  // 50% opacity colors
  final Color _creamWhite50 = Color(0x80FFF9E6);
  final Color _lightGreen50 = Color(0x80E0F2F1);
  final Color _lightYellow50 = Color(0x80FFF3E0);
  
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
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedParticle(int index, double width, double height) {
    return Positioned(
      left: (index * 37) % width,
      top: (index * 53) % height,
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
                      widget.primaryGreen.withOpacity(0.1),
                      widget.softGreen.withOpacity(0.05),
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

  String _formatBudget(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final user = widget.user;
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
                  // Header Section
                  SliverToBoxAdapter(
                    child: Container(
                      height: isTablet ? 280 : 220,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.primaryGreen, _darkGreen, widget.softGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: EdgeInsets.all(isTablet ? 24 : 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Premium Pattern Line
                              Container(
                                height: 4,
                                width: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [widget.secondaryGold, _softGold],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              SizedBox(height: isTablet ? 16 : 12),
                              
                              // Partner Type
                              Text(
                                request.partnerType.displayName,
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 32 : 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: isTablet ? 8 : 6),
                              
                              // Business Type
                              Text(
                                request.businessType.displayName,
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              
                              SizedBox(height: isTablet ? 16 : 12),
                              
                              // Urgent Badge
                              if (request.isUrgent)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 16 : 14,
                                    vertical: isTablet ? 8 : 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.priority_high_rounded, color: widget.secondaryGold, size: isTablet ? 18 : 16),
                                      SizedBox(width: isTablet ? 8 : 6),
                                      Text(
                                        'URGENT REQUEST',
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 14 : 12,
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
                          // Back Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: _shadowColor,
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.arrow_back_rounded, color: _textPrimary, size: isTablet ? 22 : 20),
                            ),
                          ),
                          
                          SizedBox(height: isTablet ? 20 : 16),
                          
                          // User Profile and Request Info
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // User Profile Image
                              Container(
                                width: isTablet ? 80 : 70,
                                height: isTablet ? 80 : 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: widget.secondaryGold, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.secondaryGold.withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _buildUserProfileImage(user, isLarge: true),
                                ),
                              ),
                              
                              SizedBox(width: isTablet ? 20 : 16),
                              
                              // Request Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // User Name
                                    if (user != null)
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
                                            Icon(Icons.person_rounded, color: widget.primaryGreen, size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              user.fullName,
                                              style: GoogleFonts.poppins(
                                                color: widget.primaryGreen,
                                                fontSize: isTablet ? 14 : 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    
                                    // Posted Date
                                    Text(
                                      'Posted on ${DateFormat('MMM d, yyyy').format(request.createdAt)}',
                                      style: GoogleFonts.inter(
                                        fontSize: isTablet ? 13 : 12,
                                        color: _textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: isTablet ? 16 : 12),
                          
                          // Partner Type and Business Type Badges
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Partner Type Badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 8 : 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [widget.primaryGreen, _darkGreen],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.primaryGreen.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 18 : 16,
                                    ),
                                    SizedBox(width: isTablet ? 8 : 6),
                                    Text(
                                      request.partnerType.displayName,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 14 : 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Business Type Badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 8 : 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [widget.softGreen, _darkGreen],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.softGreen.withOpacity(0.3),
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
                                      request.businessType.displayName,
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
                          
                          // Verified and Views Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Verified Badge
                              if (request.isVerified)
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
                              
                              // Views Badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 6 : 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [widget.secondaryGold, _softGold],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.secondaryGold.withOpacity(0.3),
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
                                      '${request.totalViews} Views',
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
                          
                          // Description Section
                          _buildPremiumDetailSection(
                            title: 'Description',
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
                                request.description,
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
                          
                          // Location and Industry Section
                          _buildPremiumDetailSection(
                            title: 'Location & Industry',
                            icon: Icons.location_on_rounded,
                            child: Column(
                              children: [
                                // Location Card
                                _buildPremiumDetailCard(
                                  icon: Icons.location_on_rounded,
                                  title: 'Location',
                                  value: '${request.location}, ${request.city}, ${request.state}',
                                  gradientColors: [widget.primaryGreen, _darkGreen],
                                  isTablet: isTablet,
                                ),
                                SizedBox(height: isTablet ? 14 : 12),
                                
                                // Industry Card
                                if (request.industry != null && request.industry!.isNotEmpty && request.industry != 'Not specified')
                                  _buildPremiumDetailCard(
                                    icon: Icons.category_rounded,
                                    title: 'Industry',
                                    value: request.industry!,
                                    gradientColors: [widget.softGreen, _darkGreen],
                                    isTablet: isTablet,
                                  ),
                              ],
                            ),
                            isTablet: isTablet,
                          ),
                          
                          // Budget Section
                          SizedBox(height: isTablet ? 32 : 24),
                          _buildPremiumDetailSection(
                            title: 'Budget & Duration',
                            icon: Icons.attach_money_rounded,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildPremiumDetailCard(
                                    icon: Icons.attach_money_rounded,
                                    title: 'Budget Range',
                                    value: '${_formatBudget(request.budgetMin)} - ${_formatBudget(request.budgetMax)}',
                                    gradientColors: [widget.primaryGreen, _darkGreen],
                                    isTablet: isTablet,
                                  ),
                                ),
                                SizedBox(width: isTablet ? 14 : 12),
                                Expanded(
                                  child: _buildPremiumDetailCard(
                                    icon: Icons.schedule_rounded,
                                    title: 'Duration',
                                    value: request.investmentDuration,
                                    gradientColors: [widget.secondaryGold, _softGold],
                                    isTablet: isTablet,
                                  ),
                                ),
                              ],
                            ),
                            isTablet: isTablet,
                          ),
                          
                          // Skills Required Section
                          if (request.skillsRequired.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPremiumDetailSection(
                              title: 'Skills Required',
                              icon: Icons.code_rounded,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: request.skillsRequired.map((skill) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 16 : 14,
                                      vertical: isTablet ? 10 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [widget.primaryGreen.withOpacity(0.1), _lightGreen],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(color: widget.primaryGreen.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      skill,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 15 : 13,
                                        fontWeight: FontWeight.w600,
                                        color: widget.primaryGreen,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Responsibilities Section
                          if (request.responsibilities.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPremiumDetailSection(
                              title: 'Responsibilities',
                              icon: Icons.task_rounded,
                              child: Column(
                                children: request.responsibilities.map((responsibility) {
                                  return Container(
                                    margin: EdgeInsets.only(bottom: isTablet ? 12 : 10),
                                    padding: EdgeInsets.all(isTablet ? 16 : 14),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [widget.softGreen.withOpacity(0.1), _lightGreen],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                                      border: Border.all(color: widget.softGreen.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(isTablet ? 8 : 6),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [widget.softGreen, _darkGreen],
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
                                            responsibility,
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
                                    icon: Icons.person_rounded,
                                    title: 'Contact Person',
                                    value: request.contactName,
                                    isTablet: isTablet,
                                  ),
                                  SizedBox(height: isTablet ? 14 : 12),
                                  _buildPremiumContactItem(
                                    icon: Icons.email_rounded,
                                    title: 'Email',
                                    value: request.contactEmail,
                                    isTablet: isTablet,
                                    onTap: () => widget.onLaunchEmail(request.contactEmail),
                                  ),
                                  SizedBox(height: isTablet ? 14 : 12),
                                  _buildPremiumContactItem(
                                    icon: Icons.phone_rounded,
                                    title: 'Phone',
                                    value: request.contactPhone,
                                    isTablet: isTablet,
                                    onTap: () => widget.onLaunchPhone(request.contactPhone),
                                  ),
                                  if (request.preferredMeetingMethod != null && request.preferredMeetingMethod!.isNotEmpty) ...[
                                    SizedBox(height: isTablet ? 14 : 12),
                                    _buildPremiumContactItem(
                                      icon: Icons.video_call_rounded,
                                      title: 'Preferred Meeting',
                                      value: request.preferredMeetingMethod!,
                                      isTablet: isTablet,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            isTablet: isTablet,
                          ),
                          
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
                              border: Border.all(color: widget.primaryGreen.withOpacity(0.2), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: isTablet ? 60 : 50,
                                  height: isTablet ? 60 : 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [widget.primaryGreen, widget.softGreen],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.primaryGreen.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.people_alt_rounded,
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
                                        'Business Partner Request',
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.w700,
                                          color: widget.primaryGreen,
                                        ),
                                      ),
                                      SizedBox(height: isTablet ? 4 : 2),
                                      Text(
                                        'Verified Opportunity',
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
                  icon: Icons.email_rounded,
                  label: 'Send Email',
                  gradient: LinearGradient(
                    colors: [widget.primaryGreen, _darkGreen],
                  ),
                  onPressed: () => widget.onLaunchEmail(request.contactEmail),
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: _buildPremiumActionButton(
                  icon: Icons.phone_rounded,
                  label: 'Call Now',
                  gradient: LinearGradient(
                    colors: [widget.secondaryGold, _softGold],
                  ),
                  onPressed: () => widget.onLaunchPhone(request.contactPhone),
                  isTablet: isTablet,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileImage(UserModel? user, {bool isLarge = false}) {
    if (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty) {
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
            return _buildDefaultProfileImage(isLarge: isLarge);
          },
        );
      } catch (e) {
        return _buildDefaultProfileImage(isLarge: isLarge);
      }
    }
    return _buildDefaultProfileImage(isLarge: isLarge);
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
                  colors: [widget.primaryGreen, widget.softGreen],
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
                      ? LinearGradient(colors: [widget.primaryGreen, widget.softGreen])
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
                        color: onTap != null ? widget.primaryGreen : _textPrimary,
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
                    color: widget.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: widget.primaryGreen,
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
}