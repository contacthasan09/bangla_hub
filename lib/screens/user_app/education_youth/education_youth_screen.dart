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
  // Remove drawer parameters completely
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
  
  // Gradient for header (keeping the same blue gradient)
  final LinearGradient _headerGradient = LinearGradient(
    colors: [
      Color(0xFF1976D2), // _primaryBlue
      Color(0xFF0D47A1), // _darkBlue
      Color(0xFF1565C0), // Medium blue
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradient for feature cards
  final LinearGradient _cardGradient = LinearGradient(
    colors: [
      Colors.white,
      Color(0xFFFDF8F2), // Cream white
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Method to open drawer using the global key from HomeScreen
  void _openDrawer(BuildContext context) {
    // Try to find the parent Scaffold and open its drawer
    final ScaffoldState? scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.hasDrawer) {
      scaffoldState.openDrawer();
    } else {
      // If direct access fails, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening menu...'),
          duration: Duration(milliseconds: 500),
          backgroundColor: _primaryBlue,
        ),
      );
      // Fallback: Try to use the root Navigator to find the scaffold
      try {
        // This is a hack, but might work in some cases
        final ScaffoldState? rootScaffold = Scaffold.maybeOf(
          Navigator.of(context, rootNavigator: true).context
        );
        rootScaffold?.openDrawer();
      } catch (e) {
        print('Could not open drawer: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;
    final isSmallScreen = screenHeight < 700;
    
    // Responsive sizes
    final double expandedHeight = isTablet ? 220 : (isSmallScreen ? 160 : 200);
    final double collapsedHeight = isTablet ? 120 : (isSmallScreen ? 90 : 100);
    final double titleFontSize = isTablet ? 32 : (isSmallScreen ? 22 : 26);
    final double collapsedTitleFontSize = isTablet ? 20 : (isSmallScreen ? 16 : 18);
    final double subtitleFontSize = isTablet ? 16 : (isSmallScreen ? 12 : 14);
    final double horizontalPadding = isTablet ? 32 : 24;
    final double cardPadding = isTablet ? 24 : (isSmallScreen ? 16 : 20);
    final double iconContainerSize = isTablet ? 60 : (isSmallScreen ? 45 : 50);
    final double iconInnerSize = isTablet ? 28 : (isSmallScreen ? 22 : 24);
    
    // Return a Container instead of Scaffold
    // This allows the parent Scaffold's drawer to work
    return Container(
      color: _primaryBlue,
      child: CustomScrollView(
        slivers: [
          // Sliver App Bar with Menu Button
          SliverAppBar(
            expandedHeight: expandedHeight,
            collapsedHeight: collapsedHeight,
            floating: false,
            pinned: true,
            snap: false,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () => _openDrawer(context),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate if we're expanded or collapsed
                final double availableHeight = constraints.biggest.height;
                final bool isCollapsed = availableHeight <= collapsedHeight + 10;
                
                return FlexibleSpaceBar(
                  titlePadding: EdgeInsets.zero,
                  // Only show title in collapsed state
                  title: isCollapsed 
                      ? Container(
                          padding: EdgeInsets.only(
                            left: horizontalPadding,
                            bottom: 12,
                          ),
                          child: Text(
                            'Education & Youth',
                            style: GoogleFonts.poppins(
                              fontSize: collapsedTitleFontSize,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null, // No title when expanded, we show full header in background
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: _headerGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(isTablet ? 40 : 30),
                        bottomRight: Radius.circular(isTablet ? 40 : 30),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: horizontalPadding,
                          right: horizontalPadding,
                          top: kToolbarHeight + (isSmallScreen ? 10 : 16),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Main Title - Only visible when expanded
                                if (!isCollapsed) ...[
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Education & Youth',
                                      style: GoogleFonts.poppins(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 4 : 8),
                                  
                                  // Subtitle - Only visible when expanded
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 10 : 12,
                                      vertical: isSmallScreen ? 4 : 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.25),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'Learning, growth, and development',
                                      style: GoogleFonts.inter(
                                        fontSize: subtitleFontSize,
                                        color: Colors.white.withOpacity(0.95),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  // Add a small bottom padding to ensure no overflow
                                  SizedBox(height: isSmallScreen ? 8 : 12),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Main Content
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: _offWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isTablet ? 50 : 40),
                  topRight: Radius.circular(isTablet ? 50 : 40),
                ),
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
                            height: isTablet ? 28 : 24,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryBlue, _softBlue],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Educational Opportunities',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 22 : 18,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 14 : 10,
                              vertical: isTablet ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: _lightBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '4 Features',
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 14 : 12,
                                fontWeight: FontWeight.w600,
                                color: _primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 1. Tutoring & Homework Help - Premium Card
                    _buildPremiumFeatureCard(
                      icon: Icons.school_rounded,
                      iconColor: _primaryBlue,
                      gradientColors: [_primaryBlue, _darkBlue],
                      title: 'Tutoring & Homework Help',
                      description: 'Academic support and subject tutoring',
                  //    badgeText: 'Tutors',
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
                    
                    // 2. School & College Admissions Guidance - Premium Card
                    _buildPremiumFeatureCard(
                      icon: Icons.business_center_rounded,
                      iconColor: Color(0xFF4CAF50),
                      gradientColors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      title: 'School & College Admissions Guidance',
                      description: 'Guidance for educational admissions',
                  //    badgeText: 'Guidance',
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
                    
                    // 3. Bangla Language & Culture Classes - Premium Card
                    _buildPremiumFeatureCard(
                      icon: Icons.language_rounded,
                      iconColor: Color(0xFFFF9800),
                      gradientColors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                      title: 'Bangla Language & Culture Classes',
                      description: 'Learn Bengali language and culture',
                  //    badgeText: 'Language',
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
                    
                    // 4. Local Sports - Premium Card
                    _buildPremiumFeatureCard(
                      icon: Icons.sports_rounded,
                      iconColor: Color(0xFFF44336),
                      gradientColors: [Color(0xFFF44336), Color(0xFFD32F2F)],
                      title: 'Local Sports Clubs',
                      description: 'Cricket, Soccer, and sports activities',
                   //   badgeText: 'Sports',
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
                    
                    SizedBox(height: isTablet ? 40 : 32),
                    
                    // Premium Footer - Information Section
                    Container(
                      padding: EdgeInsets.all(cardPadding),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_lightBlue, _creamWhite],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(isTablet ? 30 : 24),
                        border: Border.all(
                          color: _primaryBlue.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: isTablet ? 60 : 48,
                                height: isTablet ? 60 : 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryBlue, _darkBlue],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryBlue.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.info_rounded,
                                    color: Colors.white,
                                    size: isTablet ? 28 : 24,
                                  ),
                                ),
                              ),
                              SizedBox(width: isTablet ? 20 : 16),
                              Expanded(
                                child: Text(
                                  'Important Information',
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 18 : 16,
                                    fontWeight: FontWeight.w700,
                                    color: _primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 16 : 12),
                          Text(
                            'All educational services are provided by verified professionals from the Bengali community. New listings require admin approval before being visible.',
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 15 : (isSmallScreen ? 12 : 14),
                              color: _textSecondary,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: isTablet ? 16 : 12),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _buildInfoBullet('Verified tutors and instructors', isTablet, isSmallScreen),
                              _buildInfoBullet('Background checked professionals', isTablet, isSmallScreen),
                              _buildInfoBullet('Competitive rates and packages', isTablet, isSmallScreen),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 40 : 30),
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
  //  required String badgeText,
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
          borderRadius: BorderRadius.circular(isTablet ? 30 : 24),
          gradient: _cardGradient,
          boxShadow: [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 15,
              offset: Offset(0, 8),
              spreadRadius: -5,
            ),
            BoxShadow(
              color: gradientColors.first.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 5),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(isTablet ? 30 : 24),
            splashColor: gradientColors.first.withOpacity(0.1),
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
                      borderRadius: BorderRadius.circular(isTablet ? 20 : 18),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors.first.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 5),
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
                  SizedBox(width: isTablet ? 20 : 16),
                  
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
                                  fontSize: isTablet ? 18 : (isSmallScreen ? 14 : 16),
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          /*  SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 10 : 8,
                                vertical: isTablet ? 6 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: badgeColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                badgeText,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 12 : (isSmallScreen ? 9 : 10),
                                  fontWeight: FontWeight.w700,
                                  color: badgeColor,
                                ),
                              ),
                            ), */
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 15 : (isSmallScreen ? 12 : 14),
                            color: _textSecondary,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow Icon
                  Container(
                    width: isTablet ? 40 : 32,
                    height: isTablet ? 40 : 32,
                    decoration: BoxDecoration(
                      color: gradientColors.first.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: gradientColors.first,
                        size: isTablet ? 22 : 18,
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
          size: isTablet ? 18 : 16,
        ),
        SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 14 : (isSmallScreen ? 11 : 13),
            color: _textSecondary,
          ),
        ),
      ],
    );
  }
}