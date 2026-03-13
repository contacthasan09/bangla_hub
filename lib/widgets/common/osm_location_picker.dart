// widgets/common/osm_location_picker.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OSMLocationPicker extends StatefulWidget {
  final Function(double latitude, double longitude, String address, String? state, String? city) onLocationSelected;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final String? initialState;
  final String? initialCity;

  const OSMLocationPicker({
    Key? key,
    required this.onLocationSelected,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    this.initialState,
    this.initialCity,
  }) : super(key: key);

  @override
  State<OSMLocationPicker> createState() => _OSMLocationPickerState();
}

class _OSMLocationPickerState extends State<OSMLocationPicker> with TickerProviderStateMixin {
  late MapController _mapController;
  LatLng? _selectedLatLng;
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingAddress = false;
  TextEditingController _searchController = TextEditingController();
  
  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // USA bounds for map
  static const LatLng _usaCenter = LatLng(39.8283, -98.5795);
  static const double _usaZoom = 4.0;
  static const double _selectedZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLatLng = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation() async {
    if (_searchQuery.isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _fadeController.forward();
    });

    try {
      // Add USA filter to search
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(_searchQuery)}&format=json&limit=5&addressdetails=1&countrycodes=us'
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'BanglaHub-App/1.0',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data.cast<Map<String, dynamic>>();
        });
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
      setState(() {
        _isSearching = false;
        _fadeController.reverse();
      });
    }
  }

  Future<void> _selectSearchResult(Map<String, dynamic> result) async {
    final lat = double.parse(result['lat']);
    final lon = double.parse(result['lon']);
    final displayName = result['display_name'];
    
    setState(() {
      _selectedLatLng = LatLng(lat, lon);
      _searchResults = [];
      _searchController.clear();
      _isLoadingAddress = true;
    });

    // Move map to selected location with animation
    _mapController.move(_selectedLatLng!, _selectedZoom);

    // Get detailed address
    String? extractedState;
    String? extractedCity;
    String address = displayName;

    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        // Extract state and city
        extractedState = place.administrativeArea;
        extractedCity = place.locality ?? place.subAdministrativeArea;
        
        // Build clean address
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
    setState(() {
      _isLoadingAddress = true;
    });
    
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;

    return Container(
      height: screenSize.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Header with drag handle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select Location',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 22 : 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF006A4E),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 18),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      onSubmitted: (_) => _searchLocation(),
                      decoration: InputDecoration(
                        hintText: 'Search city, address, or place...',
                        hintStyle: GoogleFonts.inter(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: isTablet ? 16 : 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSearching ? null : _searchLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006A4E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
          ),
          
          // Search Results
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _searchResults.isNotEmpty ? 200 : 0,
            child: _searchResults.isNotEmpty
                ? Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF006A4E), Color(0xFF004D38)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            result['display_name'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            _getLocationType(result),
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 14 : 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          
          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLatLng ?? _usaCenter,
                    initialZoom: _selectedLatLng != null ? _selectedZoom : _usaZoom,
                    maxZoom: 19.0,
                    minZoom: 3.0,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedLatLng = point;
                      });
                      _getAddressFromLatLng(point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.bangla_hub',
                      maxZoom: 19,
                    ),
                    if (_selectedLatLng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLatLng!,
                            width: 50,
                            height: 50,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.elasticOut,
                              child: const Icon(
                                Icons.location_on,
                                color: Color(0xFFF42A41),
                                size: 40,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                
                // Crosshair in center (optional)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF006A4E).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF42A41),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Loading indicator
                if (_isLoadingAddress)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF006A4E),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Selected location info
          if (_selectedLatLng != null && !_isLoadingAddress)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF006A4E), Color(0xFF004D38)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location Selected',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedLatLng!.latitude.toStringAsFixed(4)}, ${_selectedLatLng!.longitude.toStringAsFixed(4)}',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 14 : 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF006A4E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006A4E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getLocationType(Map<String, dynamic> result) {
    final type = result['type'] ?? '';
    final category = result['category'] ?? '';
    
    if (type.isNotEmpty) {
      return type[0].toUpperCase() + type.substring(1);
    } else if (category.isNotEmpty) {
      return category[0].toUpperCase() + category.substring(1);
    }
    return 'Location';
  }
}