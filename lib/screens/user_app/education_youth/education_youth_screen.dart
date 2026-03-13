import 'package:bangla_hub/models/user_model.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/business_partner_request/business_partner_requests_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/job_posting/job_postings_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/networing_partner/networking_partners_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/others_job_sites/others_job_sites_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/small_business_promotion/small_business_promotion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bangla_hub/main.dart'; // Import for navigatorKey

class EntrepreneurshipScreen extends StatelessWidget {
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
  
  // Light background for main content
  final Color _mainContentBg = Color(0xFFFFFFFF);
  final Color _cardBg = Color(0xFFFFFFFF);
  final Color _sectionBg = Color(0xFFFAFAFA);
  
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
          backgroundColor: _primaryGreen,
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

  // ✅ FIXED: Proper logout method for drawer with safety
  Future<void> _handleLogoutFromDrawer(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    BuildContext? dialogContext;

    // Show loading dialog with safety
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogContext = context;
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryGreen, _primaryRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Logging out...',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      await authProvider.signOut();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_tab_index');
      print('📊 Cleared saved tab index on logout');

      // Safety timeout - force close dialog after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (dialogContext != null && Navigator.canPop(dialogContext!)) {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        }
      });

      // Close dialog if it's still open
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      }

      // Navigate using global navigator key
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );

    } catch (e) {
      // Close dialog on error
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: _primaryRed,
        ),
      );
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
      color: _primaryGreen,
      child: CustomScrollView(
        slivers: [
          // Sliver App Bar with conditional drawer button
          SliverAppBar(
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
                          'Entrepreneurship',
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
                            'Empowering Bengali entrepreneurs',
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
                      padding: EdgeInsets.only(left: 8, bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: isTablet ? 24 : 20,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryGreen, _softGreen],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Business Opportunities',
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
                              color: _lightGreen,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '5 Features',
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 12 : 10,
                                fontWeight: FontWeight.w600,
                                color: _primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 1. Networking Business Partners
                    _buildPremiumFeatureCard(
                      icon: Icons.store_rounded,
                      iconColor: _primaryGreen,
                      gradientColors: [_primaryGreen, _darkGreen],
                      title: 'Networking Business Partners',
                      description: 'Directory of Bengali-owned businesses ready to connect',
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
                    
                    // 2. Job Postings
                    _buildPremiumFeatureCard(
                      icon: Icons.monetization_on_rounded,
                      iconColor: _coralRed,
                      gradientColors: [_coralRed, _deepRed],
                      title: 'Job Postings',
                      description: 'Find job opportunities in Bengali-owned businesses',
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
                    
                    // 3. Small Business Promotion
                    _buildPremiumFeatureCard(
                      icon: Icons.school_rounded,
                      iconColor: _softGold,
                      gradientColors: [_softGold, _goldAccent],
                      title: 'Small Business Promotion',
                      description: 'Promote your small business to the community',
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
                    
                    // 4. Find Business Partners
                    _buildPremiumFeatureCard(
                      icon: Icons.network_check_rounded,
                      iconColor: _softGreen,
                      gradientColors: [_softGreen, _primaryGreen],
                      title: 'Find Business Partners',
                      description: 'Connect with collaborators and co-founders',
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
                    
                    // 5. Other Job Sites
                    _buildPremiumFeatureCard(
                      icon: Icons.work_outline_rounded,
                      iconColor: _charcoal,
                      gradientColors: [_charcoal, Color(0xFF1A2B3C)],
                      title: 'Other Job Sites',
                      description: 'Explore external job platforms and opportunities',
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
                    
                    SizedBox(height: isTablet ? 40 : 35),
                    
                    // Premium Footer
                    Container(
                      padding: EdgeInsets.all(cardPadding),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_lightGreen, _creamWhite],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                        border: Border.all(
                          color: _primaryGreen.withOpacity(0.15),
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
                      child: Row(
                        children: [
                          Container(
                            width: isTablet ? 50 : 42,
                            height: isTablet ? 50 : 42,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryGreen, _darkGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryGreen.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.lightbulb_rounded,
                                color: Colors.white,
                                size: isTablet ? 24 : 20,
                              ),
                            ),
                          ),
                          SizedBox(width: isTablet ? 16 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Supporting Bengali Entrepreneurs',
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 16 : 14,
                                    fontWeight: FontWeight.w700,
                                    color: _primaryGreen,
                                  ),
                                ),
                                SizedBox(height: isTablet ? 4 : 2),
                                Text(
                                  'Connect with verified business owners and find opportunities in your community',
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 12 : 11,
                                    color: _textSecondary,
                                  ),
                                ),
                              ],
                            ),
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
            colors: [_lightGreen, _creamWhite],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: gradientColors.first.withOpacity(0.08),
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
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
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
                      color: gradientColors.first.withOpacity(0.1),
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
}