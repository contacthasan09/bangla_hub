// providers/service_provider_provider.dart
import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import '../models/community_services_models.dart';
import '../services/service_provider_service.dart';
import 'package:bangla_hub/providers/location_filter_provider.dart';

class ServiceProviderProvider with ChangeNotifier {
  final ServiceProviderService _service = ServiceProviderService();

  // State
  List<ServiceProviderModel> _allProviders = []; // All providers from Firestore
  List<ServiceProviderModel> _filteredProviders = []; // Filtered providers for display
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

  // Optimistic update tracking
  final Map<String, OptimisticLike> _pendingLikes = {};
  Timer? _batchUpdateTimer;
  static const int _batchDelayMs = 500;

  // Stream subscription
  StreamSubscription<List<ServiceProviderModel>>? _streamSubscription;

  // Getters
  List<ServiceProviderModel> get serviceProviders => _filteredProviders; // Return filtered list
  List<ServiceProviderModel> get allProviders => _allProviders; // Return all providers
  ServiceProviderModel? get selectedProvider => _selectedProvider;
  bool get isLoading => _isLoading;
  String get error => _error;

  String? get selectedState => _selectedState;
  // FIX: Add stateFilter getter that returns the current state filter value
  String? get stateFilter => _selectedState;
  String? get selectedCity => _selectedCity;
  ServiceCategory? get selectedCategory => _selectedCategory;
  String? get selectedServiceProvider => _selectedServiceProvider;
  String? get selectedSubServiceProvider => _selectedSubServiceProvider;
  String get searchQuery => _searchQuery;
  
  // Stream getter for selected provider
  Stream<ServiceProviderModel?> get selectedProviderStream => _selectedProviderController.stream;

  // Method to sync with global location filter
  void syncWithLocationFilter(LocationFilterProvider locationProvider) {
    print('📍 ServiceProvider.syncWithLocationFilter called with state: ${locationProvider.selectedState}');
    
    // Check if the state filter has actually changed
    if (_selectedState == locationProvider.selectedState) {
      print('📍 ServiceProvider filter already in sync: $_selectedState');
      return;
    }
    
    // Update the state filter
    _selectedState = locationProvider.selectedState;
    print('📍 ServiceProvider state filter changed to: $_selectedState');
    
    // Apply filters with the new state
    _applyFilters();
    
    // Notify listeners after the update is complete
    notifyListeners();
  }

  // Setters with automatic filtering
  void setSelectedState(String? state) {
    if (_selectedState != state) {
      _selectedState = state;
      if (state == null) {
        _selectedCity = null;
      }
      _applyFilters();
      notifyListeners();
    }
  }

  void setSelectedCity(String? city) {
    if (_selectedCity != city) {
      _selectedCity = city;
      _applyFilters();
      notifyListeners();
    }
  }

  void setSelectedCategory(ServiceCategory? category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      if (category == null) {
        _selectedServiceProvider = null;
        _selectedSubServiceProvider = null;
      }
      _applyFilters();
      notifyListeners();
    }
  }

  void setSelectedServiceProvider(String? serviceProvider) {
    if (_selectedServiceProvider != serviceProvider) {
      _selectedServiceProvider = serviceProvider;
      if (serviceProvider == null) {
        _selectedSubServiceProvider = null;
      }
      _applyFilters();
      notifyListeners();
    }
  }

  void setSelectedSubServiceProvider(String? subServiceProvider) {
    if (_selectedSubServiceProvider != subServiceProvider) {
      _selectedSubServiceProvider = subServiceProvider;
      _applyFilters();
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFilters();
      notifyListeners();
    }
  }

  // Load service providers
  Future<void> loadServiceProviders({bool adminView = false}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    print('🔄 loadServiceProviders called with adminView: $adminView');
    print('📍 Current state filter: $_selectedState');
    
    try {
      // Cancel existing subscription
      _streamSubscription?.cancel();
      
      // Get stream and listen for updates
      _streamSubscription = _service.getServiceProviders(
        state: _selectedState,
        city: _selectedCity,
        category: _selectedCategory,
        serviceProvider: _selectedServiceProvider,
        subServiceProvider: _selectedSubServiceProvider,
        searchQuery: _searchQuery,
        adminView: adminView,
        includeDeleted: adminView,
      ).listen(
        (providers) => _handleStreamUpdate(providers, adminView),
        onError: (error) {
          print('❌ Stream error: $error');
          _error = 'Failed to load service providers: ${error.toString()}';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('❌ Catch error: $e');
      _error = 'Failed to load service providers: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Handle stream updates
  void _handleStreamUpdate(List<ServiceProviderModel> providers, bool adminView) {
    // Apply any pending optimistic updates to the incoming data
    _allProviders = providers.map((provider) {
      final pendingLike = _pendingLikes[provider.id!];
      if (pendingLike != null) {
        return provider.copyWith(
          totalLikes: pendingLike.newTotalLikes,
          likedByUsers: pendingLike.newLikedByUsers,
          updatedAt: DateTime.now(),
        );
      }
      return provider;
    }).toList();

    // Apply current filters to the new data
    _applyFilters();
    _isLoading = false;
    
    print('✅ Stream received ${providers.length} providers');
    print('📊 After filtering: ${_filteredProviders.length} providers');
    notifyListeners();
  }

  // Apply filters to all providers
  void _applyFilters() {
    if (_allProviders.isEmpty) {
      _filteredProviders = [];
      return;
    }

    List<ServiceProviderModel> filtered = List.from(_allProviders);

    // Apply state filter
    if (_selectedState != null && _selectedState!.isNotEmpty) {
      filtered = filtered.where((p) => p.state == _selectedState).toList();
      print('📍 After state filter (${_selectedState}): ${filtered.length} providers');
    }

    // Apply city filter
    if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      filtered = filtered.where((p) => p.city == _selectedCity).toList();
      print('🏙️ After city filter (${_selectedCity}): ${filtered.length} providers');
    }

    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((p) => p.serviceCategory == _selectedCategory).toList();
      print('📁 After category filter (${_selectedCategory!.displayName}): ${filtered.length} providers');
    }

    // Apply service provider filter
    if (_selectedServiceProvider != null && _selectedServiceProvider!.isNotEmpty) {
      filtered = filtered.where((p) => p.serviceProvider == _selectedServiceProvider).toList();
      print('🔧 After service provider filter (${_selectedServiceProvider}): ${filtered.length} providers');
    }

    // Apply sub-service provider filter
    if (_selectedSubServiceProvider != null && _selectedSubServiceProvider!.isNotEmpty) {
      filtered = filtered.where((p) => p.subServiceProvider == _selectedSubServiceProvider).toList();
      print('🔨 After sub-service provider filter (${_selectedSubServiceProvider}): ${filtered.length} providers');
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      filtered = filtered.where((p) {
        return p.fullName.toLowerCase().contains(query) ||
               p.companyName.toLowerCase().contains(query) ||
               p.serviceProvider.toLowerCase().contains(query) ||
               (p.subServiceProvider?.toLowerCase().contains(query) ?? false) ||
               p.city.toLowerCase().contains(query) ||
               p.state.toLowerCase().contains(query);
      }).toList();
      print('🔍 After search filter (${_searchQuery}): ${filtered.length} providers');
    }

    _filteredProviders = filtered;
    
    // Log active filters
    print('🎯 Active filters: State: ${_selectedState ?? "Any"}, City: ${_selectedCity ?? "Any"}, Category: ${_selectedCategory?.displayName ?? "Any"}, Service: ${_selectedServiceProvider ?? "Any"}');
  }

  // Clear all filters
  void clearFilters() {
    _selectedState = null;
    _selectedCity = null;
    _selectedCategory = null;
    _selectedServiceProvider = null;
    _selectedSubServiceProvider = null;
    _searchQuery = '';
    _applyFilters();
    print('🧹 All filters cleared');
    notifyListeners();
  }

  // Clear specific filters
  void clearCategoryFilter() {
    _selectedCategory = null;
    _selectedServiceProvider = null;
    _selectedSubServiceProvider = null;
    _applyFilters();
    notifyListeners();
  }

  void clearServiceProviderFilter() {
    _selectedServiceProvider = null;
    _selectedSubServiceProvider = null;
    _applyFilters();
    notifyListeners();
  }

  void clearSubServiceProviderFilter() {
    _selectedSubServiceProvider = null;
    _applyFilters();
    notifyListeners();
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

  // Get count of active filters
  int get activeFilterCount {
    int count = 0;
    if (_selectedState != null) count++;
    if (_selectedCity != null) count++;
    if (_selectedCategory != null) count++;
    if (_selectedServiceProvider != null) count++;
    if (_selectedSubServiceProvider != null) count++;
    if (_searchQuery.isNotEmpty) count++;
    return count;
  }

  // Toggle like with optimistic update
  Future<bool> toggleLike(String providerId, String userId) async {
    final index = _allProviders.indexWhere((p) => p.id == providerId);
    if (index == -1) return false;
    
    final provider = _allProviders[index];
    final wasLiked = provider.isLikedByUser(userId);
    
    // Calculate new state
    final newLikedByUsers = List<String>.from(provider.likedByUsers);
    if (wasLiked) {
      newLikedByUsers.remove(userId);
    } else {
      newLikedByUsers.add(userId);
    }
    final newTotalLikes = newLikedByUsers.length;

    // Store optimistic state
    _pendingLikes[providerId] = OptimisticLike(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      newTotalLikes: newTotalLikes,
      newLikedByUsers: newLikedByUsers,
      userId: userId,
    );

    // Optimistic update in all providers
    final updatedProvider = provider.copyWith(
      totalLikes: newTotalLikes,
      likedByUsers: newLikedByUsers,
      updatedAt: DateTime.now(),
    );
    
    _allProviders[index] = updatedProvider;
    
    // Update filtered list if this provider is currently in it
    final filteredIndex = _filteredProviders.indexWhere((p) => p.id == providerId);
    if (filteredIndex != -1) {
      _filteredProviders[filteredIndex] = updatedProvider;
    }
    
    // Update selected provider if needed
    if (_selectedProvider?.id == providerId) {
      _selectedProvider = updatedProvider;
      _selectedProviderController.add(updatedProvider);
    }
    
    notifyListeners();
    
    // Queue for batch update
    _queueLikeUpdate();
    
    return true;
  }

  void _queueLikeUpdate() {
    _batchUpdateTimer?.cancel();
    _batchUpdateTimer = Timer(Duration(milliseconds: _batchDelayMs), _processPendingLikes);
  }

  Future<void> _processPendingLikes() async {
    if (_pendingLikes.isEmpty) return;

    final pendingToProcess = Map<String, OptimisticLike>.from(_pendingLikes);
    _pendingLikes.clear();

    for (final entry in pendingToProcess.entries) {
      final providerId = entry.key;
      final optimisticState = entry.value;
      
      try {
        await _service.toggleLike(providerId, optimisticState.userId);
        print('✅ Like processed for $providerId');
      } catch (e) {
        print('❌ Failed to process like for $providerId: $e');
        _revertLike(providerId, optimisticState);
      }
    }
  }

  void _revertLike(String providerId, OptimisticLike failedState) {
    final index = _allProviders.indexWhere((p) => p.id == providerId);
    if (index == -1) return;

    final currentProvider = _allProviders[index];
    
    final revertedLikedByUsers = List<String>.from(currentProvider.likedByUsers);
    if (revertedLikedByUsers.contains(failedState.userId)) {
      revertedLikedByUsers.remove(failedState.userId);
    } else {
      revertedLikedByUsers.add(failedState.userId);
    }
    
    final revertedProvider = currentProvider.copyWith(
      totalLikes: revertedLikedByUsers.length,
      likedByUsers: revertedLikedByUsers,
      updatedAt: DateTime.now(),
    );
    
    _allProviders[index] = revertedProvider;
    
    final filteredIndex = _filteredProviders.indexWhere((p) => p.id == providerId);
    if (filteredIndex != -1) {
      _filteredProviders[filteredIndex] = revertedProvider;
    }
    
    if (_selectedProvider?.id == providerId) {
      _selectedProvider = revertedProvider;
      _selectedProviderController.add(revertedProvider);
    }
    
    notifyListeners();
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
      _selectedProviderController.add(provider);
      _isLoading = false;
      notifyListeners();
      return provider;
    } catch (e) {
      _error = 'Failed to get provider: $e';
      _selectedProviderController.add(null);
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
      
      final index = _allProviders.indexWhere((p) => p.id == id);
      if (index != -1) {
        _allProviders[index] = provider.copyWith(id: id);
        _applyFilters();
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
      
      _allProviders.removeWhere((p) => p.id == id);
      _applyFilters();
      
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
      
      final index = _allProviders.indexWhere((p) => p.id == id);
      if (index != -1) {
        _allProviders[index] = _allProviders[index].copyWith(
          isAvailable: isAvailable,
          updatedAt: DateTime.now(),
        );
        _applyFilters();
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
      
      final index = _allProviders.indexWhere((p) => p.id == id);
      if (index != -1) {
        _allProviders[index] = _allProviders[index].copyWith(
          isVerified: isVerified,
          updatedAt: DateTime.now(),
        );
        _applyFilters();
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to toggle verification: $e';
      notifyListeners();
      return false;
    }
  }

  // Reset state
  void reset() {
    _allProviders.clear();
    _filteredProviders.clear();
    _selectedProvider = null;
    _isLoading = false;
    _error = '';
    _pendingLikes.clear();
    clearFilters();
    notifyListeners();
  }

  // Get available service providers for current category
  List<String> getAvailableServiceProviders() {
    if (_selectedCategory == null) return [];
    return _selectedCategory!.serviceProviders;
  }

  // Get available sub-service providers for current service provider
  List<String> getAvailableSubServiceProviders() {
    if (_selectedCategory == null || _selectedServiceProvider == null) return [];
    return _selectedCategory!.subServiceProviders[_selectedServiceProvider!] ?? [];
  }

  // Check if sub-service providers are available
  bool get hasSubServiceProvidersAvailable {
    if (_selectedCategory == null || _selectedServiceProvider == null) return false;
    return _selectedCategory!.subServiceProviders[_selectedServiceProvider!]?.isNotEmpty ?? false;
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

  // Dispose method
  void disposeProvider() {
    _batchUpdateTimer?.cancel();
    _streamSubscription?.cancel();
    _pendingLikes.clear();
    _selectedProviderController.close();
  }
}

// Helper class for optimistic likes
class OptimisticLike {
  final int timestamp;
  final int newTotalLikes;
  final List<String> newLikedByUsers;
  final String userId;

  OptimisticLike({
    required this.timestamp,
    required this.newTotalLikes,
    required this.newLikedByUsers,
    required this.userId,
  });
}