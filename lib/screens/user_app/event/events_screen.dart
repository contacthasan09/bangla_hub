import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:bangla_hub/screens/user_app/event/event_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bangla_hub/models/event_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bangla_hub/providers/event_provider.dart';
import 'package:bangla_hub/providers/auth_provider.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with TickerProviderStateMixin {
  // Color scheme matching CommunityServicesListScreen
  final Color _primaryRed = Color(0xFFF42A41);
  final Color _primaryGreen = Color(0xFF006A4E);
  final Color _darkGreen = Color(0xFF004D38);
  final Color _goldAccent = Color(0xFFFFD700);
  final Color _offWhite = Color(0xFFF8F8F8);
  
  // Extended vibrant colors that complement the theme
  final Color _coralRed = Color(0xFFFF6B6B);
  final Color _mintGreen = Color(0xFF98D8C8);
  final Color _softGold = Color(0xFFFFD966);
  final Color _creamWhite = Color(0xFFFFF9E6);
  final Color _lightGreen = Color(0xFFE8F5E9);
  final Color _lightRed = Color(0xFFFFEBEE);

  // Additional colors needed for success dialog
  final Color _emeraldGreen = Color(0xFF2ECC71);
  final Color _sapphireBlue = Color(0xFF3498DB);
  final Color _amethystPurple = Color(0xFF9B59B6);
  final Color _mintCream = Color(0xFFDCF8C6);
  final Color _peachBlossom = Color(0xFFFFC0CB);
  
  // Background Gradient matching CommunityServicesListScreen
  final LinearGradient _premiumBgGradient = LinearGradient(
    colors: [
      Color(0xFF006A4E), // _primaryGreen
      Color(0xFF004D38), // _darkGreen
      Color(0xFFF42A41), // _primaryRed
      Color(0xFFD32F2F), // darker red
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  final LinearGradient _sunsetGradient = LinearGradient(
    colors: [
      Color(0xFFF42A41), // _primaryRed
      Color(0xFFFF6B6B), // _coralRed
      Color(0xFFFFD966), // _softGold
      Color(0xFF006A4E), // _primaryGreen
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _oceanGradient = LinearGradient(
    colors: [
      Color(0xFF006A4E), // _primaryGreen
      Color(0xFF004D38), // _darkGreen
      Color(0xFF98D8C8), // _mintGreen
      Color(0xFFE8F5E9), // _lightGreen
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _royalGradient = LinearGradient(
    colors: [
      Color(0xFFF42A41), // _primaryRed
      Color(0xFFD32F2F), // darker red
      Color(0xFFFFD966), // _softGold
      Color(0xFF006A4E), // _primaryGreen
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _neonGradient = LinearGradient(
    colors: [
      Color(0xFFF42A41), // _primaryRed
      Color(0xFFFF6B6B), // _coralRed
      Color(0xFF006A4E), // _primaryGreen
      Color(0xFF98D8C8), // _mintGreen
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _auroraGradient = LinearGradient(
    colors: [
      Color(0xFF00F5A0),
      Color(0xFF00D9F5),
      Color(0xFF9D50BB),
      Color(0xFF6E48AA),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient _glassMorphismGradient = LinearGradient(
    colors: [
      Colors.white.withOpacity(0.3),
      Colors.white.withOpacity(0.1),
      Colors.white.withOpacity(0.2),
      Colors.white.withOpacity(0.05),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Colors
  final Color _textPrimary = Color(0xFF1A1A2E);
  final Color _textSecondary = Color(0xFF4A4A4A);
  final Color _textLight = Color(0xFF6C757D);

  int _currentSliderIndex = 0;
  final PageController _sliderController = PageController(viewportFraction: 0.9);
  final ScrollController _eventScrollController = ScrollController();
  String? _selectedCategory;
  List<EventModel> _filteredUpcomingEvents = [];
  
  bool _showAllUpcomingEvents = false;
  bool _showAllPastEvents = false;
  bool _isInitialized = false;
  
  // Cache for better performance
  final Map<String, List<EventModel>> _categorizedEvents = {};
  
  // Category order: all, social, religious, sports, business, educational
  final List<EventCategory> _categoryOrder = [
    EventCategory.all,
    EventCategory.social,
    EventCategory.religious,
    EventCategory.sports,
    EventCategory.business,
    EventCategory.educational,
  ];
  
  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _rotateController;
  late Animation<double> _rotateAnimation;
  
  // Scroll Hint Animation
  late AnimationController _scrollHintController;
  late Animation<Offset> _scrollHintAnimation;
  late Animation<double> _scrollHintOpacity;
  
  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _organizerController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Image handling
  XFile? _selectedImage;
  String? _base64Image;
  bool _isImageLoading = false;
  
  // Form state
  bool _isSaving = false;
  DateTime? _selectedDate;
  String _selectedEventCategory = 'social';
  bool _isFree = true;
  Map<String, double> _ticketPrices = {};
  final TextEditingController _ticketTypeController = TextEditingController();
  final TextEditingController _ticketPriceController = TextEditingController();
  
  // Auto slide timer
  late Timer _autoSlideTimer;
  
  // Scroll listener for hint
  bool _hasScrolled = false;

  @override
  void initState() {
    super.initState();
    
    print('🚀 EventsScreen initState called');
    
    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800), // Reduced for faster loading
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController, 
      curve: Curves.easeInOut,
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    
    _rotateController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    
    _rotateAnimation = CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeInOut,
    );
    
    // Scroll Hint Animation
    _scrollHintController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    
    _scrollHintAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0, 0.3),
    ).animate(CurvedAnimation(
      parent: _scrollHintController,
      curve: Curves.easeInOut,
    ));
    
    _scrollHintOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _scrollHintController,
      curve: Curves.easeInOut,
    ));
    
    _scrollHintController.repeat(reverse: true);
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    _rotateController.repeat();
    
    // Add scroll listener
    _eventScrollController.addListener(_onScroll);
    
    // Start auto-slide after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoSlide();
      setState(() {
        _isInitialized = true;
      });
    });
  }
  
  void _onScroll() {
    if (!_hasScrolled && _eventScrollController.position.pixels > 50) {
      setState(() {
        _hasScrolled = true;
      });
    }
  }
  
  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted && _sliderController.hasClients && _filteredUpcomingEvents.isNotEmpty) {
        int nextPage = _currentSliderIndex + 1;
        int totalEvents = _showAllUpcomingEvents ? _filteredUpcomingEvents.length : _filteredUpcomingEvents.take(5).length;
        if (nextPage >= totalEvents) nextPage = 0;
        
        _sliderController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    _scrollHintController.dispose();
    _sliderController.dispose();
    _eventScrollController.dispose();
    _autoSlideTimer.cancel();
    _titleController.dispose();
    _organizerController.dispose();
    _contactPersonController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _ticketTypeController.dispose();
    _ticketPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;
    final isSmallScreen = screenHeight < 700;
    final eventProvider = Provider.of<EventProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Optimize filtering with caching
    if (_selectedCategory == null || _selectedCategory == 'all') {
      _filteredUpcomingEvents = eventProvider.upcomingEvents;
    } else {
      final cacheKey = 'upcoming_${_selectedCategory}';
      if (_categorizedEvents[cacheKey] == null) {
        _categorizedEvents[cacheKey] = eventProvider.upcomingEvents
            .where((event) => event.category == _selectedCategory)
            .toList();
      }
      _filteredUpcomingEvents = _categorizedEvents[cacheKey]!;
    }
    
    final carouselEvents = _showAllUpcomingEvents 
        ? _filteredUpcomingEvents 
        : _filteredUpcomingEvents.take(5).toList();
    
    final upcomingEventsToShow = _showAllUpcomingEvents 
        ? _filteredUpcomingEvents 
        : _filteredUpcomingEvents.take(5).toList();
    
    final pastEventsToShow = _showAllPastEvents 
        ? eventProvider.pastEvents 
        : eventProvider.pastEvents.take(3).toList();
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        drawer: _buildDrawer(context, authProvider, isTablet),
        floatingActionButton: authProvider.user != null 
            ? _buildPremiumFloatingActionButton(isTablet) 
            : null,
        body: Container(
          decoration: BoxDecoration(
            gradient: _premiumBgGradient,
          ),
          child: Stack(
            children: [
              // Animated Background Particles (keep existing)
              ...List.generate(30, (index) => _buildAnimatedParticle(index, screenWidth, screenHeight)),
              
              // Animated Gradient Overlay (keep existing)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: 0.3,
                  duration: Duration(seconds: 2),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                          _primaryRed.withOpacity(0.1),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Floating Bubbles (keep existing)
              ...List.generate(8, (index) => _buildFloatingBubble(index, screenWidth, screenHeight)),
              
              // Main Content
              RefreshIndicator(
                color: _goldAccent,
                backgroundColor: Colors.white,
                strokeWidth: 3,
                displacement: 40,
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  // Clear cache on refresh
                  _categorizedEvents.clear();
                },
                child: CustomScrollView(
                  controller: _eventScrollController,
                  physics: BouncingScrollPhysics(),
                  slivers: [
                    _buildPremiumAppBar(isTablet, authProvider),
                    
                    SliverToBoxAdapter(
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: _buildPremiumBodyContent(
                          isSmallScreen,
                          isTablet,
                          eventProvider,
                          carouselEvents,
                          upcomingEventsToShow,
                          pastEventsToShow,
                          authProvider,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Scroll Hint (only show if not scrolled and events exist)
              if (!_hasScrolled && _filteredUpcomingEvents.isNotEmpty && _isInitialized)
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _scrollHintOpacity,
                    child: SlideTransition(
                      position: _scrollHintAnimation,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 20,
                          vertical: isTablet ? 16 : 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: _glassMorphismGradient,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        margin: EdgeInsets.symmetric(horizontal: isTablet ? 100 : 50),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.swipe_vertical_rounded,
                              color: Colors.white,
                              size: isTablet ? 24 : 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                          //    'Scroll for more events',
                               'Scroll for more ',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider, bool isTablet) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryGreen, _darkGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                authProvider.user?.firstName ?? 'Guest User',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              accountEmail: Text(
                authProvider.user?.email ?? 'guest@example.com',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  authProvider.user?.firstName?.substring(0, 1).toUpperCase() ?? 'G',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.w800,
                    color: _primaryGreen,
                  ),
                ),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryRed, _primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.home_rounded,
              title: 'Home',
              onTap: () => Navigator.pop(context),
              isTablet: isTablet,
            ),
            _buildDrawerItem(
              icon: Icons.event_rounded,
              title: 'Events',
              onTap: () => Navigator.pop(context),
              isTablet: isTablet,
              isSelected: true,
            ),
            _buildDrawerItem(
              icon: Icons.favorite_rounded,
              title: 'My Interests',
              onTap: () {
                Navigator.pop(context);
                // Navigate to interests screen
              },
              isTablet: isTablet,
            ),
            _buildDrawerItem(
              icon: Icons.history_rounded,
              title: 'My Events',
              onTap: () {
                Navigator.pop(context);
                // Navigate to my events screen
              },
              isTablet: isTablet,
            ),
            Divider(color: Colors.white.withOpacity(0.3)),
            if (authProvider.user != null) ...[
              _buildDrawerItem(
                icon: Icons.logout_rounded,
                title: 'Logout',
                onTap: () async {
                  Navigator.pop(context);
                  await authProvider.signOut();
                },
                isTablet: isTablet,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isTablet,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? _goldAccent : Colors.white,
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: isSelected ? _goldAccent : Colors.white,
          fontSize: isTablet ? 18 : 16,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildFloatingBubble(int index, double width, double height) {
    final size = 50 + (index * 15).toDouble();
    return Positioned(
      left: (index * 73) % width,
      top: (index * 47) % height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(seconds: 8 + (index * 2)),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (value - 0.5)),
            child: Opacity(
              opacity: 0.1 + (value * 0.1),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      _primaryRed.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedParticle(int index, double width, double height) {
    return Positioned(
      left: (index * 37) % width,
      top: (index * 53) % height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(seconds: 3 + (index % 3)),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: (0.1 + (value * 0.2)) * (0.5 + (index % 3) * 0.1),
            child: Transform.rotate(
              angle: value * 6.28,
              child: Container(
                width: 2 + (index % 3) * 2,
                height: 2 + (index % 3) * 2,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _goldAccent.withOpacity(0.5),
                      _primaryGreen.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumAppBar(bool isTablet, AuthProvider authProvider) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          isTablet ? 32 : 24,
          MediaQuery.of(context).padding.top + (isTablet ? 30 : 20),
          isTablet ? 32 : 24,
          isTablet ? 20 : 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Text
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  _goldAccent,
                  _primaryRed,
                  _primaryGreen,
                  _softGold,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                authProvider.user != null 
                  ? 'Welcome, ${authProvider.user!.firstName}!'
                  : 'Welcome to BanglaHub!',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: isTablet ? 32 : 24,
                  height: 1.2,
                  color: Colors.white,
                  letterSpacing: -1,
                  shadows: [
                    Shadow(
                      color: _darkGreen.withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isTablet ? 8 : 4),
            
            // Events Title (with larger size)
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  _goldAccent,
                  _primaryRed,
                  _primaryGreen,
                  _softGold,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Events',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  fontSize: isTablet ? 40 : 32,
                  height: 1.1,
                  color: Colors.white,
                  letterSpacing: -2,
                  shadows: [
                    Shadow(
                      color: _darkGreen.withOpacity(0.5),
                      blurRadius: 20,
                      offset: Offset(0, 5),
                    ),
                    Shadow(
                      color: _primaryRed.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            
            // Animated Subtitle
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 1200),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 15 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 18 : 14,
                  vertical: isTablet ? 10 : 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primaryGreen.withOpacity(0.2),
                      _primaryRed.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: _goldAccent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: _goldAccent,
                      size: isTablet ? 22 : 20,
                    ),
                    SizedBox(width: isTablet ? 10 : 8),
                    Text(
                      'Discover and manage events seamlessly',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFloatingActionButton(bool isTablet) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryRed, _primaryGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: _primaryRed.withOpacity(0.5),
              blurRadius: 25,
              offset: Offset(0, 12),
              spreadRadius: 3,
            ),
            BoxShadow(
              color: _primaryGreen.withOpacity(0.4),
              blurRadius: 30,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showPremiumAddEventDialog(context, isTablet),
            borderRadius: BorderRadius.circular(35),
            splashColor: Colors.white.withOpacity(0.3),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 28 : 24,
                vertical: isTablet ? 16 : 14,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RotationTransition(
                    turns: _rotateAnimation,
                    child: Icon(
                      Icons.add_circle_rounded,
                      color: Colors.white,
                      size: isTablet ? 26 : 22,
                    ),
                  ),
                  SizedBox(width: isTablet ? 12 : 10),
                  Text(
                    'Create Event',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: isTablet ? 18 : 16,
                      color: Colors.white,
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
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

  Widget _buildPremiumBodyContent(
    bool isSmallScreen,
    bool isTablet,
    EventProvider eventProvider,
    List<EventModel> carouselEvents,
    List<EventModel> upcomingEventsToShow,
    List<EventModel> pastEventsToShow,
    AuthProvider authProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryRed.withOpacity(0.05),
            Colors.white,
            _primaryGreen.withOpacity(0.05),
            _offWhite,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isTablet ? 50 : 40),
          topRight: Radius.circular(isTablet ? 50 : 40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 5,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: isTablet ? 40 : 30),
          
          // Upcoming Events Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryGreen, _darkGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryGreen.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.event_available_rounded,
                        color: Colors.white,
                        size: isTablet ? 24 : 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [_primaryRed, _primaryGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'Upcoming Events',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 14 : 12,
                    vertical: isTablet ? 8 : 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryGreen, _darkGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryGreen.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '${_filteredUpcomingEvents.length} events',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: isTablet ? 24 : 20),
          
          // Events Carousel
          if (carouselEvents.isNotEmpty)
            SizedBox(
              height: isTablet ? 450 : 380,
              child: PageView.builder(
                controller: _sliderController,
                itemCount: carouselEvents.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentSliderIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailsScreen(event: carouselEvents[index]),
                        ),
                      );
                    },
                    child: _buildPremiumEventCard(
                      carouselEvents[index], 
                      isSmallScreen, 
                      isTablet, 
                      index == _currentSliderIndex,
                      eventProvider,
                    ),
                  );
                },
              ),
            )
          else
            _buildEmptyCarouselState(isTablet),
          
          if (carouselEvents.isNotEmpty) ...[
            SizedBox(height: isTablet ? 20 : 16),
            
            // Premium Carousel Indicators
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(carouselEvents.length, (index) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: _currentSliderIndex == index ? (isTablet ? 30 : 24) : (isTablet ? 12 : 8),
                    height: isTablet ? 8 : 6,
                    margin: EdgeInsets.symmetric(horizontal: isTablet ? 6 : 4),
                    decoration: BoxDecoration(
                      gradient: _currentSliderIndex == index 
                          ? LinearGradient(colors: [_primaryRed, _primaryGreen])
                          : LinearGradient(colors: [Colors.grey[300]!, Colors.grey[400]!]),
                      borderRadius: BorderRadius.circular(isTablet ? 6 : 4),
                    ),
                  );
                }),
              ),
            ),
          ],
          
          SizedBox(height: isTablet ? 30 : 24),
          
          // Categories Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryRed, _coralRed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryRed.withOpacity(0.2),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.category_rounded,
                    color: Colors.white,
                    size: isTablet ? 20 : 18,
                  ),
                ),
                SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [_primaryRed, _primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'Browse Categories',
                    style: GoogleFonts.poppins(
                   //   fontSize: isTablet ? 20 : 18,
                       fontSize: isTablet ? 25 : 23,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: isTablet ? 20 : 16),
          
          // Premium Categories Horizontal Scroll
          SizedBox(
            height: isTablet ? 90 : 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
              itemCount: _categoryOrder.length,
              itemBuilder: (context, index) {
                final category = _categoryOrder[index];
                return _buildPremiumCategoryCard(category, isSmallScreen, isTablet);
              },
            ),
          ),
          
          SizedBox(height: isTablet ? 30 : 24),
          
          // View All / Show Less Buttons
          if (_filteredUpcomingEvents.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
              child: _buildViewToggleButton(isTablet),
            ),
          
          SizedBox(height: isTablet ? 20 : 16),
          
          // All Upcoming Events List
          if (upcomingEventsToShow.isNotEmpty)
            ...upcomingEventsToShow.map((event) => 
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailsScreen(event: event),
                    ),
                  );
                },
                child: _buildPremiumEventListItem(event, isSmallScreen, isTablet, isPast: false),
              )
            ).toList(),
          
          // Past Events Section
          if (eventProvider.pastEvents.isNotEmpty) ...[
            SizedBox(height: isTablet ? 40 : 30),
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_coralRed, _primaryRed],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _coralRed.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      color: Colors.white,
                      size: isTablet ? 20 : 18,
                    ),
                  ),
                  SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [_primaryRed, _coralRed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'Past Events',
                      style: GoogleFonts.poppins(
                    //    fontSize: isTablet ? 20 : 18,
                         fontSize: isTablet ? 25 : 23,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Spacer(),
                  _buildPastEventsToggleButton(isTablet),
                ],
              ),
            ),
            
            SizedBox(height: isTablet ? 20 : 16),
            
            // Past Events List
            ...pastEventsToShow.map((event) => 
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailsScreen(event: event),
                    ),
                  );
                },
                child: _buildPremiumEventListItem(event, isSmallScreen, isTablet, isPast: true),
              )
            ).toList(),
          ],
          
          SizedBox(height: isTablet ? 50 : 40),
          
          // Premium Footer
          _buildPremiumFooter(isTablet),
          
          SizedBox(height: isTablet ? 30 : 20),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton(bool isTablet) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAllUpcomingEvents = !_showAllUpcomingEvents;
          _currentSliderIndex = 0;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 18 : 16,
        ),
        decoration: BoxDecoration(
          gradient: _showAllUpcomingEvents 
              ? LinearGradient(colors: [_primaryRed, _coralRed])
              : LinearGradient(colors: [_primaryGreen, _darkGreen]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: (_showAllUpcomingEvents ? _primaryRed : _primaryGreen).withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showAllUpcomingEvents ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: Colors.white,
              size: isTablet ? 24 : 22,
            ),
            SizedBox(width: 12),
            Text(
              _showAllUpcomingEvents ? 'Show Less' : 'View All Upcoming Events',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Icon(
              _showAllUpcomingEvents ? Icons.remove_rounded : Icons.add_rounded,
              color: Colors.white,
              size: isTablet ? 24 : 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastEventsToggleButton(bool isTablet) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAllPastEvents = !_showAllPastEvents;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 12 : 10,
        ),
        decoration: BoxDecoration(
          gradient: _showAllPastEvents 
              ? LinearGradient(colors: [_primaryRed, _coralRed])
              : LinearGradient(colors: [_primaryGreen, _darkGreen]),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: (_showAllPastEvents ? _primaryRed : _primaryGreen).withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              _showAllPastEvents ? Icons.remove_rounded : Icons.add_rounded,
              color: Colors.white,
              size: isTablet ? 20 : 18,
            ),
            SizedBox(width: 8),
            Text(
              _showAllPastEvents ? 'Show Less' : 'View All',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCarouselState(bool isTablet) {
    return Container(
      height: isTablet ? 400 : 350,
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isTablet ? 40 : 35),
        border: Border.all(
          color: Colors.grey.shade300.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isTablet ? 40 : 35),
        child: Stack(
          children: [
            // Beautiful network image for empty state
            Image.network(
              'https://images.unsplash.com/photo-1531058020387-3be344556be6?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryRed, _primaryGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.event_busy_rounded,
                      size: isTablet ? 80 : 70,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                );
              },
            ),
            // Gradient overlay for text visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Content
            Center(
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 40 : 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RotationTransition(
                      turns: _rotateAnimation,
                      child: Container(
                        width: isTablet ? 120 : 100,
                        height: isTablet ? 120 : 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryRed, _primaryGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _primaryRed.withOpacity(0.3),
                              blurRadius: 25,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.event_busy_rounded,
                            size: isTablet ? 60 : 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 30 : 24),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [_primaryRed, _primaryGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'No Upcoming Events',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 28 : 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    Text(
                      _selectedCategory != null && _selectedCategory != 'all'
                          ? 'No events in ${EventCategoryExtension.fromString(_selectedCategory!).displayName} category'
                          : 'Be the first to create an event!',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 18 : 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 30 : 24),
                    // Create Event Button
                    GestureDetector(
                      onTap: () {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        if (authProvider.user != null) {
                          _showPremiumAddEventDialog(context, isTablet);
                        } else {
                          _showPremiumSnackBar('Please login to create an event', isError: true);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 40 : 30,
                          vertical: isTablet ? 16 : 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryRed, _primaryGreen],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryRed.withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_circle_rounded,
                              color: Colors.white,
                              size: isTablet ? 24 : 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Create Event',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '(${_filteredUpcomingEvents.length} total)',
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 14 : 12,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumEventCard(
    EventModel event, 
    bool isSmallScreen, 
    bool isTablet, 
    bool isActive,
    EventProvider eventProvider,
  ) {
    bool isInterested = eventProvider.userInterestedEventIds.contains(event.id);
    
    // Get gradient based on category for more variety
    final categoryGradient = _getCategoryGradient(event.category);
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 8, vertical: isTablet ? 12 : 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isTablet ? 45 : 40),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: _primaryRed.withOpacity(0.4),
                  blurRadius: 40,
                  offset: Offset(0, 20),
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: _primaryGreen.withOpacity(0.3),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 25,
                  offset: Offset(0, 15),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isTablet ? 45 : 40),
        child: Stack(
          children: [
            // Background Image with Gradient Overlay
            Container(
              width: double.infinity,
              height: double.infinity,
              child: _buildEventImage(event, isTablet),
            ),
            
            // Premium Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
            
            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(isTablet ? 32 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category and Featured Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 20 : 16,
                            vertical: isTablet ? 12 : 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: categoryGradient,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryRed.withOpacity(0.3),
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                EventCategoryExtension.fromString(event.category).iconData,
                                color: Colors.white,
                                size: isTablet ? 20 : 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                event.categoryText,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        if (isActive)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.8, end: 1.2),
                            duration: Duration(milliseconds: 800),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                //    horizontal: isTablet ? 20 : 16,
                                 //   vertical: isTablet ? 12 : 10,
                                   horizontal: isTablet ? 16 : 12,
                                    vertical: isTablet ? 10 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_goldAccent, _softGold],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _goldAccent.withOpacity(0.4),
                                        blurRadius: 20,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        color: Colors.white,
                                        size: isTablet ? 20 : 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'FEATURED',
                                        style: GoogleFonts.poppins(
                                      //    fontSize: isTablet ? 16 : 14,
                                            fontSize: isTablet ? 14 : 12,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    
                    SizedBox(height: isTablet ? 30 : 24),
                    
                    // Event Title
          /*          ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [_goldAccent, _softGold],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        event.title,
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 36 : 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),  */

                    ShaderMask(
  shaderCallback: (bounds) => LinearGradient(
    colors: [Colors.white, Colors.white],
  ).createShader(bounds),
  child: Text(
    event.title,
    style: GoogleFonts.poppins(
      fontSize: isTablet ? 36 : 28,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      height: 1.2,
    ),
  ),
),
                    
                    SizedBox(height: isTablet ? 20 : 16),
                    
                    // Event Details
                    Container(
                      padding: EdgeInsets.all(isTablet ? 24 : 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Date
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isTablet ? 12 : 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryGreen, _darkGreen],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  Icons.calendar_today_rounded,
                                  color: Colors.white,
                                  size: isTablet ? 24 : 20,
                                ),
                              ),
                              SizedBox(width: isTablet ? 20 : 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date & Time',
                                      style: GoogleFonts.inter(
                                        fontSize: isTablet ? 14 : 12,
                                        color: Colors.white.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      event.formattedDate,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 20 : 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: isTablet ? 16 : 12),
                          
                          // Location
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isTablet ? 12 : 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryRed, _coralRed],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: isTablet ? 24 : 20,
                                ),
                              ),
                              SizedBox(width: isTablet ? 20 : 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Location',
                                      style: GoogleFonts.inter(
                                        fontSize: isTablet ? 14 : 12,
                                        color: Colors.white.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      event.location,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 20 : 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Footer with Stats and CTA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Interested Count
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16 : 12,
                            vertical: isTablet ? 12 : 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.favorite_rounded,
                                color: _goldAccent,
                                size: isTablet ? 22 : 18,
                              ),
                              SizedBox(width: isTablet ? 10 : 8),
                              Text(
                                '${event.totalInterested} interested',
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.w700,
                                  color: _goldAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // View Details Button
                        Container(
                          width: isTablet ? 70 : 60,
                          height: isTablet ? 70 : 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryRed, _primaryGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _primaryRed.withOpacity(0.4),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: isTablet ? 30 : 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get gradient based on category
  LinearGradient _getCategoryGradient(String category) {
    switch (category) {
      case 'social':
        return LinearGradient(colors: [_coralRed, _primaryRed]);
      case 'religious':
        return LinearGradient(colors: [_amethystPurple, _primaryRed]);
      case 'sports':
        return LinearGradient(colors: [_emeraldGreen, _primaryGreen]);
      case 'business':
        return LinearGradient(colors: [_sapphireBlue, _primaryGreen]);
      case 'educational':
        return LinearGradient(colors: [_goldAccent, _softGold]);
      default:
        return LinearGradient(colors: [_primaryRed, _primaryGreen]);
    }
  }

  Widget _buildPremiumCategoryCard(EventCategory category, bool isSmallScreen, bool isTablet) {
    final String categoryName = category.displayName;
    final IconData categoryIcon = category.iconData;
    final String categoryValue = category.stringValue;
    final bool isSelected = _selectedCategory == categoryValue;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedCategory == categoryValue) {
            _selectedCategory = null;
          } else {
            _selectedCategory = categoryValue;
          }
          _showAllUpcomingEvents = false;
          _currentSliderIndex = 0;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: isTablet ? 100 : 80,
        margin: EdgeInsets.only(right: isTablet ? 12 : 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [_primaryRed, _primaryGreen])
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _primaryRed.withOpacity(0.4)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isSelected ? 25 : 15,
              offset: Offset(0, isSelected ? 10 : 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isTablet ? 50 : 40,
              height: isTablet ? 50 : 40,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)])
                    : _getCategoryGradient(categoryValue),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? Colors.white : _primaryRed).withOpacity(0.2),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  categoryIcon,
                  color: isSelected ? Colors.white : Colors.white,
                  size: isTablet ? 24 : 20,
                ),
              ),
            ),
            SizedBox(height: isTablet ? 8 : 6),
            Text(
              categoryName,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : _darkGreen,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumEventListItem(EventModel event, bool isSmallScreen, bool isTablet, {required bool isPast}) {
    final authProvider = Provider.of<AuthProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);
    bool isInterested = eventProvider.userInterestedEventIds.contains(event.id);
    
    // Get beautiful gradient for the card
    final cardGradient = isPast 
        ? LinearGradient(
            colors: [
              _lightRed.withOpacity(0.3),
              Colors.white.withOpacity(0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              Colors.white.withOpacity(0.98),
              Colors.white,
              _lightGreen.withOpacity(0.2),
              _creamWhite.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24, vertical: isTablet ? 12 : 8),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(isTablet ? 35 : 30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: isPast 
                ? _primaryRed.withOpacity(0.1)
                : _primaryGreen.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isPast 
              ? Colors.grey.shade300.withOpacity(0.3)
              : Colors.grey.shade300.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            Container(
              width: isTablet ? 120 : 100,
              height: isTablet ? 120 : 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                child: _buildEventImage(event, isTablet, thumbnail: true),
              ),
            ),
            
            SizedBox(width: isTablet ? 24 : 20),
            
            // Event Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and Interest Button
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 14 : 12,
                          vertical: isTablet ? 8 : 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: isPast
                              ? LinearGradient(colors: [Colors.grey[400]!, Colors.grey[500]!])
                              : _getCategoryGradient(event.category),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (isPast ? Colors.grey : _primaryRed).withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              EventCategoryExtension.fromString(event.category).iconData,
                              color: Colors.white,
                              size: isTablet ? 16 : 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              event.categoryText,
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 14 : 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                      if (!isPast)
                        _buildPremiumInterestButton(event, isInterested, isTablet),
                    ],
                  ),
                  
                  SizedBox(height: isTablet ? 16 : 12),
                  
                  // Event Title
                  Text(
                    event.title,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 22 : 18,
                      fontWeight: FontWeight.w800,
                      color: isPast ? _darkGreen.withOpacity(0.7) : _darkGreen,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: isTablet ? 12 : 8),
                  
                  // Organizer
                  Row(
                    children: [
                      Icon(
                        Icons.business_rounded,
                        size: isTablet ? 18 : 16,
                        color: isPast ? _primaryRed : _primaryGreen,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.organizer,
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 16 : 14,
                            color: isPast ? _textLight : _textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: isTablet ? 12 : 8),
                  
                  // Date
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: isTablet ? 18 : 16,
                        color: isPast ? _coralRed.withOpacity(0.7) : _coralRed,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.formattedDate,
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 15 : 13,
                            color: isPast ? _textLight : _textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 8),
                  
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: isTablet ? 18 : 16,
                        color: isPast ? _mintGreen.withOpacity(0.7) : _mintGreen,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.location,
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 15 : 13,
                            color: isPast ? _textLight : _textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Interested Count for List Items (if not shown elsewhere)
                  if (!isPast) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          size: isTablet ? 16 : 14,
                          color: _goldAccent,
                        ),
                        SizedBox(width: 4),
                        Text(
                          event.interestedCountText,
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 14 : 12,
                            color: _goldAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumInterestButton(EventModel event, bool isInterested, bool isTablet) {
    final authProvider = Provider.of<AuthProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);
    
    return StatefulBuilder(
      builder: (context, setState) {
        bool _isLoading = false;
        
        Future<void> _toggleInterest() async {
          if (authProvider.user == null) {
            _showPremiumSnackBar('Please login to show interest', isError: true);
            return;
          }
          
          setState(() => _isLoading = true);
          
          try {
            await eventProvider.toggleUserInterest(
              event.id,
              authProvider.user!.id,
            );
            HapticFeedback.lightImpact();
          } catch (e) {
            _showPremiumSnackBar('Error: $e', isError: true);
          } finally {
            setState(() => _isLoading = false);
          }
        }
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _toggleInterest,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: isTablet ? 50 : 44,
              height: isTablet ? 50 : 44,
              decoration: BoxDecoration(
                gradient: isInterested
                    ? LinearGradient(colors: [_primaryRed, _coralRed])
                    : LinearGradient(colors: [Colors.white, _lightRed.withOpacity(0.5)]),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isInterested ? Colors.transparent : Colors.grey.shade300,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isInterested
                        ? _primaryRed.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: _isLoading
                    ? SizedBox(
                        width: isTablet ? 24 : 20,
                        height: isTablet ? 24 : 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: isInterested ? Colors.white : _primaryRed,
                        ),
                      )
                    : Icon(
                        isInterested ? Icons.favorite : Icons.favorite_border,
                        color: isInterested ? Colors.white : _primaryRed,
                        size: isTablet ? 24 : 20,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventImage(EventModel event, bool isTablet, {bool thumbnail = false}) {
    if (event.bannerImageUrl != null && event.bannerImageUrl!.isNotEmpty) {
      try {
        if (event.isBase64Image) {
          String imageData = event.bannerImageUrl!;
          if (imageData.startsWith('data:image/') && imageData.contains('base64,')) {
            imageData = imageData.split('base64,').last;
          }
          
          imageData = imageData.replaceAll(RegExp(r'\s'), '');
          
          if (imageData.length % 4 != 0) {
            imageData = imageData.padRight(imageData.length + (4 - imageData.length % 4), '=');
          }
          
          final bytes = base64Decode(imageData);
          
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultEventImage(isTablet);
            },
          );
        } else {
          return Image.network(
            event.bannerImageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primaryGreen,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultEventImage(isTablet);
            },
          );
        }
      } catch (e) {
        return _buildDefaultEventImage(isTablet);
      }
    }
    return _buildDefaultEventImage(isTablet);
  }

  Widget _buildDefaultEventImage(bool isTablet) {
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
          Icons.event_rounded,
          size: isTablet ? 50 : 40,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildPremiumFooter(bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
      padding: EdgeInsets.all(isTablet ? 40 : 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryGreen, _darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isTablet ? 40 : 35),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withOpacity(0.3),
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotationTransition(
                turns: _rotateAnimation,
                child: Icon(
                  Icons.event_available_rounded,
                  color: Colors.white,
                  size: isTablet ? 50 : 40,
                ),
              ),
              SizedBox(width: isTablet ? 20 : 16),
              Text(
                'BanglaHub Events',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 30 : 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 24 : 20),
          Text(
            'Discover, connect, and celebrate with the Bengali community',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 18 : 16,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 30 : 24),
          Container(
            height: 2,
            width: isTablet ? 200 : 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.5), Colors.white, Colors.white.withOpacity(0.5)],
              ),
            ),
          ),
          SizedBox(height: isTablet ? 24 : 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '© 2026',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 18 : 16,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: isTablet ? 20 : 16),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _goldAccent,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: isTablet ? 20 : 16),
              Text(
                'Version 2.0',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 18 : 16,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPremiumAddEventDialog(BuildContext context, bool isTablet) {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final mediaQuery = MediaQuery.of(context);
          final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
          final screenHeight = mediaQuery.size.height;
          final screenWidth = mediaQuery.size.width;
          final isTablet = screenWidth >= 600;
          final isSmallScreen = screenHeight < 600;
          
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isTablet ? 40 : 20,
              vertical: isKeyboardVisible ? (isTablet ? 20 : 10) : (isTablet ? 40 : 20),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * scale),
                  child: child,
                );
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 700,
                  maxHeight: mediaQuery.size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.98),
                      Colors.white,
                      _lightGreen.withOpacity(0.1),
                      _creamWhite.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 50 : 40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 60,
                      offset: Offset(0, 30),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Premium Header
                    Container(
                      padding: EdgeInsets.all(isTablet ? 32 : 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryRed, _primaryGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(isTablet ? 50 : 40),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryRed.withOpacity(0.4),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: isTablet ? 70 : 60,
                            height: isTablet ? 70 : 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(isTablet ? 20 : 18),
                            ),
                            child: Center(
                              child: RotationTransition(
                                turns: _rotateAnimation,
                                child: Icon(
                                  Icons.add_circle_rounded,
                                  color: Colors.white,
                                  size: isTablet ? 40 : 35,
                                ),
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
                                    colors: [Colors.white, _goldAccent],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: Text(
                                    'Create New Event',
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 32 : 26,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Share your event with the community',
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 18 : 16,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: isTablet ? 28 : 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isTablet ? 32 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Info Card
                            Container(
                              padding: EdgeInsets.all(isTablet ? 20 : 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_primaryGreen.withOpacity(0.1), _primaryRed.withOpacity(0.1)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: _primaryGreen.withOpacity(0.25),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_primaryGreen, _darkGreen],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _primaryGreen.withOpacity(0.3),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.info_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 28 : 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Admin Approval Required',
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.w700,
                                            color: _primaryGreen,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Events will be reviewed before appearing publicly',
                                          style: GoogleFonts.inter(
                                            fontSize: isTablet ? 14 : 12,
                                            color: _textLight,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: isTablet ? 30 : 24),

                            // Form Fields
                            _buildPremiumDialogTextField(
                              controller: _titleController,
                              label: 'Event Title',
                              isRequired: true,
                              icon: Icons.title_rounded,
                              gradient: LinearGradient(
                                colors: [_primaryGreen, _darkGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              isTablet: isTablet,
                            ),
                            SizedBox(height: isTablet ? 20 : 16),

                            _buildPremiumDialogTextField(
                              controller: _organizerController,
                              label: 'Organizer',
                              isRequired: true,
                              icon: Icons.business_rounded,
                              gradient: LinearGradient(
                                colors: [_primaryRed, _coralRed],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              isTablet: isTablet,
                            ),
                            SizedBox(height: isTablet ? 20 : 16),

                            _buildPremiumDialogTextField(
                              controller: _contactPersonController,
                              label: 'Contact Person',
                              isRequired: true,
                              icon: Icons.person_rounded,
                              gradient: LinearGradient(
                                colors: [_primaryGreen, _mintGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              isTablet: isTablet,
                            ),
                            SizedBox(height: isTablet ? 20 : 16),

                            _buildPremiumDialogTextField(
                              controller: _contactEmailController,
                              label: 'Contact Email',
                              isRequired: true,
                              icon: Icons.email_rounded,
                              gradient: LinearGradient(
                                colors: [_goldAccent, _softGold],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              isTablet: isTablet,
                            ),
                            SizedBox(height: isTablet ? 20 : 16),

                            _buildPremiumDialogTextField(
                              controller: _contactPhoneController,
                              label: 'Contact Phone',
                              isRequired: true,
                              icon: Icons.phone_rounded,
                              gradient: LinearGradient(
                                colors: [_primaryRed, _coralRed],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              keyboardType: TextInputType.phone,
                              isTablet: isTablet,
                            ),
                            SizedBox(height: isTablet ? 20 : 16),

                            // Date Picker
                            GestureDetector(
                              onTap: () => _selectEventDate(context, setState),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 24 : 20,
                                  vertical: isTablet ? 20 : 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.95),
                                      Colors.white.withOpacity(0.9),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: _selectedDate != null ? _emeraldGreen : Colors.grey.shade300.withOpacity(0.3),
                                    width: _selectedDate != null ? 2 : 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryGreen.withOpacity(0.15),
                                      blurRadius: 16,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [_primaryGreen, _darkGreen],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.calendar_today_rounded,
                                        color: Colors.white,
                                        size: isTablet ? 24 : 22,
                                      ),
                                    ),
                                    SizedBox(width: isTablet ? 20 : 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Event Date & Time *',
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 16 : 14,
                                              fontWeight: FontWeight.w600,
                                              color: _primaryGreen,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            _selectedDate != null
                                                ? DateFormat('EEEE, MMMM d, y • h:mm a').format(_selectedDate!)
                                                : 'Select date and time',
                                            style: GoogleFonts.inter(
                                              fontSize: isTablet ? 16 : 14,
                                              color: _selectedDate != null ? _textPrimary : _textLight,
                                              fontWeight: _selectedDate != null ? FontWeight.w700 : FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: _primaryGreen,
                                      size: isTablet ? 32 : 28,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: isTablet ? 20 : 16),

                            _buildPremiumDialogTextField(
                              controller: _locationController,
                              label: 'Location',
                              isRequired: true,
                              icon: Icons.location_on_rounded,
                              gradient: LinearGradient(
                                colors: [_primaryGreen, _mintGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              isTablet: isTablet,
                            ),
                            SizedBox(height: isTablet ? 20 : 16),

                            // Category Dropdown
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 24 : 20,
                                vertical: isTablet ? 16 : 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.95),
                                    Colors.white.withOpacity(0.9),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.grey.shade300.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _goldAccent.withOpacity(0.15),
                                    blurRadius: 16,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: DropdownButton<String>(
                                value: _selectedEventCategory,
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                underline: SizedBox(),
                                icon: RotationTransition(
                                  turns: _rotateAnimation,
                                  child: Icon(
                                    Icons.arrow_drop_down_circle_rounded,
                                    color: _primaryRed,
                                    size: isTablet ? 28 : 24,
                                  ),
                                ),
                                items: EventCategory.values
                                    .where((category) => category != EventCategory.all)
                                    .map((category) {
                                  return DropdownMenuItem<String>(
                                    value: category.stringValue,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [_primaryRed, _primaryGreen],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            category.iconData,
                                            color: Colors.white,
                                            size: isTablet ? 22 : 18,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Text(
                                          category.displayName,
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.w600,
                                            color: _darkGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedEventCategory = value!;
                                  });
                                },
                              ),
                            ),
                            SizedBox(height: isTablet ? 20 : 16),

                            // Image Upload
                            GestureDetector(
                              onTap: () => _pickImage(setState),
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 24 : 20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.95),
                                      Colors.white.withOpacity(0.9),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: _selectedImage != null ? _emeraldGreen : Colors.grey.shade300.withOpacity(0.3),
                                    width: _selectedImage != null ? 2 : 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryRed.withOpacity(0.15),
                                      blurRadius: 16,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    if (_selectedImage != null) ...[
                                      Container(
                                        height: isTablet ? 180 : 140,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          image: DecorationImage(
                                            image: FileImage(File(_selectedImage!.path)),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: isTablet ? 20 : 16),
                                    ],
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [_primaryRed, _coralRed],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Icon(
                                            _selectedImage != null ? Icons.image_rounded : Icons.add_photo_alternate_rounded,
                                            color: Colors.white,
                                            size: isTablet ? 24 : 22,
                                          ),
                                        ),
                                        SizedBox(width: 20),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _selectedImage != null ? 'Banner Image Selected' : 'Upload Banner Image',
                                                style: GoogleFonts.poppins(
                                                  fontSize: isTablet ? 18 : 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: _selectedImage != null ? _emeraldGreen : _primaryGreen,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                _selectedImage != null 
                                                    ? 'Tap to change image' 
                                                    : 'Recommended: 1200×600px',
                                                style: GoogleFonts.inter(
                                                  fontSize: isTablet ? 14 : 12,
                                                  color: _textLight,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_isImageLoading)
                                      Padding(
                                        padding: EdgeInsets.only(top: isTablet ? 20 : 16),
                                        child: CircularProgressIndicator(
                                          color: _emeraldGreen,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: isTablet ? 20 : 16),

                            // Description
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.95),
                                    Colors.white.withOpacity(0.9),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.grey.shade300.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _mintGreen.withOpacity(0.15),
                                    blurRadius: 16,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _descriptionController,
                                maxLines: 4,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 16 : 14,
                                  color: _textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Event Description *',
                                  labelStyle: GoogleFonts.poppins(
                                    fontSize: isTablet ? 14 : 13,
                                    color: _coralRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  alignLabelWithHint: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(isTablet ? 24 : 20),
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.only(top: 20),
                                    child: Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [_coralRed, _primaryRed],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.description_rounded,
                                        color: Colors.white,
                                        size: isTablet ? 24 : 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isTablet ? 20 : 16),

                            // Free Event Checkbox
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isFree = !_isFree;
                                  if (_isFree) {
                                    _ticketPrices.clear();
                                  }
                                });
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 20 : 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.95),
                                      Colors.white.withOpacity(0.9),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: _isFree ? _emeraldGreen : Colors.grey.shade300.withOpacity(0.3),
                                    width: _isFree ? 2 : 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _emeraldGreen.withOpacity(_isFree ? 0.2 : 0.1),
                                      blurRadius: 16,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: isTablet ? 30 : 26,
                                      height: isTablet ? 30 : 26,
                                      decoration: BoxDecoration(
                                        gradient: _isFree ? LinearGradient(colors: [_emeraldGreen, _darkGreen]) : null,
                                        color: _isFree ? null : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _isFree ? Colors.transparent : Colors.grey[400]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: _isFree
                                          ? Icon(
                                              Icons.check_rounded,
                                              color: Colors.white,
                                              size: isTablet ? 20 : 18,
                                            )
                                          : null,
                                    ),
                                    SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Free Event',
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 20 : 18,
                                              fontWeight: FontWeight.w700,
                                              color: _isFree ? _emeraldGreen : _textPrimary,
                                            ),
                                          ),
                                          if (!_isFree)
                                            Text(
                                              'Configure ticket prices below',
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
                              ),
                            ),
                            SizedBox(height: isTablet ? 20 : 16),

                            // Ticket Prices (if not free)
                            if (!_isFree) ...[
                              Container(
                                padding: EdgeInsets.all(isTablet ? 20 : 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryRed, _coralRed],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.monetization_on_rounded,
                                          color: Colors.white,
                                          size: isTablet ? 28 : 24,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Ticket Prices',
                                          style: GoogleFonts.poppins(
                                            fontSize: isTablet ? 22 : 18,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: isTablet ? 20 : 16),
                                    
                                    // Existing Tickets
                                    ..._ticketPrices.entries.map((entry) {
                                      return Container(
                                        margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
                                        padding: EdgeInsets.all(isTablet ? 16 : 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                entry.key,
                                                style: GoogleFonts.poppins(
                                                  fontSize: isTablet ? 18 : 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isTablet ? 20 : 16,
                                                vertical: isTablet ? 10 : 8,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [_goldAccent, _softGold],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '\$${entry.value.toStringAsFixed(2)}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: isTablet ? 18 : 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    
                                    // Add Ticket Row
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: TextFormField(
                                              controller: _ticketTypeController,
                                              style: GoogleFonts.inter(
                                                fontSize: isTablet ? 16 : 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: 'Type (e.g., VIP)',
                                                hintStyle: GoogleFonts.inter(
                                                  color: Colors.white.withOpacity(0.5),
                                                ),
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.all(isTablet ? 16 : 12),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          flex: 1,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: TextFormField(
                                              controller: _ticketPriceController,
                                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                                              style: GoogleFonts.inter(
                                                fontSize: isTablet ? 16 : 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: 'Price',
                                                hintStyle: GoogleFonts.inter(
                                                  color: Colors.white.withOpacity(0.5),
                                                ),
                                                prefixText: '\$',
                                                prefixStyle: GoogleFonts.inter(
                                                  color: Colors.white,
                                                ),
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.all(isTablet ? 16 : 12),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: () {
                                            final type = _ticketTypeController.text.trim();
                                            final priceText = _ticketPriceController.text.trim();
                                            if (type.isNotEmpty && priceText.isNotEmpty) {
                                              final price = double.tryParse(priceText);
                                              if (price != null && price > 0) {
                                                setState(() {
                                                  _ticketPrices[type] = price;
                                                  _ticketTypeController.clear();
                                                  _ticketPriceController.clear();
                                                });
                                                HapticFeedback.lightImpact();
                                              }
                                            }
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [_emeraldGreen, _darkGreen],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _emeraldGreen.withOpacity(0.3),
                                                  blurRadius: 12,
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.add_rounded,
                                              color: Colors.white,
                                              size: isTablet ? 24 : 22,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: isTablet ? 20 : 16),
                            ],

                            SizedBox(height: isTablet ? 20 : 16),
                          ],
                        ),
                      ),
                    ),

                    // Footer Buttons
                    Container(
                      padding: EdgeInsets.all(isTablet ? 32 : 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(isTablet ? 50 : 40),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.shade300.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _clearForm();
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 20 : 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: _primaryRed,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryRed.withOpacity(0.15),
                                      blurRadius: 15,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 20 : 18,
                                      fontWeight: FontWeight.w700,
                                      color: _primaryRed,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: isTablet ? 20 : 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: _isSaving ? null : () => _createEvent(context, setState),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 20 : 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: _isSaving
                                      ? LinearGradient(colors: [_textLight, _textSecondary])
                                      : LinearGradient(colors: [_primaryGreen, _darkGreen]),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _emeraldGreen.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isSaving
                                      ? SizedBox(
                                          width: isTablet ? 30 : 26,
                                          height: isTablet ? 30 : 26,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.send_rounded,
                                              color: Colors.white,
                                              size: isTablet ? 24 : 22,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Create',
                                              style: GoogleFonts.poppins(
                                                fontSize: isTablet ? 20 : 18,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
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
        },
      ),
    );
  }

  Widget _buildPremiumDialogTextField({
    required TextEditingController controller,
    required String label,
    required bool isRequired,
    required IconData icon,
    required LinearGradient gradient,
    TextInputType keyboardType = TextInputType.text,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.grey.shade300.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.15),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
          fontSize: isTablet ? 16 : 14,
          color: _textPrimary,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          labelStyle: GoogleFonts.poppins(
            fontSize: isTablet ? 14 : 13,
            color: gradient.colors.first,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(isTablet ? 14 : 12),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.25),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: isTablet ? 22 : 20),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 20,
            vertical: isTablet ? 18 : 14,
          ),
        ),
      ),
    );
  }

  Future<void> _selectEventDate(BuildContext context, StateSetter setState) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: _emeraldGreen,
              onPrimary: Colors.white,
              surface: _darkGreen,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: _darkGreen,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _goldAccent,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: 18, minute: 0),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: _emeraldGreen,
                onPrimary: Colors.white,
                surface: _darkGreen,
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: _darkGreen,
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: _goldAccent,
                ),
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _pickImage(StateSetter setState) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _isImageLoading = true;
        });
        
        final bytes = await File(image.path).readAsBytes();
        final base64String = base64Encode(bytes);
        
        final mimeType = _getMimeType(image.path);
        final dataUrl = 'data:$mimeType;base64,$base64String';
        
        setState(() {
          _base64Image = dataUrl;
          _isImageLoading = false;
        });
        
        print('✅ Image converted to base64, length: ${dataUrl.length}');
      }
    } catch (e) {
      setState(() {
        _isImageLoading = false;
      });
      print('❌ Error picking image: $e');
      _showPremiumSnackBar('Error picking image: $e', isError: true);
    }
  }

  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _createEvent(BuildContext context, StateSetter setState) async {
    // Validation
    if (_titleController.text.isEmpty) {
      _showPremiumSnackBar('Enter event title', isError: true);
      return;
    }
    
    if (_organizerController.text.isEmpty) {
      _showPremiumSnackBar('Enter organizer name', isError: true);
      return;
    }
    
    if (_contactPersonController.text.isEmpty) {
      _showPremiumSnackBar('Enter contact person', isError: true);
      return;
    }
    
    if (_contactEmailController.text.isEmpty) {
      _showPremiumSnackBar('Enter contact email', isError: true);
      return;
    }
    
    if (_contactPhoneController.text.isEmpty) {
      _showPremiumSnackBar('Enter contact phone', isError: true);
      return;
    }
    
    if (_selectedDate == null) {
      _showPremiumSnackBar('Select event date', isError: true);
      return;
    }
    
    if (_locationController.text.isEmpty) {
      _showPremiumSnackBar('Enter location', isError: true);
      return;
    }
    
    if (_descriptionController.text.isEmpty) {
      _showPremiumSnackBar('Enter event description', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await eventProvider.createEvent(
        title: _titleController.text,
        organizer: _organizerController.text,
        contactPerson: _contactPersonController.text,
        contactEmail: _contactEmailController.text,
        contactPhone: _contactPhoneController.text,
        eventDate: _selectedDate!,
        location: _locationController.text,
        description: _descriptionController.text,
        category: _selectedEventCategory,
        bannerImageUrl: _base64Image,
        isFree: _isFree,
        ticketPrices: _ticketPrices.isEmpty ? null : _ticketPrices,
        paymentInfo: null,
        createdBy: currentUser.id,
      );

      _clearForm();
      
      Navigator.pop(context);
      
      _showPremiumSuccessDialog(context, isTablet: MediaQuery.of(context).size.width >= 600);
    } catch (e) {
      _showPremiumSnackBar('Error: $e', isError: true);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showPremiumSuccessDialog(BuildContext context, {required bool isTablet}) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(isTablet ? 40 : 20),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, _mintCream, _peachBlossom],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: _emeraldGreen.withOpacity(0.3),
                    blurRadius: 40,
                    offset: Offset(0, 20),
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 50 : 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success Animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.85 + (0.15 * value),
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 28 : 24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryGreen, _darkGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _emeraldGreen.withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: RotationTransition(
                              turns: _rotateAnimation,
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: isTablet ? 80 : 70,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: isTablet ? 40 : 30),
                    
                    // Welcome Text
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [_primaryGreen, _darkGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'Success! 🎉',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 40 : 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    
                    // Success Message
                    Text(
                      'Your event has been created!',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 22 : 20,
                        fontWeight: FontWeight.w700,
                        color: _primaryGreen,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Admin Contact Card
                    Container(
                      padding: EdgeInsets.all(isTablet ? 24 : 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryGreen.withOpacity(0.1), _primaryRed.withOpacity(0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(
                          color: _primaryGreen.withOpacity(0.25),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryRed, _primaryGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryRed.withOpacity(0.3),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.admin_panel_settings_rounded,
                              color: Colors.white,
                              size: isTablet ? 40 : 35,
                            ),
                          ),
                          SizedBox(height: isTablet ? 16 : 12),
                          Text(
                            'Admin Approval Pending',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.w700,
                              color: _primaryGreen,
                            ),
                          ),
                          SizedBox(height: isTablet ? 6 : 4),
                          Text(
                            'Your event will appear after review',
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 16 : 14,
                              color: _textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isTablet ? 40 : 30),
                    
                    // Close Button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 20 : 18,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryGreen, _darkGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: _emeraldGreen.withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Awesome!',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: isTablet ? 24 : 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPremiumSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isError
                ? LinearGradient(colors: [_primaryRed, _coralRed])
                : LinearGradient(colors: [_primaryGreen, _darkGreen]),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: (isError ? _primaryRed : _primaryGreen).withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 6),
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

  void _clearForm() {
    _titleController.clear();
    _organizerController.clear();
    _contactPersonController.clear();
    _contactEmailController.clear();
    _contactPhoneController.clear();
    _locationController.clear();
    _descriptionController.clear();
    _ticketTypeController.clear();
    _ticketPriceController.clear();
    _selectedDate = null;
    _selectedImage = null;
    _base64Image = null;
    _isFree = true;
    _ticketPrices.clear();
    _selectedEventCategory = 'social';
  }
}