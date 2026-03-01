import 'package:bangla_hub/models/user_model.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/screens/admin_app/screens/business_management/business_management_screen.dart';
import 'package:bangla_hub/screens/admin_app/screens/community_service_management/service_management_screen.dart';
import 'package:bangla_hub/screens/admin_app/screens/dashboard/admin_dashboard_screen.dart';
import 'package:bangla_hub/screens/admin_app/screens/education_dashboard/education_dashboard_screen.dart';
import 'package:bangla_hub/screens/admin_app/screens/event_management/event_management_screen.dart';
import 'package:bangla_hub/screens/admin_app/screens/job_management/job_management_screen.dart';
import 'package:bangla_hub/screens/admin_app/screens/user_management/user_management_screen.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();

  // Navigation items with screens
  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.dashboard_outlined,
      'label': 'Dashboard',
      'color': Color(0xFFE03C32),
      'screen': AdminDashboardScreen(),
    },
  /*  {
      'icon': Icons.people_outline,
      'label': 'Users',
      'color': Color(0xFF2196F3),
      'screen': AdminUsersScreen(),
    },  */

        {
      'icon': Icons.diversity_3_outlined,
      'label': 'Community',
      'color': Color(0xFF2196F3),
      'screen': ServiceManagementScreen(),
    },

    {
      'icon': Icons.event_outlined,
      'label': 'Events',
      'color': Color(0xFF9C27B0),
      'screen': AdminEventsScreen(),
    },
    {
      'icon': Icons.business_outlined,
      'label': 'Businesses',
      'color': Color(0xFF4CAF50),
      'screen': AdminEntrepreneurshipDashboard(),
    },
    {
      'icon': Icons.work_outlined,
      'label': 'Education',
      'color': Color(0xFFFF9800),
      'screen': AdminEducationDashboard(),
    },
  ];

  // Premium Color Palette
  final Color _primaryRed = Color(0xFFE03C32);
  final Color _primaryGreen = Color(0xFF006A4E);
  final Color _darkGreen = Color(0xFF00432D);
  final Color _goldAccent = Color(0xFFFFD700);
  final Color _bgGradient1 = Color(0xFF0A2F1D);
  final Color _bgGradient2 = Color(0xFF004D38);
  final Color _cardColor = Color(0x1AFFFFFF);
  final Color _borderColor = Color(0x33FFFFFF);
  final Color _textWhite = Color(0xFFFFFFFF);
  final Color _textLight = Color(0xFFE0E0E0);
  final Color _textMuted = Color(0xFFAAAAAA);
  final Color _offWhite = Color(0xFFF8F8F8);
  final Color _surfaceColor = Color(0xFFF5F7FA);

  // Get current screen title
  String get _currentTitle {
    return _navItems[_selectedIndex]['label'];
  }

  Future<void> _handlePremiumLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_bgGradient2, _primaryRed.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: _borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryRed, _darkGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryRed.withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Confirm Logout',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _textWhite,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Are you sure you want to logout from admin panel?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _textLight,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderColor),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                color: _textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          try {
                            await authProvider.signOut();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => LoginScreen()),
                              (route) => false,
                            );
                          } catch (e) {
                            _showPremiumSnackBar('Logout failed: $e', _primaryRed);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryRed, _darkGreen],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryRed.withOpacity(0.4),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
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

  void _showPremiumSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
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
                color == _primaryGreen ? Icons.check_circle_rounded : Icons.error_rounded,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.zero,
      ),
    );
  }

  // Build Sliver App Bar for Dashboard screen
  Widget _buildSliverAppBar(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final UserModel? adminUser = authProvider.user;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: isTablet ? 280 : 240,
      floating: false,
      pinned: true,
      snap: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _primaryGreen.withOpacity(0.95),
                _primaryRed.withOpacity(0.15),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 24,
                vertical: 20,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Section
                  Row(
                    children: [
                      Container(
                        width: isTablet ? 70 : 60,
                        height: isTablet ? 70 : 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryRed, _primaryGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(isTablet ? 20 : 15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: isTablet ? 32 : 28,
                        ),
                      ),
                      SizedBox(width: isTablet ? 20 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Panel',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 28 : 24,
                                fontWeight: FontWeight.w800,
                                color: _textWhite,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Premium Management System',
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 14 : 12,
                                color: _textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Welcome Section
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 16 : 14,
                                color: _textLight,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              adminUser?.fullName ?? 'Administrator',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 26 : 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              adminUser?.email ?? 'admin@banglahub.com',
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 14 : 12,
                                color: _textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _handlePremiumLogout,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: isTablet ? 56 : 48,
                            height: isTablet ? 56 : 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryRed, _darkGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
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
                            child: Center(
                              child: Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                                size: isTablet ? 24 : 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _surfaceColor,
        body: Stack(
          children: [
            // Show different screens based on selection
            _selectedIndex == 0
                ? CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      _buildSliverAppBar(context),
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _offWhite,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(isTablet ? 40 : 30),
                              topRight: Radius.circular(isTablet ? 40 : 30),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(isTablet ? 40 : 30),
                              topRight: Radius.circular(isTablet ? 40 : 30),
                            ),
                            child: _navItems[_selectedIndex]['screen'],
                          ),
                        ),
                      ),
                    ],
                  )
                : _navItems[_selectedIndex]['screen'],
          ],
        ),
        bottomNavigationBar: _buildPremiumBottomNavBar(isTablet),
      ),
    );
  }

  Widget _buildPremiumBottomNavBar(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryGreen, _darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 32 : 20,
            vertical: isTablet ? 12 : 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = _selectedIndex == index;
              
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 14 : 12,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [item['color'].withOpacity(0.3), item['color'].withOpacity(0.1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(color: item['color'].withOpacity(0.4))
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item['icon'],
                            color: isSelected ? Colors.white : _textLight,
                            size: isTablet ? 22 : 18,
                          ),
                          SizedBox(height: 4),
                          Text(
                            item['label'],
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 12 : 10,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : _textLight,
                            ),
                          ),
                          if (isSelected)
                            Container(
                              margin: EdgeInsets.only(top: 4),
                              width: 6,
                              height: 3,
                              decoration: BoxDecoration(
                                color: _goldAccent,
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}