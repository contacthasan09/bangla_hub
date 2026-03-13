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
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  
  @override
  bool get wantKeepAlive => true;

  // ✅ Instance-specific scaffold key
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  
  // Color scheme
  final Color _primaryRed = const Color(0xFFF42A41);
  final Color _primaryGreen = const Color(0xFF006A4E);
  final Color _darkGreen = const Color(0xFF004D38);
  final Color _goldAccent = const Color(0xFFFFD700);
  final Color _offWhite = const Color(0xFFF8F8F8);
  
  // Screens for each navigation item
  late final List<Widget> _screens;
  
  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  // Cache expensive widgets
  Widget? _cachedBottomNavBar;
  Widget? _cachedDrawer;
  UserModel? _lastUserForDrawer;
  bool _didInitDependencies = false;
  
  // Navigation items data - made const
  static const List<NavItem> _navItems = [
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
    
    // Add WidgetsBindingObserver
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize screens
    _screens =  [
      const EventsScreen(),
      const CommunityServicesListScreen(),
      EntrepreneurshipScreen(),
      EducationScreen(),
      PremiumSettingsScreen(),
    ];
    
    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    // Start animations if app is visible
    if (_appLifecycleState == AppLifecycleState.resumed) {
      _startAnimations();
    }
    
    // Initialize data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
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
      _fadeController.forward();
      _slideController.forward();
    }
  }
  
  void _stopAnimations() {
    _fadeController.stop();
    _slideController.stop();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_didInitDependencies) {
      _didInitDependencies = true;
      _cachedBottomNavBar = _buildPremiumBottomNavBar();
    }
  }
  
  Future<void> _loadSavedIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hasSavedIndex = prefs.containsKey('selected_tab_index');
      
      if (hasSavedIndex) {
        final savedIndex = prefs.getInt('selected_tab_index') ?? 0;
        if (mounted && savedIndex >= 0 && savedIndex < _navItems.length) {
          setState(() {
            _selectedIndex = savedIndex;
          });
          print('📊 Loaded saved tab index: $savedIndex');
        }
      } else {
        if (mounted) {
          setState(() {
            _selectedIndex = 0;
          });
          print('📊 Fresh login - starting at Events tab');
        }
      }
    } catch (e) {
      print('Error loading saved tab index: $e');
    }
  }
  
  Future<void> _saveSelectedIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selected_tab_index', index);
      print('📊 Saved tab index: $index');
    } catch (e) {
      print('Error saving tab index: $e');
    }
  }
  
  Future<void> _clearSavedIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_tab_index');
      print('📊 Cleared saved tab index');
    } catch (e) {
      print('Error clearing saved index: $e');
    }
  }
  
  Future<void> _initializeData() async {
    print('📊 Initializing HomeScreen data');
    final authProvider = context.read<AuthProvider>();
    print('👤 User data initialized: ${authProvider.user?.email}');
    await _loadSavedIndex();
  }
  
  @override
  void dispose() {
    print('🗑️ HomeScreen disposing...');
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ✅ FIXED: Proper logout method with safety
  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
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
      await _clearSavedIndex();

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

      // Navigate to login screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }

    } catch (e) {
      // Close dialog on error
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: _primaryRed,
          ),
        );
      }
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  // ✅ NEW: Centralized method for handling navigation taps
  void _onNavItemTapped(int index) {
    if (_selectedIndex != index) {
      print('📱 Nav item tapped: ${_navItems[index].label} (index: $index)');
      setState(() {
        _selectedIndex = index;
      });
      _saveSelectedIndex(index);
      // Invalidate cached bottom nav bar to force rebuild with new selected state
      _cachedBottomNavBar = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    print('🏗️ Building HomeScreen, screen size: ${MediaQuery.of(context).size}');
    
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUser = authProvider.user;
        
        if (_lastUserForDrawer != currentUser) {
          _lastUserForDrawer = currentUser;
          _cachedDrawer = _buildDrawer(currentUser);
        }
        
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: _offWhite,
          drawer: _cachedDrawer,
          body: shouldAnimate
              ? FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _screens,
                    ),
                  ),
                )
              : IndexedStack(
                  index: _selectedIndex,
                  children: _screens,
                ),
          bottomNavigationBar: _cachedBottomNavBar ?? _buildPremiumBottomNavBar(),
        );
      },
    );
  }

  // Drawer builder
  Widget _buildDrawer(UserModel? currentUser) {
    final screenSize = MediaQuery.of(context).size;
    final drawerWidth = screenSize.width * 0.6 > 280 ? 280.0 : screenSize.width * 0.6;

    print('📐 Building drawer, width: $drawerWidth, screen width: ${screenSize.width}');
    
    return Drawer(
      width: drawerWidth,
      child: Container(
        decoration: BoxDecoration(
          color: _offWhite,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildDrawerHeader(currentUser),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _navItems.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _navItems.length) {
                      return Column(
                        children: [
                          const Divider(
                            indent: 20,
                            endIndent: 20,
                            height: 30,
                          ),
                          _buildDrawerItem(
                            icon: Icons.logout_rounded,
                            title: 'Logout',
                            color: _primaryRed,
                            index: index, // Pass index but it won't be used for logout
                            onTap: () {
                              Navigator.pop(context); // Close drawer first
                              _handleLogout(); // Then logout
                            },
                          ),
                        ],
                      );
                    }
                    
                    final item = _navItems[index];
                    return _buildDrawerItem(
                      icon: item.icon,
                      title: item.label,
                      index: index,
                      onTap: () {
                        Navigator.pop(context);
                        _onNavItemTapped(index); // Use centralized method
                      },
                    );
                  },
                ),
              ),
              _buildDrawerFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(UserModel? currentUser) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryGreen, _darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
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
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
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
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
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
    );
  }

  Widget _buildDrawerFooter() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'BanglaHub v1.0.0',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '© 2026 BanglaHub. All rights reserved.',
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey,
            ),
          ),
        ],
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
            return _buildDefaultProfileAvatar(size);
          },
        );
      } catch (e) {
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
    required int index,
    required VoidCallback onTap,
  }) {
    // For navigation items (not logout)
    if (index >= 0 && index < _navItems.length) {
      final isSelected = _selectedIndex == index;
      return ListTile(
        leading: Icon(
          icon,
          color: isSelected ? _primaryGreen : (color ?? _darkGreen),
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? _primaryGreen : (color ?? Colors.grey[800]),
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _primaryGreen,
                  shape: BoxShape.circle,
                ),
              )
            : Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 24,
              ),
        selected: isSelected,
        selectedTileColor: _primaryGreen.withOpacity(0.05),
        onTap: onTap,
      );
    }
    
    // For logout button
    return ListTile(
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey[400],
        size: 24,
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
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 25,
            offset: Offset(0, -5),
            spreadRadius: 5,
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: isSmallScreen ? 72 : 80,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              return _buildNavItem(
                index: index,
                icon: _navItems[index].icon,
                label: _navItems[index].label,
                isSmallScreen: isSmallScreen,
              );
            }),
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
      onTap: () => _onNavItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
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
          const SizedBox(height: 4),
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

class NavItem {
  final IconData icon;
  final String label;

  const NavItem({required this.icon, required this.label});
}