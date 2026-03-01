// screens/user_app/entrepreneurship/job_posting/job_details_screen.dart
import 'dart:convert';
import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class JobDetailsScreen extends StatefulWidget {
  final JobPosting job;
  final UserModel? user;
  final ScrollController scrollController;
  final Function(String) onLaunchPhone;
  final Function(String) onLaunchEmail;
  final Function(String) onLaunchUrl;
  final Color primaryRed;
  final Color goldAccent;
  final Color purpleAccent;
  final Color tealAccent;

  const JobDetailsScreen({
    Key? key,
    required this.job,
    this.user,
    required this.scrollController,
    required this.onLaunchPhone,
    required this.onLaunchEmail,
    required this.onLaunchUrl,
    required this.primaryRed,
    required this.goldAccent,
    required this.purpleAccent,
    required this.tealAccent,
  }) : super(key: key);

  @override
  _JobDetailsScreenState createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  
  // Premium Color Palette - Sports Theme (from SportsClubsScreen)
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
  
  // Light backgrounds with opacity
  final Color _lightRedBg = Color(0x80FFEBEE);
  final Color _lightGoldBg = Color(0x80FFF3E0);
  final Color _creamWhite50 = Color(0x80FAF7F2);
  
  // Shadow color
  final Color _shadowColor = Color(0x1A000000);

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
                      widget.primaryRed.withOpacity(0.1),
                      widget.goldAccent.withOpacity(0.05),
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

  void _showPremiumSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isError 
                  ? [_primaryRed, _darkRed] 
                  : [_successGreen, _tealAccent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_rounded : Icons.check_circle_rounded,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final user = widget.user;
    final isDeadlineNear = job.applicationDeadline.difference(DateTime.now()).inDays <= 7;
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
              colors: [_lightRed, _creamWhite, Colors.white],
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
                      height: isTablet ? 300 : 250,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.primaryRed, widget.purpleAccent, _royalPurple],
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
                                    colors: [widget.goldAccent, _orangeAccent, widget.goldAccent],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              SizedBox(height: isTablet ? 16 : 12),
                              
                              // Job Title
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [Colors.white, widget.goldAccent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: Text(
                                  job.jobTitle,
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 32 : 28,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: isTablet ? 8 : 6),
                              
                              // Company Name
                              Text(
                                job.companyName,
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              
                              SizedBox(height: isTablet ? 16 : 12),
                              
                              // Urgent Badge
                              if (job.isUrgent)
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
                                      Icon(Icons.priority_high_rounded, color: widget.goldAccent, size: isTablet ? 18 : 16),
                                      SizedBox(width: isTablet ? 8 : 6),
                                      Text(
                                        'URGENT HIRING',
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
                          
                          // User Profile and Job Info
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // User Profile Image
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
                                  child: _buildUserProfileImage(user, isLarge: true),
                                ),
                              ),
                              
                              SizedBox(width: isTablet ? 20 : 16),
                              
                              // Job Info
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
                                          color: _lightRed,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.person_rounded, color: widget.primaryRed, size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              user.fullName,
                                              style: GoogleFonts.poppins(
                                                color: widget.primaryRed,
                                                fontSize: isTablet ? 14 : 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    
                                    // Posted Date
                                    Text(
                                      'Posted on ${DateFormat('MMM d, yyyy').format(job.createdAt)}',
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
                          
                          // Job Type and Experience Badges
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Job Type Badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 8 : 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [widget.primaryRed, widget.purpleAccent],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.primaryRed.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 18 : 16,
                                    ),
                                    SizedBox(width: isTablet ? 8 : 6),
                                    Text(
                                      job.jobType.displayName,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 14 : 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Experience Level Badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 8 : 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [widget.goldAccent, _orangeAccent],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.goldAccent.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.timeline_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 18 : 16,
                                    ),
                                    SizedBox(width: isTablet ? 8 : 6),
                                    Text(
                                      job.experienceLevel.displayName,
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
                          
                          // Deadline and Status Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Deadline Badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 6 : 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isDeadlineNear
                                      ? LinearGradient(
                                          colors: [_warningOrange, _orangeAccent],
                                        )
                                      : LinearGradient(
                                          colors: [_successGreen, _tealAccent],
                                        ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDeadlineNear ? _warningOrange.withOpacity(0.3) : _successGreen.withOpacity(0.3),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 16 : 14,
                                    ),
                                    SizedBox(width: isTablet ? 4 : 3),
                                    Text(
                                      'Deadline: ${DateFormat('MMM d, yyyy').format(job.applicationDeadline)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 12 : 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Verified Badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 12,
                                  vertical: isTablet ? 6 : 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_successGreen, widget.tealAccent],
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
                            ],
                          ),
                          
                          SizedBox(height: isTablet ? 32 : 24),
                          
                          // Location Section
                          _buildPremiumDetailSection(
                            title: 'Location',
                            icon: Icons.location_on_rounded,
                            child: _buildPremiumDetailCard(
                              icon: Icons.location_on_rounded,
                              title: 'Address',
                              value: '${job.location}, ${job.city}, ${job.state}',
                              gradientColors: [widget.primaryRed, widget.purpleAccent],
                              isTablet: isTablet,
                            ),
                            isTablet: isTablet,
                          ),
                          
                          SizedBox(height: isTablet ? 32 : 24),
                          
                          // Description Section
                          _buildPremiumDetailSection(
                            title: 'Job Description',
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
                                job.description,
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
                          
                          // Requirements Section
                          _buildPremiumDetailSection(
                            title: 'Requirements',
                            icon: Icons.checklist_rounded,
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
                                job.requirements,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 15 : 14,
                                  color: _textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            isTablet: isTablet,
                          ),
                          
                          // Skills Section
                          if (job.skillsRequired.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPremiumDetailSection(
                              title: 'Skills Required',
                              icon: Icons.code_rounded,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: job.skillsRequired.map((skill) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 16 : 14,
                                      vertical: isTablet ? 10 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [widget.primaryRed.withOpacity(0.1), _lightRed],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(color: widget.primaryRed.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      skill,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 15 : 13,
                                        fontWeight: FontWeight.w600,
                                        color: widget.primaryRed,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Benefits Section
                          if (job.benefits.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPremiumDetailSection(
                              title: 'Benefits',
                              icon: Icons.card_giftcard_rounded,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: job.benefits.map((benefit) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 16 : 14,
                                      vertical: isTablet ? 10 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [widget.goldAccent.withOpacity(0.1), _creamWhite],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(color: widget.goldAccent.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      benefit,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 15 : 13,
                                        fontWeight: FontWeight.w600,
                                        color: widget.goldAccent,
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
                                    icon: Icons.email_rounded,
                                    title: 'Email',
                                    value: job.contactEmail,
                                    isTablet: isTablet,
                                    onTap: () => widget.onLaunchEmail(job.contactEmail),
                                  ),
                                  SizedBox(height: isTablet ? 14 : 12),
                                  _buildPremiumContactItem(
                                    icon: Icons.phone_rounded,
                                    title: 'Phone',
                                    value: job.contactPhone,
                                    isTablet: isTablet,
                                    onTap: () => widget.onLaunchPhone(job.contactPhone),
                                  ),
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
                                colors: [_lightRedBg, _lightRed],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                              border: Border.all(color: widget.primaryRed.withOpacity(0.2), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: isTablet ? 60 : 50,
                                  height: isTablet ? 60 : 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [widget.primaryRed, widget.purpleAccent, widget.tealAccent],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.primaryRed.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.work_rounded,
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
                                      ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: [widget.primaryRed, widget.purpleAccent],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ).createShader(bounds),
                                        child: Text(
                                          'Premium Job Opportunity',
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: isTablet ? 4 : 2),
                                      Text(
                                        'Verified Employer',
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
                  label: 'Apply via Email',
                  gradient: LinearGradient(
                    colors: [widget.primaryRed, widget.purpleAccent],
                  ),
                  onPressed: () => widget.onLaunchEmail(job.contactEmail),
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: _buildPremiumActionButton(
                  icon: Icons.phone_rounded,
                  label: 'Call Employer',
                  gradient: LinearGradient(
                    colors: [widget.goldAccent, _orangeAccent],
                  ),
                  onPressed: () => widget.onLaunchPhone(job.contactPhone),
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
      color: _lightRed,
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: widget.primaryRed,
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
                  colors: [widget.primaryRed, widget.purpleAccent],
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
                      ? LinearGradient(colors: [widget.primaryRed, widget.purpleAccent])
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
                        color: onTap != null ? widget.primaryRed : _textPrimary,
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
                    color: widget.primaryRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: widget.primaryRed,
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