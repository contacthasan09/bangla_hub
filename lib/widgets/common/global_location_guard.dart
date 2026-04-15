// widgets/common/location_guard.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bangla_hub/providers/location_filter_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationGuard extends StatelessWidget {
  final Widget child;
  final bool required;
  final bool showBackButton;
  
  const LocationGuard({
    Key? key,
    required this.child,
    this.required = true,
    this.showBackButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!required) return child;
    
    return Consumer<LocationFilterProvider>(
      builder: (context, locationProvider, _) {
        final hasState = locationProvider.isStateSelected;
        
        if (!hasState) {
          return LocationSelectionScreen(
            showBackButton: showBackButton,
          );
        }
        
        return child;
      },
    );
  }
}

class LocationSelectionScreen extends StatelessWidget {
  final bool showBackButton;
  
  // Premium Color Palette - Bengali Flag Inspired
  static const Color _primaryRed = Color(0xFFE03C32);
  static const Color _primaryGreen = Color(0xFF006A4E);
  static const Color _darkGreen = Color(0xFF00432D);
  static const Color _goldAccent = Color(0xFFFFD700);
  static const Color _deepRed = Color(0xFFC62828);
  
  const LocationSelectionScreen({
    Key? key,
    this.showBackButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: showBackButton ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Location',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ) : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              _primaryGreen,
              _darkGreen,
              _primaryRed.withOpacity(0.8),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: _LocationSelectionContent(isTablet: isTablet),
      ),
    );
  }
}

class _LocationSelectionContent extends StatefulWidget {
  final bool isTablet;
  
  const _LocationSelectionContent({Key? key, required this.isTablet}) : super(key: key);

  @override
  State<_LocationSelectionContent> createState() => _LocationSelectionContentState();
}

class _LocationSelectionContentState extends State<_LocationSelectionContent> with TickerProviderStateMixin {
  // Premium Color Palette - Bengali Flag Inspired
  static const Color _primaryRed = Color(0xFFE03C32);
  static const Color _primaryGreen = Color(0xFF006A4E);
  static const Color _darkGreen = Color(0xFF00432D);
  static const Color _goldAccent = Color(0xFFFFD700);
  static const Color _lightGreen = Color(0xFFE8F5E9);
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _rotateController;
  late Animation<double> _rotateAnimation;
  
  String _searchQuery = '';
  
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
  
  List<String> get _filteredStates {
    if (_searchQuery.isEmpty) return _usStates;
    return _usStates.where((state) => 
      state.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _rotateAnimation = CurvedAnimation(parent: _rotateController, curve: Curves.linear);
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // Decorative background elements
          ...List.generate(3, (index) => _buildFloatingCircle(index)),
          
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(widget.isTablet ? 32 : 20),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ========== BANGLAHUB APP NAME HEADER ==========
                    _buildBanglaHubHeader(),
                    
                    SizedBox(height: widget.isTablet ? 16 : 12),
                    
                    // Animated Icon
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: RotationTransition(
                        turns: _rotateAnimation,
                        child: Container(
                          width: widget.isTablet ? 80 : 65,
                          height: widget.isTablet ? 80 : 65,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primaryRed, _goldAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _primaryRed.withOpacity(0.4),
                                blurRadius: 25,
                                spreadRadius: 3,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: _goldAccent.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: widget.isTablet ? 20 : 16),
                    
                    // Title
                    Text(
                      'Select Your Location',
                      style: GoogleFonts.poppins(
                        fontSize: widget.isTablet ? 26 : 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: widget.isTablet ? 8 : 6),
                    
                    // Subtitle
                    Text(
                      'Please select a state to view\nservices and opportunities in your area.',
                      style: GoogleFonts.inter(
                        fontSize: widget.isTablet ? 14 : 12,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: widget.isTablet ? 24 : 20),
                    
                    // Search Bar - Premium Style
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: widget.isTablet ? 20 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search for a state...',
                          hintStyle: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear_rounded, color: Colors.white.withOpacity(0.8)),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: widget.isTablet ? 14 : 12,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: widget.isTablet ? 20 : 16),
                    
                    // States Grid - Smaller Cards
                    Container(
                      height: widget.isTablet ? 380 : 320,
                      margin: EdgeInsets.symmetric(horizontal: widget.isTablet ? 12 : 8),
                      child: _filteredStates.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 40,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No states found',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: widget.isTablet ? 4 : 2,
                                childAspectRatio: 3.5,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                              ),
                              itemCount: _filteredStates.length,
                              itemBuilder: (context, index) {
                                final state = _filteredStates[index];
                                return _buildSmallStateCard(state);
                              },
                            ),
                    ),
                    
                    SizedBox(height: widget.isTablet ? 16 : 12),
                    
                    // Footer Note - Premium Style
                    Container(
                      padding: EdgeInsets.all(widget.isTablet ? 10 : 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: widget.isTablet ? 14 : 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Selecting your state helps us show you relevant local content',
                              style: GoogleFonts.inter(
                                fontSize: widget.isTablet ? 10 : 9,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
// ========== NEW: BanglaHub App Name Header (Brighter Gradient) ==========
Widget _buildBanglaHubHeader() {
  return Container(
    margin: EdgeInsets.only(bottom: widget.isTablet ? 16 : 12),
    padding: EdgeInsets.symmetric(
      horizontal: widget.isTablet ? 16 : 12,
      vertical: widget.isTablet ? 8 : 6,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated Logo/Icon with Brighter Gradient
     /*   TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.2),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                padding: EdgeInsets.all(widget.isTablet ? 8 : 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFFB300), Color(0xFFFF3D00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: widget.isTablet ? 22 : 18,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
       */ 
        // App Name with Brighter Gradient Text
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFF6B35),  // Bright Orange
              Color(0xFFFFB300),  // Bright Gold/Yellow
              Color(0xFFE03C32),  // Bright Red
              Color(0xFFFF6B35),  // Back to Orange
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'BanglaHub',
            style: GoogleFonts.poppins(
              fontSize: widget.isTablet ? 26 : 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.8,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
        
        // Small decorative dot with brighter gradient
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(left: 8, bottom: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFFB300)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B35).withOpacity(0.6),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


  Widget _buildFloatingCircle(int index) {
    final double size = 150 + (index * 50);
    final double left = (index * 100) % MediaQuery.of(context).size.width;
    final double top = (index * 80) % MediaQuery.of(context).size.height;
    
    return Positioned(
      left: left - size / 2,
      top: top - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withOpacity(0.03),
              Colors.white.withOpacity(0.01),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallStateCard(String state) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        
        final locationProvider = Provider.of<LocationFilterProvider>(
          context,
          listen: false,
        );
        
        locationProvider.setLocationFilter(state, fromEvents: true);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing content for $state',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: _primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryRed, _goldAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      state.substring(0, 2).toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    state,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 8,
                  color: Colors.white.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}