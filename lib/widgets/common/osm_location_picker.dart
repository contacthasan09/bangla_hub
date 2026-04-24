// widgets/common/google_maps_location_picker.dart
import 'dart:io';
import 'package:bangla_hub/config/api_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart' as location_lib;
import 'package:location/location.dart';

class GoogleMapsLocationPicker extends StatefulWidget {
  final Function(double latitude, double longitude, String address, String? state, String? city) onLocationSelected;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final String? initialState;
  final String? initialCity;

  const GoogleMapsLocationPicker({
    Key? key,
    required this.onLocationSelected,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    this.initialState,
    this.initialCity,
  }) : super(key: key);

  @override
  State<GoogleMapsLocationPicker> createState() => _GoogleMapsLocationPickerState();
}

class _GoogleMapsLocationPickerState extends State<GoogleMapsLocationPicker> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  GoogleMapController? _mapController;
  LatLng? _selectedLatLng;
  String _selectedAddress = '';
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _autocompleteResults = [];
  bool _isSearching = false;
  bool _isLoadingAddress = false;
  bool _showAutocomplete = false;
  TextEditingController _searchController = TextEditingController();
  FocusNode _searchFocusNode = FocusNode();
  
  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  // USA bounds for map
  static const LatLng _usaCenter = LatLng(39.8283, -98.5795);
  static const double _usaZoom = 4.0;
  static const double _selectedZoom = 15.0;
  
  // Location service
  final location_lib.Location _location = location_lib.Location();
  bool _hasLocationPermission = false;
  LatLng? _currentLocation;
  
  // Marker dragging
  bool _isDraggingMarker = false;
  BitmapDescriptor? _draggableMarkerIcon;

  // Premium Colors
  final Color _primaryGreen = const Color(0xFF006A4E);
  final Color _primaryRed = const Color(0xFFF42A41);
  final Color _goldAccent = const Color(0xFFFFD700);
  final Color _darkGreen = const Color(0xFF004D38);
  final Color _lightGreen = const Color(0xFFE8F5E9);
  final Color _coralRed = const Color(0xFFFF6B6B);
  final Color _softGold = const Color(0xFFFFD966);
  final Color _textPrimary = const Color(0xFF1A1A2E);
  final Color _textSecondary = const Color(0xFF4A4A4A);
  final Color _shadowColor = const Color(0x1A000000);
  
  final LinearGradient _glassMorphismGradient = LinearGradient(
    colors: [
      Colors.white.withOpacity(0.95),
      Colors.white.withOpacity(0.9),
      Colors.white.withOpacity(0.85),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  String _getApiKey() {
    return ApiKeys.googleMapsKey;
  }

  @override
  void initState() {
    super.initState();
    
    // ✅ Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
      curve: Curves.easeOutCubic,
    ));
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLatLng = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _selectedAddress = widget.initialAddress ?? '';
    }
    
    _checkLocationPermission();
    _searchFocusNode.addListener(_onFocusChange);
    _loadDraggableMarkerIcon();
    
    // ✅ Start animations only if app is resumed
    if (_appLifecycleState == AppLifecycleState.resumed) {
      _startAnimations();
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
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
      _pulseController.repeat(reverse: true);
    }
  }
  
  void _stopAnimations() {
    _fadeController.stop();
    _slideController.stop();
    _pulseController.stop();
  }
  
  Future<void> _loadDraggableMarkerIcon() async {
    _draggableMarkerIcon = await BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueRed,
    );
    if (mounted) setState(() {});
  }
  
  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _showAutocomplete = _searchFocusNode.hasFocus && _searchQuery.isNotEmpty;
      });
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }
    
    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }
    
    if (mounted) {
      setState(() {
        _hasLocationPermission = true;
      });
    }
  }
  
  Future<void> _getCurrentLocation() async {
    if (!_hasLocationPermission) {
      await _checkLocationPermission();
    }
    
    try {
      final locationData = await _location.getLocation();
      final currentLatLng = LatLng(locationData.latitude!, locationData.longitude!);
      
      if (mounted) {
        setState(() {
          _currentLocation = currentLatLng;
          _selectedLatLng = currentLatLng;
        });
      }
      
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLatLng,
            zoom: _selectedZoom,
          ),
        ),
      );
      
      await _getAddressFromLatLng(currentLatLng);
      
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get current location. Please select manually.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _searchAutocomplete(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _autocompleteResults = [];
          _showAutocomplete = false;
        });
      }
      return;
    }
    
    try {
      final apiKey = _getApiKey();
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
        'input=${Uri.encodeComponent(query)}&types=geocode&location=39.8283,-98.5795&radius=5000000&key=$apiKey'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _autocompleteResults = List<Map<String, dynamic>>.from(data['predictions']);
            _showAutocomplete = true;
          });
        }
      }
    } catch (e) {
      print('Autocomplete error: $e');
    }
  }

  Future<void> _searchLocation() async {
    if (_searchQuery.isEmpty) return;
    
    if (mounted) {
      setState(() {
        _isSearching = true;
        _showAutocomplete = false;
      });
    }

    try {
      final apiKey = _getApiKey();
      
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json?'
        'query=${Uri.encodeComponent(_searchQuery)}&location=39.8283,-98.5795&radius=5000000&key=$apiKey'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          setState(() {
            _searchResults = List<Map<String, dynamic>>.from(data['results']);
          });
        } else if (data['status'] == 'ZERO_RESULTS' && mounted) {
          setState(() {
            _searchResults = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No results found'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('Search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _selectAutocompleteResult(Map<String, dynamic> result) async {
    final placeId = result['place_id'];
    
    if (mounted) {
      setState(() {
        _isLoadingAddress = true;
        _showAutocomplete = false;
        _searchController.text = result['description'];
      });
    }
    
    try {
      final apiKey = _getApiKey();
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?'
        'place_id=$placeId&fields=geometry,formatted_address,address_component&key=$apiKey'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          final lat = location['lat'];
          final lng = location['lng'];
          final address = data['result']['formatted_address'] ?? result['description'];
          
          String? extractedState;
          String? extractedCity;
          
          final components = data['result']['address_components'] as List?;
          if (components != null) {
            for (var component in components) {
              final types = component['types'] as List;
              if (types.contains('administrative_area_level_1')) {
                extractedState = component['long_name'];
              }
              if (types.contains('locality') || types.contains('administrative_area_level_2')) {
                extractedCity = component['long_name'];
              }
            }
          }
          
          setState(() {
            _selectedLatLng = LatLng(lat, lng);
            _selectedAddress = address;
          });
          
          await _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(lat, lng),
                zoom: _selectedZoom,
              ),
            ),
          );
          
          widget.onLocationSelected(
            lat,
            lng,
            address,
            extractedState,
            extractedCity,
          );
        }
      }
    } catch (e) {
      print('Place details error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    }
  }

  Future<void> _selectSearchResult(Map<String, dynamic> result) async {
    final geometry = result['geometry']['location'];
    final lat = geometry['lat'];
    final lon = geometry['lng'];
    final displayName = result['formatted_address'] ?? result['name'];
    
    if (mounted) {
      setState(() {
        _selectedLatLng = LatLng(lat, lon);
        _selectedAddress = displayName;
        _searchResults = [];
        _searchController.clear();
        _isLoadingAddress = true;
      });
    }

    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lon),
          zoom: _selectedZoom,
        ),
      ),
    );

    String? extractedState;
    String? extractedCity;
    String address = displayName;

    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        extractedState = place.administrativeArea;
        extractedCity = place.locality ?? place.subAdministrativeArea;
        
        final addressParts = [
          place.street,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((s) => s != null && s.isNotEmpty).toList();
        
        if (addressParts.isNotEmpty) {
          address = addressParts.join(', ');
          if (mounted) {
            setState(() {
              _selectedAddress = address;
            });
          }
        }
      }
    } catch (e) {
      print('Error getting address details: $e');
    }

    widget.onLocationSelected(
      lat, 
      lon, 
      address,
      extractedState,
      extractedCity,
    );

    if (mounted) {
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(LatLng point) async {
    if (_isLoadingAddress) return;
    
    if (mounted) {
      setState(() {
        _isLoadingAddress = true;
        _selectedLatLng = point;
      });
    }
    
    String? extractedState;
    String? extractedCity;
    String address = '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';

    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        extractedState = place.administrativeArea;
        extractedCity = place.locality ?? place.subAdministrativeArea;
        
        final addressParts = [
          place.street,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((s) => s != null && s.isNotEmpty).toList();
        
        if (addressParts.isNotEmpty) {
          address = addressParts.join(', ');
        }
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    
    if (mounted) {
      setState(() {
        _selectedAddress = address;
      });
    }
    
    widget.onLocationSelected(
      point.latitude,
      point.longitude,
      address,
      extractedState,
      extractedCity,
    );
    
    if (mounted) {
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  void _onMarkerDragStart(LatLng newPosition) {
    if (mounted) {
      setState(() {
        _isDraggingMarker = true;
        _selectedLatLng = newPosition;
      });
    }
  }
  
  void _onMarkerDragEnd(LatLng newPosition) {
    if (mounted) {
      setState(() {
        _isDraggingMarker = false;
        _selectedLatLng = newPosition;
      });
    }
    _getAddressFromLatLng(newPosition);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 Location updated!'),
        duration: Duration(seconds: 1),
        backgroundColor: Color(0xFF006A4E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _onMarkerDrag(LatLng newPosition) {
    if (mounted) {
      setState(() {
        _selectedLatLng = newPosition;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    if (_selectedLatLng != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _selectedLatLng!,
            zoom: _selectedZoom,
          ),
        ),
      );
    }
  }
  
  Future<void> _centerOnSelectedLocation() async {
    if (_selectedLatLng != null) {
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _selectedLatLng!,
            zoom: _selectedZoom,
          ),
        ),
      );
    }
  }
  
  Future<void> _zoomIn() async {
    await _mapController?.animateCamera(CameraUpdate.zoomIn());
  }
  
  Future<void> _zoomOut() async {
    await _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  @override
  void dispose() {
    // ✅ Stop all animations before disposing
    _stopAnimations();
    
    // ✅ Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onTap, bool isTablet) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: _primaryGreen, size: isTablet ? 26 : 24),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;
    final bool shouldAnimate = _appLifecycleState == AppLifecycleState.resumed;

    return Container(
      height: screenSize.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Premium Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryGreen, _darkGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryGreen.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_goldAccent, _softGold],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: _goldAccent,
                            size: isTablet ? 28 : 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Location',
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 22 : 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pinpoint your exact location',
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 14 : 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                            splashRadius: isTablet ? 24 : 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: _glassMorphismGradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _goldAccent.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _shadowColor,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: (value) {
                                setState(() => _searchQuery = value);
                                _searchAutocomplete(value);
                              },
                              onSubmitted: (_) {
                                _searchLocation();
                                setState(() => _showAutocomplete = false);
                              },
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 16 : 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search city, address, or place...',
                                hintStyle: GoogleFonts.inter(
                                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                                  fontSize: isTablet ? 14 : 12,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: _primaryGreen,
                                  size: 22,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear_rounded, color: _primaryGreen, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                            _autocompleteResults = [];
                                            _showAutocomplete = false;
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryGreen, _darkGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: _isSearching
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.search_rounded, color: Colors.white),
                              onPressed: _isSearching ? null : _searchLocation,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    // Current Location Button with animation only when app is resumed
                    GestureDetector(
                      onTap: _getCurrentLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_coralRed.withOpacity(0.1), Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _coralRed.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            shouldAnimate
                                ? ScaleTransition(
                                    scale: _pulseAnimation,
                                    child: Icon(Icons.my_location_rounded, color: _coralRed, size: 20),
                                  )
                                : Icon(Icons.my_location_rounded, color: _coralRed, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Use Current Location',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 14 : 13,
                                fontWeight: FontWeight.w600,
                                color: _coralRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Autocomplete Results
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _showAutocomplete && _autocompleteResults.isNotEmpty ? 200 : 0,
                child: _showAutocomplete && _autocompleteResults.isNotEmpty
                    ? Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _shadowColor,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _autocompleteResults.length,
                          itemBuilder: (context, index) {
                            final result = _autocompleteResults[index];
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _lightGreen,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.location_on_rounded, color: _primaryGreen, size: 18),
                              ),
                              title: Text(
                                result['description'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 14 : 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
                              onTap: () => _selectAutocompleteResult(result),
                            );
                          },
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              
              // Search Results
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _searchResults.isNotEmpty ? 200 : 0,
                child: _searchResults.isNotEmpty
                    ? Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _shadowColor,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            final address = result['formatted_address'] ?? result['name'];
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryGreen, _darkGreen],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
                              ),
                              title: Text(
                                result['name'] ?? 'Unknown',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 15 : 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: isTablet ? 12 : 11, color: Colors.grey[600]),
                              ),
                              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
                              onTap: () => _selectSearchResult(result),
                            );
                          },
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              
              // Map Section
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        GoogleMap(
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: CameraPosition(
                            target: _selectedLatLng ?? _usaCenter,
                            zoom: _selectedLatLng != null ? _selectedZoom : _usaZoom,
                          ),
                          onTap: (point) {
                            if (!_isDraggingMarker) {
                              setState(() => _selectedLatLng = point);
                              _getAddressFromLatLng(point);
                            }
                          },
                          markers: _selectedLatLng != null
                              ? {
                                  Marker(
                                    markerId: const MarkerId('draggable_marker'),
                                    position: _selectedLatLng!,
                                    draggable: true,
                                    onDragStart: _onMarkerDragStart,
                                    onDragEnd: _onMarkerDragEnd,
                                    onDrag: _onMarkerDrag,
                                    infoWindow: InfoWindow(
                                      title: 'Selected Location',
                                      snippet: _selectedAddress.isNotEmpty && _selectedAddress.length > 50
                                          ? _selectedAddress.substring(0, 50) + '...'
                                          : _selectedAddress.isNotEmpty ? _selectedAddress : 'Tap and hold to move',
                                    ),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                                  ),
                                }
                              : {},
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          compassEnabled: true,
                          mapToolbarEnabled: false,
                          minMaxZoomPreference: const MinMaxZoomPreference(3.0, 19.0),
                        ),
                        
                        // Premium Zoom Controls
                        Positioned(
                          right: 20,
                          bottom: 20,
                          child: Column(
                            children: [
                              _buildZoomButton(Icons.add, _zoomIn, isTablet),
                              const SizedBox(height: 8),
                              _buildZoomButton(Icons.remove, _zoomOut, isTablet),
                            ],
                          ),
                        ),
                        
                        // Center Crosshair
                        if (!_isDraggingMarker)
                          Center(
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _primaryGreen.withOpacity(0.4), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryGreen.withOpacity(0.2),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _primaryRed,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryRed.withOpacity(0.4),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        
                        // Dragging Overlay
                        if (_isDraggingMarker)
                          Positioned(
                            top: 20,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _primaryGreen,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Release to set location',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        
                        // Loading Overlay
                        if (_isLoadingAddress)
                          Container(
                            color: Colors.black.withOpacity(0.5),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(color: Color(0xFF006A4E)),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Getting address...',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: _textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Selected Location Card
              if (_selectedLatLng != null && !_isLoadingAddress)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, _lightGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _primaryGreen.withOpacity(0.2), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: _shadowColor,
                        blurRadius: 15,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryGreen, _darkGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryGreen.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Location Selected',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedAddress.isNotEmpty && _selectedAddress.length > 60
                                  ? _selectedAddress.substring(0, 60) + '...'
                                  : _selectedAddress.isNotEmpty
                                      ? _selectedAddress
                                      : '${_selectedLatLng!.latitude.toStringAsFixed(4)}, ${_selectedLatLng!.longitude.toStringAsFixed(4)}',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 14 : 13,
                                fontWeight: FontWeight.w600,
                                color: _primaryGreen,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      shouldAnimate
                          ? ScaleTransition(
                              scale: _pulseAnimation,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: Text(
                                  'Done',
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 14 : 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              child: Text(
                                'Done',
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 14 : 13,
                                  fontWeight: FontWeight.w700,
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
  }
}