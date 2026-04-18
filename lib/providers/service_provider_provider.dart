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

  // My Services state
  List<ServiceProviderModel> _myApprovedServices = [];
  List<ServiceProviderModel> _myPendingServices = [];

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
  StreamSubscription<List<ServiceProviderModel>>? _userServicesSubscription;
  
  // Flag to prevent multiple simultaneous reloads
  bool _isReloading = false;

  // Getters
  List<ServiceProviderModel> get serviceProviders => _filteredProviders;
  List<ServiceProviderModel> get allProviders => _allProviders;
  ServiceProviderModel? get selectedProvider => _selectedProvider;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  // My Services getters
  List<ServiceProviderModel> get myApprovedServices => _myApprovedServices;
  List<ServiceProviderModel> get myPendingServices => _myPendingServices;

  String? get selectedState => _selectedState;
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
    
    if (_selectedState == locationProvider.selectedState) {
      print('📍 ServiceProvider filter already in sync: $_selectedState');
      return;
    }
    
    _selectedState = locationProvider.selectedState;
    print('📍 ServiceProvider state filter changed to: $_selectedState');
    loadServiceProviders();
  }

  // Setters with automatic filtering
  void setSelectedState(String? state) {
    if (_selectedState != state) {
      _selectedState = state;
      if (state == null) {
        _selectedCity = null;
      }
      loadServiceProviders();
    }
  }

  void setSelectedCity(String? city) {
    if (_selectedCity != city) {
      _selectedCity = city;
      loadServiceProviders();
    }
  }

  void setSelectedCategory(ServiceCategory? category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      if (category == null) {
        _selectedServiceProvider = null;
        _selectedSubServiceProvider = null;
      }
      loadServiceProviders();
    }
  }

  void setSelectedServiceProvider(String? serviceProvider) {
    if (_selectedServiceProvider != serviceProvider) {
      _selectedServiceProvider = serviceProvider;
      if (serviceProvider == null) {
        _selectedSubServiceProvider = null;
      }
      loadServiceProviders();
    }
  }

  void setSelectedSubServiceProvider(String? subServiceProvider) {
    if (_selectedSubServiceProvider != subServiceProvider) {
      _selectedSubServiceProvider = subServiceProvider;
      loadServiceProviders();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applySearchFilter();
    }
  }

  // Apply search filter locally
  void _applySearchFilter() {
    if (_allProviders.isEmpty) {
      _filteredProviders = [];
      return;
    }

    List<ServiceProviderModel> filtered = List.from(_allProviders);

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
    
    print('🎯 Active filters: State: ${_selectedState ?? "Any"}, City: ${_selectedCity ?? "Any"}, Category: ${_selectedCategory?.displayName ?? "Any"}, Service: ${_selectedServiceProvider ?? "Any"}');
    notifyListeners();
  }

  // Load service providers
  Future<void> loadServiceProviders({bool adminView = false}) async {
    if (_isReloading) return;
    
    _isReloading = true;
    _isLoading = true;
    _error = '';
    notifyListeners();

    print('🔄 loadServiceProviders called with adminView: $adminView');
    print('📍 Current state filter: $_selectedState');
    
    try {
      _streamSubscription?.cancel();
      
      _streamSubscription = _service.getServiceProviders(
        state: _selectedState,
        city: _selectedCity,
        category: _selectedCategory,
        serviceProvider: _selectedServiceProvider,
        subServiceProvider: _selectedSubServiceProvider,
        searchQuery: _searchQuery,
        adminView: adminView,
        includeDeleted: adminView,
        onlyVerified: !adminView,
        onlyAvailable: !adminView,
      ).listen(
        (providers) => _handleStreamUpdate(providers, adminView),
        onError: (error) {
          print('❌ Stream error: $error');
          _error = 'Failed to load service providers: ${error.toString()}';
          _isLoading = false;
          _isReloading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('❌ Catch error: $e');
      _error = 'Failed to load service providers: ${e.toString()}';
      _isLoading = false;
      _isReloading = false;
      notifyListeners();
    }
  }

  // Handle stream updates
  void _handleStreamUpdate(List<ServiceProviderModel> providers, bool adminView) {
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

    _applySearchFilter();
    _isLoading = false;
    _isReloading = false;
    
    print('✅ Stream received ${providers.length} providers');
    print('📊 After filtering: ${_filteredProviders.length} providers');
    notifyListeners();
  }

  // ==================== MY SERVICES METHODS ====================
// ==================== MY SERVICES METHODS ====================

// Load user's services - FIXED to show all services including pending
Future<void> loadUserServices(String userId, {bool adminView = false}) async {
  if (_isReloading) return;
  
  _isReloading = true;
  _isLoading = true;
  _error = '';
  notifyListeners();

  print('🔄 loadUserServices called for userId: $userId');
  print('🔄 Admin view: $adminView');
  
  try {
    _userServicesSubscription?.cancel();
    
    // IMPORTANT: For user's own services, we want to see ALL their services
    // regardless of verification status. Set adminView = true to bypass filters.
    _userServicesSubscription = _service.getUserServices(
      userId: userId,
      adminView: true, // Set to true to show all services including unverified
      includeDeleted: adminView,
      onlyVerified: false, // Don't filter by verification for user's own services
      onlyAvailable: false, // Don't filter by availability for user's own services
    ).listen(
      (providers) => _handleUserServicesUpdate(providers),
      onError: (error) {
        print('❌ User services stream error: $error');
        _error = 'Failed to load your services: ${error.toString()}';
        _isLoading = false;
        _isReloading = false;
        notifyListeners();
      },
    );
  } catch (e) {
    print('❌ Catch error: $e');
    _error = 'Failed to load your services: ${e.toString()}';
    _isLoading = false;
    _isReloading = false;
    notifyListeners();
  }
}

// Handle user services update
void _handleUserServicesUpdate(List<ServiceProviderModel> providers) {
  print('📊 Processing ${providers.length} user services');
  
  // Log each service for debugging
  for (var service in providers) {
    print('  - Service: ${service.companyName}, Verified: ${service.isVerified}, Deleted: ${service.isDeleted}');
  }
  
  // Separate into approved and pending based on isVerified
  // Show ALL services that are not deleted
  _myApprovedServices = providers
      .where((p) => p.isVerified == true && !p.isDeleted)
      .toList();
  _myPendingServices = providers
      .where((p) => p.isVerified == false && !p.isDeleted)
      .toList();

  _isLoading = false;
  _isReloading = false;
  
  print('✅ Approved services: ${_myApprovedServices.length}');
  print('✅ Pending services: ${_myPendingServices.length}');
  
  // Log pending services details
  for (var service in _myPendingServices) {
    print('  - Pending: ${service.companyName} (ID: ${service.id})');
  }
  
  notifyListeners();
}


  // Delete user service
  Future<bool> deleteUserService(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.deleteServiceProvider(id);
      
      // Remove from local lists
      _myApprovedServices.removeWhere((p) => p.id == id);
      _myPendingServices.removeWhere((p) => p.id == id);
      _allProviders.removeWhere((p) => p.id == id);
      _applySearchFilter();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete service: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user service
  Future<bool> updateUserService(String id, ServiceProviderModel provider) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.updateServiceProvider(id, provider);
      
      final updatedProvider = provider.copyWith(id: id);
      
      // Update in local lists
      final approvedIndex = _myApprovedServices.indexWhere((p) => p.id == id);
      if (approvedIndex != -1) {
        _myApprovedServices[approvedIndex] = updatedProvider;
      }
      
      final pendingIndex = _myPendingServices.indexWhere((p) => p.id == id);
      if (pendingIndex != -1) {
        _myPendingServices[pendingIndex] = updatedProvider;
      }
      
      final allIndex = _allProviders.indexWhere((p) => p.id == id);
      if (allIndex != -1) {
        _allProviders[allIndex] = updatedProvider;
        _applySearchFilter();
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update service: $e';
      _isLoading = false;
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
    loadServiceProviders();
    print('🧹 All filters cleared');
  }

  // Clear specific filters
  void clearCategoryFilter() {
    _selectedCategory = null;
    _selectedServiceProvider = null;
    _selectedSubServiceProvider = null;
    loadServiceProviders();
    notifyListeners();
  }

  void clearServiceProviderFilter() {
    _selectedServiceProvider = null;
    _selectedSubServiceProvider = null;
    loadServiceProviders();
    notifyListeners();
  }

  void clearSubServiceProviderFilter() {
    _selectedSubServiceProvider = null;
    loadServiceProviders();
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
    
    final newLikedByUsers = List<String>.from(provider.likedByUsers);
    if (wasLiked) {
      newLikedByUsers.remove(userId);
    } else {
      newLikedByUsers.add(userId);
    }
    final newTotalLikes = newLikedByUsers.length;

    _pendingLikes[providerId] = OptimisticLike(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      newTotalLikes: newTotalLikes,
      newLikedByUsers: newLikedByUsers,
      userId: userId,
    );

    final updatedProvider = provider.copyWith(
      totalLikes: newTotalLikes,
      likedByUsers: newLikedByUsers,
      updatedAt: DateTime.now(),
    );
    
    _allProviders[index] = updatedProvider;
    
    final filteredIndex = _filteredProviders.indexWhere((p) => p.id == providerId);
    if (filteredIndex != -1) {
      _filteredProviders[filteredIndex] = updatedProvider;
    }
    
    if (_selectedProvider?.id == providerId) {
      _selectedProvider = updatedProvider;
      _selectedProviderController.add(updatedProvider);
    }
    
    notifyListeners();
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
      
      // If user is viewing their services, refresh
      if (provider.createdBy.isNotEmpty) {
        await loadUserServices(provider.createdBy);
      }
      
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
        _applySearchFilter();
      }
      
      // Update in user services lists
      final approvedIndex = _myApprovedServices.indexWhere((p) => p.id == id);
      if (approvedIndex != -1) {
        _myApprovedServices[approvedIndex] = provider.copyWith(id: id);
      }
      
      final pendingIndex = _myPendingServices.indexWhere((p) => p.id == id);
      if (pendingIndex != -1) {
        _myPendingServices[pendingIndex] = provider.copyWith(id: id);
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
      _myApprovedServices.removeWhere((p) => p.id == id);
      _myPendingServices.removeWhere((p) => p.id == id);
      _applySearchFilter();
      
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
        _applySearchFilter();
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
        _applySearchFilter();
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
    _myApprovedServices.clear();
    _myPendingServices.clear();
    _isLoading = false;
    _isReloading = false;
    _error = '';
    _pendingLikes.clear();
    _selectedState = null;
    _selectedCity = null;
    _selectedCategory = null;
    _selectedServiceProvider = null;
    _selectedSubServiceProvider = null;
    _searchQuery = '';
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
      onlyVerified: true,
      onlyAvailable: true,
    );
  }

  // Refresh data
  Future<void> refresh() async {
    await loadServiceProviders();
  }

  // Dispose method
  void disposeProvider() {
    _batchUpdateTimer?.cancel();
    _streamSubscription?.cancel();
    _userServicesSubscription?.cancel();
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