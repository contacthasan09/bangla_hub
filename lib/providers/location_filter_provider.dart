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
  
  // Set location filter from Events screen
  void setLocationFilter(String state, {bool fromEvents = true}) {
    if (_selectedState != state) {
      _selectedState = state;
      _isFilterActive = true;
      _isFilterAppliedFromEvents = fromEvents;
      notifyListeners();
    }
  }
  
  // Clear filter (affects all screens)
  void clearLocationFilter() {
    _selectedState = null;
    _isFilterActive = false;
    _isFilterAppliedFromEvents = false;
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
}