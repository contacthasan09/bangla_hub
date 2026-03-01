// providers/service_provider_provider.dart
import 'dart:async';

import 'package:flutter/material.dart';
import '../models/community_services_models.dart';
import '../services/service_provider_service.dart';

class ServiceProviderProvider with ChangeNotifier {
  final ServiceProviderService _service = ServiceProviderService();

  // State
  List<ServiceProviderModel> _serviceProviders = [];
  List<ServiceProviderModel> _filteredProviders = [];
  ServiceProviderModel? _selectedProvider;
  bool _isLoading = false;
  String _error = '';

    // Stream controller for selected provider
  final StreamController<ServiceProviderModel?> _selectedProviderController = 
      StreamController<ServiceProviderModel?>.broadcast();

  // Filter state
  String? _selectedState;
  String? _selectedCity;
  ServiceCategory? _selectedCategory;
  String? _selectedServiceProvider;
  String? _selectedSubServiceProvider;
  String _searchQuery = '';

  // Getters
  List<ServiceProviderModel> get serviceProviders => _filteredProviders;
  List<ServiceProviderModel> get allProviders => _serviceProviders;
  ServiceProviderModel? get selectedProvider => _selectedProvider;
  bool get isLoading => _isLoading;
  String get error => _error;

  String? get selectedState => _selectedState;
  String? get selectedCity => _selectedCity;
  ServiceCategory? get selectedCategory => _selectedCategory;
  String? get selectedServiceProvider => _selectedServiceProvider;
  String? get selectedSubServiceProvider => _selectedSubServiceProvider;
  String get searchQuery => _searchQuery;
    // Stream getter for selected provider
  Stream<ServiceProviderModel?> get selectedProviderStream => _selectedProviderController.stream;

  // Setters - FIXED: Don't clear other filters when setting one
  void setSelectedProvider(ServiceProviderModel? provider) {
    _selectedProvider = provider;
        _selectedProviderController.add(provider); // Add this line

    notifyListeners();
  }

  void setSelectedState(String? state) {
    _selectedState = state;
    // Only clear city if state changes to null
    if (state == null) {
      _selectedCity = null;
    }
    applyFilters();
    notifyListeners();
  }

  void setSelectedCity(String? city) {
    _selectedCity = city;
    applyFilters();
    notifyListeners();
  }

  void setSelectedCategory(ServiceCategory? category) {
    _selectedCategory = category;
    // Only clear service provider if category changes to null
    if (category == null) {
      _selectedServiceProvider = null;
      _selectedSubServiceProvider = null;
    }
    applyFilters();
    notifyListeners();
  }

  void setSelectedServiceProvider(String? serviceProvider) {
    _selectedServiceProvider = serviceProvider;
    // Only clear sub-service provider if service provider changes to null
    if (serviceProvider == null) {
      _selectedSubServiceProvider = null;
    }
    applyFilters();
    notifyListeners();
  }

  void setSelectedSubServiceProvider(String? subServiceProvider) {
    _selectedSubServiceProvider = subServiceProvider;
    applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    applyFilters();
    notifyListeners();
  }

  // Load service providers
  Future<void> loadServiceProviders({bool adminView = false}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    print('🔄 loadServiceProviders called with adminView: $adminView');
    
    try {
      // Get stream and listen for updates
      final stream = _service.getServiceProviders(
        state: _selectedState,
        city: _selectedCity,
        category: _selectedCategory,
        serviceProvider: _selectedServiceProvider,
        subServiceProvider: _selectedSubServiceProvider,
        searchQuery: _searchQuery,
        adminView: adminView,
        includeDeleted: adminView,
      );

      // Listen to stream and update providers
      stream.listen((providers) {
        print('✅ Stream received ${providers.length} providers');
        _serviceProviders = providers;
        _filteredProviders = providers;
        _isLoading = false;
        notifyListeners();
      }, onError: (error) {
        print('❌ Stream error: $error');
        _error = 'Failed to load service providers: ${error.toString()}';
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      print('❌ Catch error: $e');
      print('❌ Error type: ${e.runtimeType}');
      _error = 'Failed to load service providers: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load popular service providers
  Future<void> loadPopularProviders({String? state, String? city}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final stream = _service.getPopularServiceProviders(
        state: state,
        city: city,
      );

      stream.listen((providers) {
        _filteredProviders = providers;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to load popular providers: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load recent service providers
  Future<void> loadRecentProviders({String? state, String? city}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final stream = _service.getRecentServiceProviders(
        state: state,
        city: city,
      );

      stream.listen((providers) {
        _filteredProviders = providers;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to load recent providers: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load by category
  Future<void> loadByCategory(ServiceCategory category, {String? state, String? city}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final stream = _service.getServiceProvidersByCategory(
        category,
        state: state,
        city: city,
      );

      stream.listen((providers) {
        _filteredProviders = providers;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to load by category: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get cities for selected state
  Future<List<String>> getCitiesForState(String state) async {
    try {
      return await _service.getCitiesByState(state);
    } catch (e) {
      _error = 'Failed to get cities: $e';
      notifyListeners();
      return [];
    }
  }

  // Get service provider by ID
  Future<ServiceProviderModel?> getProviderById(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final provider = await _service.getServiceProviderById(id);
      _selectedProvider = provider;
            _selectedProviderController.add(provider); // Add this line

      _isLoading = false;
      notifyListeners();
      return provider;
    } catch (e) {
      _error = 'Failed to get provider: $e';
            _selectedProviderController.add(null); // Add this line

      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Add service provider
  Future<bool> addServiceProvider(ServiceProviderModel provider) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.addServiceProvider(provider);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add provider: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update service provider
  Future<bool> updateServiceProvider(String id, ServiceProviderModel provider) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.updateServiceProvider(id, provider);
      
      // Update in local list
      final index = _serviceProviders.indexWhere((p) => p.id == id);
      if (index != -1) {
        _serviceProviders[index] = provider.copyWith(id: id);
        applyFilters();
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update provider: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete service provider
  Future<bool> deleteServiceProvider(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.deleteServiceProvider(id);
      
      // Remove from local list
      _serviceProviders.removeWhere((p) => p.id == id);
      applyFilters();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete provider: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Toggle availability
  Future<bool> toggleAvailability(String id, bool isAvailable) async {
    try {
      await _service.toggleAvailability(id, isAvailable);
      
      // Update in local list
      final index = _serviceProviders.indexWhere((p) => p.id == id);
      if (index != -1) {
        _serviceProviders[index] = _serviceProviders[index].copyWith(
          isAvailable: isAvailable,
          updatedAt: DateTime.now(),
        );
        applyFilters();
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to toggle availability: $e';
      notifyListeners();
      return false;
    }
  }

  // Toggle verification
  Future<bool> toggleVerification(String id, bool isVerified) async {
    try {
      await _service.toggleVerification(id, isVerified);
      
      // Update in local list
      final index = _serviceProviders.indexWhere((p) => p.id == id);
      if (index != -1) {
        _serviceProviders[index] = _serviceProviders[index].copyWith(
          isVerified: isVerified,
          updatedAt: DateTime.now(),
        );
        applyFilters();
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to toggle verification: $e';
      notifyListeners();
      return false;
    }
  }

  // Toggle like
/*  Future<bool> toggleLike(String providerId, String userId) async {
    try {
      await _service.toggleLike(providerId, userId);
      
      // Update in local list
      final index = _serviceProviders.indexWhere((p) => p.id == providerId);
      if (index != -1) {
        final provider = _serviceProviders[index];
        final updatedProvider = provider.toggleLike(userId);
        _serviceProviders[index] = updatedProvider;
        applyFilters();
        
        // Update selected provider if it's the same
        if (_selectedProvider?.id == providerId) {
          _selectedProvider = updatedProvider;
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to toggle like: $e';
      notifyListeners();
      return false;
    }
  }  */

  // Update toggleLike method
  Future<bool> toggleLike(String providerId, String userId) async {
    try {
      await _service.toggleLike(providerId, userId);
      
      // Update in local list
      final index = _serviceProviders.indexWhere((p) => p.id == providerId);
      if (index != -1) {
        final provider = _serviceProviders[index];
        final updatedProvider = provider.toggleLike(userId);
        _serviceProviders[index] = updatedProvider;
        applyFilters();
        
        // Update selected provider if it's the same
        if (_selectedProvider?.id == providerId) {
          _selectedProvider = updatedProvider;
          _selectedProviderController.add(updatedProvider); // Add this line
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to toggle like: $e';
      notifyListeners();
      return false;
    }
  }


  // Clear all filters
  void clearFilters() {
    _selectedState = null;
    _selectedCity = null;
    _selectedCategory = null;
    _selectedServiceProvider = null;
    _selectedSubServiceProvider = null;
    _searchQuery = '';
    _filteredProviders = _serviceProviders;
    notifyListeners();
  }

  // Clear specific filters
  void clearCategoryFilter() {
    _selectedCategory = null;
    _selectedServiceProvider = null;
    _selectedSubServiceProvider = null;
    applyFilters();
    notifyListeners();
  }

  void clearServiceProviderFilter() {
    _selectedServiceProvider = null;
    _selectedSubServiceProvider = null;
    applyFilters();
    notifyListeners();
  }

  void clearSubServiceProviderFilter() {
    _selectedSubServiceProvider = null;
    applyFilters();
    notifyListeners();
  }

  // Reset state
  void reset() {
    _serviceProviders.clear();
    _filteredProviders.clear();
    _selectedProvider = null;
    _isLoading = false;
    _error = '';
    clearFilters();
    notifyListeners();
  }

  // Apply filters to service providers - LOCAL FILTERING (for UI responsiveness)
  void applyFilters() {
    List<ServiceProviderModel> filtered = _serviceProviders;

    // Apply state filter
    if (_selectedState != null) {
      filtered = filtered.where((p) => p.state == _selectedState).toList();
    }

    // Apply city filter
    if (_selectedCity != null) {
      filtered = filtered.where((p) => p.city == _selectedCity).toList();
    }

    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((p) => p.serviceCategory == _selectedCategory).toList();
    }

    // Apply service provider filter
    if (_selectedServiceProvider != null) {
      filtered = filtered.where((p) => p.serviceProvider == _selectedServiceProvider).toList();
    }

    // Apply sub-service provider filter
    if (_selectedSubServiceProvider != null) {
      filtered = filtered.where((p) => p.subServiceProvider == _selectedSubServiceProvider).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.fullName.toLowerCase().contains(query) ||
               p.companyName.toLowerCase().contains(query) ||
               p.serviceTags.any((tag) => tag.toLowerCase().contains(query)) ||
               p.address.toLowerCase().contains(query) ||
               p.serviceProvider.toLowerCase().contains(query) ||
               (p.subServiceProvider != null && p.subServiceProvider!.toLowerCase().contains(query));
      }).toList();
    }

    _filteredProviders = filtered;
  }

  // Get available service providers for current category
  List<String> getAvailableServiceProviders() {
    if (_selectedCategory == null) return [];
    return _selectedCategory!.serviceProviders;
  }

  // Get available sub-service providers for current service provider
  List<String> getAvailableSubServiceProviders() {
    if (_selectedCategory == null || _selectedServiceProvider == null) return [];
    final subProviders = _selectedCategory!.subServiceProviders[_selectedServiceProvider!];
    return subProviders ?? [];
  }

  // Check if sub-service providers are available for current selection
  bool get hasSubServiceProvidersAvailable {
    if (_selectedCategory == null || _selectedServiceProvider == null) return false;
    final subProviders = _selectedCategory!.subServiceProviders[_selectedServiceProvider!];
    return subProviders != null && subProviders.isNotEmpty;
  }

  // Stream getter for real-time updates
  Stream<List<ServiceProviderModel>> serviceProvidersStream() {
    return _service.getServiceProviders(
      state: _selectedState,
      city: _selectedCity,
      category: _selectedCategory,
      serviceProvider: _selectedServiceProvider,
      subServiceProvider: _selectedSubServiceProvider,
      searchQuery: _searchQuery,
      adminView: false,
    );
  }

  // Check if any filters are active
  bool get hasActiveFilters {
    return _selectedState != null ||
        _selectedCity != null ||
        _selectedCategory != null ||
        _selectedServiceProvider != null ||
        _selectedSubServiceProvider != null ||
        _searchQuery.isNotEmpty;
  }

    // Dispose method (add to provider)
  void disposeProvider() {
    _selectedProviderController.close();
  }
}

