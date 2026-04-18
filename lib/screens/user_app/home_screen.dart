import 'dart:async';
import 'dart:convert';

import 'package:bangla_hub/main.dart';
import 'package:bangla_hub/models/user_model.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/user_app/community_services/community_services_list_screen.dart';
import 'package:bangla_hub/screens/user_app/community_services/my_services/my_services_screen.dart';
import 'package:bangla_hub/screens/user_app/education_youth/education_youth_screen.dart';
import 'package:bangla_hub/screens/user_app/education_youth/my_education/my_education_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/entrepreneurship_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/my_business/my_business_screen.dart';
import 'package:bangla_hub/screens/user_app/event/events_screen.dart';
import 'package:bangla_hub/screens/user_app/event/my_events/my_events_screen.dart';
import 'package:bangla_hub/screens/user_app/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Static variable to preserve selected index across rebuilds
  static int _globalSelectedIndex = 0;
  int _selectedIndex = 0;
  bool _isIndexLoaded = false;
  
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  
  final Color _primaryRed = const Color(0xFFF42A41);
  final Color _primaryGreen = const Color(0xFF006A4E);
  final Color _darkGreen = const Color(0xFF004D38);
  final Color _goldAccent = const Color(0xFFFFD700);
  final Color _offWhite = const Color(0xFFF8F8F8);
  
  late final List<Widget> _regularScreens;
  late final List<Widget> _myItemsScreens;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  Widget? _cachedDrawer;
  UserModel? _lastUserForDrawer;
  
  static const List<NavItem> _navItems = [
    NavItem(icon: Icons.event_rounded, label: 'Events'),
    NavItem(icon: Icons.people_rounded, label: 'Services'),
    NavItem(icon: Icons.business_rounded, label: 'Business'),
    NavItem(icon: Icons.school_rounded, label: 'Education'),
    NavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];
  
  static const List<DrawerItem> _drawerItems = [
    DrawerItem(icon: Icons.event_note_rounded, label: 'My Events'),
    DrawerItem(icon: Icons.miscellaneous_services_rounded, label: 'My Services'),
    DrawerItem(icon: Icons.business_center_rounded, label: 'My Business'),
    DrawerItem(icon: Icons.school_rounded, label: 'My Education'),
  ];

  @override
  void initState() {
    super.initState();
    
    print('🔄 HomeScreen initState called');
    
    // Reset to Events tab on fresh login (not from static variable)
    _resetToEventsTab();
    
    WidgetsBinding.instance.addObserver(this);
    
    _regularScreens = [
      const EventsScreen(),
      const CommunityServicesListScreen(),
      EntrepreneurshipScreen(),
      EducationScreen(),
      PremiumSettingsScreen(),
    ];
    
    _myItemsScreens = [
      MyEventsScreen(onBack: _goToHome),
      MyServicesScreen(onBack: _goToHome),
      MyBusinessScreen(onBack: _goToHome),
      MyEducationScreen(onBack: _goToHome),
    ];
    
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
    
    if (_appLifecycleState == AppLifecycleState.resumed) {
      _startAnimations();
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }
  
  void _resetToEventsTab() {
    // Reset to Events tab (index 0)
    _selectedIndex = 0;
    _globalSelectedIndex = 0;
    print('📊 Reset to Events tab (index: 0)');
  }
  
  void _goToHome() {
    print("🔙 Returning to Events screen from My Items");
    if (mounted) {
      setState(() {
        _selectedIndex = 0;
        _globalSelectedIndex = 0;
      });
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
      _fadeController.forward();
      _slideController.forward();
    }
  }
  
  void _stopAnimations() {
    _fadeController.stop();
    _slideController.stop();
  }
  
  Future<void> _loadSavedIndex() async {
    try {
      if (mounted) {
        // Always start from Events tab on fresh load
        _selectedIndex = 0;
        _globalSelectedIndex = 0;
        print('📊 HomeScreen loaded - current tab index: $_selectedIndex');
        setState(() {
          _isIndexLoaded = true;
        });
      }
    } catch (e) {
      print('Error in _loadSavedIndex: $e');
      if (mounted) {
        setState(() {
          _selectedIndex = 0;
          _globalSelectedIndex = 0;
          _isIndexLoaded = true;
        });
      }
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

  Future<void> _performPremiumLogout(BuildContext context) async {
    BuildContext? dialogContext;
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          dialogContext = context;
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(30),
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
                  CircularProgressIndicator(
                    color: _goldAccent,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Logging out...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      final authProvider = context.read<AuthProvider>();
      await authProvider.signOut(context);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_tab_index');
      print('📊 Cleared saved tab index on logout');

      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
    } catch (e) {
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: _primaryRed,
            ),
          );
        }
      });
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex != index) {
      print('📱 Nav item tapped: ${_navItems[index].label} (index: $index)');
      setState(() {
        _selectedIndex = index;
        _globalSelectedIndex = index;
      });
    }
  }
  
  void _onDrawerItemTapped(int drawerIndex) {
    final mappedIndex = 5 + drawerIndex;
    
    if (_selectedIndex != mappedIndex) {
      print('📱 Drawer item tapped: ${_drawerItems[drawerIndex].label} (mapped index: $mappedIndex)');
      setState(() {
        _selectedIndex = mappedIndex;
        _globalSelectedIndex = mappedIndex;
      });
    }
  }

  // Handle device back button
  Future<bool> _onWillPop() async {
    print('📍 Device back button pressed, current index: $_selectedIndex');
    
    if (_selectedIndex >= 5) {
      print('📍 On My Items screen, switching to Events');
      setState(() {
        _selectedIndex = 0;
        _globalSelectedIndex = 0;
      });
      return false;
    }
    
    if (_selectedIndex > 0 && _selectedIndex < 5) {
      print('📍 On ${_navItems[_selectedIndex].label}, switching to Events');
      setState(() {
        _selectedIndex = 0;
        _globalSelectedIndex = 0;
      });
      return false;
    }
    
    if (_selectedIndex == 0) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Exit BanglaHub',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: _primaryGreen,
            ),
          ),
          content: Text(
            'Are you sure you want to exit the app?',
            style: GoogleFonts.inter(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: _primaryGreen, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Exit',
                style: TextStyle(color: _primaryRed, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
      
      if (shouldExit == true) {
        SystemNavigator.pop();
      }
      return false;
    }
    
    return false;
  }

  Widget _getCurrentScreen() {
    if (_selectedIndex >= 0 && _selectedIndex < _regularScreens.length) {
      return _regularScreens[_selectedIndex];
    }
    else if (_selectedIndex >= 5 && _selectedIndex < 5 + _myItemsScreens.length) {
      return _myItemsScreens[_selectedIndex - 5];
    }
    return _regularScreens[0];
  }

  bool _shouldShowBottomNav() {
    return _selectedIndex >= 0 && _selectedIndex < _regularScreens.length;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    print('🏗️ Building HomeScreen, selectedIndex: $_selectedIndex');
    
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUser = authProvider.user;
        
        if (_lastUserForDrawer != currentUser) {
          _lastUserForDrawer = currentUser;
          _cachedDrawer = _buildDrawer(currentUser);
        }
        
        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: _offWhite,
            drawer: _cachedDrawer,
            body: shouldAnimate
                ? FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _getCurrentScreen(),
                    ),
                  )
                : _getCurrentScreen(),
            bottomNavigationBar: _isIndexLoaded && _shouldShowBottomNav() 
                ? _buildPremiumBottomNavBar() 
                : null,
          ),
        );
      },
    );
  }

  Widget _buildDrawer(UserModel? currentUser) {
    final screenSize = MediaQuery.of(context).size;
    final drawerWidth = screenSize.width * 0.6 > 280 ? 280.0 : screenSize.width * 0.6;

    print('📐 Building drawer, width: $drawerWidth');
    
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
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        'MY ITEMS',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    
                    ..._drawerItems.asMap().entries.map((entry) {
                      final drawerIndex = entry.key;
                      final item = entry.value;
                      final mappedIndex = 5 + drawerIndex;
                      final isSelected = _selectedIndex == mappedIndex;
                      
                      return _buildDrawerItem(
                        icon: item.icon,
                        title: item.label,
                        isSelected: isSelected,
                        onTap: () {
                          Navigator.pop(context);
                          _onDrawerItemTapped(drawerIndex);
                        },
                      );
                    }),
                    
                    const Divider(indent: 20, endIndent: 20, height: 30),
                    
                    _buildDrawerItem(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      color: _primaryRed,
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        _performPremiumLogout(context);
                      },
                    ),
                  ],
                ),
              ),
              _buildDrawerFooter(),
            ],
          ),
        ),
      ),
    );
  }

/*  Widget _buildDrawerHeader(UserModel? currentUser) {
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
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

*/


Widget _buildDrawerHeader(UserModel? currentUser) {
  final authProvider = Provider.of<AuthProvider>(context);
  
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
        ValueListenableBuilder<String?>(
          valueListenable: authProvider.profileImageNotifier,
          builder: (context, profileImageUrl, child) {
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: _getProfileImageWithUrl(currentUser, profileImageUrl, 60),
              ),
            );
          },
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _goldAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _goldAccent),
                  ),
                  child: Text(
                    'Admin',
                    style: TextStyle(fontSize: 10, color: _goldAccent, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Add helper method
Widget _getProfileImageWithUrl(UserModel? currentUser, String? profileImageUrl, double size) {
  if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
    return Image.network(
      profileImageUrl,
      fit: BoxFit.cover,
      width: size,
      height: size,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildDefaultProfileAvatar(size);
      },
    );
  }
  return _buildDefaultProfileAvatar(size);
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
    // Proper null check
    if (currentUser == null) {
      return _buildDefaultProfileAvatar(size);
    }
    
    // Check if profileImageUrl exists and is not empty
    final hasProfileImage = currentUser.profileImageUrl != null && 
                            currentUser.profileImageUrl!.isNotEmpty;
    
    if (!hasProfileImage) {
      return _buildDefaultProfileAvatar(size);
    }
    
    final imageData = currentUser.profileImageUrl!;
    
    // Check if it's a URL
    if (_isUrlString(imageData)) {
      return ClipOval(
        child: Image.network(
          imageData,
          fit: BoxFit.cover,
          width: size,
          height: size,
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
            print('Error loading profile image: $error');
            return _buildDefaultProfileAvatar(size);
          },
        ),
      );
    } else {
      // Handle Base64
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
            width: size,
            height: size,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultProfileAvatar(size);
            },
          ),
        );
      } catch (e) {
        return _buildDefaultProfileAvatar(size);
      }
    }
  }

  Widget _buildDefaultProfileAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryGreen, _darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
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

  bool _isUrlString(String str) {
    return str.startsWith('http://') || str.startsWith('https://');
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    Color? color,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? _primaryGreen : (color ?? _darkGreen),
        size: 24,
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
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
          : null,
      selected: isSelected,
      selectedTileColor: _primaryGreen.withOpacity(0.05),
      onTap: onTap,
    );
  }
  
  Widget _buildPremiumBottomNavBar() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryGreen, _darkGreen],
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
}

class NavItem {
  final IconData icon;
  final String label;
  const NavItem({required this.icon, required this.label});
}

class DrawerItem {
  final IconData icon;
  final String label;
  const DrawerItem({required this.icon, required this.label});
}