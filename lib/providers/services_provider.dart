import 'package:bangla_hub/models/service_provider_model.dart';
import 'package:bangla_hub/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/* class ServicesProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = const Uuid();
  
  Map<String, List<ServiceProviderModel>> _servicesByCategory = {};
  List<ServiceProviderModel> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedCategory;
  
  Map<String, List<ServiceProviderModel>> get servicesByCategory => _servicesByCategory;
  List<ServiceProviderModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategory => _selectedCategory;
  
  List<String> get categories => _servicesByCategory.keys.toList();
  
  ServicesProvider() {
    _loadServices();
  }
  
  Future<void> _loadServices() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Load services for each category
      for (final category in [
        'Accountants & Tax Preparers',
        'Legal Services',
        'Healthcare Needs',
        'Religious',
        'Restaurants & Grocery Stores',
        'Real Estate Agents',
        'Plumbers, Electricians, Mechanics',
      ]) {
        _firestoreService.getServicesByCategory(category).listen((services) {
          _servicesByCategory[category] = services;
          notifyListeners();
        });
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> addServiceProvider({
    required String name,
    required String category,
    required String subCategory,
    required String description,
    required String contactName,
    required String contactPhone,
    required String contactEmail,
    required String location,
    required bool isBengaliSpeaking,
    required List<String> services,
    String? imageUrl,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final service = ServiceProviderModel(
        id: _uuid.v4(),
        name: name,
        category: category,
        subCategory: subCategory,
        description: description,
        contactName: contactName,
        contactPhone: contactPhone,
        contactEmail: contactEmail,
        location: location,
        isBengaliSpeaking: isBengaliSpeaking,
        services: services,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );
      
      await _firestoreService.addServiceProvider(service);
      
      // Add to local cache
      if (_servicesByCategory.containsKey(category)) {
        _servicesByCategory[category]!.insert(0, service);
      } else {
        _servicesByCategory[category] = [service];
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> searchServices(String query) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _firestoreService.searchServices(query).listen((services) {
        _searchResults = services;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  List<ServiceProviderModel> getServicesForCategory(String category) {
    return _servicesByCategory[category] ?? [];
  }
  
  List<ServiceProviderModel> getBengaliSpeakingServices() {
    final allServices = _servicesByCategory.values.expand((x) => x).toList();
    return allServices.where((service) => service.isBengaliSpeaking).toList();
  }
  
  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }
  
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  List<String> getSubCategories(String category) {
    final services = _servicesByCategory[category];
    if (services == null) return [];
    
    final subCategories = services.map((s) => s.subCategory).toSet();
    return subCategories.toList();
  }
}  */