import 'package:bangla_hub/models/user_model.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/screens/user_app/education_youth/admissions_guidance/admissions_guidance_screen.dart';
import 'package:bangla_hub/screens/user_app/education_youth/bangla_classes/bangla_classes_screen.dart';
import 'package:bangla_hub/screens/user_app/education_youth/sports_clubs/sports_clubs_screen.dart';
import 'package:bangla_hub/screens/user_app/education_youth/tutoring/tutoring_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class EducationScreen extends StatelessWidget {
  EducationScreen({Key? key}) : super(key: key);

  // Premium Color Palette - Education Theme
  final Color _primaryBlue = Color(0xFF1976D2);
  final Color _darkBlue = Color(0xFF0D47A1);
  final Color _lightBlue = Color(0xFFE3F2FD);
  final Color _softBlue = Color(0xFF64B5F6);
  final Color _offWhite = Color(0xFFF8F8F8);
  final Color _creamWhite = Color(0xFFFFF9E6);
  final Color _goldAccent = Color(0xFFFFD700);
  final Color _purpleAccent = Color(0xFF8E24AA);
  final Color _tealAccent = Color(0xFF00897B);
  final Color _textPrimary = Color(0xFF1A2B3C);
  final Color _textSecondary = Color(0xFF5D6D7E);
  final Color _shadowColor = Color(0x1A000000);
  
  // Light background for main content - pure white for better visibility
  final Color _mainContentBg = Color(0xFFFFFFFF);
  final Color _cardBg = Color(0xFFFFFFFF);
  
  // Gradient for header
  final LinearGradient _headerGradient = LinearGradient(
    colors: [
      Color(0xFF1976D2), // _primaryBlue
      Color(0xFF0D47A1), // _darkBlue
      Color(0xFF1565C0), // Medium blue
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ✅ Robust drawer opening method
  void _openDrawer(BuildContext context) {
    try {
      final ScaffoldState? scaffoldState = Scaffold.maybeOf(
        Navigator.of(context, rootNavigator: true).context
      );
      
      if (scaffoldState != null && scaffoldState.hasDrawer) {
        scaffoldState.openDrawer();
        return;
      }
      
      final ScaffoldState? currentScaffold = Scaffold.maybeOf(context);
      if (currentScaffold != null && currentScaffold.hasDrawer) {
        currentScaffold.openDrawer();
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Menu is available from the home screen'),
          duration: Duration(milliseconds: 800),
          backgroundColor: _primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('Could not open drawer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;
    final isSmallScreen = screenHeight < 700;
    
    // Get auth state to conditionally show drawer
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isLoggedIn = authProvider.isLoggedIn && authProvider.user != null;
    
    // Responsive sizes
    final double expandedHeight = isTablet ? 180 : (isSmallScreen ? 150 : 160);
    final double collapsedHeight = isTablet ? 70 : (isSmallScreen ? 56 : 60);
    final double titleFontSize = isTablet ? 32 : 26;
    final double subtitleFontSize = isTablet ? 16 : (isSmallScreen ? 13 : 14);
    final double horizontalPadding = isTablet ? 32 : 24;
    final double cardPadding = isTablet ? 20 : (isSmallScreen ? 14 : 16);
    final double iconContainerSize = isTablet ? 55 : (isSmallScreen ? 42 : 48);
    final double iconInnerSize = isTablet ? 26 : (isSmallScreen ? 20 : 22);
    
    return Container(
      color: _primaryBlue,
      child: CustomScrollView(
        slivers: [
          // Sliver App Bar with conditional drawer button
  
  /*        SliverAppBar(
            expandedHeight: expandedHeight,
            collapsedHeight: collapsedHeight,
            floating: false,
            pinned: true,
            snap: false,
            elevation: 0,
            backgroundColor: Colors.transparent,
            // ✅ ONLY show drawer button when user is logged in
            leading: isLoggedIn 
                ? IconButton(
                    icon: Icon(Icons.menu, color: Colors.white, size: isTablet ? 28 : 24),
                    onPressed: () => _openDrawer(context),
                  )
                : null, // Hide for guests
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: _headerGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(isTablet ? 30 : 24),
                    bottomRight: Radius.circular(isTablet ? 30 : 24),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: horizontalPadding,
                      right: horizontalPadding,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Education & Youth',
                          style: GoogleFonts.poppins(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 16,
                            vertical: isSmallScreen ? 6 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Learning, growth, and development',
                            style: GoogleFonts.poppins(
                              fontSize: subtitleFontSize,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

    */


SliverAppBar(
  expandedHeight: expandedHeight,
  collapsedHeight: collapsedHeight,
  floating: false,
  pinned: true,
  snap: false,
  elevation: 0,
  backgroundColor: Colors.transparent,
  // ✅ Back button (if needed) or menu button
  leading: isLoggedIn 
      ? IconButton(
          icon: Icon(Icons.menu, color: Colors.white, size: isTablet ? 28 : 24),
          onPressed: () => _openDrawer(context),
        )
      : IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white, size: isTablet ? 28 : 24),
          onPressed: () => Navigator.pop(context),
        ),
  // ✅ Logo on the right side
  actions: [
    Padding(
      padding: EdgeInsets.only(right: isTablet ? 16 : 12),
      child: Container(
        width: isTablet ? 44 : 36,
        height: isTablet ? 44 : 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _goldAccent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: _goldAccent.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/logo/logo.png',
            width: isTablet ? 40 : 32,
            height: isTablet ? 40 : 32,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.white.withOpacity(0.2),
                child: Center(
                  child: Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: isTablet ? 24 : 20,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  ],
  centerTitle: true,
  flexibleSpace: FlexibleSpaceBar(
    centerTitle: true,
    background: Container(
      decoration: BoxDecoration(
        gradient: _headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(isTablet ? 30 : 24),
          bottomRight: Radius.circular(isTablet ? 30 : 24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Education & Youth',
                style: GoogleFonts.poppins(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: isSmallScreen ? 8 : 12),
              
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Learning, growth, and development',
                  style: GoogleFonts.poppins(
                    fontSize: subtitleFontSize,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
),
   
   
          // Main Content
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: _mainContentBg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isTablet ? 40 : 30),
                  topRight: Radius.circular(isTablet ? 40 : 30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: isTablet ? 24 : 20,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryBlue, _softBlue],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Educational Opportunities',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 20 : 16,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 12 : 8,
                              vertical: isTablet ? 4 : 3,
                            ),
                            decoration: BoxDecoration(
                              color: _lightBlue,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '4 Features',
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 12 : 10,
                                fontWeight: FontWeight.w600,
                                color: _primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 1. Tutoring & Homework Help
                    _buildPremiumFeatureCard(
                      icon: Icons.school_rounded,
                      iconColor: _primaryBlue,
                      gradientColors: [_primaryBlue, _darkBlue],
                      title: 'Tutoring & Homework Help',
                      description: 'Academic support and subject tutoring',
                      badgeColor: _primaryBlue,
                      isTablet: isTablet,
                      isSmallScreen: isSmallScreen,
                      cardPadding: cardPadding,
                      iconContainerSize: iconContainerSize,
                      iconInnerSize: iconInnerSize,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TutoringScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    
                    // 2. School & College Admissions Guidance
                    _buildPremiumFeatureCard(
                      icon: Icons.business_center_rounded,
                      iconColor: Color(0xFF4CAF50),
                      gradientColors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      title: 'School & College Admissions Guidance',
                      description: 'Guidance for educational admissions',
                      badgeColor: Color(0xFF4CAF50),
                      isTablet: isTablet,
                      isSmallScreen: isSmallScreen,
                      cardPadding: cardPadding,
                      iconContainerSize: iconContainerSize,
                      iconInnerSize: iconInnerSize,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdmissionsGuidanceScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    
                    // 3. Bangla Language & Culture Classes
                    _buildPremiumFeatureCard(
                      icon: Icons.language_rounded,
                      iconColor: Color(0xFFFF9800),
                      gradientColors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                      title: 'Bangla Language & Culture Classes',
                      description: 'Learn Bengali language and culture',
                      badgeColor: Color(0xFFFF9800),
                      isTablet: isTablet,
                      isSmallScreen: isSmallScreen,
                      cardPadding: cardPadding,
                      iconContainerSize: iconContainerSize,
                      iconInnerSize: iconInnerSize,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BanglaClassesScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    
                    // 4. Local Sports Clubs
                    _buildPremiumFeatureCard(
                      icon: Icons.sports_rounded,
                      iconColor: Color(0xFFF44336),
                      gradientColors: [Color(0xFFF44336), Color(0xFFD32F2F)],
                      title: 'Local Sports Clubs',
                      description: 'Cricket, Soccer, and sports activities',
                      badgeColor: Color(0xFFF44336),
                      isTablet: isTablet,
                      isSmallScreen: isSmallScreen,
                      cardPadding: cardPadding,
                      iconContainerSize: iconContainerSize,
                      iconInnerSize: iconInnerSize,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SportsClubsScreen(),
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: isSmallScreen ? 40 : 35),
                    
                    // Premium Footer - Information Section
                    Container(
                      padding: EdgeInsets.all(cardPadding),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_lightBlue, _creamWhite],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                        border: Border.all(
                          color: _primaryBlue.withOpacity(0.15),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: isTablet ? 50 : 42,
                                height: isTablet ? 50 : 42,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryBlue, _darkBlue],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryBlue.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.info_rounded,
                                    color: Colors.white,
                                    size: isTablet ? 24 : 20,
                                  ),
                                ),
                              ),
                              SizedBox(width: isTablet ? 16 : 12),
                              Expanded(
                                child: Text(
                                  'Important Information',
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 16 : 14,
                                    fontWeight: FontWeight.w700,
                                    color: _primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 12 : 8),
                          Text(
                            'All educational services are provided by verified professionals from the Bengali community. New listings require admin approval before being visible.',
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 13 : (isSmallScreen ? 11 : 12),
                              color: _textSecondary,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: isTablet ? 12 : 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              _buildInfoBullet('Verified tutors and instructors', isTablet, isSmallScreen),
                              _buildInfoBullet('Background checked professionals', isTablet, isSmallScreen),
                              _buildInfoBullet('Competitive rates and packages', isTablet, isSmallScreen),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 30 : 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeatureCard({
    required IconData icon,
    required Color iconColor,
    required List<Color> gradientColors,
    required String title,
    required String description,
    required Color badgeColor,
    required bool isTablet,
    required bool isSmallScreen,
    required double cardPadding,
    required double iconContainerSize,
    required double iconInnerSize,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
          gradient: LinearGradient(
            colors: [_lightBlue, _creamWhite],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: _primaryBlue.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: gradientColors.first.withOpacity(0.05),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
            splashColor: gradientColors.first.withOpacity(0.05),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Row(
                children: [
                  // Icon Container with Gradient
                  Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors.first.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: iconInnerSize,
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 16 : (isSmallScreen ? 14 : 15),
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 13 : (isSmallScreen ? 11 : 12),
                            color: _textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow Icon
                  Container(
                    width: isTablet ? 36 : 28,
                    height: isTablet ? 36 : 28,
                    decoration: BoxDecoration(
                      color: gradientColors.first.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: gradientColors.first,
                        size: isTablet ? 18 : 15,
                      ),
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

  Widget _buildInfoBullet(String text, bool isTablet, bool isSmallScreen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: _primaryBlue,
          size: isTablet ? 16 : 14,
        ),
        SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 13 : (isSmallScreen ? 11 : 12),
            color: _textSecondary,
          ),
        ),
      ],
    );
  }
}