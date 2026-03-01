import 'dart:convert';
import 'package:bangla_hub/models/education_models.dart';
import 'package:bangla_hub/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class BanglaClassDetailsScreen extends StatefulWidget {
  final BanglaClass banglaClass;
  final UserModel? user;
  final ScrollController scrollController;
  final Color primaryOrange;
  final Color successGreen;
  final Color redAccent;
  final Color greenAccent;
  final Color tealAccent;
  final Color purpleAccent;
  final Color goldAccent;
  final Color lightOrange;

  const BanglaClassDetailsScreen({
    Key? key,
    required this.banglaClass,
    this.user,
    required this.scrollController,
    required this.primaryOrange,
    required this.successGreen,
    required this.redAccent,
    required this.greenAccent,
    required this.tealAccent,
    required this.purpleAccent,
    required this.goldAccent,
    required this.lightOrange,
  }) : super(key: key);

  @override
  _BanglaClassDetailsScreenState createState() => _BanglaClassDetailsScreenState();
}

class _BanglaClassDetailsScreenState extends State<BanglaClassDetailsScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  
  final Color _darkOrange = Color(0xFFF57C00);
  final Color _textPrimary = Color(0xFF1E2A3A);
  final Color _textSecondary = Color(0xFF5D6D7E);
  final Color _borderLight = Color(0xFFE0E7E9);
  final Color _creamWhite = Color(0xFFFAF7F2);
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

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      _showPremiumSnackBar('Opening email app...');
    } else {
      _showPremiumSnackBar('Could not launch email app', isError: true);
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
        _showPremiumSnackBar('Opening phone dialer...');
      }
    } catch (e) {
      _showPremiumSnackBar('Could not launch phone dialer', isError: true);
    }
  }

  void _showPremiumSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isError 
                  ? [widget.primaryOrange, _darkOrange] 
                  : [widget.successGreen, widget.greenAccent],
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
      color: widget.lightOrange,
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: widget.primaryOrange,
          size: isLarge ? 40 : 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final banglaClass = widget.banglaClass;
    final user = widget.user;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isFull = banglaClass.enrolledStudents >= banglaClass.maxStudents;

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
              colors: [widget.lightOrange, _creamWhite, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
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
                          colors: [widget.primaryOrange, widget.redAccent, _darkOrange],
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
                                    colors: [widget.goldAccent, widget.greenAccent, widget.goldAccent],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              SizedBox(height: isTablet ? 16 : 12),
                              
                              // Instructor Name
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [Colors.white, widget.goldAccent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: Text(
                                  banglaClass.instructorName,
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
                              
                              // Organization
                              Text(
                                banglaClass.organizationName ?? 'Independent Instructor',
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              
                              SizedBox(height: isTablet ? 16 : 12),
                              
                              // Verified Badge
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
                                    Icon(Icons.verified_rounded, color: widget.goldAccent, size: isTablet ? 18 : 16),
                                    SizedBox(width: isTablet ? 8 : 6),
                                    Text(
                                      'VERIFIED CLASS',
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
                          
                          // User Profile and Instructor Info
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
                              
                              // Instructor Info
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
                                          color: widget.lightOrange,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.person_rounded, color: widget.primaryOrange, size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              user.fullName,
                                              style: GoogleFonts.poppins(
                                                color: widget.primaryOrange,
                                                fontSize: isTablet ? 14 : 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    
                                    // Member Since
                                    Text(
                                      'Class added on ${DateFormat('MMM d, yyyy').format(banglaClass.createdAt)}',
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
                          
                          SizedBox(height: isTablet ? 32 : 24),
                          
                          // Quick Stats Grid
                          Container(
                            padding: EdgeInsets.all(isTablet ? 24 : 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.grey[50]!, Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: _borderLight),
                              boxShadow: [
                                BoxShadow(
                                  color: _shadowColor,
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildPremiumStatItem(
                                  Icons.category_rounded,
                                  'Class Types',
                                  '${banglaClass.classTypes.length}',
                                  widget.primaryOrange,
                                  isTablet,
                                ),
                                _buildPremiumStatItem(
                                  Icons.schedule_rounded,
                                  'Duration',
                                  banglaClass.formattedDuration,
                                  widget.tealAccent,
                                  isTablet,
                                ),
                                _buildPremiumStatItem(
                                  Icons.attach_money_rounded,
                                  'Fee',
                                  banglaClass.formattedFee,
                                  widget.successGreen,
                                  isTablet,
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: isTablet ? 32 : 24),
                          
                          // About Section
                          _buildPremiumSection(
                            title: 'About the Class',
                            icon: Icons.info_rounded,
                            color: widget.primaryOrange,
                            child: Container(
                              padding: EdgeInsets.all(isTablet ? 20 : 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _borderLight),
                                boxShadow: [
                                  BoxShadow(
                                    color: _shadowColor,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                banglaClass.description,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 16 : 15,
                                  color: _textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            isTablet: isTablet,
                          ),
                          
                          SizedBox(height: isTablet ? 32 : 24),
                          
                          // Instructor Qualifications
                          if (banglaClass.qualifications != null && banglaClass.qualifications!.isNotEmpty)
                            _buildPremiumSection(
                              title: 'Instructor Qualifications',
                              icon: Icons.school_rounded,
                              color: widget.purpleAccent,
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 20 : 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _borderLight),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _shadowColor,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  banglaClass.qualifications!,
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 16 : 15,
                                    color: _textSecondary,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              isTablet: isTablet,
                            ),
                          
                          if (banglaClass.qualifications != null && banglaClass.qualifications!.isNotEmpty)
                            SizedBox(height: isTablet ? 32 : 24),
                          
                          // Class Types Section
                          _buildPremiumSection(
                            title: 'Class Types',
                            icon: Icons.category_rounded,
                            color: widget.primaryOrange,
                            child: Container(
                              padding: EdgeInsets.all(isTablet ? 20 : 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _borderLight),
                                boxShadow: [
                                  BoxShadow(
                                    color: _shadowColor,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: banglaClass.classTypes.map((type) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 16 : 12,
                                      vertical: isTablet ? 10 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [widget.primaryOrange.withOpacity(0.1), widget.lightOrange],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(color: widget.primaryOrange.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      type,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 15 : 13,
                                        fontWeight: FontWeight.w600,
                                        color: widget.primaryOrange,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            isTablet: isTablet,
                          ),
                          
                          SizedBox(height: isTablet ? 32 : 24),
                          
                          // Teaching Methods Section
                          _buildPremiumSection(
                            title: 'Teaching Methods',
                            icon: Icons.video_call_rounded,
                            color: widget.tealAccent,
                            child: Container(
                              padding: EdgeInsets.all(isTablet ? 20 : 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _borderLight),
                                boxShadow: [
                                  BoxShadow(
                                    color: _shadowColor,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: banglaClass.teachingMethods.map((method) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 16 : 12,
                                      vertical: isTablet ? 10 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [widget.tealAccent.withOpacity(0.1), widget.tealAccent.withOpacity(0.05)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(color: widget.tealAccent.withOpacity(0.3)),
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
                                          color: widget.tealAccent,
                                          size: isTablet ? 18 : 16,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          method.displayName,
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 15 : 13,
                                            fontWeight: FontWeight.w600,
                                            color: widget.tealAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            isTablet: isTablet,
                          ),
                          
                          SizedBox(height: isTablet ? 32 : 24),
                          
                          // Cultural Activities
                          if (banglaClass.culturalActivities.isNotEmpty)
                            _buildPremiumSection(
                              title: 'Cultural Activities',
                              icon: Icons.celebration_rounded,
                              color: widget.purpleAccent,
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 20 : 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _borderLight),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _shadowColor,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: banglaClass.culturalActivities.map((activity) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 16 : 12,
                                        vertical: isTablet ? 10 : 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [widget.purpleAccent.withOpacity(0.1), widget.purpleAccent.withOpacity(0.05)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(color: widget.purpleAccent.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.celebration_rounded,
                                            color: widget.purpleAccent,
                                            size: isTablet ? 18 : 16,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            activity,
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 15 : 13,
                                              fontWeight: FontWeight.w600,
                                              color: widget.purpleAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              isTablet: isTablet,
                            ),
                          
                          if (banglaClass.culturalActivities.isNotEmpty)
                            SizedBox(height: isTablet ? 32 : 24),
                          
                          // Schedule
                          if (banglaClass.schedule != null && banglaClass.schedule!.isNotEmpty)
                            _buildPremiumSection(
                              title: 'Schedule',
                              icon: Icons.calendar_today_rounded,
                              color: widget.greenAccent,
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 20 : 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _borderLight),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _shadowColor,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded, color: widget.greenAccent, size: isTablet ? 24 : 20),
                                    SizedBox(width: isTablet ? 16 : 12),
                                    Expanded(
                                      child: Text(
                                        banglaClass.schedule!,
                                        style: GoogleFonts.inter(
                                          fontSize: isTablet ? 16 : 15,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              isTablet: isTablet,
                            ),
                          
                          if (banglaClass.schedule != null && banglaClass.schedule!.isNotEmpty)
                            SizedBox(height: isTablet ? 32 : 24),
                          
                          // Location
                          _buildPremiumSection(
                            title: 'Location',
                            icon: Icons.location_on_rounded,
                            color: widget.redAccent,
                            child: Container(
                              padding: EdgeInsets.all(isTablet ? 20 : 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _borderLight),
                                boxShadow: [
                                  BoxShadow(
                                    color: _shadowColor,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(isTablet ? 12 : 10),
                                    decoration: BoxDecoration(
                                      color: widget.redAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.location_on_rounded,
                                      color: widget.redAccent,
                                      size: isTablet ? 24 : 20,
                                    ),
                                  ),
                                  SizedBox(width: isTablet ? 16 : 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Class Location',
                                          style: GoogleFonts.inter(
                                            fontSize: isTablet ? 14 : 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '${banglaClass.address}, ${banglaClass.city}, ${banglaClass.state}',
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            isTablet: isTablet,
                          ),
                          
                          SizedBox(height: isTablet ? 32 : 24),
                          
                          // Class Details
                          _buildPremiumSection(
                            title: 'Class Details',
                            icon: Icons.info_outline_rounded,
                            color: widget.primaryOrange,
                            child: Container(
                              padding: EdgeInsets.all(isTablet ? 20 : 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _borderLight),
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
                                  _buildPremiumDetailRow(
                                    icon: Icons.attach_money_rounded,
                                    label: 'Class Fee',
                                    value: banglaClass.formattedFee,
                                    color: widget.successGreen,
                                    isTablet: isTablet,
                                  ),
                                  SizedBox(height: isTablet ? 12 : 8),
                                  _buildPremiumDetailRow(
                                    icon: Icons.schedule_rounded,
                                    label: 'Duration per Class',
                                    value: banglaClass.formattedDuration,
                                    color: widget.tealAccent,
                                    isTablet: isTablet,
                                  ),
                                  SizedBox(height: isTablet ? 12 : 8),
                                  _buildPremiumDetailRow(
                                    icon: Icons.people_rounded,
                                    label: 'Enrollment',
                                    value: '${banglaClass.enrolledStudents}/${banglaClass.maxStudents} students',
                                    color: isFull ? widget.redAccent : widget.greenAccent,
                                    isTablet: isTablet,
                                  ),
                                ],
                              ),
                            ),
                            isTablet: isTablet,
                          ),
                          
                          if (isFull) ...[
                            SizedBox(height: isTablet ? 16 : 12),
                            Container(
                              padding: EdgeInsets.all(isTablet ? 16 : 12),
                              decoration: BoxDecoration(
                                color: widget.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: widget.redAccent),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_rounded, color: widget.redAccent, size: isTablet ? 24 : 20),
                                  SizedBox(width: isTablet ? 12 : 8),
                                  Expanded(
                                    child: Text(
                                      'This class is currently full',
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 16 : 14,
                                        fontWeight: FontWeight.w600,
                                        color: widget.redAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          SizedBox(height: isTablet ? 32 : 24),
                          
                          // Contact Information
                          _buildPremiumSection(
                            title: 'Contact Information',
                            icon: Icons.contact_phone_rounded,
                            color: widget.primaryOrange,
                            child: Container(
                              padding: EdgeInsets.all(isTablet ? 20 : 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _borderLight),
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
                                    label: 'Email',
                                    value: banglaClass.email,
                                    color: widget.primaryOrange,
                                    onTap: () => _launchEmail(banglaClass.email),
                                    isTablet: isTablet,
                                  ),
                                  SizedBox(height: isTablet ? 16 : 12),
                                  _buildPremiumContactItem(
                                    icon: Icons.phone_rounded,
                                    label: 'Phone',
                                    value: banglaClass.phone,
                                    color: widget.successGreen,
                                    onTap: () => _launchPhone(banglaClass.phone),
                                    isTablet: isTablet,
                                  ),
                                ],
                              ),
                            ),
                            isTablet: isTablet,
                          ),
                          
                          SizedBox(height: isTablet ? 40 : 32),
                          
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: _buildPremiumActionButton(
                                  icon: Icons.person_add_rounded,
                                  label: isFull ? 'Class Full' : 'Enroll Now',
                                  onPressed: isFull ? null : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle_rounded, color: Colors.white),
                                            SizedBox(width: 10),
                                            Text('Enrollment feature coming soon!'),
                                          ],
                                        ),
                                        backgroundColor: widget.primaryOrange,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        margin: EdgeInsets.all(12),
                                      ),
                                    );
                                  },
                                  gradientColors: [widget.primaryOrange, widget.redAccent],
                                  isTablet: isTablet,
                                  isEnabled: !isFull,
                                ),
                              ),
                              SizedBox(width: isTablet ? 16 : 12),
                              Expanded(
                                child: _buildPremiumActionButton(
                                  icon: Icons.close_rounded,
                                  label: 'Close',
                                  onPressed: () => Navigator.pop(context),
                                  gradientColors: [widget.successGreen, widget.tealAccent],
                                  isTablet: isTablet,
                                  isEnabled: true,
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: isTablet ? 16 : 12),
                          
                          // Premium Footer
                          Container(
                            padding: EdgeInsets.all(isTablet ? 24 : 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [widget.lightOrange.withOpacity(0.5), widget.lightOrange],
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
                                    child: Icon(
                                      Icons.language_rounded,
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
                                          colors: [widget.primaryOrange, widget.redAccent],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ).createShader(bounds),
                                        child: Text(
                                          'Premium Language Class',
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: isTablet ? 4 : 2),
                                      Text(
                                        'Learn Bengali with verified instructors',
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
                          
                          SizedBox(height: isTablet ? 24 : 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumStatItem(IconData icon, String label, String value, Color color, bool isTablet) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 12 : 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: isTablet ? 28 : 24),
        ),
        SizedBox(height: isTablet ? 8 : 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 16 : 12,
            fontWeight: FontWeight.w800,
            color: Colors.grey[800],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 14 : 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumSection({
    required String title,
    required IconData icon,
    required Color color,
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: isTablet ? 20 : 18),
            ),
            SizedBox(width: isTablet ? 12 : 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 12 : 10),
        child,
      ],
    );
  }

  Widget _buildPremiumDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isTablet,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 8 : 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: isTablet ? 18 : 16),
        ),
        SizedBox(width: isTablet ? 12 : 8),
        Expanded(
          child: Row(
            children: [
              Text(
                '$label:',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 15 : 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(width: isTablet ? 8 : 4),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 15 : 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumContactItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 14 : 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 10 : 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: isTablet ? 22 : 18),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 13 : 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                      decoration: TextDecoration.underline,
                      decorationColor: color.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              color: Colors.grey[400],
              size: isTablet ? 20 : 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required List<Color> gradientColors,
    required bool isTablet,
    required bool isEnabled,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isEnabled
            ? LinearGradient(
                colors: gradientColors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isEnabled ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: isTablet ? 16 : 14,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isEnabled ? Colors.white : Colors.grey[600], size: isTablet ? 22 : 20),
                SizedBox(width: isTablet ? 10 : 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w700,
                    color: isEnabled ? Colors.white : Colors.grey[600],
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