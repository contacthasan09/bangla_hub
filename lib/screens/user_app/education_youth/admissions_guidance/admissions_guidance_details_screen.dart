import 'dart:async';
import 'dart:convert';
import 'package:bangla_hub/models/education_models.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class AdmissionsGuidanceDetailsScreen extends StatefulWidget {
  final AdmissionsGuidance service;
  final ScrollController scrollController;
  final Color primaryGreen;
  final Color successGreen;
  final Color warningOrange;
  final Color infoBlue;
  final Color purpleAccent;
  final Color goldAccent;
  final Color lightGreen;

  const AdmissionsGuidanceDetailsScreen({
    Key? key,
    required this.service,
    required this.scrollController,
    required this.primaryGreen,
    required this.successGreen,
    required this.warningOrange,
    required this.infoBlue,
    required this.purpleAccent,
    required this.goldAccent,
    required this.lightGreen,
  }) : super(key: key);

  @override
  _AdmissionsGuidanceDetailsScreenState createState() => _AdmissionsGuidanceDetailsScreenState();
}

class _AdmissionsGuidanceDetailsScreenState extends State<AdmissionsGuidanceDetailsScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  late AnimationController _animationController;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  
  final Color _darkGreen = Color(0xFF1B5E20);
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
      if (_animationController.isCompleted) {
        _animationController.reset();
        _animationController.forward();
      }
    } else {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    print('🗑️ AdmissionsGuidanceDetailsScreen disposing...');
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
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isError 
                  ? [widget.primaryGreen, _darkGreen] 
                  : [widget.successGreen, widget.infoBlue],
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

  // UPDATED: Build poster image with URL and Base64 support
  Widget _buildPosterImage({bool isLarge = false}) {
    final imageData = widget.service.postedByProfileImageBase64;
    
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
              print('Error loading guidance poster image: $error');
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
                print('Error decoding guidance poster image: $error');
                return _buildDefaultProfileImage(isLarge: isLarge);
              },
            ),
          );
        } catch (e) {
          print('Error processing guidance poster image: $e');
          return _buildDefaultProfileImage(isLarge: isLarge);
        }
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

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
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
        body: shouldAnimate
            ? FadeTransition(
                opacity: _animationController,
                child: _buildBodyContent(service, isTablet, shouldAnimate),
              )
            : _buildBodyContent(service, isTablet, shouldAnimate),
      ),
    );
  }

  Widget _buildBodyContent(AdmissionsGuidance service, bool isTablet, bool shouldAnimate) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.lightGreen, _creamWhite, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          // Header Section
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.primaryGreen, widget.purpleAccent, _darkGreen],
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
                              service.consultantName,
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
                          
                          Text(
                            service.organizationName ?? 'Independent Consultant',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 18 : 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          if (service.isVerified) ...[
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
                                    'VERIFIED CONSULTANT',
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
                  
                  // User Profile and Consultant Info
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
                          child: _buildPosterImage(isLarge: true),
                        ),
                      ),
                      
                      SizedBox(width: isTablet ? 20 : 16),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (service.postedByName != null && service.postedByName!.isNotEmpty)
                              Container(
                                margin: EdgeInsets.only(bottom: 8),
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: widget.lightGreen,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.person_rounded, color: widget.primaryGreen, size: 14),
                                    SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        service.postedByName!,
                                        style: GoogleFonts.poppins(
                                          color: widget.primaryGreen,
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
                              'Member since ${DateFormat('MMM d, yyyy').format(service.createdAt)}',
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
                          'Specializations',
                          '${service.specializations.length}',
                          widget.primaryGreen,
                          isTablet,
                        ),
                        _buildPremiumStatItem(
                          Icons.public_rounded,
                          'Countries',
                          '${service.countries.length}',
                          widget.infoBlue,
                          isTablet,
                        ),
                        _buildPremiumStatItem(
                          Icons.attach_money_rounded,
                          'Fee',
                          service.formattedFee,
                          widget.successGreen,
                          isTablet,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: isTablet ? 32 : 24),
                  
                  // About Section
                  _buildPremiumSection(
                    title: 'About the Consultant',
                    icon: Icons.info_rounded,
                    color: widget.primaryGreen,
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
                        service.description,
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 16 : 15,
                          color: _textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                    isTablet: isTablet,
                    shouldAnimate: shouldAnimate,
                  ),
                  
                  SizedBox(height: isTablet ? 32 : 24),
                  
                  // Experience Section
                  if (service.experience != null && service.experience!.isNotEmpty)
                    _buildPremiumSection(
                      title: 'Experience',
                      icon: Icons.work_history_rounded,
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
                        child: Text(
                          service.experience!,
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 16 : 15,
                            color: _textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ),
                      isTablet: isTablet,
                      shouldAnimate: shouldAnimate,
                    ),
                  
                  if (service.experience != null && service.experience!.isNotEmpty)
                    SizedBox(height: isTablet ? 32 : 24),
                  
                  // Qualifications Section
                  if (service.qualifications != null && service.qualifications!.isNotEmpty)
                    _buildPremiumSection(
                      title: 'Qualifications',
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
                          service.qualifications!,
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 16 : 15,
                            color: _textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ),
                      isTablet: isTablet,
                      shouldAnimate: shouldAnimate,
                    ),
                  
                  if (service.qualifications != null && service.qualifications!.isNotEmpty)
                    SizedBox(height: isTablet ? 32 : 24),
                  
                  // Specializations Section
                  _buildPremiumSection(
                    title: 'Specializations',
                    icon: Icons.category_rounded,
                    color: widget.primaryGreen,
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
                        children: service.specializations.map((spec) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 16 : 12,
                              vertical: isTablet ? 10 : 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [widget.primaryGreen.withOpacity(0.1), widget.lightGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: widget.primaryGreen.withOpacity(0.3)),
                            ),
                            child: Text(
                              spec,
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 15 : 13,
                                fontWeight: FontWeight.w600,
                                color: widget.primaryGreen,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    isTablet: isTablet,
                    shouldAnimate: shouldAnimate,
                  ),
                  
                  SizedBox(height: isTablet ? 32 : 24),
                  
                  // Countries Served Section
                  _buildPremiumSection(
                    title: 'Countries Served',
                    icon: Icons.public_rounded,
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
                        children: service.countries.map((country) {
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
                              country,
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
                    shouldAnimate: shouldAnimate,
                  ),
                  
                  SizedBox(height: isTablet ? 32 : 24),
                  
                  // Services Offered Section
                  if (service.servicesOffered.isNotEmpty)
                    _buildPremiumSection(
                      title: 'Services Offered',
                      icon: Icons.checklist_rounded,
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
                          children: service.servicesOffered.map((serviceItem) {
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
                                serviceItem,
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
                      shouldAnimate: shouldAnimate,
                    ),
                  
                  if (service.servicesOffered.isNotEmpty)
                    SizedBox(height: isTablet ? 32 : 24),
                  
                  // Location Section
                  _buildPremiumSection(
                    title: 'Location',
                    icon: Icons.location_on_rounded,
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
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isTablet ? 12 : 10),
                            decoration: BoxDecoration(
                              color: widget.warningOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              color: widget.warningOrange,
                              size: isTablet ? 24 : 20,
                            ),
                          ),
                          SizedBox(width: isTablet ? 16 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Full Address',
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 14 : 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${service.address}, ${service.city}, ${service.state}',
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
                    shouldAnimate: shouldAnimate,
                  ),
                  
                  SizedBox(height: isTablet ? 32 : 24),
                  
                  // Contact Information Section
                  _buildPremiumSection(
                    title: 'Contact Information',
                    icon: Icons.contact_phone_rounded,
                    color: widget.primaryGreen,
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
                            value: service.email,
                            color: widget.primaryGreen,
                            onTap: () => _launchEmail(service.email),
                            isTablet: isTablet,
                            shouldAnimate: shouldAnimate,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),
                          _buildPremiumContactItem(
                            icon: Icons.phone_rounded,
                            label: 'Phone',
                            value: service.phone,
                            color: widget.successGreen,
                            onTap: () => _launchPhone(service.phone),
                            isTablet: isTablet,
                            shouldAnimate: shouldAnimate,
                          ),
                        ],
                      ),
                    ),
                    isTablet: isTablet,
                    shouldAnimate: shouldAnimate,
                  ),
                  
                  SizedBox(height: isTablet ? 40 : 32),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildPremiumActionButton(
                          icon: Icons.email_rounded,
                          label: 'Email',
                          gradient: LinearGradient(
                            colors: [widget.primaryGreen, widget.purpleAccent],
                          ),
                          onPressed: () => _launchEmail(service.email),
                          isTablet: isTablet,
                          shouldAnimate: shouldAnimate,
                        ),
                      ),
                      SizedBox(width: isTablet ? 16 : 12),
                      Expanded(
                        child: _buildPremiumActionButton(
                          icon: Icons.phone_rounded,
                          label: 'Call',
                          gradient: LinearGradient(
                            colors: [widget.successGreen, widget.infoBlue],
                          ),
                          onPressed: () => _launchPhone(service.phone),
                          isTablet: isTablet,
                          shouldAnimate: shouldAnimate,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: isTablet ? 16 : 12),
                  
                  // Rating and reviews
                  Container(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber, size: isTablet ? 40 : 32),
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${service.rating.toStringAsFixed(1)} out of 5',
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber[800],
                                ),
                              ),
                              Text(
                                'Based on ${service.totalReviews} reviews',
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 14 : 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: isTablet ? 24 : 20),
                  
                  // Premium Footer
                  Container(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [widget.lightGreen.withOpacity(0.5), widget.lightGreen],
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
                              colors: [widget.primaryGreen, widget.purpleAccent, widget.infoBlue],
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
                            child: shouldAnimate
                                ? RotationTransition(
                                    turns: _animationController,
                                    child: Icon(
                                      Icons.business_center_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 28 : 24,
                                    ),
                                  )
                                : Icon(
                                    Icons.business_center_rounded,
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
                                  colors: [widget.primaryGreen, widget.purpleAccent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: Text(
                                  'Premium Consultant',
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 18 : 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(height: isTablet ? 4 : 2),
                              Text(
                                'Verified by Admin',
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
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 16 : 12,
            fontWeight: FontWeight.w800,
            color: Colors.grey[800],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 12 : 10,
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
                  colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
    required bool shouldAnimate,
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