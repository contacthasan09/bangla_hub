// screens/user_app/event/events_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:bangla_hub/providers/location_filter_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/auth/signup_screen.dart';
import 'package:bangla_hub/screens/user_app/event/event_details_screen.dart';
import 'package:bangla_hub/widgets/common/distance_widget.dart';
import 'package:bangla_hub/widgets/common/global_location_filter_bar.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';
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
  
  // Track filter state for UI updates
  String? _lastFilterState;
  bool _forceRebuild = false;
  
  final Map<String, List<EventModel>> _categorizedCache = {};
  final Map<String, Widget> _imageCache = {};
  
  Timer? _debounceTimer;
  
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
  DateTime? _selectedDate;
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
      
      // ✅ ADD THIS: Listen to location filter changes
      locationProvider.addListener(_onLocationFilterChanged);
    });
  }

  // ✅ ADD THIS METHOD: Handle location filter changes
  void _onLocationFilterChanged() {
    print('📍 EventsScreen: Location filter changed to: ${Provider.of<LocationFilterProvider>(context, listen: false).selectedState}');
    
    // Force UI update immediately
    if (mounted) {
      setState(() {
        _categorizedCache.clear();
        _imageCache.clear();
        _currentSliderIndex = 0;
        _lastFilterState = Provider.of<LocationFilterProvider>(context, listen: false).selectedState;
        _forceRebuild = !_forceRebuild;
      });
    }
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
    
    // Sync with global location filter - FIXED: changed stateFilter to currentStateFilter
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
  
  List<EventModel> _getFilteredEvents(EventProvider eventProvider) {
    final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
    
    if (locationProvider.isFilterActive && eventProvider.upcomingEvents.isEmpty) {
      print('📍 Filter active but no events, returning empty list');
      return [];
    }
    
    if (_selectedCategory == null || _selectedCategory == 'all') {
      return eventProvider.upcomingEvents;
    }
    
    final cacheKey = 'upcoming_${_selectedCategory}';
    if (!_categorizedCache.containsKey(cacheKey)) {
      _categorizedCache[cacheKey] = eventProvider.upcomingEvents
          .where((event) => event.category == _selectedCategory)
          .toList();
    }
    return _categorizedCache[cacheKey]!;
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
    
    // ✅ Cancel timers first
    _debounceTimer?.cancel();
    _autoSlideTimer?.cancel();
    
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

  // Show empty state for filter with no results
  Widget _buildEmptyFilterState(bool isTablet, String state) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 30, offset: Offset(0, 15))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _lightBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off_rounded,
              size: isTablet ? 80 : 60,
              color: _primaryGreen,
            ),
          ),
          SizedBox(height: isTablet ? 24 : 20),
          Text(
            'No Events in $state',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.w800,
              color: _primaryGreen,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            'There are currently no events in $state.',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 18 : 16,
              color: _textLight,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            'Check back later or try a different state.',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 16 : 14,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 32 : 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 32 : 24,
                    vertical: isTablet ? 16 : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Clear Filter',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 15))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primaryRed, _primaryGreen]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: const Icon(Icons.lock_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 8),
                    Text('Login Required', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('You need to login to $feature', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]), textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text('Create an account or sign in to access full details', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Login', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen(role: 'user')));
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryGreen,
                          side: BorderSide(color: _primaryGreen, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Create Account', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Continue Browsing', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
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

  void _showLocationFilterDialog(BuildContext context) {
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
                    
                    SliverToBoxAdapter(
                      child: Consumer3<EventProvider, LocationFilterProvider, AuthProvider>(
                        builder: (context, eventProvider, locationProvider, authProvider, _) {
                          if (locationProvider.isFilterActive) {
                            print('📍 Active filter: ${locationProvider.selectedState}');
                            _debugCheckEvents(eventProvider);
                          }
                          
                          // Force rebuild when locationProvider changes by using its value in the key
                          return _buildPremiumBodyContent(
                            Key('events_content_${locationProvider.selectedState}_$_selectedCategory${locationProvider.isFilterActive}_$_forceRebuild'),
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
              if (!_hasScrolled && _isInitialized)
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

  Widget _buildPremiumAppBar(bool isTablet, AuthProvider authProvider) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFF42A41), Color(0xFF006A4E), Color(0xFFFFD966)]).createShader(bounds),
                    child: Text(
                      authProvider.user != null ? 'Hello, ${authProvider.user!.firstName}!' : authProvider.isGuestMode ? 'Hello, Guest!' : 'Hello to BanglaHub!',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: isTablet ? 22 : 18, height: 1.2, color: Colors.white, letterSpacing: -0.5, shadows: const [Shadow(color: Color(0xFF004D38), blurRadius: 15, offset: Offset(0, 3))]),
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
            const SizedBox(height: 4),
            Text('Welcome to BanglaHub', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: isTablet ? 18 : 16, color: Colors.white.withOpacity(0.95), letterSpacing: 0.5, shadows: const [Shadow(color: Colors.black26, blurRadius: 5)])),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFF42A41), Color(0xFF006A4E), Color(0xFFFFD966)]).createShader(bounds),
                  child: Text('Events', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: isTablet ? 40 : 32, height: 1.1, color: Colors.white, letterSpacing: -2, shadows: const [Shadow(color: Color(0xFF004D38), blurRadius: 20, offset: Offset(0, 5)), Shadow(color: Color(0xFFF42A41), blurRadius: 15, offset: Offset(0, 2))])),
                ),
                Consumer<LocationFilterProvider>(
                  builder: (context, filterProvider, child) {
                    return Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: Stack(
                        children: [
                          IconButton(
                            icon: Icon(filterProvider.isFilterActive ? Icons.filter_alt_rounded : Icons.filter_alt_outlined, color: Colors.white, size: isTablet ? 28 : 24),
                            onPressed: () => _showLocationFilterDialog(context),
                          ),
                          if (filterProvider.isFilterActive)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(width: 12, height: 12, decoration: BoxDecoration(color: _primaryRed, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: _primaryRed.withOpacity(0.5), blurRadius: 5)])),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<LocationFilterProvider>(
              builder: (context, filterProvider, child) {
                if (!filterProvider.isFilterActive) return const SizedBox.shrink();
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: _primaryGreen, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text('📍 ${filterProvider.selectedState}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                print('📍 Events: Clear button in app bar tapped');
                                
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
                                
                                filterProvider.clearLocationFilter();
                                final eventProvider = Provider.of<EventProvider>(context, listen: false);
                                eventProvider.updateStateFilter(null);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Location filter cleared'),
                                    backgroundColor: Color(0xFF006A4E),
                                    behavior: SnackBarBehavior.floating,
                                  )
                                );
                              },
                              child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 14)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
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
                    Text(authProvider.isGuestMode ? 'Browse events as guest' : 'Discover and manage events seamlessly', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.95), fontSize: isTablet ? 16 : 14, fontWeight: FontWeight.w600, shadows: const [Shadow(color: Colors.black26, blurRadius: 3)])),
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

    if (eventProvider.error != null && eventProvider.upcomingEvents.isEmpty) {
      return _buildErrorState(isTablet, isSmallScreen, eventProvider.error!);
    }

    if (locationProvider.isFilterActive && 
        eventProvider.upcomingEvents.isEmpty && 
        eventProvider.pastEvents.isEmpty) {
      return Column(
        children: [
          SizedBox(height: isTablet ? 36 : 26),
          _buildEmptyFilterState(isTablet, locationProvider.selectedState!),
        ],
      );
    }

    final safeFilteredEvents = _getFilteredEvents(eventProvider);
    final safePastEvents = eventProvider.pastEvents;
    
    final carouselEvents = safeFilteredEvents.isNotEmpty 
        ? (_showAllUpcomingEvents ? safeFilteredEvents : safeFilteredEvents.take(5).toList())
        : [];
        
    final upcomingEventsToShow = safeFilteredEvents.isNotEmpty
        ? (_showAllUpcomingEvents ? safeFilteredEvents : safeFilteredEvents.take(5).toList())
        : [];
        
    final pastEventsToShow = safePastEvents.isNotEmpty
        ? (_showAllPastEvents ? safePastEvents : safePastEvents.take(3).toList())
        : [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: isTablet ? 36 : 26),
        
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
                    child: Icon(Icons.event_available_rounded, color: Colors.white, size: isTablet ? 24 : 20),
                  ),
                  const SizedBox(width: 12),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFF42A41), Color(0xFF006A4E)]).createShader(bounds),
                    child: Text('Upcoming Events', style: GoogleFonts.poppins(fontSize: isTablet ? 24 : 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 14 : 12, vertical: isTablet ? 8 : 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF006A4E), Color(0xFF004D38)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Text('${safeFilteredEvents.length} events', style: GoogleFonts.poppins(fontSize: isTablet ? 14 : 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          ),
        ),
        
        SizedBox(height: isTablet ? 20 : 17),
        
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
        else
          _buildEmptyCarouselState(isTablet, isSmallScreen, authProvider, locationProvider),
          
        if (carouselEvents.isNotEmpty) ...[
          SizedBox(height: isTablet ? 16 : 12),
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
        
        SizedBox(height: isTablet ? 25 : 20),
        
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
              const SizedBox(width: 10),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFF42A41), Color(0xFF006A4E)]).createShader(bounds),
                child: Text('Browse Categories', style: GoogleFonts.poppins(fontSize: isTablet ? 22 : 20, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
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
        if (safeFilteredEvents.isNotEmpty)
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
        if (safePastEvents.isNotEmpty) ...[
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
                  child: Text('Past Events', style: GoogleFonts.poppins(fontSize: isTablet ? 25 : 23, fontWeight: FontWeight.w600, color: Colors.white)),
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

  if (eventProvider.error != null && eventProvider.upcomingEvents.isEmpty) {
    return _buildErrorState(isTablet, isSmallScreen, eventProvider.error!);
  }

  // Get filtered events for the current state
  final filteredUpcoming = _getFilteredEvents(eventProvider);
  final filteredPast = locationProvider.isFilterActive 
      ? eventProvider.pastEvents.where((event) => event.state == locationProvider.selectedState).toList()
      : eventProvider.pastEvents;

  // If filter is active and there are no events, show empty state
  if (locationProvider.isFilterActive && filteredUpcoming.isEmpty && filteredPast.isEmpty) {
    return Column(
      children: [
        SizedBox(height: isTablet ? 36 : 26),
        _buildEmptyFilterState(isTablet, locationProvider.selectedState!),
      ],
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
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: isTablet ? 36 : 26),
      
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
                  child: Icon(Icons.event_available_rounded, color: Colors.white, size: isTablet ? 24 : 20),
                ),
                const SizedBox(width: 12),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFF42A41), Color(0xFF006A4E)]).createShader(bounds),
                  child: Text('Upcoming Events', style: GoogleFonts.poppins(fontSize: isTablet ? 24 : 20, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 14 : 12, vertical: isTablet ? 8 : 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF006A4E), Color(0xFF004D38)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Text('${filteredUpcoming.length} events', style: GoogleFonts.poppins(fontSize: isTablet ? 14 : 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
      ),
      
      SizedBox(height: isTablet ? 20 : 17),
      
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
      else if (!locationProvider.isFilterActive)
        _buildEmptyCarouselState(isTablet, isSmallScreen, authProvider, locationProvider),
        
      if (carouselEvents.isNotEmpty) ...[
        SizedBox(height: isTablet ? 16 : 12),
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
      
      SizedBox(height: isTablet ? 25 : 20),
      
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
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFF42A41), Color(0xFF006A4E)]).createShader(bounds),
              child: Text('Browse Categories', style: GoogleFonts.poppins(fontSize: isTablet ? 22 : 20, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
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
                child: Text('Past Events', style: GoogleFonts.poppins(fontSize: isTablet ? 25 : 23, fontWeight: FontWeight.w600, color: Colors.white)),
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

  Widget _buildCachedEventImage(EventModel event, bool isTablet, {bool thumbnail = false}) {
    final cacheKey = event.id + (thumbnail ? '_thumb' : '');
    
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey]!;
    }
    
    Widget imageWidget;
    
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
          imageWidget = Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (context, error, stackTrace) => _buildDefaultEventImage(isTablet));
        } else {
          imageWidget = Image.network(
            event.bannerImageUrl!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(child: CircularProgressIndicator(strokeWidth: 2, color: _primaryGreen));
            },
            errorBuilder: (context, error, stackTrace) => _buildDefaultEventImage(isTablet),
          );
        }
      } catch (e) {
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
                  Text(event.title, style: GoogleFonts.poppins(fontSize: isTablet ? 22 : 18, fontWeight: FontWeight.w800, color: isPast ? _darkGreen.withOpacity(0.7) : _darkGreen), maxLines: 2, overflow: TextOverflow.ellipsis),
                  SizedBox(height: isTablet ? 12 : 8),
                  Row(
                    children: [
                      Icon(Icons.business_rounded, size: isTablet ? 18 : 16, color: isPast ? _primaryRed : _primaryGreen),
                      const SizedBox(width: 8),
                      Expanded(child: Text(event.organizer, style: GoogleFonts.inter(fontSize: isTablet ? 16 : 14, color: isPast ? _textLight : _textSecondary, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: isTablet ? 18 : 16, color: isPast ? _coralRed.withOpacity(0.7) : _coralRed),
                      const SizedBox(width: 8),
                      Expanded(child: Text(event.formattedDate, style: GoogleFonts.inter(fontSize: isTablet ? 15 : 13, color: isPast ? _textLight : _textSecondary, fontWeight: FontWeight.w600))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: isTablet ? 18 : 16, color: isPast ? _mintGreen.withOpacity(0.7) : _mintGreen),
                      const SizedBox(width: 8),
                      Expanded(child: Text(event.location, style: GoogleFonts.inter(fontSize: isTablet ? 15 : 13, color: isPast ? _textLight : _textSecondary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                        Text(event.interestedCountText, style: GoogleFonts.inter(fontSize: isTablet ? 14 : 12, color: _goldAccent, fontWeight: FontWeight.w600)),
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
              Text('Version 2.0', style: GoogleFonts.inter(fontSize: isTablet ? 14 : 13, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600)),
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

  // Add Event Dialog
  void _showPremiumAddEventDialog(BuildContext context, bool isTablet) {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final mediaQuery = MediaQuery.of(context);
          final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
          final screenWidth = mediaQuery.size.width;
          final isTablet = screenWidth >= 600;
          
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isTablet ? 40 : 20,
              vertical: isKeyboardVisible ? (isTablet ? 20 : 10) : (isTablet ? 40 : 20),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
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
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF42A41), Color(0xFF006A4E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(isTablet ? 50 : 40),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: isTablet ? 70 : 60,
                            height: isTablet ? 70 : 60,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(isTablet ? 20 : 18),
                            ),
                            child: Center(
                              child: _appLifecycleState == AppLifecycleState.resumed
                                  ? RotationTransition(
                                      turns: _rotateAnimation,
                                      child: const Icon(
                                        Icons.add_circle_rounded,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.add_circle_rounded,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                          SizedBox(width: isTablet ? 20 : 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Colors.white, Color(0xFFFFD700)],
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
                                const SizedBox(height: 4),
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
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
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
                          mainAxisSize: MainAxisSize.min,
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
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF006A4E), Color(0xFF004D38)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.info_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
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
                                        const SizedBox(height: 4),
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
                              gradient: const LinearGradient(
                                colors: [Color(0xFF006A4E), Color(0xFF004D38)],
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
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF006A4E), Color(0xFF004D38)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.calendar_today_rounded,
                                        color: Colors.white,
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
                                          const SizedBox(height: 4),
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
                      
                            // Location Picker - REPLACED WITH MAP PICKER
                            _buildLocationFieldWithMap(isTablet, setState),
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
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: DropdownButton<String>(
                                value: _selectedEventCategory,
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                underline: const SizedBox(),
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
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFF42A41), Color(0xFF006A4E)],
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
                                        const SizedBox(width: 16),
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
                                      offset: const Offset(0, 8),
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
                                          padding: const EdgeInsets.all(12),
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
                                        const SizedBox(width: 20),
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
                                              const SizedBox(height: 4),
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
                                        child: const CircularProgressIndicator(
                                          color: Color(0xFF2ECC71),
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
                                    offset: const Offset(0, 8),
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
                                    padding: const EdgeInsets.only(top: 20),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [_coralRed, _primaryRed],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.description_rounded,
                                        color: Colors.white,
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
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: isTablet ? 30 : 26,
                                      height: isTablet ? 30 : 26,
                                      decoration: BoxDecoration(
                                        gradient: _isFree ? const LinearGradient(colors: [Color(0xFF2ECC71), Color(0xFF004D38)]) : null,
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
                                    const SizedBox(width: 20),
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
                                        const Icon(
                                          Icons.monetization_on_rounded,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 12),
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
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFFFFD700), Color(0xFFFFD966)],
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
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 1,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: TextFormField(
                                              controller: _ticketPriceController,
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                                        const SizedBox(width: 12),
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
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF2ECC71), Color(0xFF004D38)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: const Icon(
                                              Icons.add_rounded,
                                              color: Colors.white,
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
                                      offset: const Offset(0, 8),
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
                                      : const LinearGradient(colors: [Color(0xFF006A4E), Color(0xFF004D38)]),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _emeraldGreen.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isSaving
                                      ? SizedBox(
                                          width: isTablet ? 30 : 26,
                                          height: isTablet ? 30 : 26,
                                          child: const CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.send_rounded,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 8),
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
            offset: const Offset(0, 8),
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
            padding: const EdgeInsets.all(10),
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
        latitude: _eventLatitude,
        longitude: _eventLongitude,
        state: _eventState,
        city: _eventCity,
      );

      _clearForm();
      
      Navigator.pop(context);
      
      _showSuccessDialog(context, isTablet: MediaQuery.of(context).size.width >= 600);
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSuccessDialog(BuildContext context, {required bool isTablet}) {
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