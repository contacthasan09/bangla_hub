import 'dart:convert';
import 'package:bangla_hub/models/education_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class BanglaClassDetailsScreen extends StatefulWidget {
  final BanglaClass banglaClass;
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

class _BanglaClassDetailsScreenState extends State<BanglaClassDetailsScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  late AnimationController _animationController;
  late List<AnimationController> _sectionControllers;
  
  final Color _darkOrange = Color(0xFFF57C00);
  final Color _textPrimary = Color(0xFF1E2A3A);
  final Color _textSecondary = Color(0xFF5D6D7E);
  final Color _borderLight = Color(0xFFE0E7E9);
  final Color _creamWhite = Color(0xFFFAF7F2);
  final Color _shadowColor = Color(0x1A000000);
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    
    // Initialize section animation controllers
    _sectionControllers = List.generate(10, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300 + (index * 50)),
      );
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
      
      for (var i = 0; i < _sectionControllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 50), () {
          if (mounted && _appLifecycleState == AppLifecycleState.resumed) {
            _sectionControllers[i].forward();
          }
        });
      }
    }
  }
  
  void _stopAnimations() {
    _animationController.stop();
    for (var controller in _sectionControllers) {
      controller.stop();
    }
  }

  @override
  void dispose() {
    print('🗑️ BanglaClassDetailsScreen disposing...');
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    for (var controller in _sectionControllers) {
      controller.dispose();
    }
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

  // UPDATED: Build instructor poster image with URL and Base64 support
  Widget _buildInstructorPosterImage({bool isLarge = false}) {
    final imageData = widget.banglaClass.postedByProfileImageBase64;
    
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
              print('Error loading instructor poster image: $error');
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
                print('Error decoding instructor poster image: $error');
                return _buildDefaultProfileImage(isLarge: isLarge);
              },
            ),
          );
        } catch (e) {
          print('Error processing instructor poster image: $e');
          return _buildDefaultProfileImage(isLarge: isLarge);
        }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isFull = banglaClass.enrolledStudents >= banglaClass.maxStudents;
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
              colors: [widget.lightOrange, _creamWhite, Colors.white],
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
                      colors: [widget.primaryOrange, widget.redAccent, _darkOrange],
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
                                    colors: [widget.goldAccent, widget.greenAccent, widget.goldAccent],
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
                                  banglaClass.instructorName,
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
                                banglaClass.organizationName ?? 'Independent Instructor',
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 18 : 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              if (banglaClass.isVerified) ...[
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
                                        'VERIFIED CLASS',
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
                      
                      // User Profile and Instructor Info
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
                              child: _buildInstructorPosterImage(isLarge: true),
                            ),
                          ),
                          
                          SizedBox(width: isTablet ? 20 : 16),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (banglaClass.postedByName != null && banglaClass.postedByName!.isNotEmpty)
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
                                        Flexible(
                                          child: Text(
                                            banglaClass.postedByName!,
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
                        shouldAnimate: shouldAnimate,
                        index: 0,
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
                          shouldAnimate: shouldAnimate,
                          index: 1,
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
                        shouldAnimate: shouldAnimate,
                        index: 2,
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
                        shouldAnimate: shouldAnimate,
                        index: 3,
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
                          shouldAnimate: shouldAnimate,
                          index: 4,
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
                          shouldAnimate: shouldAnimate,
                          index: 5,
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
                        shouldAnimate: shouldAnimate,
                        index: 6,
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
                        shouldAnimate: shouldAnimate,
                        index: 7,
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
                        shouldAnimate: shouldAnimate,
                        index: 8,
                      ),
                      
                      SizedBox(height: isTablet ? 40 : 32),
                      
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
                                child: shouldAnimate
                                    ? RotationTransition(
                                        turns: _animationController,
                                        child: Icon(
                                          Icons.language_rounded,
                                          color: Colors.white,
                                          size: isTablet ? 28 : 24,
                                        ),
                                      )
                                    : Icon(
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
    required bool shouldAnimate,
    required int index,
  }) {
    final Widget sectionContent = Column(
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
    
    if (!shouldAnimate || index >= _sectionControllers.length) {
      return sectionContent;
    }
    
    return FadeTransition(
      opacity: _sectionControllers[index],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _sectionControllers[index],
          curve: Curves.easeOut,
        )),
        child: sectionContent,
      ),
    );
  }

  Widget _buildPremiumDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isTablet,
  }) {
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 8 : 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: shouldAnimate
              ? RotationTransition(
                  turns: _animationController,
                  child: Icon(icon, color: color, size: isTablet ? 18 : 16),
                )
              : Icon(icon, color: color, size: isTablet ? 18 : 16),
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