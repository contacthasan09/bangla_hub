// screens/user_app/event/events_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:bangla_hub/providers/location_filter_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/auth/signup_screen.dart';
import 'package:bangla_hub/screens/user_app/event/event_details_screen.dart';
import 'package:bangla_hub/services/cloudinary_service.dart';
import 'package:bangla_hub/widgets/common/distance_widget.dart';
import 'package:bangla_hub/widgets/common/global_location_filter_bar.dart';
import 'package:bangla_hub/widgets/common/global_location_guard.dart';
import 'package:bangla_hub/widgets/common/location_aware_screen.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bangla_hub/models/event_model.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:bangla_hub/providers/event_provider.dart';
import 'package:bangla_hub/providers/auth_provider.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  // Color scheme
  final Color _primaryRed = const Color(0xFFF42A41);
  final Color _primaryGreen = const Color(0xFF006A4E);
  final Color _darkGreen = const Color(0xFF004D38);
  final Color _goldAccent = const Color(0xFFFFD700);
  final Color _offWhite = const Color(0xFFF8F8F8);
  final Color _primaryBlue = const Color(0xFF1976D2);
  final Color _darkBlue = const Color(0xFF0D47A1);
  final Color _lightBlue = const Color(0xFFE3F2FD);
  final Color _coralRed = const Color(0xFFFF6B6B);
  final Color _mintGreen = const Color(0xFF98D8C8);
  final Color _softGold = const Color(0xFFFFD966);
  final Color _creamWhite = const Color(0xFFFFF9E6);
  final Color _lightGreen = const Color(0xFFE8F5E9);
  final Color _lightRed = const Color(0xFFFFEBEE);
  final Color _emeraldGreen = const Color(0xFF2ECC71);
  final Color _sapphireBlue = const Color(0xFF3498DB);
  final Color _amethystPurple = const Color(0xFF9B59B6);
  final Color _mintCream = const Color(0xFFDCF8C6);
  final Color _peachBlossom = const Color(0xFFFFC0CB);
  final Color _textPrimary = const Color(0xFF1A1A2E);
  final Color _textSecondary = const Color(0xFF4A4A4A);
  final Color _textLight = const Color(0xFF6C757D);


   // Date/Time variables - ADD THESE
  bool _isMultiDay = false;
  DateTime? _selectedDate;  // For backward compatibility
  DateTime? _startDate;     // Start date
  DateTime? _endDate;       // End date for multi-day
  TimeOfDay? _startTime;    // Start time - THIS WAS MISSING
  TimeOfDay? _endTime;      // End time - THIS WAS MISSING
  
  final LinearGradient _premiumBgGradient = const LinearGradient(
    colors: [Color(0xFF006A4E), Color(0xFF004D38), Color(0xFFF42A41), Color(0xFFD32F2F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.3, 0.7, 1.0],
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

  int _currentSliderIndex = 0;
  late final PageController _sliderController;
  late final ScrollController _eventScrollController;
  String? _selectedCategory;
  
  bool _showAllUpcomingEvents = false;
  bool _showAllPastEvents = false;
  bool _isInitialized = false;
  bool _isFilterLoading = false;
  
  // Track filter state for UI updates
  String? _lastFilterState;
  bool _forceRebuild = false;
  
  final Map<String, List<EventModel>> _categorizedCache = {};
  final Map<String, Widget> _imageCache = {};
  
  Timer? _debounceTimer;
  Timer? _filterDebounceTimer;
  
  // ✅ Animation Controllers - All properly declared
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _rotateController;
  late final Animation<double> _rotateAnimation;
  late final AnimationController _scrollHintController;
  late final Animation<Offset> _scrollHintAnimation;
  late final Animation<double> _scrollHintOpacity;
  
  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _organizerController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ticketTypeController = TextEditingController();
  final TextEditingController _ticketPriceController = TextEditingController();
  
  // Image handling
  XFile? _selectedImage;
  String? _base64Image;
  bool _isImageLoading = false;
  
  // Form state
  bool _isSaving = false;
  String _selectedEventCategory = 'social';
  bool _isFree = true;
  final Map<String, double> _ticketPrices = {};
  
  // Location picking for event creation
  double? _eventLatitude;
  double? _eventLongitude;
  String? _eventState;
  String? _eventCity;
  
  // Auto slide timer
  Timer? _autoSlideTimer;
  bool _hasScrolled = false;

  // ✅ Track app lifecycle state
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  final List<EventCategory> _categoryOrder = const [
    EventCategory.all,
    EventCategory.social,
    EventCategory.religious,
    EventCategory.sports,
    EventCategory.business,
    EventCategory.educational,
  ];

  final List<String> _usStates = const [
    'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
    'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho',
    'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
    'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
    'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada',
    'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
    'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon',
    'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
    'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
    'West Virginia', 'Wisconsin', 'Wyoming'
  ];

  @override
  void initState() {
    super.initState();
    
    print('🚀 EventsScreen initState called');
    
    _sliderController = PageController(viewportFraction: 0.9);
    _eventScrollController = ScrollController();
    
    // ✅ Initialize animations properly
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
    
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnimation = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
    
    _rotateController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _rotateAnimation = CurvedAnimation(parent: _rotateController, curve: Curves.easeInOut);
    
    _scrollHintController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _scrollHintAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.3))
        .animate(CurvedAnimation(parent: _scrollHintController, curve: Curves.easeInOut));
    _scrollHintOpacity = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _scrollHintController, curve: Curves.easeInOut));
    
    // ✅ Add WidgetsBindingObserver for lifecycle
    WidgetsBinding.instance.addObserver(this);
    
    _eventScrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimations(); // ✅ Start animations only when visible
      setState(() => _isInitialized = true);
      
      // Get user location if not already
      final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
      if (locationProvider.currentUserLocation == null) {
        locationProvider.getUserLocation(showLoading: false);
      }
      
      // ✅ Add listener to location filter changes
      locationProvider.addListener(_onLocationFilterChanged);
    });
  }

  // ✅ Handle location filter changes with debounce
  void _onLocationFilterChanged() {
    final newState = Provider.of<LocationFilterProvider>(context, listen: false).selectedState;
    print('📍 EventsScreen: Location filter changed to: $newState');
    
    // Cancel previous debounce timer
    _filterDebounceTimer?.cancel();
    
    // Show loading indicator
    if (mounted) {
      setState(() => _isFilterLoading = true);
    }
    
    // Debounce to prevent too many rebuilds
    _filterDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _categorizedCache.clear();
          _imageCache.clear();
          _currentSliderIndex = 0;
          _lastFilterState = newState;
          _forceRebuild = !_forceRebuild;
          _isFilterLoading = false;
        });
        print('📍 EventsScreen: UI updated with filter: $newState');
      }
    });
  }

  // ✅ New method to start animations
  void _startAnimations() {
    if (_appLifecycleState == AppLifecycleState.resumed && mounted) {
      _fadeController.forward();
      _slideController.forward();
      _scaleController.forward();
      _pulseController.repeat(reverse: true);
      _rotateController.repeat();
      _scrollHintController.repeat(reverse: true);
      _startAutoSlide();
    }
  }

  // ✅ New method to stop animations
  void _stopAnimations() {
    _fadeController.stop();
    _slideController.stop();
    _pulseController.stop();
    _scaleController.stop();
    _rotateController.stop();
    _scrollHintController.stop();
    _autoSlideTimer?.cancel();
  }

  // ✅ Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });
    
    if (state == AppLifecycleState.resumed) {
      // App is visible - start animations
      _startAnimations();
    } else if (state == AppLifecycleState.paused || 
               state == AppLifecycleState.inactive || 
               state == AppLifecycleState.detached) {
      // App is not visible - stop animations to save resources
      _stopAnimations();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
      
      // Sync with global location filter
      if (eventProvider.currentStateFilter != locationProvider.selectedState) {
        print('📍 EventsScreen: Syncing filter from ${eventProvider.currentStateFilter} to ${locationProvider.selectedState}');
        eventProvider.syncWithLocationFilter(locationProvider);
        
        // Force UI update
        setState(() {
          _categorizedCache.clear();
          _imageCache.clear();
          _lastFilterState = locationProvider.selectedState;
          _forceRebuild = !_forceRebuild;
        });
      }
      
      if (authProvider.user != null) {
        eventProvider.loadUserInterestedEvents(authProvider.user!.id);
      }
    });
  }

  void _onFilterChanged() {
    final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
    final currentFilter = locationProvider.selectedState;
    
    if (_lastFilterState != currentFilter) {
      print('📍 Events: Filter changed from $_lastFilterState to $currentFilter - forcing UI update');
      
      // Also sync with EventProvider if needed
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      if (eventProvider.currentStateFilter != currentFilter) {
        eventProvider.syncWithLocationFilter(locationProvider);
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _categorizedCache.clear();
            _imageCache.clear();
            _currentSliderIndex = 0;
            _lastFilterState = currentFilter;
            _forceRebuild = !_forceRebuild;
          });
        }
      });
    }
  }
  
  void _onScroll() {
    if (!_hasScrolled && _eventScrollController.position.pixels > 50) {
      setState(() => _hasScrolled = true);
    }
  }
  
  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (_appLifecycleState != AppLifecycleState.resumed) return;
    
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _sliderController.hasClients && _appLifecycleState == AppLifecycleState.resumed) {
        final eventProvider = Provider.of<EventProvider>(context, listen: false);
        final filteredEvents = _getFilteredEvents(eventProvider);
        
        if (filteredEvents.isNotEmpty) {
          int nextPage = _currentSliderIndex + 1;
          int totalEvents = _showAllUpcomingEvents ? filteredEvents.length : filteredEvents.take(5).length;
          if (nextPage >= totalEvents) nextPage = 0;
          
          _sliderController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }
  
  // ✅ FIXED: Properly filter events by location and category with null safety
  List<EventModel> _getFilteredEvents(EventProvider eventProvider) {
    final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
    
    // Start with all upcoming events
    List<EventModel> filteredEvents = eventProvider.upcomingEvents;
    
    // Apply location filter if active - with null safety
    if (locationProvider.isFilterActive && locationProvider.selectedState != null) {
      filteredEvents = filteredEvents.where((event) => 
        event.state != null && event.state == locationProvider.selectedState
      ).toList();
      print('📍 Filtered events by state (${locationProvider.selectedState}): ${filteredEvents.length}');
    }
    
    // Apply category filter if selected
    if (_selectedCategory != null && _selectedCategory != 'all') {
      filteredEvents = filteredEvents.where((event) => 
        event.category != null && event.category == _selectedCategory
      ).toList();
      print('📁 Filtered events by category (${_selectedCategory}): ${filteredEvents.length}');
    }
    
    if (filteredEvents.isEmpty && locationProvider.isFilterActive) {
      print('📍 Filter active but no events, returning empty list');
    }
    
    return filteredEvents;
  }

  // ✅ FIXED: All controllers properly disposed
  @override
  void dispose() {
    print('🗑️ EventsScreen disposing...');
    
    // ✅ Remove location filter listener
    try {
      final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
      locationProvider.removeListener(_onLocationFilterChanged);
    } catch (e) {
      // Provider might already be disposed
    }
    
    // ✅ Cancel timers
    _debounceTimer?.cancel();
    _autoSlideTimer?.cancel();
    _filterDebounceTimer?.cancel();
    
    // ✅ Remove observer
    WidgetsBinding.instance.removeObserver(this);
    
    // ✅ Stop all animations
    _stopAnimations();
    
    // ✅ Dispose all animation controllers
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    _scrollHintController.dispose();
    
    // ✅ Dispose scroll controllers
    _sliderController.dispose();
    _eventScrollController.dispose();
    
    // ✅ Dispose all TextEditingControllers
    _titleController.dispose();
    _organizerController.dispose();
    _contactPersonController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _ticketTypeController.dispose();
    _ticketPriceController.dispose();
    
    // ✅ Clear caches
    _imageCache.clear();
    _categorizedCache.clear();
    
    super.dispose();
  }


  // ✅ Improved empty filter state with better background integration
Widget _buildEmptyFilterState(bool isTablet, String state) {
  final screenHeight = MediaQuery.of(context).size.height;
  
  return Container(
    height: screenHeight * 0.6, // Take 60% of screen height for proper spacing
    margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
    child: Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 24 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.9),
                _lightRed.withOpacity(0.1), // Match your screen's light red
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
            border: Border.all(
              color: _primaryGreen.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with gradient background
              Container(
                padding: EdgeInsets.all(isTablet ? 18 : 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryGreen, _primaryRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _primaryGreen.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.location_off_rounded,
                  size: isTablet ? 45 : 38,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isTablet ? 20 : 16),
              
              // Title
              Text(
                'No Events Found',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.w800,
                  color: _primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 8 : 6),
              
              // Message with state
              Text(
                'in $state',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: _primaryRed,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 16 : 12),
              
              // Description
              Text(
                'There are currently no events scheduled in $state.\nCheck back later or try a different location.',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 14 : 12,
                  color: _textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 24 : 20),
              
              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Clear Filter Button
                  ElevatedButton.icon(
                    onPressed: () {
                      print('📍 Empty state: Clear filter button tapped');
                      
                      final filterProvider = Provider.of<LocationFilterProvider>(context, listen: false);
                      filterProvider.clearLocationFilter();
                      
                      final eventProvider = Provider.of<EventProvider>(context, listen: false);
                      eventProvider.updateStateFilter(null);
                      
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _categorizedCache.clear();
                            _imageCache.clear();
                            _currentSliderIndex = 0;
                            _lastFilterState = null;
                            _forceRebuild = !_forceRebuild;
                          });
                        }
                      });
                    },
                    icon: Icon(Icons.clear_rounded, size: isTablet ? 18 : 16),
                    label: Text(
                      'Clear Filter',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 14 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 16,
                        vertical: isTablet ? 12 : 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 3,
                    ),
                  ),
                  
             
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
  
  
  
  // ✅ Subtle background decoration
  Widget _buildBackgroundDecoration(bool isTablet) {
    return Container(
      height: 80,
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            left: -20,
            bottom: 0,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _primaryGreen.withOpacity(0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -30,
            top: 0,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _primaryRed.withOpacity(0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showLoginRequiredDialog(BuildContext context, String feature) {
    final Color _primaryRed = Color(0xFFE03C32);
    final Color _primaryGreen = Color(0xFF006A4E);
    final Color _goldAccent = Color(0xFFFFD700);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_primaryGreen, _primaryRed]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [_primaryRed, _primaryGreen]), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                child: Column(
                  children: [
                    Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(gradient: LinearGradient(colors: [_goldAccent, Color(0xFFFFC107)]), shape: BoxShape.circle), child: Icon(Icons.lock_rounded, color: Colors.white, size: 24)),
                    SizedBox(height: 8),
                    Text('Login Required', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('to access $feature', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.9))),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen())); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _primaryGreen, padding: EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text('Login', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)))),
                    SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen(role: 'user'))); }, style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white, width: 1.5), padding: EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text('Create Account', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)))),
                    SizedBox(height: 10),
                    TextButton(onPressed: () => Navigator.pop(context), child: Text('Continue Browsing', style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.7)))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  



/*  void _showLocationFilterDialog(BuildContext context) {
    final filterProvider = Provider.of<LocationFilterProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter by State', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: _primaryGreen)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 10),
            
            GestureDetector(
              onTap: () {
                print('📍 Events: Clearing filter - All States selected');
                
                filterProvider.clearLocationFilter();
                
                final eventProvider = Provider.of<EventProvider>(context, listen: false);
                eventProvider.updateStateFilter(null);
                
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _categorizedCache.clear();
                      _imageCache.clear();
                      _currentSliderIndex = 0;
                      _lastFilterState = null;
                      _forceRebuild = !_forceRebuild;
                    });
                  }
                });
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Showing events from all states'),
                    backgroundColor: Color(0xFF006A4E),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.public, color: _primaryGreen),
                    const SizedBox(width: 15),
                    Text('All States', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            
            Container(
              height: 300,
              child: ListView.builder(
                itemCount: _usStates.length,
                itemBuilder: (context, index) {
                  final state = _usStates[index];
                  final isSelected = filterProvider.selectedState == state;
                  
                  return GestureDetector(
                    onTap: () {
                      print('📍 Events: Setting filter to: $state');
                      
                      filterProvider.setLocationFilter(state, fromEvents: true);
                      
                      final eventProvider = Provider.of<EventProvider>(context, listen: false);
                      eventProvider.updateStateFilter(state);
                      
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _categorizedCache.clear();
                            _imageCache.clear();
                            _currentSliderIndex = 0;
                            _lastFilterState = state;
                            _forceRebuild = !_forceRebuild;
                          });
                        }
                      });
                      
                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Showing events in $state'),
                          backgroundColor: _primaryGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? _primaryGreen.withOpacity(0.1) : null,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: isSelected ? _primaryGreen : Colors.grey),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              state,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? _primaryGreen : Colors.black87,
                              ),
                            ),
                          ),
                          if (isSelected) Icon(Icons.check_circle, color: _primaryGreen),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

*/

void _showLocationFilterDialog(BuildContext context) {
  final filterProvider = Provider.of<LocationFilterProvider>(context, listen: false);
  final screenHeight = MediaQuery.of(context).size.height;
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // ✅ Add this to allow bottom sheet to be scrollable
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20))
    ),
    builder: (context) => SafeArea( // ✅ Wrap with SafeArea for notched phones
      child: Container(
        height: screenHeight * 0.8, // ✅ Limit height to 80% of screen
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter by State', 
                  style: GoogleFonts.poppins(
                    fontSize: 20, 
                    fontWeight: FontWeight.w700, 
                    color: _primaryGreen
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close), 
                  onPressed: () => Navigator.pop(context)
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            GestureDetector(
              onTap: () {
                print('📍 Events: Clearing filter - All States selected');
                
                filterProvider.clearLocationFilter();
                
                final eventProvider = Provider.of<EventProvider>(context, listen: false);
                eventProvider.updateStateFilter(null);
                
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _categorizedCache.clear();
                      _imageCache.clear();
                      _currentSliderIndex = 0;
                      _lastFilterState = null;
                      _forceRebuild = !_forceRebuild;
                    });
                  }
                });
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Showing events from all states'),
                    backgroundColor: Color(0xFF006A4E),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.public, color: _primaryGreen),
                    const SizedBox(width: 15),
                    Text('All States', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // ✅ Replace fixed height Container with Expanded
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _usStates.length,
                itemBuilder: (context, index) {
                  final state = _usStates[index];
                  final isSelected = filterProvider.selectedState == state;
                  
                  return GestureDetector(
                    onTap: () {
                      print('📍 Events: Setting filter to: $state');
                      
                      filterProvider.setLocationFilter(state, fromEvents: true);
                      
                      final eventProvider = Provider.of<EventProvider>(context, listen: false);
                      eventProvider.updateStateFilter(state);
                      
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _categorizedCache.clear();
                            _imageCache.clear();
                            _currentSliderIndex = 0;
                            _lastFilterState = state;
                            _forceRebuild = !_forceRebuild;
                          });
                        }
                      });
                      
                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Showing events in $state'),
                          backgroundColor: _primaryGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? _primaryGreen.withOpacity(0.1) : null,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: isSelected ? _primaryGreen : Colors.grey),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              state,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? _primaryGreen : Colors.black87,
                              ),
                            ),
                          ),
                          if (isSelected) Icon(Icons.check_circle, color: _primaryGreen),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  void _debugCheckEvents(EventProvider eventProvider) {
    print('🔍 DEBUG: Checking events in provider');
    print('📊 Upcoming events count: ${eventProvider.upcomingEvents.length}');
    if (eventProvider.upcomingEvents.isNotEmpty) {
      eventProvider.upcomingEvents.take(5).forEach((event) {
        print('  - Event: ${event.title}');
        print('    State: ${event.state ?? "Not set"}');
        print('    Has location: ${event.latitude != null && event.longitude != null}');
      });
    } else {
      print('⚠️ No upcoming events found');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

        return LocationGuard(
            required: true, // Events require location
            showBackButton: false,
      child: _buildMainContent(context),
    );
  }



     Widget _buildMainContent(BuildContext context) {
 
    _onFilterChanged();
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;
    final isSmallScreen = screenHeight < 700;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent, 
        statusBarIconBrightness: Brightness.light
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        drawer: _buildDrawer(context, isTablet),
        floatingActionButton: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return authProvider.user != null ? _buildPremiumFloatingActionButton(isTablet) : const SizedBox.shrink();
          },
        ),
        body: Container(
          decoration: BoxDecoration(gradient: _premiumBgGradient),
          child: Stack(
            children: [
              ...List.generate(30, (index) => _buildAnimatedParticle(index, screenWidth, screenHeight)),
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: 0.3,
                  duration: const Duration(seconds: 2),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Colors.white.withOpacity(0.1), Colors.transparent, _primaryRed.withOpacity(0.1), Colors.transparent],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              ...List.generate(8, (index) => _buildFloatingBubble(index, screenWidth, screenHeight)),
              RefreshIndicator(
                color: _goldAccent,
                backgroundColor: Colors.white,
                strokeWidth: 3,
                displacement: 40,
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _categorizedCache.clear();
                    _imageCache.clear();
                  });
                  
                  final eventProvider = Provider.of<EventProvider>(context, listen: false);
                  final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
                  eventProvider.syncWithLocationFilter(locationProvider);
                },
                child: CustomScrollView(
                  controller: _eventScrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) => _buildPremiumAppBar(isTablet, authProvider),
                    ),
                    
                    SliverToBoxAdapter(
                      child: Consumer<LocationFilterProvider>(
                        builder: (context, locationProvider, _) {
                          return GlobalLocationFilterBar(
                            isTablet: isTablet,
                            onClearTap: () {
                              print('📍 Events: Global filter bar clear button tapped');
                              
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _categorizedCache.clear();
                                    _imageCache.clear();
                                    _currentSliderIndex = 0;
                                    _lastFilterState = null;
                                    _forceRebuild = !_forceRebuild;
                                  });
                                }
                              });
                              
                              locationProvider.clearLocationFilter();
                              
                              final eventProvider = Provider.of<EventProvider>(context, listen: false);
                              eventProvider.updateStateFilter(null);
                            },
                          );
                        },
                      ),
                    ),
                    
                    // Show loading indicator during filter changes
                    if (_isFilterLoading)
                      SliverToBoxAdapter(
                        child: Container(
                          height: 50,
                          margin: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _goldAccent,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    
                    SliverToBoxAdapter(
                      child: Consumer3<EventProvider, LocationFilterProvider, AuthProvider>(
                        builder: (context, eventProvider, locationProvider, authProvider, _) {
                          if (locationProvider.isFilterActive) {
                            print('📍 Active filter: ${locationProvider.selectedState}');
                            _debugCheckEvents(eventProvider);
                          }
                          
                          // Force rebuild when locationProvider changes by using its value in the key
                          return _buildPremiumBodyContent(
                            Key('events_content_${locationProvider.selectedState ?? 'all'}_${_selectedCategory ?? 'all'}_${locationProvider.isFilterActive}_$_forceRebuild'),
                            isSmallScreen, 
                            isTablet, 
                            eventProvider, 
                            locationProvider, 
                            authProvider
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (!_hasScrolled && _isInitialized && !_isFilterLoading)
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _scrollHintOpacity,
                    child: SlideTransition(
                      position: _scrollHintAnimation,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20, vertical: isTablet ? 16 : 12),
                        decoration: BoxDecoration(
                          gradient: _glassMorphismGradient,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
                        ),
                        margin: EdgeInsets.symmetric(horizontal: isTablet ? 100 : 50),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.swipe_vertical_rounded, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('Scroll for more events', style: GoogleFonts.poppins(color: Colors.white, fontSize: isTablet ? 16 : 14, fontWeight: FontWeight.w600)),
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

 


/* Widget _buildMainContent(BuildContext context) {
  _onFilterChanged();
  
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final isTablet = screenWidth >= 600;
  final isSmallScreen = screenHeight < 700;
  
  // Get auth state to conditionally show drawer
  final authProvider = Provider.of<AuthProvider>(context);
  final bool isLoggedIn = authProvider.isLoggedIn && authProvider.user != null;
  
  return AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent, 
      statusBarIconBrightness: Brightness.light
    ),
    child: Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      drawer: isLoggedIn ? _buildDrawer(context, isTablet) : null, // Only show drawer if logged in
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return authProvider.user != null ? _buildPremiumFloatingActionButton(isTablet) : const SizedBox.shrink();
        },
      ),
      body: Container(
        decoration: BoxDecoration(gradient: _premiumBgGradient),
        child: Stack(
          children: [
            ...List.generate(30, (index) => _buildAnimatedParticle(index, screenWidth, screenHeight)),
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: 0.3,
                duration: const Duration(seconds: 2),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Colors.white.withOpacity(0.1), Colors.transparent, _primaryRed.withOpacity(0.1), Colors.transparent],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            ...List.generate(8, (index) => _buildFloatingBubble(index, screenWidth, screenHeight)),
            RefreshIndicator(
              color: _goldAccent,
              backgroundColor: Colors.white,
              strokeWidth: 3,
              displacement: 40,
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                setState(() {
                  _categorizedCache.clear();
                  _imageCache.clear();
                });
                
                final eventProvider = Provider.of<EventProvider>(context, listen: false);
                final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
                eventProvider.syncWithLocationFilter(locationProvider);
              },
              child: CustomScrollView(
                controller: _eventScrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Add a SliverAppBar with drawer button for logged-in users
                  if (isLoggedIn)
                    SliverAppBar(
                      expandedHeight: 0,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: IconButton(
                        icon: Icon(
                          Icons.menu_rounded,
                          color: Colors.white,
                          size: isTablet ? 28 : 24,
                        ),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      flexibleSpace: Container(),
                    ),
                  
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) => _buildPremiumAppBar(isTablet, authProvider),
                  ),
                  
                  SliverToBoxAdapter(
                    child: Consumer<LocationFilterProvider>(
                      builder: (context, locationProvider, _) {
                        return GlobalLocationFilterBar(
                          isTablet: isTablet,
                          onClearTap: () {
                            print('📍 Events: Global filter bar clear button tapped');
                            
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _categorizedCache.clear();
                                  _imageCache.clear();
                                  _currentSliderIndex = 0;
                                  _lastFilterState = null;
                                  _forceRebuild = !_forceRebuild;
                                });
                              }
                            });
                            
                            locationProvider.clearLocationFilter();
                            
                            final eventProvider = Provider.of<EventProvider>(context, listen: false);
                            eventProvider.updateStateFilter(null);
                          },
                        );
                      },
                    ),
                  ),
                  
                  // Show loading indicator during filter changes
                  if (_isFilterLoading)
                    SliverToBoxAdapter(
                      child: Container(
                        height: 50,
                        margin: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: _goldAccent,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                  
                  SliverToBoxAdapter(
                    child: Consumer3<EventProvider, LocationFilterProvider, AuthProvider>(
                      builder: (context, eventProvider, locationProvider, authProvider, _) {
                        if (locationProvider.isFilterActive) {
                          print('📍 Active filter: ${locationProvider.selectedState}');
                          _debugCheckEvents(eventProvider);
                        }
                        
                        // Force rebuild when locationProvider changes by using its value in the key
                        return _buildPremiumBodyContent(
                          Key('events_content_${locationProvider.selectedState ?? 'all'}_${_selectedCategory ?? 'all'}_${locationProvider.isFilterActive}_$_forceRebuild'),
                          isSmallScreen, 
                          isTablet, 
                          eventProvider, 
                          locationProvider, 
                          authProvider
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (!_hasScrolled && _isInitialized && !_isFilterLoading)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _scrollHintOpacity,
                  child: SlideTransition(
                    position: _scrollHintAnimation,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20, vertical: isTablet ? 16 : 12),
                      decoration: BoxDecoration(
                        gradient: _glassMorphismGradient,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
                      ),
                      margin: EdgeInsets.symmetric(horizontal: isTablet ? 100 : 50),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.swipe_vertical_rounded, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Scroll for more events', style: GoogleFonts.poppins(color: Colors.white, fontSize: isTablet ? 16 : 14, fontWeight: FontWeight.w600)),
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
  
*/  



  
  Widget _buildDrawer(BuildContext context, bool isTablet) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Drawer(
          child: Container(
            decoration: BoxDecoration(gradient: LinearGradient(colors: [_primaryGreen, _darkGreen])),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(authProvider.user?.firstName ?? 'Guest User', style: GoogleFonts.poppins(fontSize: isTablet ? 20 : 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  accountEmail: Text(authProvider.user?.email ?? 'guest@example.com', style: GoogleFonts.inter(fontSize: isTablet ? 16 : 14, color: Colors.white.withOpacity(0.9))),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(authProvider.user?.firstName?.substring(0, 1).toUpperCase() ?? 'G', style: GoogleFonts.poppins(fontSize: isTablet ? 24 : 20, fontWeight: FontWeight.w800, color: _primaryGreen)),
                  ),
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF42A41), Color(0xFF006A4E)])),
                ),
                _buildDrawerItem(icon: Icons.home_rounded, title: 'Home', onTap: () => Navigator.pop(context), isTablet: isTablet),
                _buildDrawerItem(icon: Icons.event_rounded, title: 'Events', onTap: () => Navigator.pop(context), isTablet: isTablet, isSelected: true),
                _buildDrawerItem(icon: Icons.favorite_rounded, title: 'My Interests', onTap: () => Navigator.pop(context), isTablet: isTablet),
                _buildDrawerItem(icon: Icons.history_rounded, title: 'My Events', onTap: () => Navigator.pop(context), isTablet: isTablet),
                const Divider(color: Colors.white30),
                if (authProvider.user != null)
                  _buildDrawerItem(icon: Icons.logout_rounded, title: 'Logout', onTap: () async {
                    Navigator.pop(context);
                    await authProvider.signOut();
                  }, isTablet: isTablet),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap, required bool isTablet, bool isSelected = false}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? _goldAccent : Colors.white),
      title: Text(title, style: GoogleFonts.poppins(color: isSelected ? _goldAccent : Colors.white, fontSize: isTablet ? 18 : 16, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
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
                  gradient: RadialGradient(colors: [Colors.white.withOpacity(0.2), _primaryRed.withOpacity(0.1), Colors.transparent]),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
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
                  gradient: RadialGradient(colors: [_goldAccent.withOpacity(0.5), _primaryGreen.withOpacity(0.3), Colors.transparent]),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }





/*Widget _buildPremiumAppBar(bool isTablet, AuthProvider authProvider) {
  return SliverToBoxAdapter(
    child: Container(
      padding: EdgeInsets.fromLTRB(isTablet ? 32 : 24, MediaQuery.of(context).padding.top + (isTablet ? 30 : 20), isTablet ? 32 : 24, isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFF42A41), Color(0xFF006A4E), Color(0xFFFFD966)]).createShader(bounds),
                  child: Text(
                    authProvider.user != null ? 'Hello, ${authProvider.user!.firstName}!' : authProvider.isGuestMode ? 'Hello, Guest!' : 'Hello to BanglaHub!',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                     //  fontSize: isTablet ? 22 : 18,
                     fontSize: isTablet ? 18 : 15,
                        height: 1.2, color: Colors.white, letterSpacing: -0.5, shadows: const [Shadow(color: Color(0xFF004D38), blurRadius: 15, offset: Offset(0, 3))]),
                  ),
                ),
              ),
              if (authProvider.isGuestMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))]),
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.person_outline, color: Colors.white, size: 16), SizedBox(width: 4), Text('Guest', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))]),
                ),
            ],
          ),
          
          const SizedBox(height: 2),
          
          // Subtitle
          Text('Welcome to BanglaHub', style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
           //  fontSize: isTablet ? 18 : 16,
             fontSize: isTablet ? 15 : 13, 
             color: Colors.white.withOpacity(0.95), letterSpacing: 0.5, shadows: const [Shadow(color: Colors.black26, blurRadius: 5)])),
          
        //  const SizedBox(height: 16),
          const SizedBox(height: 12),
          
          // Events Title and Location Filter Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Events Title
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFF42A41), Color(0xFF006A4E), Color(0xFFFFD966)]).createShader(bounds),
                child: Text(
                  'Events', 
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900, 
                  //  fontSize: isTablet ? 40 : 32, 
                  fontSize: isTablet ? 32 : 24, 
                    height: 1.1, 
                    color: Colors.white, 
                    letterSpacing: -2, 
                    shadows: const [
                      Shadow(color: Color(0xFF004D38), blurRadius: 20, offset: Offset(0, 5)), 
                      Shadow(color: Color(0xFFF42A41), blurRadius: 15, offset: Offset(0, 2))
                    ],
                  ),
                ),
              ),
              
              // Location Filter Button - Impressive text when active
              Consumer<LocationFilterProvider>(

                builder: (context, filterProvider, child) {
                  final hasFilter = filterProvider.isFilterActive;
                  final selectedState = filterProvider.selectedState ?? '';
                  
                  return GestureDetector(
                    onTap: () => _showLocationFilterDialog(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: isTablet ? 14 : 10, vertical: isTablet ? 8 : 6),
                      decoration: BoxDecoration(
                        gradient: hasFilter
                            ? const LinearGradient(
                                colors: [Color(0xFF006A4E), Color(0xFF004D38)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: hasFilter 
                              ? const Color(0xFFFFD700).withOpacity(0.6)
                              : _goldAccent.withOpacity(0.4),
                          width: 1,
                        ),
                        boxShadow: hasFilter
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasFilter ? Icons.edit_location_rounded : Icons.location_on_rounded,
                            size: isTablet ? 16 : 14,
                            color: hasFilter ? const Color(0xFFFFD700) : _goldAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasFilter ? "Change Location" : "Select Location",
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 12 : 11,
                              fontWeight: hasFilter ? FontWeight.w600 : FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          if (!hasFilter) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: isTablet ? 18 : 16,
                              color: _goldAccent,
                            ),
                          ],
                          if (hasFilter) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFD700),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            
            
            ],
          ),
          
        //  const SizedBox(height: 20),
           const SizedBox(height: 14),
          
          // Browse Events Container
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1200),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(offset: Offset(0, 15 * (1 - value)), child: child),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 18 : 14, vertical: isTablet ? 10 : 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_primaryGreen.withOpacity(0.2), _primaryRed.withOpacity(0.1)]),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: _goldAccent.withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: _goldAccent, size: isTablet ? 22 : 20),
                  SizedBox(width: isTablet ? 10 : 8),
                  Text(
                    authProvider.isGuestMode ? 'Browse events as guest' : 'Discover and manage events seamlessly', 
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.95), 
                      fontSize: isTablet ? 13 : 11, 
                      fontWeight: FontWeight.w600, 
                      shadows: const [Shadow(color: Colors.black26, blurRadius: 3)]
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

*/

Widget _buildPremiumAppBar(bool isTablet, AuthProvider authProvider) {
  final bool isLoggedIn = authProvider.isLoggedIn && authProvider.user != null;
  final String userName = authProvider.user?.firstName ?? authProvider.user?.email?.split('@').first ?? 'User';
  
  return SliverToBoxAdapter(
    child: Container(
      padding: EdgeInsets.fromLTRB(isTablet ? 32 : 24, MediaQuery.of(context).padding.top + (isTablet ? 30 : 20), isTablet ? 32 : 24, isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Row with Drawer Button and Username together
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side - Drawer button and Welcome text
              Expanded(
                child: Row(
                  children: [
                    // Drawer button for logged-in users
                    if (isLoggedIn)
                      IconButton(
                        icon: Icon(
                          Icons.menu_rounded,
                          color: Colors.white,
                          size: isTablet ? 28 : 24,
                        ),
                        onPressed: () {
                          try {
                            final ScaffoldState? scaffoldState = Scaffold.maybeOf(context);
                            if (scaffoldState != null && scaffoldState.hasDrawer) {
                              scaffoldState.openDrawer();
                            } else {
                              // Fallback: Try to find scaffold in the widget tree
                              Scaffold.of(context).openDrawer();
                            }
                          } catch (e) {
                            print('Could not open drawer: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Menu is available'),
                                duration: Duration(milliseconds: 800),
                                backgroundColor: _primaryGreen,
                              ),
                            );
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    
                    // Welcome text with username
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFF42A41), Color(0xFF006A4E), Color(0xFFFFD966)]
                        ).createShader(bounds),
                        child: Text(
                          isLoggedIn ? 'Hello, $userName!' : (authProvider.isGuestMode ? 'Hello, Guest!' : 'Hello to BanglaHub!'),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: isTablet ? 18 : 15,
                            height: 1.2, 
                            color: Colors.white, 
                            letterSpacing: -0.5, 
                            shadows: const [
                              Shadow(color: Color(0xFF004D38), blurRadius: 15, offset: Offset(0, 3))
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Right side - Guest badge or placeholder
              if (authProvider.isGuestMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange, 
                    borderRadius: BorderRadius.circular(20), 
                    boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))]
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, 
                    children: const [
                      Icon(Icons.person_outline, color: Colors.white, size: 16), 
                      SizedBox(width: 4), 
                      Text('Guest', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))
                    ],
                  ),
                )
              else if (!isLoggedIn)
                const SizedBox(width: 40) // Balance for non-logged in non-guest users
              else
                const SizedBox(width: 40), // Balance for logged-in users
            ],
          ),
          
          const SizedBox(height: 2),
          
          // Subtitle
          Text(
            'Welcome to BanglaHub', 
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: isTablet ? 15 : 13, 
              color: Colors.white.withOpacity(0.95), 
              letterSpacing: 0.5, 
              shadows: const [Shadow(color: Colors.black26, blurRadius: 5)]
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Events Title and Location Filter Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Events Title
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFF42A41), Color(0xFF006A4E), Color(0xFFFFD966)]
                ).createShader(bounds),
                child: Text(
                  'Events', 
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900, 
                    fontSize: isTablet ? 32 : 24, 
                    height: 1.1, 
                    color: Colors.white, 
                    letterSpacing: -2, 
                    shadows: const [
                      Shadow(color: Color(0xFF004D38), blurRadius: 20, offset: Offset(0, 5)), 
                      Shadow(color: Color(0xFFF42A41), blurRadius: 15, offset: Offset(0, 2))
                    ],
                  ),
                ),
              ),
              
              // Location Filter Button
              Consumer<LocationFilterProvider>(
                builder: (context, filterProvider, child) {
                  final hasFilter = filterProvider.isFilterActive;
                  final selectedState = filterProvider.selectedState ?? '';
                  
                  return GestureDetector(
                    onTap: () => _showLocationFilterDialog(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: isTablet ? 14 : 10, vertical: isTablet ? 8 : 6),
                      decoration: BoxDecoration(
                        gradient: hasFilter
                            ? const LinearGradient(
                                colors: [Color(0xFF006A4E), Color(0xFF004D38)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: hasFilter 
                              ? const Color(0xFFFFD700).withOpacity(0.6)
                              : _goldAccent.withOpacity(0.4),
                          width: 1,
                        ),
                        boxShadow: hasFilter
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasFilter ? Icons.edit_location_rounded : Icons.location_on_rounded,
                            size: isTablet ? 16 : 14,
                            color: hasFilter ? const Color(0xFFFFD700) : _goldAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasFilter ? "Change Location" : "Select Location",
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 12 : 11,
                              fontWeight: hasFilter ? FontWeight.w600 : FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          if (!hasFilter) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: isTablet ? 18 : 16,
                              color: _goldAccent,
                            ),
                          ],
                          if (hasFilter) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFD700),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 14),
          
          // Browse Events Container
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1200),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(offset: Offset(0, 15 * (1 - value)), child: child),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 18 : 14, vertical: isTablet ? 10 : 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_primaryGreen.withOpacity(0.2), _primaryRed.withOpacity(0.1)]),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: _goldAccent.withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: _goldAccent, size: isTablet ? 22 : 20),
                  SizedBox(width: isTablet ? 10 : 8),
                  Text(
                    authProvider.isGuestMode ? 'Browse events as guest' : 'Discover and manage events seamlessly', 
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.95), 
                      fontSize: isTablet ? 13 : 11, 
                      fontWeight: FontWeight.w600, 
                      shadows: const [Shadow(color: Colors.black26, blurRadius: 3)]
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
    // Only animate if app is visible
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    Widget button = Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF42A41), Color(0xFF006A4E)]),
        borderRadius: BorderRadius.circular(35),
        boxShadow: const [
          BoxShadow(color: Color(0xFFF42A41), blurRadius: 25, offset: Offset(0, 12), spreadRadius: 3), 
          BoxShadow(color: Color(0xFF006A4E), blurRadius: 30)
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPremiumAddEventDialog(context, isTablet),
          borderRadius: BorderRadius.circular(35),
          splashColor: Colors.white30,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 28 : 24, vertical: isTablet ? 16 : 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Only rotate if app is visible
                shouldAnimate
                    ? RotationTransition(turns: _rotateAnimation, child: const Icon(Icons.add_circle_rounded, color: Colors.white))
                    : const Icon(Icons.add_circle_rounded, color: Colors.white),
                SizedBox(width: isTablet ? 12 : 10),
                Text('Create Event', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: isTablet ? 18 : 16, color: Colors.white, letterSpacing: 0.3, shadows: const [Shadow(color: Colors.black26, blurRadius: 8)])),
              ],
            ),
          ),
        ),
      ),
    );
    
    // Only apply scale animation if app is visible
    return shouldAnimate
        ? ScaleTransition(scale: _pulseAnimation, child: button)
        : button;
  }

  Widget _buildPremiumBodyContent(
    Key key,
    bool isSmallScreen, 
    bool isTablet, 
    EventProvider eventProvider,
    LocationFilterProvider locationProvider,
    AuthProvider authProvider,
  ) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryRed.withOpacity(0.05), Colors.white, _primaryGreen.withOpacity(0.05), _offWhite],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isTablet ? 50 : 40),
          topRight: Radius.circular(isTablet ? 50 : 40),
        ),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 30, spreadRadius: 5, offset: Offset(0, -10))],
      ),
      child: _buildContent(isSmallScreen, isTablet, eventProvider, locationProvider, authProvider),
    );
  }


/*  Widget _buildContent(
  bool isSmallScreen, 
  bool isTablet, 
  EventProvider eventProvider,
  LocationFilterProvider locationProvider,
  AuthProvider authProvider,
) {
  if (!eventProvider.isInitialized && eventProvider.isLoading) {
    return _buildLoadingState(isTablet, isSmallScreen);
  }

  if (eventProvider.error != null && eventProvider.upcomingEvents.isEmpty && eventProvider.pastEvents.isEmpty) {
    return _buildErrorState(isTablet, isSmallScreen, eventProvider.error!);
  }

  // Get filtered events for the current state
  final filteredUpcoming = _getFilteredEvents(eventProvider);
  
  // Filter past events by location if needed - with null safety
  final filteredPast = locationProvider.isFilterActive && locationProvider.selectedState != null
      ? eventProvider.pastEvents.where((event) => 
          event.state != null && event.state == locationProvider.selectedState
        ).toList()
      : eventProvider.pastEvents;

  // If filter is active and there are no events, show empty state (NON-SCROLLABLE)
  if (locationProvider.isFilterActive && 
      filteredUpcoming.isEmpty && 
      filteredPast.isEmpty && 
      locationProvider.selectedState != null) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(), // Disable scrolling
          child: _buildEmptyFilterState(isTablet, locationProvider.selectedState!),
        ),
      ),
    );
  }

  // If no filter is active but there are no events at all, show empty carousel (NON-SCROLLABLE)
  if (!locationProvider.isFilterActive && 
      eventProvider.upcomingEvents.isEmpty && 
      eventProvider.pastEvents.isEmpty) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(), // Disable scrolling
          child: _buildEmptyCarouselState(isTablet, isSmallScreen, authProvider, locationProvider),
        ),
      ),
    );
  }

  final carouselEvents = filteredUpcoming.isNotEmpty 
      ? (_showAllUpcomingEvents ? filteredUpcoming : filteredUpcoming.take(5).toList())
      : [];
      
  final upcomingEventsToShow = filteredUpcoming.isNotEmpty
      ? (_showAllUpcomingEvents ? filteredUpcoming : filteredUpcoming.take(5).toList())
      : [];
      
  final pastEventsToShow = filteredPast.isNotEmpty
      ? (_showAllPastEvents ? filteredPast : filteredPast.take(3).toList())
      : [];
  
  // Regular scrollable content when events exist
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      //  SizedBox(height: isTablet ? 36 : 26),
        SizedBox(height: isTablet ? 20 : 15),
        
        // Upcoming Events Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF006A4E), Color(0xFF004D38)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Icon(Icons.event_available_rounded, color: Colors.white, size: isTablet ? 20 : 18),
                  ),
                  const SizedBox(width: 12),
                

                  ShaderMask(
  shaderCallback: (bounds) => const LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFF42A41)] // 2 colors: Gold and Red
  ).createShader(bounds),
  child: Text(
    'Upcoming Events',
    style: GoogleFonts.poppins(
      fontSize: isTablet ? 18 : 16,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
  ),
)


                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 14 : 12, vertical: isTablet ? 8 : 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF006A4E), Color(0xFF004D38)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Text('${filteredUpcoming.length} events', style: GoogleFonts.poppins(
                //  fontSize: isTablet ? 14 : 12,
                   fontSize: isTablet ? 12 : 10,
                   fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          ),
        ),
        
      //  SizedBox(height: isTablet ? 20 : 17),
      SizedBox(height: isTablet ? 12 : 10),
        
        // Events Carousel
        if (carouselEvents.isNotEmpty)
          SizedBox(
            height: isTablet ? 380 : 320,
            child: PageView.builder(
              controller: _sliderController,
              itemCount: carouselEvents.length,
              onPageChanged: (index) => setState(() => _currentSliderIndex = index),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () {
                  if (authProvider.isGuestMode) {
                    _showLoginRequiredDialog(context, 'view event details');
                    return;
                  }
                  HapticFeedback.mediumImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailsScreen(event: carouselEvents[index])));
                },
                child: _buildPremiumEventCard(carouselEvents[index], isSmallScreen, isTablet, index == _currentSliderIndex),
              ),
            ),
          )
        else if (!locationProvider.isFilterActive && filteredUpcoming.isEmpty)
          _buildEmptyCarouselState(isTablet, isSmallScreen, authProvider, locationProvider),
        
        if (carouselEvents.isNotEmpty) ...[
        //  SizedBox(height: isTablet ? 16 : 12),
           SizedBox(height: isTablet ? 12 : 10),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(carouselEvents.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentSliderIndex == index ? (isTablet ? 24 : 20) : (isTablet ? 10 : 8),
                  height: isTablet ? 6 : 4,
                  margin: EdgeInsets.symmetric(horizontal: isTablet ? 4 : 3),
                  decoration: BoxDecoration(
                    gradient: _currentSliderIndex == index 
                        ? const LinearGradient(colors: [Color(0xFFF42A41), Color(0xFF006A4E)]) 
                        : LinearGradient(colors: [Colors.grey[300]!, Colors.grey[400]!]),
                    borderRadius: BorderRadius.circular(isTablet ? 4 : 3),
                  ),
                );
              }),
            ),
          ),
        ],
        
     //   SizedBox(height: isTablet ? 25 : 20),
      SizedBox(height: isTablet ? 15 : 10),
        
        // Categories Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primaryRed, _coralRed]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: _primaryRed.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
                ),
                child: Icon(Icons.category_rounded, color: Colors.white, size: isTablet ? 20 : 18),
              ),
             // const SizedBox(width: 10),
               const SizedBox(width: 7),
            


ShaderMask(
  shaderCallback: (bounds) => const LinearGradient(
    colors: [Color(0xFF006A4E), Color(0xFF004D38)] // Dark Green to Darker Green
  ).createShader(bounds),
  child: Text(
    'Browse Categories',
    style: GoogleFonts.poppins(
      fontSize: isTablet ? 18 : 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
)



            ],
          ),
        ),
        
        SizedBox(height: isTablet ? 17 : 13),
        
        // Categories List
        SizedBox(
          height: isTablet ? 70 : 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
            itemCount: _categoryOrder.length,
            itemBuilder: (context, index) => _buildPremiumCategoryCard(_categoryOrder[index], isSmallScreen, isTablet),
          ),
        ),
        
        SizedBox(height: isTablet ? 30 : 24),
        
        // View All Toggle Button
        if (filteredUpcoming.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
            child: _buildViewToggleButton(isTablet),
          ),
        
        SizedBox(height: isTablet ? 20 : 16),
        
        // Upcoming Events List
        if (upcomingEventsToShow.isNotEmpty)
          ...upcomingEventsToShow.map((event) => GestureDetector(
            onTap: () {
              if (authProvider.isGuestMode) {
                _showLoginRequiredDialog(context, 'view event details');
                return;
              }
              HapticFeedback.lightImpact();
              Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailsScreen(event: event)));
            },
            child: _buildPremiumEventListItem(event, isSmallScreen, isTablet, isPast: false),
          )).toList(),
        
        // Past Events Section
        if (filteredPast.isNotEmpty) ...[
          SizedBox(height: isTablet ? 40 : 30),
          
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_coralRed, _primaryRed]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: _coralRed.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
                  ),
                  child: Icon(Icons.history_rounded, color: Colors.white, size: isTablet ? 20 : 18),
                ),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFF42A41), Color(0xFFFF6B6B)]).createShader(bounds),
                  child: Text('Past Events', style: GoogleFonts.poppins(
                  //  fontSize: isTablet ? 25 : 23,
                     fontSize: isTablet ? 18 : 16,
                     fontWeight: FontWeight.w600, color: Colors.white)),
                ),
                const Spacer(),
                _buildPastEventsToggleButton(isTablet),
              ],
            ),
          ),
          
          SizedBox(height: isTablet ? 20 : 16),
          
          // Past Events List
          ...pastEventsToShow.map((event) => GestureDetector(
            onTap: () {
              if (authProvider.isGuestMode) {
                _showLoginRequiredDialog(context, 'view event details');
                return;
              }
              HapticFeedback.lightImpact();
              Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailsScreen(event: event)));
            },
            child: _buildPremiumEventListItem(event, isSmallScreen, isTablet, isPast: true),
          )).toList(),
        ],
        
        SizedBox(height: isTablet ? 50 : 40),
        
        // Footer
        _buildPremiumFooter(isTablet),
        
        SizedBox(height: isTablet ? 30 : 20),
      ],
    ),
  );
}

*/

Widget _buildContent(
  bool isSmallScreen, 
  bool isTablet, 
  EventProvider eventProvider,
  LocationFilterProvider locationProvider,
  AuthProvider authProvider,
) {
  if (!eventProvider.isInitialized && eventProvider.isLoading) {
    return _buildLoadingState(isTablet, isSmallScreen);
  }

  if (eventProvider.error != null && eventProvider.upcomingEvents.isEmpty && eventProvider.pastEvents.isEmpty) {
    return _buildErrorState(isTablet, isSmallScreen, eventProvider.error!);
  }

  // Get filtered events for the current state
  final filteredUpcoming = _getFilteredEvents(eventProvider);
  
  // CORRECTED: Filter past events by state - only apply filter if state exists in event
  List<EventModel> filteredPast;
  
  if (locationProvider.isFilterActive && locationProvider.selectedState != null && locationProvider.selectedState!.isNotEmpty) {
    // Only filter past events that have a state field matching the selected state
    // Events without state will NOT be shown when filter is active
    filteredPast = eventProvider.pastEvents.where((event) => 
      event.state != null && event.state == locationProvider.selectedState
    ).toList();
    
    print('📍 Filtering past events by state: ${locationProvider.selectedState}');
    print('📊 Past events with state in this location: ${filteredPast.length}');
  } else {
    // No active filter - show ALL past events
    filteredPast = eventProvider.pastEvents;
    print('📍 No filter active, showing all ${filteredPast.length} past events');
  }

  // Debug prints
  print('📊 Past events total in provider: ${eventProvider.pastEvents.length}');
  print('📊 Past events with state field: ${eventProvider.pastEvents.where((e) => e.state != null).length}');
  print('📊 Filtered past events count: ${filteredPast.length}');
  
  if (filteredPast.isNotEmpty) {
    print('📋 Sample past event: ${filteredPast.first.title}, State: ${filteredPast.first.state ?? "No state"}');
  }

  // If filter is active and there are no events, show empty state
  if (locationProvider.isFilterActive && 
      filteredUpcoming.isEmpty && 
      filteredPast.isEmpty && 
      locationProvider.selectedState != null) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: _buildEmptyFilterState(isTablet, locationProvider.selectedState!),
        ),
      ),
    );
  }

  // If no filter is active but there are no events at all, show empty carousel
  if (!locationProvider.isFilterActive && 
      eventProvider.upcomingEvents.isEmpty && 
      eventProvider.pastEvents.isEmpty) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: _buildEmptyCarouselState(isTablet, isSmallScreen, authProvider, locationProvider),
        ),
      ),
    );
  }

  final carouselEvents = filteredUpcoming.isNotEmpty 
      ? (_showAllUpcomingEvents ? filteredUpcoming : filteredUpcoming.take(5).toList())
      : [];
      
  final upcomingEventsToShow = filteredUpcoming.isNotEmpty
      ? (_showAllUpcomingEvents ? filteredUpcoming : filteredUpcoming.take(5).toList())
      : [];
      
  final pastEventsToShow = filteredPast.isNotEmpty
      ? (_showAllPastEvents ? filteredPast : filteredPast.take(3).toList())
      : [];
  
  // Regular scrollable content when events exist
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: isTablet ? 20 : 15),
        
        // Upcoming Events Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF006A4E), Color(0xFF004D38)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Icon(Icons.event_available_rounded, color: Colors.white, size: isTablet ? 20 : 18),
                  ),
                  const SizedBox(width: 12),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFF42A41)]
                    ).createShader(bounds),
                    child: Text(
                      'Upcoming Events',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 14 : 12, vertical: isTablet ? 8 : 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF006A4E), Color(0xFF004D38)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Text('${filteredUpcoming.length} events', style: GoogleFonts.poppins(
                  fontSize: isTablet ? 12 : 10,
                  fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          ),
        ),
        
        SizedBox(height: isTablet ? 12 : 10),
        
        // Events Carousel
        if (carouselEvents.isNotEmpty)
          SizedBox(
            height: isTablet ? 380 : 320,
            child: PageView.builder(
              controller: _sliderController,
              itemCount: carouselEvents.length,
              onPageChanged: (index) => setState(() => _currentSliderIndex = index),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () {
                  if (authProvider.isGuestMode) {
                    _showLoginRequiredDialog(context, 'view event details');
                    return;
                  }
                  HapticFeedback.mediumImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailsScreen(event: carouselEvents[index])));
                },
                child: _buildPremiumEventCard(carouselEvents[index], isSmallScreen, isTablet, index == _currentSliderIndex),
              ),
            ),
          )
        else if (!locationProvider.isFilterActive && filteredUpcoming.isEmpty)
          _buildEmptyCarouselState(isTablet, isSmallScreen, authProvider, locationProvider),
        
        if (carouselEvents.isNotEmpty) ...[
          SizedBox(height: isTablet ? 12 : 10),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(carouselEvents.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentSliderIndex == index ? (isTablet ? 24 : 20) : (isTablet ? 10 : 8),
                  height: isTablet ? 6 : 4,
                  margin: EdgeInsets.symmetric(horizontal: isTablet ? 4 : 3),
                  decoration: BoxDecoration(
                    gradient: _currentSliderIndex == index 
                        ? const LinearGradient(colors: [Color(0xFFF42A41), Color(0xFF006A4E)]) 
                        : LinearGradient(colors: [Colors.grey[300]!, Colors.grey[400]!]),
                    borderRadius: BorderRadius.circular(isTablet ? 4 : 3),
                  ),
                );
              }),
            ),
          ),
        ],
        
        SizedBox(height: isTablet ? 15 : 10),
        
        // Categories Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primaryRed, _coralRed]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: _primaryRed.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
                ),
                child: Icon(Icons.category_rounded, color: Colors.white, size: isTablet ? 20 : 18),
              ),
              const SizedBox(width: 7),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF006A4E), Color(0xFF004D38)]
                ).createShader(bounds),
                child: Text(
                  'Browse Categories',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
        ),
        
        SizedBox(height: isTablet ? 17 : 13),
        
        // Categories List
        SizedBox(
          height: isTablet ? 70 : 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
            itemCount: _categoryOrder.length,
            itemBuilder: (context, index) => _buildPremiumCategoryCard(_categoryOrder[index], isSmallScreen, isTablet),
          ),
        ),
        
        SizedBox(height: isTablet ? 30 : 24),
        
        // View All Toggle Button
        if (filteredUpcoming.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
            child: _buildViewToggleButton(isTablet),
          ),
        
        SizedBox(height: isTablet ? 20 : 16),
        
        // Upcoming Events List
        if (upcomingEventsToShow.isNotEmpty)
          ...upcomingEventsToShow.map((event) => GestureDetector(
            onTap: () {
              if (authProvider.isGuestMode) {
                _showLoginRequiredDialog(context, 'view event details');
                return;
              }
              HapticFeedback.lightImpact();
              Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailsScreen(event: event)));
            },
            child: _buildPremiumEventListItem(event, isSmallScreen, isTablet, isPast: false),
          )).toList(),
        
        // Past Events Section
        if (filteredPast.isNotEmpty) ...[
          SizedBox(height: isTablet ? 40 : 30),
          
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_coralRed, _primaryRed]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: _coralRed.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
                  ),
                  child: Icon(Icons.history_rounded, color: Colors.white, size: isTablet ? 20 : 18),
                ),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFF42A41), Color(0xFFFF6B6B)]).createShader(bounds),
                  child: Text('Past Events', style: GoogleFonts.poppins(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600, 
                    color: Colors.white)),
                ),
                const Spacer(),
                if (filteredPast.length > 3)
                  _buildPastEventsToggleButton(isTablet),
              ],
            ),
          ),
          
          SizedBox(height: isTablet ? 20 : 16),
          
          // Past Events List
          ...pastEventsToShow.map((event) => GestureDetector(
            onTap: () {
              if (authProvider.isGuestMode) {
                _showLoginRequiredDialog(context, 'view event details');
                return;
              }
              HapticFeedback.lightImpact();
              Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailsScreen(event: event)));
            },
            child: _buildPremiumEventListItem(event, isSmallScreen, isTablet, isPast: true),
          )).toList(),
        ],
        
        SizedBox(height: isTablet ? 50 : 40),
        
        // Footer
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
        padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 10),
        decoration: BoxDecoration(
          gradient: _showAllUpcomingEvents ? LinearGradient(colors: [_primaryRed, _coralRed]) : const LinearGradient(colors: [Color(0xFF006A4E), Color(0xFF004D38)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: (_showAllUpcomingEvents ? _primaryRed : _primaryGreen).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_showAllUpcomingEvents ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: Colors.white, size: isTablet ? 18 : 16),
            const SizedBox(width: 8),
            Text(_showAllUpcomingEvents ? 'Show Less' : 'View All Events', style: GoogleFonts.poppins(fontSize: isTablet ? 14 : 13, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(width: 8),
            Icon(_showAllUpcomingEvents ? Icons.remove_rounded : Icons.add_rounded, color: Colors.white, size: isTablet ? 18 : 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPastEventsToggleButton(bool isTablet) {
    return GestureDetector(
      onTap: () {
        setState(() => _showAllPastEvents = !_showAllPastEvents);
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: isTablet ? 12 : 10),
        decoration: BoxDecoration(
          gradient: _showAllPastEvents ? LinearGradient(colors: [_primaryRed, _coralRed]) : const LinearGradient(colors: [Color(0xFF006A4E), Color(0xFF004D38)]),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: (_showAllPastEvents ? _primaryRed : _primaryGreen).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Icon(_showAllPastEvents ? Icons.remove_rounded : Icons.add_rounded, color: Colors.white, size: isTablet ? 20 : 18),
            const SizedBox(width: 8),
            Text(_showAllPastEvents ? 'Show Less' : 'View All', style: GoogleFonts.poppins(fontSize: isTablet ? 16 : 14, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCarouselState(bool isTablet, bool isSmallScreen, AuthProvider authProvider, LocationFilterProvider locationProvider) {
    String message;
    if (locationProvider.isFilterActive) {
      message = 'No events in ${locationProvider.selectedState}';
    } else {
      message = _selectedCategory != null && _selectedCategory != 'all' 
          ? 'No events in ${EventCategoryExtension.fromString(_selectedCategory!).displayName} category'
          : 'Be the first to create an event!';
    }
    
    return Container(
      height: isTablet ? 340 : 280,
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.9)]),
        borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
        border: Border.all(color: Colors.grey.shade300.withOpacity(0.3), width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 30, offset: Offset(0, 15))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
        child: Stack(
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1531058020387-3be344556be6?ixlib=rb-4.0.3&auto=format&fit=crop&w=1170&q=80',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF42A41), Color(0xFF006A4E)])),
                child: Center(child: Icon(Icons.event_busy_rounded, size: isTablet ? 60 : 50, color: Colors.white70)),
              ),
            ),
            Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.7)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
            Center(
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 30 : 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Only rotate if app is visible
                    _appLifecycleState == AppLifecycleState.resumed
                        ? RotationTransition(
                            turns: _rotateAnimation,
                            child: Container(
                              width: isTablet ? 90 : 70,
                              height: isTablet ? 90 : 70,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFF42A41), Color(0xFF006A4E)]),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: _primaryRed.withOpacity(0.3), blurRadius: 20, spreadRadius: 3)],
                              ),
                              child: Center(child: Icon(Icons.event_busy_rounded, size: isTablet ? 45 : 35, color: Colors.white)),
                            ),
                          )
                        : Container(
                            width: isTablet ? 90 : 70,
                            height: isTablet ? 90 : 70,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFF42A41), Color(0xFF006A4E)]),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: _primaryRed.withOpacity(0.3), blurRadius: 20, spreadRadius: 3)],
                            ),
                            child: Center(child: Icon(Icons.event_busy_rounded, size: isTablet ? 45 : 35, color: Colors.white)),
                          ),
                    SizedBox(height: isTablet ? 20 : 16),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFF42A41), Color(0xFF006A4E)]).createShader(bounds),
                      child: Text('No Upcoming Events', style: GoogleFonts.poppins(fontSize: isTablet ? 22 : 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                    SizedBox(height: isTablet ? 12 : 8),
                    Text(
                      message,
                      style: GoogleFonts.inter(fontSize: isTablet ? 16 : 14, color: Colors.white, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    if (!locationProvider.isFilterActive)
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) => GestureDetector(
                          onTap: () {
                            if (authProvider.user != null) {
                              _showPremiumAddEventDialog(context, isTablet);
                            } else {
                              _showLoginRequiredDialog(context, 'create an event');
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: isTablet ? 30 : 24, vertical: isTablet ? 14 : 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFF42A41), Color(0xFF006A4E)]),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [BoxShadow(color: _primaryRed.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_circle_rounded, color: Colors.white),
                                const SizedBox(width: 6),
                                Text('Create Event', style: GoogleFonts.poppins(fontSize: isTablet ? 16 : 14, fontWeight: FontWeight.w700, color: Colors.white)),
                              ],
                            ),
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

/*  Widget _buildPremiumEventCard(EventModel event, bool isSmallScreen, bool isTablet, bool isActive) {
    final categoryGradient = _getCategoryGradient(event.category);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 6, vertical: isTablet ? 10 : 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isTablet ? 35 : 30),
        boxShadow: isActive
            ? const [BoxShadow(color: Color(0xFFF42A41), blurRadius: 30, offset: Offset(0, 15), spreadRadius: 3), BoxShadow(color: Color(0xFF006A4E), blurRadius: 20, offset: Offset(0, 8))]
            : [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isTablet ? 35 : 30),
        child: Stack(
          children: [
            Container(width: double.infinity, height: double.infinity, child: _buildCachedEventImage(event, isTablet)),
            Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.9)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.0, 0.3, 0.7, 1.0]))),
            
            // Distance Badge
            if (event.latitude != null && event.longitude != null)
              Positioned(
                top: 16,
                right: 16,
                child: DistanceBadge(
                  latitude: event.latitude!,
                  longitude: event.longitude!,
                  isTablet: isTablet,
                ),
              ),
            
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(isTablet ? 24 : 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category Button
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12, vertical: isTablet ? 10 : 8),
                          decoration: BoxDecoration(
                            gradient: categoryGradient,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [BoxShadow(color: _primaryRed.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(EventCategoryExtension.fromString(event.category).iconData, color: Colors.white, size: isTablet ? 18 : 16),
                              const SizedBox(width: 6),
                              Text(event.categoryText, style: GoogleFonts.inter(fontSize: isTablet ? 14 : 12, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                        ),
                        
                        // Featured Button
                        if (isActive && _appLifecycleState == AppLifecycleState.resumed)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.8, end: 1.2),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              final clampedValue = value.clamp(0.8, 1.2);
                              return Transform.scale(
                                scale: clampedValue,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12, vertical: isTablet ? 10 : 8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFD966)]),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [BoxShadow(color: Color(0xFFFFD700).withOpacity(0.3), blurRadius: 12, offset: Offset(0, 4))],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'FEATURED', 
                                        style: GoogleFonts.inter(
                                          fontSize: isTablet ? 12 : 12, 
                                          fontWeight: FontWeight.w700, 
                                          color: Colors.white,
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
                    SizedBox(height: isTablet ? 24 : 18),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(colors: [Colors.white, Colors.white]).createShader(bounds),
                      child: Text(event.title, style: GoogleFonts.poppins(fontSize: isTablet ? 28 : 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    Container(
                      padding: EdgeInsets.all(isTablet ? 18 : 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF4D4D), Color(0xFF00B36B), Color(0xFF00E676)], begin: Alignment.topLeft, end: Alignment.bottomRight, stops: [0.0, 0.5, 1.0]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isTablet ? 10 : 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF006A4E), Color(0xFF004D38)]),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
                                ),
                                child: Icon(Icons.calendar_today_rounded, color: Colors.white, size: isTablet ? 20 : 18),
                              ),
                              SizedBox(width: isTablet ? 16 : 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Date & Time', style: GoogleFonts.inter(fontSize: isTablet ? 12 : 10, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                    Text(event.formattedDate, style: GoogleFonts.poppins(fontSize: isTablet ? 16 : 14, fontWeight: FontWeight.w700, color: Colors.white, shadows: const [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))])),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 12 : 8),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isTablet ? 10 : 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [_primaryRed, _coralRed]),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: _primaryRed.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
                                ),
                                child: Icon(Icons.location_on_rounded, color: Colors.white, size: isTablet ? 20 : 18),
                              ),
                              SizedBox(width: isTablet ? 16 : 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Location', style: GoogleFonts.inter(fontSize: isTablet ? 12 : 10, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                    Text(event.location, style: GoogleFonts.poppins(fontSize: isTablet ? 16 : 14, fontWeight: FontWeight.w700, color: Colors.white, shadows: const [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isTablet ? 18 : 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: isTablet ? 14 : 10, vertical: isTablet ? 10 : 8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
                          child: Row(
                            children: [
                              Icon(Icons.favorite_rounded, color: _goldAccent, size: isTablet ? 18 : 16),
                              SizedBox(width: isTablet ? 6 : 4),
                              Text('${event.totalInterested} interested', style: GoogleFonts.inter(fontSize: isTablet ? 16 : 14, fontWeight: FontWeight.w700, color: _goldAccent)),
                            ],
                          ),
                        ),
                        Container(
                          width: isTablet ? 55 : 45,
                          height: isTablet ? 55 : 45,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFF42A41), Color(0xFF006A4E)]),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: _primaryRed.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 5)), BoxShadow(color: _primaryGreen.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Center(child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: isTablet ? 24 : 20)),
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

*/
Widget _buildPremiumEventCard(EventModel event, bool isSmallScreen, bool isTablet, bool isActive) {
  final categoryGradient = _getCategoryGradient(event.category);
  
  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    margin: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 6, vertical: isTablet ? 10 : 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(isTablet ? 35 : 30),
      boxShadow: isActive
          ? const [BoxShadow(color: Color(0xFFF42A41), blurRadius: 30, offset: Offset(0, 15), spreadRadius: 3), BoxShadow(color: Color(0xFF006A4E), blurRadius: 20, offset: Offset(0, 8))]
          : [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 12))],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(isTablet ? 35 : 30),
      child: Stack(
        children: [
          // Background image with Cloudinary optimization
          Container(
            width: double.infinity,
            height: double.infinity,
            child: _buildCachedEventImage(event, isTablet, thumbnail: false),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          
          // Multi-Day Badge
          if (event.isMultiDay)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 10, vertical: isTablet ? 6 : 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.date_range_rounded, color: Colors.white, size: isTablet ? 16 : 14),
                    SizedBox(width: 4),
                    Text(
                      'Multi-Day',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 12 : 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Distance Badge
          if (event.latitude != null && event.longitude != null)
            Positioned(
              top: 16,
              right: 16,
              child: DistanceBadge(
                latitude: event.latitude!,
                longitude: event.longitude!,
                isTablet: isTablet,
              ),
            ),
          
          // Event info overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(isTablet ? 24 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12, vertical: isTablet ? 10 : 8),
                        decoration: BoxDecoration(
                          gradient: categoryGradient,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [BoxShadow(color: _primaryRed.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(EventCategoryExtension.fromString(event.category).iconData, color: Colors.white, size: isTablet ? 18 : 16),
                            const SizedBox(width: 6),
                            Text(event.categoryText, style: GoogleFonts.inter(fontSize: isTablet ? 14 : 12, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                      
                      if (isActive && _appLifecycleState == AppLifecycleState.resumed)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.8, end: 1.2),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            final clampedValue = value.clamp(0.8, 1.2);
                            return Transform.scale(
                              scale: clampedValue,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12, vertical: isTablet ? 10 : 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFD966)]),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [BoxShadow(color: Color(0xFFFFD700).withOpacity(0.3), blurRadius: 12, offset: Offset(0, 4))],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'FEATURED', 
                                      style: GoogleFonts.inter(
                                        fontSize: isTablet ? 12 : 12, 
                                        fontWeight: FontWeight.w700, 
                                        color: Colors.white,
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
                  SizedBox(height: isTablet ? 24 : 18),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(colors: [Colors.white, Colors.white]).createShader(bounds),
                    child: Text(
                      event.title,
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 28 : 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                  Container(
                    padding: EdgeInsets.all(isTablet ? 18 : 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF4D4D), Color(0xFF00B36B), Color(0xFF00E676)], begin: Alignment.topLeft, end: Alignment.bottomRight, stops: [0.0, 0.5, 1.0]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isTablet ? 10 : 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF006A4E), Color(0xFF004D38)]),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
                              ),
                              child: Icon(Icons.calendar_today_rounded, color: Colors.white, size: isTablet ? 20 : 18),
                            ),
                            SizedBox(width: isTablet ? 16 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.isMultiDay ? 'Event Period' : 'Date & Time',
                                    style: GoogleFonts.inter(fontSize: isTablet ? 12 : 10, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                  ),
                                  Text(
                                    event.compactFormattedDateTime,
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 14 : 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      shadows: const [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 12 : 8),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isTablet ? 10 : 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [_primaryRed, _coralRed]),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: _primaryRed.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
                              ),
                              child: Icon(Icons.location_on_rounded, color: Colors.white, size: isTablet ? 20 : 18),
                            ),
                            SizedBox(width: isTablet ? 16 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Location', style: GoogleFonts.inter(fontSize: isTablet ? 12 : 10, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                  Text(
                                    event.location,
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      shadows: const [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
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
                  SizedBox(height: isTablet ? 18 : 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: isTablet ? 14 : 10, vertical: isTablet ? 10 : 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.favorite_rounded, color: _goldAccent, size: isTablet ? 18 : 16),
                            SizedBox(width: isTablet ? 6 : 4),
                            Text('${event.totalInterested} interested', style: GoogleFonts.inter(fontSize: isTablet ? 16 : 14, fontWeight: FontWeight.w700, color: _goldAccent)),
                          ],
                        ),
                      ),
                      Container(
                        width: isTablet ? 55 : 45,
                        height: isTablet ? 55 : 45,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFF42A41), Color(0xFF006A4E)]),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: _primaryRed.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 5)),
                            BoxShadow(color: _primaryGreen.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Center(child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: isTablet ? 24 : 20)),
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


Widget _buildCachedEventImage(EventModel event, bool isTablet, {bool thumbnail = false}) {
  final cacheKey = event.id + (thumbnail ? '_thumb' : '');
  
  if (_imageCache.containsKey(cacheKey)) {
    return _imageCache[cacheKey]!;
  }
  
  Widget imageWidget;
  
  // Check if event has banner image
  if (event.bannerImageUrl != null && event.bannerImageUrl!.isNotEmpty) {
    try {
      // Use Cloudinary optimized URLs if available
      final imageUrl = thumbnail 
          ? (event.bannerImageUrl!.contains('cloudinary.com') 
              ? event.thumbnailUrl 
              : event.bannerImageUrl!)
          : (isTablet 
              ? (event.bannerImageUrl!.contains('cloudinary.com') 
                  ? event.cardUrl 
                  : event.bannerImageUrl!)
              : (event.bannerImageUrl!.contains('cloudinary.com') 
                  ? event.thumbnailUrl 
                  : event.bannerImageUrl!));
      
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _primaryGreen,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading image: $error');
          return _buildDefaultEventImage(isTablet);
        },
      );
    } catch (e) {
      print('❌ Error building image widget: $e');
      imageWidget = _buildDefaultEventImage(isTablet);
    }
  } else {
    imageWidget = _buildDefaultEventImage(isTablet);
  }
  
  _imageCache[cacheKey] = imageWidget;
  return imageWidget;
}


  LinearGradient _getCategoryGradient(String category) {
    switch (category) {
      case 'social': return LinearGradient(colors: [_coralRed, _primaryRed]);
      case 'religious': return LinearGradient(colors: [_amethystPurple, _primaryRed]);
      case 'sports': return LinearGradient(colors: [_emeraldGreen, _primaryGreen]);
      case 'business': return LinearGradient(colors: [_sapphireBlue, _primaryGreen]);
      case 'educational': return LinearGradient(colors: [_goldAccent, _softGold]);
      default: return const LinearGradient(colors: [Color(0xFFF42A41), Color(0xFF006A4E)]);
    }
  }

  Widget _buildPremiumCategoryCard(EventCategory category, bool isSmallScreen, bool isTablet) {
    final String categoryName = category.displayName;
    final IconData categoryIcon = category.iconData;
    final String categoryValue = category.stringValue;
    final bool isSelected = _selectedCategory == categoryValue;
    
    double getCardWidth() {
      if (isTablet) return 90;
      if (categoryName.length <= 6) return 70;
      if (categoryName.length <= 8) return 75;
      return 80;
    }
    
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
          _categorizedCache.clear();
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: getCardWidth(),
        margin: EdgeInsets.only(right: isTablet ? 8 : 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0xFFF42A41), Color(0xFF006A4E)])
              : LinearGradient(colors: [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.9)]),
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300.withOpacity(0.3), width: 1.2),
          boxShadow: [BoxShadow(color: isSelected ? _primaryRed.withOpacity(0.3) : Colors.black.withOpacity(0.08), blurRadius: isSelected ? 15 : 10, offset: Offset(0, isSelected ? 6 : 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isTablet ? 40 : 32,
              height: isTablet ? 40 : 32,
              decoration: BoxDecoration(
                gradient: isSelected ? LinearGradient(colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)]) : _getCategoryGradient(categoryValue),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: (isSelected ? Colors.white : _primaryRed).withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Center(child: Icon(categoryIcon, color: isSelected ? Colors.white : Colors.white, size: isTablet ? 20 : 16)),
            ),
            SizedBox(height: isTablet ? 6 : 4),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(categoryName, style: GoogleFonts.poppins(fontSize: isTablet ? 12 : 10, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : _darkGreen), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Updated event list item with Cloudinary thumbnail
Widget _buildPremiumEventListItem(EventModel event, bool isSmallScreen, bool isTablet, {required bool isPast}) {
  final cardGradient = isPast 
      ? LinearGradient(colors: [_lightRed.withOpacity(0.3), Colors.white.withOpacity(0.95)])
      : LinearGradient(colors: [Colors.white.withOpacity(0.98), Colors.white, _lightGreen.withOpacity(0.2), _creamWhite.withOpacity(0.1)]);
  
  return Container(
    margin: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24, vertical: isTablet ? 12 : 8),
    decoration: BoxDecoration(
      gradient: cardGradient,
      borderRadius: BorderRadius.circular(isTablet ? 35 : 30),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 25, offset: const Offset(0, 12)),
        BoxShadow(color: isPast ? _primaryRed.withOpacity(0.1) : _primaryGreen.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5)),
      ],
      border: Border.all(color: isPast ? Colors.grey.shade300.withOpacity(0.3) : Colors.grey.shade300.withOpacity(0.2), width: 1.5),
    ),
    child: Padding(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image with Cloudinary thumbnail
          Stack(
            children: [
              Container(
                width: isTablet ? 120 : 100,
                height: isTablet ? 120 : 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                  child: _buildCachedEventImage(event, isTablet, thumbnail: true),
                ),
              ),
              // Multi-Day Badge on Image
              if (event.isMultiDay)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.date_range_rounded, color: Colors.white, size: 10),
                        SizedBox(width: 2),
                        Text(
                          'Multi-Day',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: isTablet ? 24 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: isTablet ? 14 : 12, vertical: isTablet ? 8 : 6),
                      decoration: BoxDecoration(
                        gradient: isPast ? LinearGradient(colors: [Colors.grey[400]!, Colors.grey[500]!]) : _getCategoryGradient(event.category),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: (isPast ? Colors.grey : _primaryRed).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(EventCategoryExtension.fromString(event.category).iconData, color: Colors.white, size: isTablet ? 16 : 14),
                          const SizedBox(width: 6),
                          Text(event.categoryText, style: GoogleFonts.inter(fontSize: isTablet ? 14 : 12, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (!isPast) _buildPremiumInterestButton(event, isTablet),
                  ],
                ),
                SizedBox(height: isTablet ? 16 : 12),
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
                Row(
                  children: [
                    Icon(Icons.business_rounded, size: isTablet ? 18 : 16, color: isPast ? _primaryRed : _primaryGreen),
                    const SizedBox(width: 8),
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
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: isTablet ? 18 : 16, color: isPast ? _coralRed.withOpacity(0.7) : _coralRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (event.isMultiDay)
                            Text(
                              event.formattedDateRange,
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 13 : 11,
                                color: isPast ? _textLight : _textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          Text(
                            event.isMultiDay && event.startTime != null && event.endTime != null
                                ? '${_formatTimeForDisplay(event.startTime!)} - ${_formatTimeForDisplay(event.endTime!)}'
                                : event.formattedDate,
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 13 : 11,
                              color: isPast ? _textLight : _textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: isTablet ? 18 : 16, color: isPast ? _mintGreen.withOpacity(0.7) : _mintGreen),
                    const SizedBox(width: 8),
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
                
                // Distance Badge for List Item
                Consumer<LocationFilterProvider>(
                  builder: (context, locationProvider, _) {
                    if (event.latitude == null || event.longitude == null) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: EdgeInsets.only(top: isTablet ? 12 : 8),
                      child: DistanceBadge(
                        latitude: event.latitude!,
                        longitude: event.longitude!,
                        isTablet: isTablet,
                      ),
                    );
                  },
                ),
                
                if (!isPast) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.favorite_rounded, size: isTablet ? 16 : 14, color: _goldAccent),
                      const SizedBox(width: 4),
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

// Helper method to format TimeOfDay for display
String _formatTimeForDisplay(TimeOfDay time) {
  final hour = time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

  Widget _buildPremiumInterestButton(EventModel event, bool isTablet) {
    return Consumer2<AuthProvider, EventProvider>(
      builder: (context, authProvider, eventProvider, _) {
        final isInterested = eventProvider.userInterestedEventIds.contains(event.id);
        final isLoading = eventProvider.isInterestButtonLoading(event.id);
        
        Future<void> _toggleInterest() async {
          if (authProvider.user == null) {
            _showLoginRequiredDialog(context, 'show interest');
            return;
          }
          
          try {
            await eventProvider.toggleUserInterest(
              event.id,
              authProvider.user!.id,
            );
            HapticFeedback.lightImpact();
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isInterested ? 'Interest removed' : 'Added to interests',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: isInterested ? _primaryRed : _primaryGreen,
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: _primaryRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : _toggleInterest,
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
                    color: isInterested ? _primaryRed.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: isTablet ? 24 : 20,
                        height: isTablet ? 24 : 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isInterested ? Colors.white : _primaryRed,
                          ),
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

  Widget _buildDefaultEventImage(bool isTablet) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF006A4E), Color(0xFF004D38)])),
      child: Center(child: Icon(Icons.event_rounded, size: isTablet ? 50 : 40, color: Colors.white70)),
    );
  }

  Widget _buildPremiumFooter(bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF006A4E), Color(0xFF004D38)]),
        borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
        boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Only rotate if app is visible
              _appLifecycleState == AppLifecycleState.resumed
                  ? RotationTransition(turns: _rotateAnimation, child: const Icon(Icons.event_available_rounded, color: Colors.white))
                  : const Icon(Icons.event_available_rounded, color: Colors.white),
              SizedBox(width: isTablet ? 12 : 8),
              Text('BanglaHub Events', style: GoogleFonts.poppins(fontSize: isTablet ? 22 : 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text('Discover, connect, and celebrate with the Bengali community', style: GoogleFonts.inter(fontSize: isTablet ? 14 : 13, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          SizedBox(height: isTablet ? 20 : 16),
          Container(height: 2, width: isTablet ? 150 : 120, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.white54, Colors.white, Colors.white54]))),
          SizedBox(height: isTablet ? 16 : 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('© 2026', style: GoogleFonts.inter(fontSize: isTablet ? 14 : 13, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600)),
              SizedBox(width: isTablet ? 12 : 8),
              Container(width: 4, height: 4, decoration: BoxDecoration(color: _goldAccent, shape: BoxShape.circle)),
              SizedBox(width: isTablet ? 12 : 8),
              Text('Version 1.0.0', style: GoogleFonts.inter(fontSize: isTablet ? 14 : 13, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isTablet, bool isSmallScreen) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_primaryRed.withOpacity(0.05), Colors.white, _primaryGreen.withOpacity(0.05), _offWhite], begin: Alignment.topLeft, end: Alignment.bottomRight, stops: const [0.0, 0.3, 0.7, 1.0]),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(isTablet ? 50 : 40), topRight: Radius.circular(isTablet ? 50 : 40)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 2 * 3.14,
                  child: Container(
                    width: isTablet ? 100 : 80,
                    height: isTablet ? 100 : 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF42A41), Color(0xFF006A4E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryRed.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.event_rounded,
                        size: isTablet ? 50 : 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Loading amazing events...',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 20 : 18,
                color: _primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover and connect with your community',
              style: GoogleFonts.inter(
                fontSize: isTablet ? 16 : 14,
                color: _textLight,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: isTablet ? 200 : 150,
              child: LinearProgressIndicator(
                backgroundColor: _lightGreen,
                valueColor: AlwaysStoppedAnimation<Color>(_primaryGreen),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isTablet, bool isSmallScreen, String error) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_primaryRed.withOpacity(0.05), Colors.white, _primaryGreen.withOpacity(0.05), _offWhite], begin: Alignment.topLeft, end: Alignment.bottomRight, stops: const [0.0, 0.3, 0.7, 1.0]),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(isTablet ? 50 : 40), topRight: Radius.circular(isTablet ? 50 : 40)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _lightRed,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: isTablet ? 60 : 50,
                color: _primaryRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 22 : 20,
                fontWeight: FontWeight.w700,
                color: _primaryRed,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 24),
              child: Text(
                error,
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 16 : 14,
                  color: _textLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final eventProvider = Provider.of<EventProvider>(context, listen: false);
                eventProvider.clearError();
                eventProvider.loadEventsWithFilter();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 24,
                  vertical: isTablet ? 16 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Add Event Dialog with Tabbed Interface (Premium)
void _showPremiumAddEventDialog(BuildContext context, bool isTablet) {
  HapticFeedback.mediumImpact();
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return PremiumAddEventDialog(
          scrollController: scrollController,
        //  onEventAdded: _loadData,
          primaryGreen: _primaryGreen,
          secondaryGold: _goldAccent,
          accentRed: _primaryRed,
          lightGreen: _lightGreen,
          rotateAnimation: _rotateAnimation,
          appLifecycleState: _appLifecycleState,
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
  final isSmallScreen = !isTablet;
  
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
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.grey.shade300.withOpacity(0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: gradient.colors.first.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        fontSize: isTablet ? 15 : 13,
        color: _textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: GoogleFonts.poppins(
          fontSize: isTablet ? 13 : 12,
          color: gradient.colors.first,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Container(
          margin: EdgeInsets.all(isTablet ? 10 : 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.25),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: isTablet ? 20 : 18),
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 12 : 10,
        ),
      ),
    ),
  );
}


  Widget _buildLocationFieldWithMap(bool isTablet, StateSetter setState) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => OSMLocationPicker(
            initialLatitude: _eventLatitude,
            initialLongitude: _eventLongitude,
            initialAddress: _locationController.text,
            initialState: _eventState,
            initialCity: _eventCity,
            onLocationSelected: (lat, lng, address, state, city) {
              setState(() {
                _eventLatitude = lat;
                _eventLongitude = lng;
                _eventState = state;
                _eventCity = city;
                _locationController.text = address;
              });
            },
          ),
        );
      },
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
            color: _eventLatitude != null ? _emeraldGreen : Colors.grey.shade300.withOpacity(0.3),
            width: _eventLatitude != null ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF006A4E), Color(0xFF004D38)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.location_on, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location *',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600,
                          color: _primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _locationController.text.isEmpty
                            ? 'Tap to select location on map'
                            : _locationController.text,
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 14 : 12,
                          color: _locationController.text.isEmpty
                              ? _textLight
                              : _textPrimary,
                          fontWeight: _locationController.text.isEmpty
                              ? FontWeight.w500
                              : FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: _primaryGreen,
                  size: isTablet ? 16 : 14,
                ),
              ],
            ),
            if (_eventLatitude != null && _eventLongitude != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _lightGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.my_location,
                      color: _primaryGreen,
                      size: isTablet ? 18 : 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Coordinates: ${_eventLatitude!.toStringAsFixed(4)}, ${_eventLongitude!.toStringAsFixed(4)}',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 12 : 11,
                        color: _primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_eventState != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _lightRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_city,
                        color: _primaryRed,
                        size: isTablet ? 18 : 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_eventCity != null ? '$_eventCity, ' : ''}$_eventState',
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 12 : 11,
                          color: _primaryRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectEventDate(BuildContext context, StateSetter setState) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
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
        initialTime: const TimeOfDay(hour: 18, minute: 0),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: _primaryRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
      _showSnackBar('Enter event title', isError: true);
      return;
    }
    
    if (_organizerController.text.isEmpty) {
      _showSnackBar('Enter organizer name', isError: true);
      return;
    }
    
    if (_contactPersonController.text.isEmpty) {
      _showSnackBar('Enter contact person', isError: true);
      return;
    }
    
    if (_contactEmailController.text.isEmpty) {
      _showSnackBar('Enter contact email', isError: true);
      return;
    }
    
    if (_contactPhoneController.text.isEmpty) {
      _showSnackBar('Enter contact phone', isError: true);
      return;
    }
    
    if (_selectedDate == null) {
      _showSnackBar('Select event date', isError: true);
      return;
    }
    
    if (_eventLatitude == null || _eventLongitude == null || _locationController.text.isEmpty) {
      _showSnackBar('Select location on map', isError: true);
      return;
    }
    
    if (_descriptionController.text.isEmpty) {
      _showSnackBar('Enter event description', isError: true);
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

      // Upload image to Cloudinary if selected
      String? bannerImageUrl;
      if (_selectedImage != null) {
        print('📸 Uploading event banner to Cloudinary...');
        
        // Generate event ID first for Cloudinary folder
        final eventId = DateTime.now().millisecondsSinceEpoch.toString();
        
        final imageFile = File(_selectedImage!.path);
        bannerImageUrl = await CloudinaryService.uploadEventBanner(imageFile, eventId);
        
        if (bannerImageUrl == null) {
          _showSnackBar('Failed to upload banner image. Please try again.', isError: true);
          setState(() {
            _isSaving = false;
          });
          return;
        }
        
        print('✅ Banner uploaded to Cloudinary: $bannerImageUrl');
      }

      // Create event date/time combining date and time
      DateTime eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _startTime?.hour ?? 0,
        _startTime?.minute ?? 0,
      );
      
      DateTime? endDateTime;
      if (_isMultiDay && _endDate != null) {
        endDateTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime?.hour ?? 23,
          _endTime?.minute ?? 59,
        );
      }

      await eventProvider.createEvent(
        title: _titleController.text,
        organizer: _organizerController.text,
        contactPerson: _contactPersonController.text,
        contactEmail: _contactEmailController.text,
        contactPhone: _contactPhoneController.text,
        startDate: eventDateTime,  // Use startDate instead of eventDate
        endDate: endDateTime,       // Add endDate for multi-day events
        startTime: _startTime,      // Add start time
        endTime: _endTime,          // Add end time
        location: _locationController.text,
        description: _descriptionController.text,
        category: _selectedEventCategory,
        bannerImageUrl: bannerImageUrl,  // Use Cloudinary URL instead of base64
        isFree: _isFree,
        ticketPrices: _ticketPrices.isEmpty ? null : _ticketPrices,
        paymentInfo: null,
        createdBy: currentUser.id,
        latitude: _eventLatitude,
        longitude: _eventLongitude,
        state: _eventState,
        city: _eventCity,
      );

      _clearForm();
      
      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog(context, isTablet: MediaQuery.of(context).size.width >= 600);
      }
    } catch (e) {
      print('❌ Error creating event: $e');
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

/*  void _showSuccessDialog(BuildContext context, {required bool isTablet}) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(isTablet ? 40 : 20),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
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
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF2ECC71),
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
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.85 + (0.15 * value),
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 28 : 24),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF006A4E), Color(0xFF004D38)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF2ECC71),
                                  blurRadius: 30,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: _appLifecycleState == AppLifecycleState.resumed
                                ? RotationTransition(
                                    turns: _rotateAnimation,
                                    child: const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                  ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: isTablet ? 40 : 30),
                    
                    // Welcome Text
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF006A4E), Color(0xFF004D38)],
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
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFF42A41), Color(0xFF006A4E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: Colors.white,
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF006A4E), Color(0xFF004D38)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(35),
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

*/


void _showSuccessDialog(BuildContext context, {required bool isTablet}) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(isTablet ? 24 : 16),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: 0.9 + (0.1 * scale),
              child: child,
            );
          },
          child: Container(
            width: isTablet ? 400 : 320,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, _mintCream, _peachBlossom],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF2ECC71),
                  blurRadius: 25,
                  offset: Offset(0, 12),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 30 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Animation - Smaller
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.9 + (0.1 * value),
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 18 : 14),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF006A4E), Color(0xFF004D38)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF2ECC71),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: _appLifecycleState == AppLifecycleState.resumed
                              ? RotationTransition(
                                  turns: _rotateAnimation,
                                  child: const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  
                  // Success Text - Smaller
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF006A4E), Color(0xFF004D38)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'Success!',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 28 : 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 8 : 6),
                  
                  // Success Message - Smaller
                  Text(
                    'Event Created!',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      color: _primaryGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                  
                  // Admin Card - Compact
                  Container(
                    padding: EdgeInsets.all(isTablet ? 16 : 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryGreen.withOpacity(0.1), _primaryRed.withOpacity(0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _primaryGreen.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFF42A41), Color(0xFF006A4E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending Approval',
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 14 : 12,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryGreen,
                                ),
                              ),
                              Text(
                                'Review by admin',
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 11 : 10,
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
                  SizedBox(height: isTablet ? 20 : 16),
                  
                  // Close Button - Compact
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 12 : 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF006A4E), Color(0xFF004D38)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          'Great!',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w700,
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

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isError
                ? LinearGradient(colors: [_primaryRed, _coralRed])
                : const LinearGradient(colors: [Color(0xFF006A4E), Color(0xFF004D38)]),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: (isError ? _primaryRed : _primaryGreen).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
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
              const SizedBox(width: 12),
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
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
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
    _eventLatitude = null;
    _eventLongitude = null;
    _eventState = null;
    _eventCity = null;
  }
}


// ====================== PREMIUM ADD EVENT DIALOG ======================
class PremiumAddEventDialog extends StatefulWidget {
  final VoidCallback? onEventAdded;
  final ScrollController scrollController;
  final Color primaryGreen;
  final Color secondaryGold;
  final Color accentRed;
  final Color lightGreen;
  final Animation<double> rotateAnimation;
  final AppLifecycleState appLifecycleState;

  const PremiumAddEventDialog({
    Key? key,
    this.onEventAdded,
    required this.scrollController,
    required this.primaryGreen,
    required this.secondaryGold,
    required this.accentRed,
    required this.lightGreen,
    required this.rotateAnimation,
    required this.appLifecycleState,
  }) : super(key: key);

  @override
  _PremiumAddEventDialogState createState() => _PremiumAddEventDialogState();
}

class _PremiumAddEventDialogState extends State<PremiumAddEventDialog> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  final _formKey = GlobalKey<FormState>();
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  
  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _organizerController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ticketTypeController = TextEditingController();
  final TextEditingController _ticketPriceController = TextEditingController();

  // Location picking variables
  double? _eventLatitude;
  double? _eventLongitude;
  String? _eventState;
  String? _eventCity;

  // Date/Time variables
  bool _isMultiDay = false;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // State variables
  String? _selectedEventCategory = 'social';
  bool _isFree = true;
  final Map<String, double> _ticketPrices = {};
  
  // Image handling (optional)
  XFile? _selectedImage;
  String? _base64Image;
  bool _isImageLoading = false;
  
  bool _isSaving = false;
  
  late TabController _tabController;
  late AnimationController _animationController;
  
  // Track completed tabs
  bool _isBasicInfoValid = false;
  bool _isMediaTabValid = true; // Media is optional
  bool _isDetailsTabValid = false;

  final List<String> _categories = ['social', 'religious', 'sports', 'business', 'educational'];

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animationController.forward();
    
    // Add listeners to validate on change
    _titleController.addListener(_validateBasicInfo);
    _organizerController.addListener(_validateBasicInfo);
    _contactPersonController.addListener(_validateBasicInfo);
    _contactEmailController.addListener(_validateBasicInfo);
    _contactPhoneController.addListener(_validateBasicInfo);
    _locationController.addListener(_validateBasicInfo);
    
    _descriptionController.addListener(_validateDetailsTab);
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _validateBasicInfo() {
    if (mounted) {
      setState(() {
        bool hasValidDates = false;
        
        if (_isMultiDay) {
          hasValidDates = _startDate != null && _endDate != null;
        } else {
          hasValidDates = _startDate != null;
        }
        
        _isBasicInfoValid = 
            _titleController.text.isNotEmpty &&
            _organizerController.text.isNotEmpty &&
            _contactPersonController.text.isNotEmpty &&
            _contactEmailController.text.isNotEmpty &&
            _contactPhoneController.text.isNotEmpty &&
            _locationController.text.isNotEmpty &&
            (_eventLatitude != null && _eventLongitude != null) &&
            hasValidDates;
      });
    }
  }

  void _validateDetailsTab() {
    if (mounted) {
      setState(() {
        _isDetailsTabValid = 
            _descriptionController.text.isNotEmpty &&
            _selectedEventCategory != null;
      });
    }
  }

  bool get _isSubmitEnabled {
    return _isBasicInfoValid && _isDetailsTabValid;
  }

  void _goToPreviousTab() {
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
    }
  }

  void _goToNextTab() {
    if (_tabController.index < 2) {
      if (_tabController.index == 0 && !_isBasicInfoValid) {
        _showErrorSnackBar('Please complete all required fields including location, date, and time');
        return;
      }
      _tabController.animateTo(_tabController.index + 1);
    }
  }

  @override
  void dispose() {
    print('🗑️ PremiumAddEventDialog disposing...');
    
    WidgetsBinding.instance.removeObserver(this);
    
    _titleController.removeListener(_validateBasicInfo);
    _organizerController.removeListener(_validateBasicInfo);
    _contactPersonController.removeListener(_validateBasicInfo);
    _contactEmailController.removeListener(_validateBasicInfo);
    _contactPhoneController.removeListener(_validateBasicInfo);
    _locationController.removeListener(_validateBasicInfo);
    _descriptionController.removeListener(_validateDetailsTab);
    
    _titleController.dispose();
    _organizerController.dispose();
    _contactPersonController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _ticketTypeController.dispose();
    _ticketPriceController.dispose();
    
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _animationController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Premium Header
          Container(
            padding: EdgeInsets.all(screenWidth > 600 ? 24 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.primaryGreen, widget.primaryGreen.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryGreen.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth > 600 ? 12 : 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.event_available_rounded, color: widget.secondaryGold, size: screenWidth > 600 ? 28 : 22),
                ),
                SizedBox(width: screenWidth > 600 ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create New Event',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth > 600 ? 20 : 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Share your event with the community',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: screenWidth > 600 ? 13 : 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  iconSize: screenWidth > 600 ? 24 : 20,
                ),
              ],
            ),
          ),
          
          // Premium Tab Indicators
          Container(
            margin: EdgeInsets.symmetric(horizontal: screenWidth > 600 ? 20 : 16, vertical: 16),
            height: screenWidth > 600 ? 60 : 50,
            child: Row(
              children: [
                _buildPremiumTabIndicator(0, 'Basic', _isBasicInfoValid),
                _buildPremiumTabConnector(_isBasicInfoValid),
                _buildPremiumTabIndicator(1, 'Media', true),
                _buildPremiumTabConnector(true),
                _buildPremiumTabIndicator(2, 'Details', _isDetailsTabValid),
              ],
            ),
          ),
          
          // Form Content with ScrollController
          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildBasicInfoTab(),
                  _buildMediaTab(),
                  _buildDetailsTab(),
                ],
              ),
            ),
          ),
          
          // Premium Navigation Buttons
          Container(
            padding: EdgeInsets.all(screenWidth > 600 ? 20 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                if (_tabController.index > 0)
                  Expanded(
                    child: _buildPremiumNavButton(
                      label: 'Previous',
                      onPressed: _goToPreviousTab,
                      isPrimary: false,
                    ),
                  ),
                if (_tabController.index > 0) SizedBox(width: 12),
                Expanded(
                  child: _tabController.index < 2
                      ? _buildPremiumNavButton(
                          label: 'Next',
                          onPressed: _goToNextTab,
                          isPrimary: true,
                        )
                      : _buildPremiumSubmitButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTabIndicator(int index, String label, bool isValid) {
    final isSelected = _tabController.index == index;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 0) {
            _tabController.animateTo(0);
          } else if (index == 1 && _isBasicInfoValid) {
            _tabController.animateTo(1);
          } else if (index == 2 && _isBasicInfoValid) {
            _tabController.animateTo(2);
          } else {
            _showErrorSnackBar('Complete previous steps first');
          }
        },
        child: Container(
          height: screenWidth > 600 ? 60 : 50,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [widget.secondaryGold, widget.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isValid ? widget.primaryGreen : Colors.grey[300]!,
              width: isValid ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: screenWidth > 600 ? 24 : 20,
                height: screenWidth > 600 ? 24 : 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isValid ? widget.primaryGreen : (isSelected ? Colors.white : Colors.grey[400]),
                ),
                child: isValid
                    ? Icon(Icons.check, color: Colors.white, size: screenWidth > 600 ? 14 : 12)
                    : Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isSelected ? widget.primaryGreen : Colors.white,
                            fontSize: screenWidth > 600 ? 12 : 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : (isValid ? widget.primaryGreen : Colors.grey[600]),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: screenWidth > 600 ? 10 : 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTabConnector(bool isCompleted) {
    return Container(
      width: MediaQuery.of(context).size.width > 600 ? 20 : 12,
      height: 2,
      margin: EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: isCompleted
            ? LinearGradient(
                colors: [widget.primaryGreen, widget.secondaryGold],
              )
            : LinearGradient(
                colors: [Colors.grey[300]!, Colors.grey[400]!],
              ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildPremiumNavButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: screenWidth > 600 ? 50 : 44,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [widget.primaryGreen, widget.primaryGreen.withOpacity(0.8)],
              )
            : null,
        color: isPrimary ? null : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPrimary ? null : Border.all(color: widget.primaryGreen),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: widget.primaryGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: isPrimary ? Colors.white : widget.primaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: screenWidth > 600 ? 15 : 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumSubmitButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: screenWidth > 600 ? 50 : 44,
      decoration: BoxDecoration(
        gradient: _isSubmitEnabled
            ? LinearGradient(
                colors: [widget.secondaryGold, widget.accentRed],
              )
            : null,
        color: _isSubmitEnabled ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isSubmitEnabled
            ? [
                BoxShadow(
                  color: widget.secondaryGold.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitEnabled ? _submitForm : null,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              'Submit',
              style: GoogleFonts.poppins(
                color: _isSubmitEnabled ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w700,
                fontSize: screenWidth > 600 ? 15 : 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Event Information', Icons.event_rounded),
          SizedBox(height: 16),
          _buildTextField(
            controller: _titleController,
            label: 'Event Title *',
            icon: Icons.title_rounded,
          ),
          SizedBox(height: 12),
          _buildTextField(
            controller: _organizerController,
            label: 'Organizer *',
            icon: Icons.business_rounded,
          ),
          SizedBox(height: 12),
          _buildTextField(
            controller: _contactPersonController,
            label: 'Contact Person *',
            icon: Icons.person_rounded,
          ),
          SizedBox(height: 12),
          _buildTextField(
            controller: _contactEmailController,
            label: 'Contact Email *',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 12),
          _buildTextField(
            controller: _contactPhoneController,
            label: 'Contact Phone *',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 20),
          
          _buildSectionHeader('Date & Time', Icons.calendar_today_rounded),
          SizedBox(height: 16),
          _buildDateTimePickerField(isTablet),
          SizedBox(height: 20),
          
          _buildSectionHeader('Location', Icons.location_on_rounded),
          SizedBox(height: 16),
          _buildLocationPickerField(isTablet),
        ],
      ),
    );
  }

  Widget _buildDateTimePickerField(bool isTablet) {
    return Column(
      children: [
        // Multi-day toggle
        GestureDetector(
          onTap: () {
            setState(() {
              _isMultiDay = !_isMultiDay;
              if (!_isMultiDay) {
                _endDate = null;
                _endTime = null;
              }
            });
            HapticFeedback.lightImpact();
          },
          child: Container(
            padding: EdgeInsets.all(isTablet ? 16 : 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isMultiDay ? widget.primaryGreen : Colors.grey.shade300.withOpacity(0.5),
                width: _isMultiDay ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryGreen.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 24 : 22,
                  height: isTablet ? 24 : 22,
                  decoration: BoxDecoration(
                    gradient: _isMultiDay ? LinearGradient(colors: [widget.primaryGreen, widget.primaryGreen.withOpacity(0.7)]) : null,
                    color: _isMultiDay ? null : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isMultiDay ? Colors.transparent : Colors.grey[400]!,
                      width: 1.5,
                    ),
                  ),
                  child: _isMultiDay
                      ? Icon(Icons.check, color: Colors.white, size: isTablet ? 16 : 14)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Multi-Day Event',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 15 : 14,
                          fontWeight: FontWeight.w700,
                          color: _isMultiDay ? widget.primaryGreen : Colors.black87,
                        ),
                      ),
                      Text(
                        _isMultiDay ? 'Event spans multiple days' : 'Single day event',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // Start Date Picker
        GestureDetector(
          onTap: () => _selectStartDate(),
          child: Container(
            padding: EdgeInsets.all(isTablet ? 16 : 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _startDate != null ? widget.primaryGreen : Colors.grey.shade300.withOpacity(0.5),
                width: _startDate != null ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryGreen.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.primaryGreen, widget.primaryGreen.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isMultiDay ? 'Start Date & Time *' : 'Event Date & Time *',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _startDate != null
                            ? '${_formatDate(_startDate!)} at ${_formatTimeOfDay(_startTime!)}'
                            : 'Select start date and time',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _startDate != null ? Colors.black87 : Colors.grey[600],
                          fontWeight: _startDate != null ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: widget.primaryGreen,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
        
        if (_isMultiDay) ...[
          SizedBox(height: 12),
          
          // End Date Picker
          GestureDetector(
            onTap: () => _selectEndDate(),
            child: Container(
              padding: EdgeInsets.all(isTablet ? 16 : 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _endDate != null ? widget.accentRed : Colors.grey.shade300.withOpacity(0.5),
                  width: _endDate != null ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentRed.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [widget.accentRed, widget.accentRed.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Date & Time *',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.accentRed,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _endDate != null
                              ? '${_formatDate(_endDate!)} at ${_formatTimeOfDay(_endTime!)}'
                              : 'Select end date and time',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: _endDate != null ? Colors.black87 : Colors.grey[600],
                            fontWeight: _endDate != null ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: widget.accentRed,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

 /* Widget _buildMediaTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Event Banner', Icons.image_rounded),
          SizedBox(height: 8),
          Text(
            'Upload a banner image for your event (optional)',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          SizedBox(height: 16),
          
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: screenWidth > 600 ? 200 : 160,
                height: screenWidth > 600 ? 200 : 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [widget.lightGreen, Colors.white],
                  ),
                  border: Border.all(color: widget.primaryGreen, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryGreen.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          File(_selectedImage!.path),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            size: screenWidth > 600 ? 40 : 32,
                            color: widget.primaryGreen,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add Banner',
                            style: GoogleFonts.poppins(
                              color: widget.primaryGreen,
                              fontSize: screenWidth > 600 ? 14 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '1200×600px (Optional)',
                            style: GoogleFonts.inter(
                              color: Colors.grey[500],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          
          if (_isImageLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  color: widget.primaryGreen,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  */


  Widget _buildMediaTab() {
  final screenWidth = MediaQuery.of(context).size.width;
  
  return SingleChildScrollView(
    controller: widget.scrollController,
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Event Banner', Icons.image_rounded),
        SizedBox(height: 8),
        Text(
          'Upload a banner image for your event (optional)',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 14, color: widget.primaryGreen),
              SizedBox(width: 6),
              Text(
                'Auto-compressed to under 1MB • Recommended: 1200×600px',
                style: TextStyle(
                  fontSize: 10,
                  color: widget.primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        
        Center(
          child: GestureDetector(
            onTap: _isImageLoading ? null : _pickImage,
            child: Container(
              width: screenWidth > 600 ? 200 : 160,
              height: screenWidth > 600 ? 200 : 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [widget.lightGreen, Colors.white],
                ),
                border: Border.all(color: widget.primaryGreen, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryGreen.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: _isImageLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: widget.primaryGreen,
                            strokeWidth: 2,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Compressing...',
                            style: TextStyle(
                              fontSize: 10,
                              color: widget.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_rounded,
                              size: screenWidth > 600 ? 40 : 32,
                              color: widget.primaryGreen,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add Banner',
                              style: GoogleFonts.poppins(
                                color: widget.primaryGreen,
                                fontSize: screenWidth > 600 ? 14 : 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tap to upload',
                              style: GoogleFonts.inter(
                                color: Colors.grey[500],
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ),
        
        if (_selectedImage != null && !_isImageLoading)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImage = null;
                    _base64Image = null;
                  });
                  _showSuccessSnackBar('Image removed');
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.accentRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.accentRed.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline, size: 14, color: widget.accentRed),
                      SizedBox(width: 4),
                      Text(
                        'Remove Image',
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.accentRed,
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
  );
}
  
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Event Details', Icons.info_rounded),
          SizedBox(height: 16),
          
          _buildCategoryDropdown(),
          SizedBox(height: 12),
          
          _buildTextField(
            controller: _descriptionController,
            label: 'Event Description *',
            icon: Icons.description_rounded,
            maxLines: 4,
          ),
          SizedBox(height: 20),
          
          _buildSectionHeader('Tickets', Icons.confirmation_number_rounded),
          SizedBox(height: 16),
          
          _buildFreeEventToggle(),
          SizedBox(height: 16),
          
          if (!_isFree) _buildTicketPricesSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth > 600 ? 8 : 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.primaryGreen, widget.primaryGreen.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: screenWidth > 600 ? 18 : 16),
        ),
        SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: screenWidth > 600 ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E2A3A),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
          prefixIcon: Icon(icon, color: widget.primaryGreen, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.primaryGreen, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines > 1 ? 14 : 12),
        ),
        validator: (value) {
          if (label.contains('*') && (value == null || value.isEmpty)) {
            return 'Required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedEventCategory,
        decoration: InputDecoration(
          labelText: 'Event Category *',
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
          prefixIcon: Icon(Icons.category_rounded, color: widget.primaryGreen, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.primaryGreen, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        ),
        items: _categories.map((category) {
          String displayName = category.substring(0, 1).toUpperCase() + category.substring(1);
          return DropdownMenuItem<String>(
            value: category,
            child: Text(displayName),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedEventCategory = value;
            _validateDetailsTab();
          });
        },
        validator: (value) {
          if (value == null) return 'Required';
          return null;
        },
      ),
    );
  }

  Widget _buildFreeEventToggle() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return GestureDetector(
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
        padding: EdgeInsets.all(screenWidth > 600 ? 16 : 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.95),
              Colors.white.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isFree ? widget.primaryGreen : Colors.grey.shade300.withOpacity(0.5),
            width: _isFree ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.primaryGreen.withOpacity(_isFree ? 0.15 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: screenWidth > 600 ? 24 : 22,
              height: screenWidth > 600 ? 24 : 22,
              decoration: BoxDecoration(
                gradient: _isFree ? LinearGradient(colors: [widget.primaryGreen, widget.primaryGreen.withOpacity(0.7)]) : null,
                color: _isFree ? null : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _isFree ? Colors.transparent : Colors.grey[400]!,
                  width: 1.5,
                ),
              ),
              child: _isFree
                  ? Icon(Icons.check, color: Colors.white, size: screenWidth > 600 ? 16 : 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Free Event',
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth > 600 ? 15 : 14,
                      fontWeight: FontWeight.w700,
                      color: _isFree ? widget.primaryGreen : Colors.black87,
                    ),
                  ),
                  if (!_isFree)
                    Text(
                      'Configure ticket prices below',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketPricesSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.accentRed, widget.accentRed.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Ticket Prices',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 12 : 10),
          
          // Existing Tickets
          ..._ticketPrices.entries.map((entry) {
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(isTablet ? 10 : 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 14 : 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 12 : 10,
                      vertical: isTablet ? 6 : 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [widget.secondaryGold, widget.secondaryGold.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '\$${entry.value.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 14 : 13,
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: _ticketTypeController,
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 13 : 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type (e.g., VIP)',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: isTablet ? 12 : 11,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(isTablet ? 12 : 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: _ticketPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 13 : 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Price',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: isTablet ? 12 : 11,
                      ),
                      prefixText: '\$',
                      prefixStyle: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: isTablet ? 13 : 12,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(isTablet ? 12 : 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                  padding: EdgeInsets.all(isTablet ? 12 : 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.green.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPickerField(bool isTablet) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => OSMLocationPicker(
            initialLatitude: _eventLatitude,
            initialLongitude: _eventLongitude,
            initialAddress: _locationController.text,
            initialState: _eventState,
            initialCity: _eventCity,
            onLocationSelected: (lat, lng, address, state, city) {
              setState(() {
                _eventLatitude = lat;
                _eventLongitude = lng;
                _eventState = state;
                _eventCity = city;
                _locationController.text = address;
                _validateBasicInfo();
              });
            },
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(isTablet ? 16 : 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.95),
              Colors.white.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _eventLatitude != null ? widget.primaryGreen : Colors.grey.shade300.withOpacity(0.5),
            width: _eventLatitude != null ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.primaryGreen.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.primaryGreen, widget.primaryGreen.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location *',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _locationController.text.isEmpty
                            ? 'Tap to select location on map'
                            : _locationController.text,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _locationController.text.isEmpty
                              ? Colors.grey[600]
                              : Colors.black87,
                          fontWeight: _locationController.text.isEmpty
                              ? FontWeight.w500
                              : FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: widget.primaryGreen,
                  size: 14,
                ),
              ],
            ),
            if (_eventLatitude != null && _eventLongitude != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.lightGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.my_location,
                      color: widget.primaryGreen,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_eventLatitude!.toStringAsFixed(4)}, ${_eventLongitude!.toStringAsFixed(4)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: widget.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _selectStartDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.primaryGreen,
              onPrimary: Colors.white,
              primaryContainer: widget.primaryGreen,
              onPrimaryContainer: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
              surfaceVariant: Colors.grey[100],
              onSurfaceVariant: Colors.black54,
              outline: widget.primaryGreen,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: widget.primaryGreen,
                backgroundColor: Colors.transparent,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 18, minute: 0),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: widget.primaryGreen,
                onPrimary: Colors.white,
                primaryContainer: widget.primaryGreen,
                onPrimaryContainer: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black87,
                surfaceVariant: Colors.grey[100],
                onSurfaceVariant: Colors.black54,
                outline: widget.primaryGreen,
              ),
              dialogBackgroundColor: Colors.white,
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: widget.primaryGreen,
                  backgroundColor: Colors.transparent,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Colors.white,
                hourMinuteTextColor: Colors.black87,
                dayPeriodTextColor: widget.primaryGreen,
                dialHandColor: widget.primaryGreen,
                dialBackgroundColor: Colors.grey[100],
                entryModeIconColor: widget.primaryGreen,
                hourMinuteColor: Colors.grey[100],
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedTime != null && context.mounted) {
        setState(() {
          _startDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
          );
          _startTime = pickedTime;
          _validateBasicInfo();
        });
      }
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      _showErrorSnackBar('Please select start date first');
      return;
    }
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.accentRed,
              onPrimary: Colors.white,
              primaryContainer: widget.accentRed,
              onPrimaryContainer: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
              surfaceVariant: Colors.grey[100],
              onSurfaceVariant: Colors.black54,
              outline: widget.accentRed,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: widget.accentRed,
                backgroundColor: Colors.transparent,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentRed,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _startTime ?? const TimeOfDay(hour: 20, minute: 0),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: widget.accentRed,
                onPrimary: Colors.white,
                primaryContainer: widget.accentRed,
                onPrimaryContainer: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black87,
                surfaceVariant: Colors.grey[100],
                onSurfaceVariant: Colors.black54,
                outline: widget.accentRed,
              ),
              dialogBackgroundColor: Colors.white,
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: widget.accentRed,
                  backgroundColor: Colors.transparent,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentRed,
                  foregroundColor: Colors.white,
                ),
              ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Colors.white,
                hourMinuteTextColor: Colors.black87,
                dayPeriodTextColor: widget.accentRed,
                dialHandColor: widget.accentRed,
                dialBackgroundColor: Colors.grey[100],
                entryModeIconColor: widget.accentRed,
                hourMinuteColor: Colors.grey[100],
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedTime != null && context.mounted) {
        setState(() {
          _endDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
          );
          _endTime = pickedTime;
          _validateBasicInfo();
        });
      }
    }
  }

/*  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      maxWidth: 1200, 
      maxHeight: 600, 
      imageQuality: 70,
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
        _isImageLoading = true;
      });
      
      final bytes = await File(pickedFile.path).readAsBytes();
      final base64String = base64Encode(bytes);
      final mimeType = _getMimeType(pickedFile.path);
      final dataUrl = 'data:$mimeType;base64,$base64String';
      
      setState(() {
        _base64Image = dataUrl;
        _isImageLoading = false;
      });
    }
  }

 */ 


Future<String?> compressAndConvertImage(XFile imageFile) async {
  try {
    final file = File(imageFile.path);
    final originalSize = await file.length();

    print("Original size: ${(originalSize / 1024).toStringAsFixed(1)} KB");

    final tempDir = await getTemporaryDirectory();

    // If already small → direct Base64
    if (originalSize <= 1000000) {
      final bytes = await file.readAsBytes();
      return "data:image/jpeg;base64,${base64Encode(bytes)}";
    }

    int quality = 85;
    File? result;

    while (quality >= 30) {
      final targetPath =
          "${tempDir.path}/img_${DateTime.now().microsecondsSinceEpoch}_$quality.jpg";

      final xfile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: quality,
        minWidth: 800,
        minHeight: 600,
        format: CompressFormat.jpeg,
      );

      if (xfile == null) {
        quality -= 10;
        continue;
      }

      result = File(xfile.path);
      final size = await result.length();

      print("Quality $quality → ${(size / 1024).toStringAsFixed(1)} KB");

      if (size <= 1000000) {
        final bytes = await result.readAsBytes();
        return "data:image/jpeg;base64,${base64Encode(bytes)}";
      }

      quality -= 10;
    }

    // Final fallback (strong compression)
    if (result != null) {
      final bytes = await result.readAsBytes();
      return "data:image/jpeg;base64,${base64Encode(bytes)}";
    }

    return null;
  } catch (e) {
    print("Compression error: $e");
    return null;
  }
}

// Updated _pickImage method using your compression function
// In PremiumAddEventDialog class
Future<void> _pickImage() async {
  try {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 600,
    );
    
    if (pickedFile != null) {
      setState(() {
        _isImageLoading = true;
      });
      
      // Check file size
      final File originalFile = File(pickedFile.path);
      final int originalSize = await originalFile.length();
      
      if (originalSize > 10 * 1024 * 1024) {
        setState(() => _isImageLoading = false);
        _showErrorSnackBar('Image is too large (max 10MB). Please select a smaller image.');
        return;
      }
      
      // Store the file for later upload (don't convert to base64)
      setState(() {
        _selectedImage = pickedFile;
        _base64Image = null; // Clear any existing base64
        _isImageLoading = false;
      });
      
      _showSuccessSnackBar('Image selected. Will be uploaded to Cloudinary when creating event.');
    }
  } catch (e) {
    setState(() => _isImageLoading = false);
    _showErrorSnackBar('Error picking image: $e');
  }
}
  
  
  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      default: return 'image/jpeg';
    }
  }
// In PremiumAddEventDialog class
Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) return;

  if (_eventLatitude == null || _eventLongitude == null) {
    _showErrorSnackBar('Please select location on map');
    return;
  }

  if (_startDate == null) {
    _showErrorSnackBar('Please select event start date and time');
    return;
  }
  
  if (_isMultiDay && _endDate == null) {
    _showErrorSnackBar('Please select event end date and time for multi-day event');
    return;
  }

  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final currentUser = authProvider.user;
  
  if (currentUser == null) {
    _showErrorSnackBar('You must be logged in to create an event');
    return;
  }

  setState(() => _isSaving = true);

  try {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    
    // Generate event ID first for Cloudinary folder
    final eventId = DateTime.now().millisecondsSinceEpoch.toString();
    
    String? bannerImageUrl;
    
    // Upload image to Cloudinary if selected
    if (_selectedImage != null) {
      setState(() {
        _isSaving = true;
      });
      
      print('📸 Uploading event banner to Cloudinary...');
      final imageFile = File(_selectedImage!.path);
      bannerImageUrl = await CloudinaryService.uploadEventBanner(imageFile, eventId);
      
      if (bannerImageUrl == null) {
        _showErrorSnackBar('Failed to upload banner image. Please try again.');
        setState(() => _isSaving = false);
        return;
      }
      
      print('✅ Banner uploaded to Cloudinary: $bannerImageUrl');
    }

    // Create event date/time
    DateTime eventDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime?.hour ?? 0,
      _startTime?.minute ?? 0,
    );
    
    DateTime? endDateTime;
    if (_isMultiDay && _endDate != null) {
      endDateTime = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _endTime?.hour ?? 23,
        _endTime?.minute ?? 59,
      );
    }

    // Create event with Cloudinary URL
    await eventProvider.createEvent(
      title: _titleController.text,
      organizer: _organizerController.text,
      contactPerson: _contactPersonController.text,
      contactEmail: _contactEmailController.text,
      contactPhone: _contactPhoneController.text,
      startDate: eventDateTime,
      endDate: endDateTime,
      startTime: _startTime,
      endTime: _endTime,
      location: _locationController.text,
      description: _descriptionController.text,
      category: _selectedEventCategory!,
      bannerImageUrl: bannerImageUrl, // Cloudinary URL instead of base64
      isFree: _isFree,
      ticketPrices: _ticketPrices.isEmpty ? null : _ticketPrices,
      paymentInfo: null,
      createdBy: currentUser.id,
      latitude: _eventLatitude,
      longitude: _eventLongitude,
      state: _eventState,
      city: _eventCity,
    );

    _clearForm();
    
    if (mounted) {
      Navigator.pop(context);
      _showSuccessSnackBar('Event created successfully! Pending admin approval.');
    }
  } catch (e) {
    print('❌ Error creating event: $e');
    _showErrorSnackBar('Failed to create event: ${e.toString()}');
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
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
    _startDate = null;
    _endDate = null;
    _startTime = null;
    _endTime = null;
    _isMultiDay = false;
    _selectedImage = null;
    _base64Image = null;
    _isFree = true;
    _ticketPrices.clear();
    _selectedEventCategory = 'social';
    _eventLatitude = null;
    _eventLongitude = null;
    _eventState = null;
    _eventCity = null;
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text(message, style: TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: widget.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(12),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text(message, style: TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: widget.accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(12),
      ),
    );
  }
}