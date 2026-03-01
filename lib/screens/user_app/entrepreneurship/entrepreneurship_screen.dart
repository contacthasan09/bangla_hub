// Updated EntrepreneurshipScreen.dart without Scaffold
import 'package:bangla_hub/models/user_model.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/business_partner_request/business_partner_requests_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/job_posting/job_postings_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/networing_partner/networking_partners_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/others_job_sites/others_job_sites_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/small_business_promotion/small_business_promotion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class EntrepreneurshipScreen extends StatelessWidget {
  // Remove drawer parameters completely
   EntrepreneurshipScreen({Key? key}) : super(key: key);

  // Premium Color Palette
  final Color _primaryGreen = Color(0xFF006A4E);
  final Color _darkGreen = Color(0xFF004D38);
  final Color _lightGreen = Color(0xFFE8F5E9);
  final Color _softGreen = Color(0xFF98D8C8);
  final Color _offWhite = Color(0xFFF8F8F8);
  final Color _creamWhite = Color(0xFFFFF9E6);
  final Color _goldAccent = Color(0xFFFFD700);
  final Color _softGold = Color(0xFFFFD966);
  final Color _coralRed = Color(0xFFFF6B6B);
  final Color _primaryRed = Color(0xFFF42A41);
  final Color _deepRed = Color(0xFFC62828);
  final Color _charcoal = Color(0xFF2C3E50);
  final Color _textPrimary = Color(0xFF1A2B3C);
  final Color _textSecondary = Color(0xFF5D6D7E);
  final Color _shadowColor = Color(0x1A000000);
  
  // Gradient for header
  final LinearGradient _headerGradient = LinearGradient(
    colors: [
      Color(0xFF006A4E), // _primaryGreen
      Color(0xFF004D38), // _darkGreen
      Color(0xFF2E7D32), // Darker green
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

  // Method to open drawer using the parent Scaffold
  void _openDrawer(BuildContext context) {
    // Try to find the parent Scaffold and open its drawer
    final ScaffoldState? scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.hasDrawer) {
      scaffoldState.openDrawer();
    } else {
      // Fallback - try using the root navigator's context
      try {
        final BuildContext? rootContext = Navigator.of(context, rootNavigator: true).context;
        final ScaffoldState? rootScaffold = Scaffold.maybeOf(rootContext!);
        if (rootScaffold != null && rootScaffold.hasDrawer) {
          rootScaffold.openDrawer();
        } else {
          // Show a snackbar to inform user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening menu...'),
              duration: Duration(milliseconds: 500),
              backgroundColor: _primaryGreen,
            ),
          );
        }
      } catch (e) {
        print('Could not open drawer: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Menu not available'),
            duration: Duration(seconds: 1),
            backgroundColor: _primaryGreen,
          ),
        );
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
      color: _primaryGreen,
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
                            'Business',
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
                                      'Business & Entrepreneurship',
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
                                      'Empowering Bengali entrepreneurs',
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
                                colors: [_primaryGreen, _softGreen],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Business Opportunities',
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
                              color: _lightGreen,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '5 Features',
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 14 : 12,
                                fontWeight: FontWeight.w600,
                                color: _primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 1. Networking Business Partners - Premium Card
                    _buildPremiumFeatureCard(
                      icon: Icons.store_rounded,
                      iconColor: _primaryGreen,
                      gradientColors: [_primaryGreen, _darkGreen],
                      title: 'Networking Business Partners',
                      description: 'Directory of Bengali-owned businesses ready to connect',
                    //  badgeText: 'Network',
                      badgeColor: _primaryGreen,
                      isTablet: isTablet,
                      isSmallScreen: isSmallScreen,
                      cardPadding: cardPadding,
                      iconContainerSize: iconContainerSize,
                      iconInnerSize: iconInnerSize,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NetworkingPartnersScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    
                    // 2. Job Postings - Premium Card
                    _buildPremiumFeatureCard(
                      icon: Icons.monetization_on_rounded,
                      iconColor: _coralRed,
                      gradientColors: [_coralRed, _deepRed],
                      title: 'Job Postings',
                      description: 'Find job opportunities in Bengali-owned businesses',
                    //  badgeText: 'Hiring',
                      badgeColor: _coralRed,
                      isTablet: isTablet,
                      isSmallScreen: isSmallScreen,
                      cardPadding: cardPadding,
                      iconContainerSize: iconContainerSize,
                      iconInnerSize: iconInnerSize,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JobPostingsScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    
                    // 3. Small Business Promotion - Premium Card
                    _buildPremiumFeatureCard(
                      icon: Icons.school_rounded,
                      iconColor: _softGold,
                      gradientColors: [_softGold, _goldAccent],
                      title: 'Small Business Promotion',
                      description: 'Promote your small business to the community',
                    //  badgeText: 'Promote',
                      badgeColor: _goldAccent,
                      isTablet: isTablet,
                      isSmallScreen: isSmallScreen,
                      cardPadding: cardPadding,
                      iconContainerSize: iconContainerSize,
                      iconInnerSize: iconInnerSize,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SmallBusinessPromotionScreen(),
                          ),
                        );
                      },  
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    
                    // 4. Looking for Business Partner - Premium Card
                    _buildPremiumFeatureCard(
                      icon: Icons.network_check_rounded,
                      iconColor: _softGreen,
                      gradientColors: [_softGreen, _primaryGreen],
                      title: 'Find Business Partners',
                      description: 'Connect with collaborators and co-founders',
                    //  badgeText: 'Partner',
                      badgeColor: _softGreen,
                      isTablet: isTablet,
                      isSmallScreen: isSmallScreen,
                      cardPadding: cardPadding,
                      iconContainerSize: iconContainerSize,
                      iconInnerSize: iconInnerSize,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BusinessPartnerRequestsScreen(),
                          ),
                        );
                      },  
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    
                    // 5. Other Job Sites - Premium Card
                    _buildPremiumFeatureCard(
                      icon: Icons.work_outline_rounded,
                      iconColor: _charcoal,
                      gradientColors: [_charcoal, Color(0xFF1A2B3C)],
                      title: 'Other Job Sites',
                      description: 'Explore external job platforms and opportunities',
                    //  badgeText: 'External',
                      badgeColor: _charcoal,
                      isTablet: isTablet,
                      isSmallScreen: isSmallScreen,
                      cardPadding: cardPadding,
                      iconContainerSize: iconContainerSize,
                      iconInnerSize: iconInnerSize,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OthersJobSitesScreen(),
                          ),
                        );
                      },  
                    ),
                    
                    SizedBox(height: isTablet ? 40 : 32),
                    
                    // Premium Footer
                    Container(
                      padding: EdgeInsets.all(cardPadding),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_lightGreen, _creamWhite],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(isTablet ? 30 : 24),
                        border: Border.all(
                          color: _primaryGreen.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: isTablet ? 60 : 48,
                            height: isTablet ? 60 : 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryGreen, _darkGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryGreen.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.lightbulb_rounded,
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
                                  'More Features Coming Soon',
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 18 : 16,
                                    fontWeight: FontWeight.w700,
                                    color: _primaryGreen,
                                  ),
                                ),
                                SizedBox(height: isTablet ? 6 : 4),
                                Text(
                                  'We\'re developing more resources for the Bengali community',
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
                            ),*/
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
}