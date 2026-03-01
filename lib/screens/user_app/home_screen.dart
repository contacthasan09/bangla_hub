import 'dart:async';
import 'dart:convert';

import 'package:bangla_hub/models/user_model.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/user_app/community_services/community_services_list_screen.dart';
import 'package:bangla_hub/screens/user_app/education_youth/education_youth_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/entrepreneurship_screen.dart';
import 'package:bangla_hub/screens/user_app/event/events_screen.dart';
import 'package:bangla_hub/screens/user_app/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Global key for drawer
final GlobalKey<ScaffoldState> homeScaffoldKey = GlobalKey<ScaffoldState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  
  // Color scheme
  final Color _primaryRed = Color(0xFFF42A41);
  final Color _primaryGreen = Color(0xFF006A4E);
  final Color _darkGreen = Color(0xFF004D38);
  final Color _goldAccent = Color(0xFFFFD700);
  final Color _offWhite = Color(0xFFF8F8F8);
  
  // Stream controllers for better performance
  late StreamController<UserModel?> _userStreamController;
  
  // Screens for each navigation item
  late final List<Widget> _screens;
  
  // Navigation items data
  final List<NavItem> _navItems = [
    NavItem(icon: Icons.event_rounded, label: 'Events'),
    NavItem(icon: Icons.people_rounded, label: 'Services'),
    NavItem(icon: Icons.business_rounded, label: 'Business'),
    NavItem(icon: Icons.school_rounded, label: 'Education'),
    NavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    
    print('🔄 HomeScreen initState called');
    
    // Initialize stream controllers
    _userStreamController = StreamController<UserModel?>.broadcast();
    
    // Initialize screens
    _screens = [
      EventsScreen(),
      CommunityServicesListScreen(),
      EntrepreneurshipScreen(),
      EducationScreen(),
      PremiumSettingsScreen(),
    ];
    
    // Initialize data
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    print('📊 Initializing HomeScreen data');
    
    // Initialize user data stream
    final authProvider = context.read<AuthProvider>();
    _userStreamController.add(authProvider.user);
    print('👤 User data initialized: ${authProvider.user?.email}');
  }
  
  @override
  void dispose() {
    print('🗑️ HomeScreen disposing...');
    _userStreamController.close();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    final parentContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout from BanglaHub?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                showDialog(
                  context: parentContext,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: CircularProgressIndicator(
                      color: _primaryGreen,
                    ),
                  ),
                );
                
                await authProvider.signOut();
                
                Navigator.of(parentContext, rootNavigator: true).pop();
                
                Navigator.pushAndRemoveUntil(
                  parentContext,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
                
              } catch (e) {
                if (Navigator.canPop(parentContext)) {
                  Navigator.of(parentContext, rootNavigator: true).pop();
                }
                
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text('Logout failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to open drawer from anywhere
  void _openDrawer() {
    homeScaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building HomeScreen, screen size: ${MediaQuery.of(context).size}');
    
    return StreamBuilder<UserModel?>(
      stream: _userStreamController.stream,
      initialData: context.watch<AuthProvider>().user,
      builder: (context, userSnapshot) {
        final currentUser = userSnapshot.data;
        print('👤 StreamBuilder - User: ${currentUser?.email ?? "No user"}');
        
        return Scaffold(
          key: homeScaffoldKey, // Use the global key
          backgroundColor: _offWhite,
          drawer: _buildDrawer(currentUser),
          body: _buildBodyWithDrawerAccess(),
          bottomNavigationBar: _buildPremiumBottomNavBar(),
        );
      },
    );
  }

  // Build body with drawer access for all screens
  Widget _buildBodyWithDrawerAccess() {
    // Pass the open drawer function to screens that need it
    Widget currentScreen = _screens[_selectedIndex];
    
    // Wrap screens that need drawer access with a provider or pass as parameter
    if (_selectedIndex == 2 || _selectedIndex == 3) {
      // For Business and Education screens, wrap with a container that has access to drawer
      return Stack(
        children: [
          currentScreen,
          // Invisible drawer opener for screens that need it
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              color: Colors.transparent,
            ),
          ),
        ],
      );
    }
    
    return currentScreen;
  }

  // Drawer builder
  Widget _buildDrawer(UserModel? currentUser) {
    final screenSize = MediaQuery.of(context).size;
    final drawerWidth = min(screenSize.width * 0.6, 280.0);

    print('📐 Building drawer, width: $drawerWidth, screen width: ${screenSize.width}');
    
    return Drawer(
      width: drawerWidth,
      child: Container(
        decoration: BoxDecoration(
          color: _offWhite,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Drawer Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryGreen, _darkGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipOval(
                        child: _getProfileImage(currentUser, 60),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser?.fullName ?? "Guest",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            currentUser?.email ?? "",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (currentUser?.isAdmin ?? false)
                            Container(
                              margin: EdgeInsets.only(top: 6),
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _goldAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _goldAccent),
                              ),
                              child: Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _goldAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Drawer Menu Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ..._navItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _buildDrawerItem(
                        icon: item.icon,
                        title: item.label,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                      );
                    }).toList(),
                    Divider(
                      indent: 20,
                      endIndent: 20,
                      height: 30,
                    ),
                    _buildDrawerItem(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      color: _primaryRed,
                      onTap: () {
                        Navigator.pop(context);
                        _handleLogout();
                      },
                    ),
                  ],
                ),
              ),
              
              // App Info
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'BanglaHub v1.0.0',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '© 2026 BanglaHub. All rights reserved.',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getProfileImage(UserModel? currentUser, double size) {
    if (currentUser?.profileImageUrl == null || 
        currentUser!.profileImageUrl!.isEmpty) {
      return _buildDefaultProfileAvatar(size);
    }
    
    final imageUrl = currentUser.profileImageUrl!;
    
    if (imageUrl.startsWith('data:image/')) {
      try {
        final base64Data = imageUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image(
          image: MemoryImage(bytes),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error loading base64 image: $error');
            return _buildDefaultProfileAvatar(size);
          },
        );
      } catch (e) {
        print('❌ Error decoding base64 image: $e');
        return _buildDefaultProfileAvatar(size);
      }
    }
    
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ Error loading network image: $error');
        return _buildDefaultProfileAvatar(size);
      },
    );
  }

  Widget _buildDefaultProfileAvatar(double size) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryGreen, _darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? _darkGreen,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color ?? Colors.grey[800],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey[400],
        size: 24,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      onTap: onTap,
    );
  }
  
  Widget _buildPremiumBottomNavBar() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryGreen,
            _darkGreen,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 25,
            offset: Offset(0, -5),
            spreadRadius: 5,
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: isSmallScreen ? 72 : 80,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Events (index 0)
              _buildNavItem(
                index: 0,
                icon: Icons.event_rounded,
                label: 'Events',
                isSmallScreen: isSmallScreen,
              ),
              
              // Community Services (index 1)
              _buildNavItem(
                index: 1,
                icon: Icons.people_rounded,
                label: 'Services',
                isSmallScreen: isSmallScreen,
              ),
              
              // Entrepreneurship (index 2)
              _buildNavItem(
                index: 2,
                icon: Icons.business_rounded,
                label: 'Business',
                isSmallScreen: isSmallScreen,
              ),

              // education (index 3)
              _buildNavItem(
                index: 3,
                icon: Icons.school_rounded,
                label: 'Education',
                isSmallScreen: isSmallScreen,
              ),
              
              // Settings (index 4)
              _buildNavItem(
                index: 4,
                icon: Icons.settings_rounded,
                label: 'Settings',
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSmallScreen,
  }) {
    bool isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () {
        print('📱 Nav item tapped: $label (index: $index)');
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: isSmallScreen ? 44 : 48,
            height: isSmallScreen ? 44 : 48,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                size: isSmallScreen ? 22 : 24,
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // Helper function for min
  double min(double a, double b) => a < b ? a : b;
}

// NavItem model
class NavItem {
  final IconData icon;
  final String label;

  NavItem({required this.icon, required this.label});
}