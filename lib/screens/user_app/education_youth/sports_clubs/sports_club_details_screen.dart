import 'dart:async';
import 'dart:convert';
import 'package:bangla_hub/models/education_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class SportsClubDetailsScreen extends StatefulWidget {
  final SportsClub club;
  final ScrollController scrollController;
  final Color primaryRed;
  final Color successGreen;
  final Color warningOrange;
  final Color infoBlue;
  final Color purpleAccent;
  final Color goldAccent;
  final Color tealAccent;
  final Color lightRed;

  const SportsClubDetailsScreen({
    Key? key,
    required this.club,
    required this.scrollController,
    required this.primaryRed,
    required this.successGreen,
    required this.warningOrange,
    required this.infoBlue,
    required this.purpleAccent,
    required this.goldAccent,
    required this.tealAccent,
    required this.lightRed,
  }) : super(key: key);

  @override
  _SportsClubDetailsScreenState createState() => _SportsClubDetailsScreenState();
}

class _SportsClubDetailsScreenState extends State<SportsClubDetailsScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  late AnimationController _animationController;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  
  final Color _darkRed = Color(0xFFD32F2F);
  final Color _textPrimary = Color(0xFF1E2A3A);
  final Color _textSecondary = Color(0xFF5D6D7E);
  final Color _borderLight = Color(0xFFE0E7E9);
  final Color _creamWhite = Color(0xFFFAF7F2);
  final Color _shadowColor = Color(0x1A000000);

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    
    if (_appLifecycleState == AppLifecycleState.resumed) {
      _animationController.forward();
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });
    
    if (state == AppLifecycleState.resumed) {
      if (_animationController.status != AnimationStatus.forward) {
        _animationController.forward();
      }
    } else {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    print('🗑️ SportsClubDetailsScreen disposing...');
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  // Helper function to check if string is a URL
  bool _isUrlString(String str) {
    return str.startsWith('http://') || str.startsWith('https://');
  }

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      if (mounted) {
        _showPremiumSnackBar('Opening email app...');
      }
    } else {
      if (mounted) {
        _showPremiumSnackBar('Could not launch email app', isError: true);
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
        if (mounted) {
          _showPremiumSnackBar('Opening phone dialer...');
        }
      }
    } catch (e) {
      if (mounted) {
        _showPremiumSnackBar('Could not launch phone dialer', isError: true);
      }
    }
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
                  ? [widget.primaryRed, _darkRed] 
                  : [widget.successGreen, widget.tealAccent],
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

  // UPDATED: Build poster image from club.postedByProfileImageBase64 (handles both URL and Base64)
  Widget _buildClubPosterImage({bool isLarge = false}) {
    final imageData = widget.club.postedByProfileImageBase64;
    
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
              print('Error loading club poster image: $error');
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
                print('Error decoding club poster image: $error');
                return _buildDefaultProfileImage(isLarge: isLarge);
              },
            ),
          );
        } catch (e) {
          print('Error processing club poster image: $e');
          return _buildDefaultProfileImage(isLarge: isLarge);
        }
      }
    }
    
    return _buildDefaultProfileImage(isLarge: isLarge);
  }

  Widget _buildDefaultProfileImage({bool isLarge = false}) {
    return Container(
      color: widget.lightRed,
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: widget.primaryRed,
          size: isLarge ? 40 : 24,
        ),
      ),
    );
  }

  IconData _getSportIcon(SportsType sportType) {
    switch (sportType) {
      case SportsType.cricket:
        return Icons.sports_cricket_rounded;
      case SportsType.soccer:
        return Icons.sports_soccer_rounded;
      case SportsType.basketball:
        return Icons.sports_basketball_rounded;
      case SportsType.volleyball:
        return Icons.sports_volleyball_rounded;
      case SportsType.badminton:
        return Icons.sports_tennis_rounded;
      case SportsType.tableTennis:
        return Icons.sports_tennis_rounded;
      case SportsType.swimming:
        return Icons.pool_rounded;
      case SportsType.martialArts:
        return Icons.sports_martial_arts_rounded;
      case SportsType.yoga:
        return Icons.self_improvement_rounded;
      default:
        return Icons.sports_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final club = widget.club;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isFull = club.currentMembers >= club.maxMembers;
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
              colors: [widget.lightRed, _creamWhite, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              CustomScrollView(
                controller: widget.scrollController,
                slivers: [
                  // Header Section
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.primaryRed, widget.purpleAccent, _darkRed],
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
                                  Container(
                                    height: 4,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [widget.goldAccent, widget.warningOrange, widget.goldAccent],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  SizedBox(height: isTablet ? 12 : 8),
                                  
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [Colors.white, widget.goldAccent],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds),
                                    child: Text(
                                      club.clubName,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 32 : 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(height: isTablet ? 4 : 2),
                                  
                                  Row(
                                    children: [
                                      Icon(
                                        _getSportIcon(club.sportType),
                                        color: Colors.white,
                                        size: isTablet ? 18 : 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        club.sportType.displayName,
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 18 : 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  
                                  if (club.isVerified) ...[
                                    SizedBox(height: isTablet ? 10 : 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 14 : 12,
                                        vertical: isTablet ? 6 : 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.verified_rounded, 
                                            color: widget.goldAccent, 
                                            size: isTablet ? 16 : 14
                                          ),
                                          SizedBox(width: isTablet ? 6 : 4),
                                          Text(
                                            'VERIFIED CLUB',
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 13 : 11,
                                              fontWeight: FontWeight.w700,
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
                  
                  // All Information in Column Below
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.all(isTablet ? 24 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: isTablet ? 20 : 16),
                          
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
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
                                  child: _buildClubPosterImage(isLarge: true),
                                ),
                              ),
                              
                              SizedBox(width: isTablet ? 20 : 16),
                              
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (club.postedByName != null && club.postedByName!.isNotEmpty)
                                      Container(
                                        margin: EdgeInsets.only(bottom: 8),
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: widget.lightRed,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.person_rounded, color: widget.primaryRed, size: 14),
                                            SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                club.postedByName!,
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
                                    
                                    Text(
                                      'Club established ${DateFormat('MMMM yyyy').format(club.createdAt)}',
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
                                  Icons.people_rounded,
                                  'Members',
                                  '${club.currentMembers}/${club.maxMembers}',
                                  widget.infoBlue,
                                  isTablet,
                                ),
                                _buildPremiumStatItem(
                                  Icons.attach_money_rounded,
                                  'Fee',
                                  club.formattedFee,
                                  widget.successGreen,
                                  isTablet,
                                ),
                                _buildPremiumStatItem(
                                  Icons.category_rounded,
                                  'Age Groups',
                                  '${club.ageGroups.length}',
                                  widget.warningOrange,
                                  isTablet,
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: isTablet ? 32 : 24),
                          
                          // About Section
                          _buildPremiumSection(
                            title: 'About the Club',
                            icon: Icons.description_rounded,
                            color: widget.primaryRed,
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
                                club.description,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 16 : 15,
                                  color: _textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            isTablet: isTablet,
                          ),
                          
                          // Coach Information
                          if (club.coachName != null && club.coachName!.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPremiumSection(
                              title: 'Coach',
                              icon: Icons.person_rounded,
                              color: widget.warningOrange,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Coach: ${club.coachName}',
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 18 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: _textPrimary,
                                      ),
                                    ),
                                    if (club.coachQualifications != null && club.coachQualifications!.isNotEmpty) ...[
                                      SizedBox(height: 8),
                                      Text(
                                        club.coachQualifications!,
                                        style: GoogleFonts.inter(
                                          fontSize: isTablet ? 15 : 14,
                                          color: _textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          SizedBox(height: isTablet ? 32 : 24),
                          
                          // Location & Venue
                          _buildPremiumSection(
                            title: 'Location & Venue',
                            icon: Icons.location_on_rounded,
                            color: Colors.red,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_rounded, color: Colors.red, size: isTablet ? 22 : 20),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          club.venue,
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 16 : 15,
                                            fontWeight: FontWeight.w600,
                                            color: _textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Padding(
                                    padding: EdgeInsets.only(left: isTablet ? 32 : 30),
                                    child: Text(
                                      '${club.address}, ${club.city}, ${club.state}',
                                      style: GoogleFonts.inter(
                                        fontSize: isTablet ? 15 : 14,
                                        color: _textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            isTablet: isTablet,
                          ),
                          
                          // Schedule
                          if (club.schedule != null && club.schedule!.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPremiumSection(
                              title: 'Schedule',
                              icon: Icons.calendar_today_rounded,
                              color: widget.successGreen,
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
                                    Icon(Icons.calendar_today_rounded, color: widget.successGreen, size: isTablet ? 22 : 20),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        club.schedule!,
                                        style: GoogleFonts.inter(
                                          fontSize: isTablet ? 16 : 15,
                                          color: _textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Age Groups
                          if (club.ageGroups.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPremiumSection(
                              title: 'Age Groups',
                              icon: Icons.people_outline_rounded,
                              color: widget.warningOrange,
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
                                  children: club.ageGroups.map((ageGroup) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 16 : 12,
                                        vertical: isTablet ? 10 : 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [widget.warningOrange.withOpacity(0.1), widget.warningOrange.withOpacity(0.05)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(color: widget.warningOrange.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        ageGroup,
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 15 : 13,
                                          fontWeight: FontWeight.w600,
                                          color: widget.warningOrange,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Skill Levels
                          if (club.skillLevels.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPremiumSection(
                              title: 'Skill Levels',
                              icon: Icons.star_rounded,
                              color: widget.infoBlue,
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
                                  children: club.skillLevels.map((level) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 16 : 12,
                                        vertical: isTablet ? 10 : 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [widget.infoBlue.withOpacity(0.1), widget.infoBlue.withOpacity(0.05)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(color: widget.infoBlue.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        level,
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 15 : 13,
                                          fontWeight: FontWeight.w600,
                                          color: widget.infoBlue,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Equipment Provided
                          if (club.equipmentProvided.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPremiumSection(
                              title: 'Equipment Provided',
                              icon: Icons.sports_handball_rounded,
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
                                  children: club.equipmentProvided.map((equipment) {
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
                                      child: Text(
                                        equipment,
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 15 : 13,
                                          fontWeight: FontWeight.w600,
                                          color: widget.purpleAccent,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Amenities
                          if (club.amenities.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPremiumSection(
                              title: 'Amenities',
                              icon: Icons.room_service_rounded,
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
                                  children: club.amenities.map((amenity) {
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
                                      child: Text(
                                        amenity,
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 15 : 13,
                                          fontWeight: FontWeight.w600,
                                          color: widget.tealAccent,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          // Tournaments
                          if (club.tournaments.isNotEmpty) ...[
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPremiumSection(
                              title: 'Tournaments',
                              icon: Icons.emoji_events_rounded,
                              color: widget.goldAccent,
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
                                  children: club.tournaments.map((tournament) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 16 : 12,
                                        vertical: isTablet ? 10 : 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [widget.goldAccent.withOpacity(0.1), widget.goldAccent.withOpacity(0.05)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(color: widget.goldAccent.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        tournament,
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 15 : 13,
                                          fontWeight: FontWeight.w600,
                                          color: widget.goldAccent,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              isTablet: isTablet,
                            ),
                          ],
                          
                          SizedBox(height: isTablet ? 32 : 24),
                          
                          // Membership Status
                          Container(
                            padding: EdgeInsets.all(isTablet ? 20 : 16),
                            decoration: BoxDecoration(
                              color: isFull ? Colors.red.withOpacity(0.1) : widget.successGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isFull ? Colors.red.withOpacity(0.3) : widget.successGreen.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isFull ? Icons.warning_rounded : Icons.check_circle_rounded,
                                  color: isFull ? Colors.red : widget.successGreen,
                                  size: isTablet ? 28 : 24,
                                ),
                                SizedBox(width: isTablet ? 16 : 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isFull ? 'Membership Full' : 'Membership Available',
                                        style: GoogleFonts.poppins(
                                          color: isFull ? Colors.red : widget.successGreen,
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        isFull 
                                            ? 'Currently at capacity. Join waiting list.'
                                            : '${club.maxMembers - club.currentMembers} spots available',
                                        style: GoogleFonts.inter(
                                          color: isFull ? Colors.red : widget.successGreen,
                                          fontSize: isTablet ? 15 : 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: isTablet ? 32 : 24),
                          
                          // Contact Information
                          _buildPremiumSection(
                            title: 'Contact',
                            icon: Icons.contact_phone_rounded,
                            color: widget.primaryRed,
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
                                    value: club.email,
                                    color: widget.primaryRed,
                                    onTap: () => _launchEmail(club.email),
                                    isTablet: isTablet,
                                  ),
                                  SizedBox(height: isTablet ? 16 : 12),
                                  _buildPremiumContactItem(
                                    icon: Icons.phone_rounded,
                                    label: 'Phone',
                                    value: club.phone,
                                    color: widget.successGreen,
                                    onTap: () => _launchPhone(club.phone),
                                    isTablet: isTablet,
                                  ),
                                ],
                              ),
                            ),
                            isTablet: isTablet,
                          ),
                          
                          SizedBox(height: isTablet ? 40 : 32),
                          
                          // Premium Footer
                          Container(
                            padding: EdgeInsets.all(isTablet ? 24 : 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [widget.lightRed.withOpacity(0.5), widget.lightRed],
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
                                              Icons.sports_rounded,
                                              color: Colors.white,
                                              size: isTablet ? 28 : 24,
                                            ),
                                          )
                                        : Icon(
                                            Icons.sports_rounded,
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
                                          'Premium Sports Club',
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: isTablet ? 4 : 2),
                                      Text(
                                        'Join and stay active! 🏆',
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
                          
                          Center(
                            child: Text(
                              '${club.currentMembers} active members',
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 14 : 12,
                                color: _textSecondary,
                              ),
                            ),
                          ),
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
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
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
          child: shouldAnimate
              ? RotationTransition(
                  turns: _animationController,
                  child: Icon(icon, color: color, size: isTablet ? 28 : 24),
                )
              : Icon(icon, color: color, size: isTablet ? 28 : 24),
        ),
        SizedBox(height: isTablet ? 8 : 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 22 : 18,
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
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
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
              child: shouldAnimate
                  ? RotationTransition(
                      turns: _animationController,
                      child: Icon(icon, color: color, size: isTablet ? 20 : 18),
                    )
                  : Icon(icon, color: color, size: isTablet ? 20 : 18),
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

  Widget _buildPremiumContactItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
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
              child: shouldAnimate
                  ? RotationTransition(
                      turns: _animationController,
                      child: Icon(icon, color: color, size: isTablet ? 22 : 18),
                    )
                  : Icon(icon, color: color, size: isTablet ? 22 : 18),
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
}