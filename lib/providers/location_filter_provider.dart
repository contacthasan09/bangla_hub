// providers/location_filter_provider.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationFilterProvider extends ChangeNotifier {
  String? _selectedState;
  bool _isFilterActive = false;
  bool _isFilterAppliedFromEvents = false; // Track which screen applied filter
  Position? _currentUserLocation;
  bool _hasLocationPermission = false;
  bool _isLoadingLocation = false;
  String? _locationErrorMessage;
  
  // Cache for cities by state
  final Map<String, List<String>> _citiesCache = {};
  
  // Getter for selected state
  String? get selectedState => _selectedState;
  bool get isFilterActive => _isFilterActive;
  bool get isFilterAppliedFromEvents => _isFilterAppliedFromEvents;
  Position? get currentUserLocation => _currentUserLocation;
  bool get hasLocationPermission => _hasLocationPermission;
  bool get isLoadingLocation => _isLoadingLocation;
  String? get locationErrorMessage => _locationErrorMessage;
  
  // Check if state is selected
  bool get isStateSelected => _selectedState != null && _selectedState!.isNotEmpty;
  
  // Get selected state display name
  String get selectedStateDisplay => _selectedState ?? 'Not Selected';
  
  // Get formatted location for display
  String get formattedLocation {
    if (!isStateSelected) return 'No location selected';
    return _selectedState!;
  }
  
  // Require state selection (triggers guard screen)
  void requireStateSelection() {
    if (!isStateSelected) {
      notifyListeners();
    }
  }
  
  // Set location filter from Events screen
  void setLocationFilter(String state, {bool fromEvents = true}) {
    if (_selectedState != state) {
      _selectedState = state;
      _isFilterActive = true;
      _isFilterAppliedFromEvents = fromEvents;
      notifyListeners();
      print('📍 LocationFilterProvider: State set to $state (fromEvents: $fromEvents)');
    }
  }
  
  // Clear filter (affects all screens)
  void clearLocationFilter() {
    _selectedState = null;
    _isFilterActive = false;
    _isFilterAppliedFromEvents = false;
    notifyListeners();
    print('📍 LocationFilterProvider: Filter cleared');
  }
  
  // ✅ NEW: Clear filter specifically for logout (same as clear but with distinct logging)
  void clearForLogout() {
    print('📍 LocationFilterProvider: Clearing filter for logout');
    _selectedState = null;
    _isFilterActive = false;
    _isFilterAppliedFromEvents = false;
    // Don't clear location data as it's user device specific
    notifyListeners();
  }
  
  // Get user location on login or when requested
  Future<bool> getUserLocation({bool showLoading = true}) async {
    if (showLoading) {
      _isLoadingLocation = true;
      _locationErrorMessage = null;
      notifyListeners();
    }
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _hasLocationPermission = false;
        _locationErrorMessage = 'Location services are disabled.';
        if (showLoading) _isLoadingLocation = false;
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _hasLocationPermission = false;
          _locationErrorMessage = 'Location permissions are denied.';
          if (showLoading) _isLoadingLocation = false;
          notifyListeners();
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _hasLocationPermission = false;
        _locationErrorMessage = 'Location permissions are permanently denied.';
        if (showLoading) _isLoadingLocation = false;
        notifyListeners();
        return false;
      }

      _currentUserLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
      _hasLocationPermission = true;
      _locationErrorMessage = null;
      if (showLoading) _isLoadingLocation = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error getting location: $e');
      _hasLocationPermission = false;
      _locationErrorMessage = 'Failed to get location: $e';
      if (showLoading) _isLoadingLocation = false;
      notifyListeners();
      return false;
    }
  }
  
  // Calculate distance between user and a location (in kilometers)
  double? calculateDistance(double lat, double lng) {
    if (_currentUserLocation == null) return null;
    
    try {
      return Geolocator.distanceBetween(
        _currentUserLocation!.latitude,
        _currentUserLocation!.longitude,
        lat,
        lng,
      ) / 1000; // Convert to kilometers
    } catch (e) {
      print('Error calculating distance: $e');
      return null;
    }
  }
  
  // Get formatted distance string
  String? getDistanceString(double lat, double lng) {
    final distance = calculateDistance(lat, lng);
    if (distance == null) return null;
    
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m away';
    } else if (distance < 10) {
      return '${distance.toStringAsFixed(1)}km away';
    } else if (distance < 100) {
      return '${distance.toStringAsFixed(0)}km away';
    } else {
      return '${distance.toStringAsFixed(0)}km away';
    }
  }
  
  // Cache cities for a state (you can call this from screens)
  void cacheCities(String state, List<String> cities) {
    _citiesCache[state] = cities;
  }
  
  // Get cached cities
  List<String>? getCachedCities(String state) {
    return _citiesCache[state];
  }
  
  // Clear cache when needed
  void clearCache() {
    _citiesCache.clear();
  }
  
  // Reset provider
  void reset() {
    _selectedState = null;
    _isFilterActive = false;
    _isFilterAppliedFromEvents = false;
    _locationErrorMessage = null;
    // Don't clear location as it's independent
    notifyListeners();
  }
  
  // Get all US states (useful for location selection)
  List<String> get usStates {
    return const [
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
  }
  
  // Get state abbreviation (optional)
  String getStateAbbreviation(String state) {
    const abbreviations = {
      'Alabama': 'AL', 'Alaska': 'AK', 'Arizona': 'AZ', 'Arkansas': 'AR',
      'California': 'CA', 'Colorado': 'CO', 'Connecticut': 'CT', 'Delaware': 'DE',
      'Florida': 'FL', 'Georgia': 'GA', 'Hawaii': 'HI', 'Idaho': 'ID',
      'Illinois': 'IL', 'Indiana': 'IN', 'Iowa': 'IA', 'Kansas': 'KS',
      'Kentucky': 'KY', 'Louisiana': 'LA', 'Maine': 'ME', 'Maryland': 'MD',
      'Massachusetts': 'MA', 'Michigan': 'MI', 'Minnesota': 'MN', 'Mississippi': 'MS',
      'Missouri': 'MO', 'Montana': 'MT', 'Nebraska': 'NE', 'Nevada': 'NV',
      'New Hampshire': 'NH', 'New Jersey': 'NJ', 'New Mexico': 'NM', 'New York': 'NY',
      'North Carolina': 'NC', 'North Dakota': 'ND', 'Ohio': 'OH', 'Oklahoma': 'OK',
      'Oregon': 'OR', 'Pennsylvania': 'PA', 'Rhode Island': 'RI', 'South Carolina': 'SC',
      'South Dakota': 'SD', 'Tennessee': 'TN', 'Texas': 'TX', 'Utah': 'UT',
      'Vermont': 'VT', 'Virginia': 'VA', 'Washington': 'WA', 'West Virginia': 'WV',
      'Wisconsin': 'WI', 'Wyoming': 'WY'
    };
    return abbreviations[state] ?? state.substring(0, 2).toUpperCase();
  }
  
  // Validate if a state is valid
  bool isValidState(String state) {
    return usStates.contains(state);
  }
  
  // Auto-detect state from user location (optional feature)
  Future<String?> detectStateFromLocation() async {
    final hasLocation = await getUserLocation(showLoading: false);
    if (!hasLocation || _currentUserLocation == null) {
      return null;
    }
    
    try {
      // This would typically use a geocoding service
      // For now, return null as this requires additional implementation
      // You can integrate with Google Maps Geocoding API here
      return null;
    } catch (e) {
      print('Error detecting state from location: $e');
      return null;
    }
  }
  
  // Suggest states based on user's location (optional)
  Future<List<String>> getSuggestedStates() async {
    final detectedState = await detectStateFromLocation();
    if (detectedState != null) {
      return [detectedState, ...usStates.where((s) => s != detectedState).take(5).toList()];
    }
    return usStates.take(10).toList();
  }
}