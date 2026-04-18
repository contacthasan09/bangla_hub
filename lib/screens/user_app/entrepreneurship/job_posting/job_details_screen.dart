// screens/user_app/entrepreneurship/job_posting/job_details_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class JobDetailsScreen extends StatefulWidget {
  final JobPosting job;
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

class _JobDetailsScreenState extends State<JobDetailsScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  late AnimationController _animationController;
  
  // Particle animation controllers
  late List<AnimationController> _particleControllers;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  
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
  
  // Light backgrounds with opacity
  final Color _lightRedBg = Color(0x80FFEBEE);
  final Color _lightGoldBg = Color(0x80FFF3E0);
  final Color _creamWhite50 = Color(0x80FAF7F2);
  
  // Shadow color
  final Color _shadowColor = Color(0x1A000000);

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    
    // Initialize particle controllers (20 particles)
    _particleControllers = List.generate(20, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(seconds: 3 + (index % 3)),
      )..repeat(reverse: true);
    });
    
    _animationController.forward();
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
    print('🗑️ JobDetailsScreen disposing...');
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    for (var controller in _particleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Helper function to check if string is a URL
  bool _isUrlString(String str) {
    return str.startsWith('http://') || str.startsWith('https://');
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
    if (!mounted) return;
    
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

  // UPDATED: Build job poster image with URL and Base64 support
  Widget _buildJobPosterImage({bool isLarge = false}) {
    final imageData = widget.job.postedByProfileImageBase64;
    
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
                print('Error decoding job poster image: $error');
                return _buildDefaultProfileImage(isLarge: isLarge);
              },
            ),
          );
        } catch (e) {
          print('Error processing job poster image: $e');
          return _buildDefaultProfileImage(isLarge: isLarge);
        }
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

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final isDeadlineNear = job.applicationDeadline.difference(DateTime.now()).inDays <= 7;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
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
              size: isTablet ? 28 : 24,
            ),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            splashRadius: isTablet ? 28 : 24,
            constraints: BoxConstraints(
              minWidth: isTablet ? 48 : 40,
              minHeight: isTablet ? 48 : 40,
            ),
          ),
          leadingWidth: isTablet ? 60 : 50,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          toolbarHeight: isTablet ? 70 : 60,
        ),
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
              ...List.generate(20, (index) => _buildAnimatedParticle(index, screenWidth, screenHeight)),
              
              // Main Content
              CustomScrollView(
                controller: widget.scrollController,
                slivers: [
                  // Header Section
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.primaryRed, widget.purpleAccent, _royalPurple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        top: true,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 40 : 24,
                            vertical: isTablet ? 16 : 12,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
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
                                  SizedBox(height: isTablet ? 12 : 8),
                                  
                                  // Title
                                  Text(
                                    job.jobTitle,
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 32 : 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: isTablet ? 4 : 2),
                                  
                                  // Company Name as Subtitle
                                  Text(
                                    job.companyName,
                                    style: GoogleFonts.inter(
                                      fontSize: isTablet ? 18 : 15,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  
                                  // Urgent Badge - Only show if urgent
                                  if (job.isUrgent) ...[
                                    SizedBox(height: isTablet ? 10 : 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 14 : 12,
                                        vertical: isTablet ? 6 : 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.priority_high_rounded, 
                                            color: widget.goldAccent, 
                                            size: isTablet ? 16 : 14
                                          ),
                                          SizedBox(width: isTablet ? 6 : 4),
                                          Text(
                                            'URGENT HIRING',
                                            style: GoogleFonts.inter(
                                              fontSize: isTablet ? 13 : 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                
                  // Main Content Section
                  SliverPadding(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // User Profile and Job Info - Using job.postedBy fields
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // User Profile Image from job.postedByProfileImageBase64
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
                                child: _buildJobPosterImage(isLarge: true),
                              ),
                            ),
                            
                            SizedBox(width: isTablet ? 20 : 16),
                            
                            // Job Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // User Name from job.postedByName
                                  if (job.postedByName != null && job.postedByName!.isNotEmpty)
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
                                          Flexible(
                                            child: Text(
                                              job.postedByName!,
                                              style: GoogleFonts.poppins(
                                                color: widget.primaryRed,
                                                fontSize: isTablet ? 14 : 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
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
                                    overflow: TextOverflow.ellipsis,
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
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 10,
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
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 16 : 12,
                                    ),
                                    SizedBox(width: isTablet ? 4 : 2),
                                    Flexible(
                                      child: Text(
                                        'Deadline: ${DateFormat('MMM d, yyyy').format(job.applicationDeadline)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 12 : 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            SizedBox(width: 8),
                            
                            // Verified Badge
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 10,
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
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 16 : 12,
                                    ),
                                    SizedBox(width: isTablet ? 4 : 2),
                                    Flexible(
                                      child: Text(
                                        'VERIFIED',
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 12 : 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
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
                            shouldAnimate: shouldAnimate,
                          ),
                          isTablet: isTablet,
                          shouldAnimate: shouldAnimate,
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
                          shouldAnimate: shouldAnimate,
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
                          shouldAnimate: shouldAnimate,
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
                                    horizontal: isTablet ? 16 : 12,
                                    vertical: isTablet ? 10 : 6,
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
                                      fontSize: isTablet ? 14 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: widget.primaryRed,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            isTablet: isTablet,
                            shouldAnimate: shouldAnimate,
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
                                    horizontal: isTablet ? 16 : 12,
                                    vertical: isTablet ? 10 : 6,
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
                                      fontSize: isTablet ? 14 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: widget.goldAccent,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            isTablet: isTablet,
                            shouldAnimate: shouldAnimate,
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
                              //    onTap: () => widget.onLaunchEmail(job.contactEmail),
                                ),
                                SizedBox(height: isTablet ? 14 : 12),
                                _buildPremiumContactItem(
                                  icon: Icons.phone_rounded,
                                  title: 'Phone',
                                  value: job.contactPhone,
                                  isTablet: isTablet,
                              //    onTap: () => widget.onLaunchPhone(job.contactPhone),
                                ),
                              ],
                            ),
                          ),
                          isTablet: isTablet,
                          shouldAnimate: shouldAnimate,
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
                                  child: shouldAnimate
                                      ? RotationTransition(
                                          turns: _animationController,
                                          child: Icon(
                                            Icons.work_rounded,
                                            color: Colors.white,
                                            size: isTablet ? 28 : 24,
                                          ),
                                        )
                                      : Icon(
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
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Add bottom padding to ensure content doesn't get hidden behind bottom nav
                        SizedBox(height: 20),
                      ]),
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
          child: SafeArea(
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
                    shouldAnimate: shouldAnimate,
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
                    shouldAnimate: shouldAnimate,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumDetailSection({
    required String title,
    required IconData icon,
    required Widget child,
    required bool isTablet,
    required bool shouldAnimate,
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
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
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
    required bool shouldAnimate,
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
    required bool shouldAnimate,
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
                shouldAnimate
                    ? RotationTransition(
                        turns: _animationController,
                        child: Icon(icon, color: Colors.white, size: isTablet ? 22 : 18),
                      )
                    : Icon(icon, color: Colors.white, size: isTablet ? 22 : 18),
                SizedBox(width: isTablet ? 10 : 8),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isTablet ? 16 : 13,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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