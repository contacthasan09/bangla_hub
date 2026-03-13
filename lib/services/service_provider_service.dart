// services/service_provider_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_services_models.dart';

class ServiceProviderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'service_providers';

  // Add a new service provider
  Future<void> addServiceProvider(ServiceProviderModel provider) async {
    try {
      await _firestore
          .collection(_collectionName)
          .add(provider.toMap());
    } catch (e) {
      throw Exception('Failed to add service provider: $e');
    }
  }

  // Update a service provider
  Future<void> updateServiceProvider(String id, ServiceProviderModel provider) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .update(provider.toMap());
    } catch (e) {
      throw Exception('Failed to update service provider: $e');
    }
  }

  // Delete a service provider (soft delete)
  Future<void> deleteServiceProvider(String id) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .update({
            'isDeleted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to delete service provider: $e');
    }
  }

  // Toggle availability
  Future<void> toggleAvailability(String id, bool isAvailable) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .update({
            'isAvailable': isAvailable,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to toggle availability: $e');
    }
  }

  // Toggle verification
  Future<void> toggleVerification(String id, bool isVerified) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .update({
            'isVerified': isVerified,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to toggle verification: $e');
    }
  }

  // Toggle like for a user
  Future<void> toggleLike(String providerId, String userId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(providerId)
          .get();

      if (!doc.exists) {
        throw Exception('Service provider not found');
      }

      final data = doc.data()!;
      List<String> likedByUsers = List<String>.from(data['likedByUsers'] ?? []);
      
      if (likedByUsers.contains(userId)) {
        likedByUsers.remove(userId);
      } else {
        likedByUsers.add(userId);
      }

      await _firestore
          .collection(_collectionName)
          .doc(providerId)
          .update({
            'totalLikes': likedByUsers.length,
            'likedByUsers': likedByUsers,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  // Get all service providers with filters
  Stream<List<ServiceProviderModel>> getServiceProviders({
    String? state,
    String? city,
    ServiceCategory? category,
    String? serviceProvider,
    String? subServiceProvider,
    String? searchQuery,
    bool includeDeleted = false,
    bool adminView = false,
  }) {
    try {
      print('🔍 Starting getServiceProviders query...');
      
      Query query = _firestore.collection(_collectionName);

      // Apply isDeleted filter for non-admin views
      if (!adminView || !includeDeleted) {
        query = query.where('isDeleted', isEqualTo: false);
      }

      // Apply state filter
      if (state != null && state.isNotEmpty) {
        query = query.where('state', isEqualTo: state);
      }

      // Apply city filter
      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      // Apply category filter
      if (category != null) {
        query = query.where('serviceCategory', isEqualTo: category.stringValue);
      }

      // Apply service provider filter
      if (serviceProvider != null && serviceProvider.isNotEmpty) {
        query = query.where('serviceProvider', isEqualTo: serviceProvider);
      }

      // Apply sub-service provider filter
      if (subServiceProvider != null && subServiceProvider.isNotEmpty) {
        query = query.where('subServiceProvider', isEqualTo: subServiceProvider);
      }

      // Apply search query
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase().trim();
        if (searchLower.isNotEmpty) {
          query = query.where('searchKeywords', arrayContains: searchLower);
        }
      }

      // Order by creation date
      query = query.orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => ServiceProviderModel.fromFirestore(doc))
            .toList();
      }).handleError((error, stackTrace) {
             print('❌ Firestore query error: $error');
        print('❌ Stack trace: $stackTrace');
        throw error;
      });
    } catch (e, stackTrace) {
      print('❌ Exception in getServiceProviders: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get unique cities for a state
  Future<List<String>> getCitiesByState(String state) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('state', isEqualTo: state)
          .where('isDeleted', isEqualTo: false)
          .get();

      final cities = snapshot.docs
          .map((doc) => doc.data()['city'] as String)
          .where((city) => city != null && city.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      return cities;
    } catch (e) {
      throw Exception('Failed to get cities: $e');
    }
  }

  // Get service provider by ID
  Future<ServiceProviderModel?> getServiceProviderById(String id) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();

      if (doc.exists) {
        return ServiceProviderModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get service provider: $e');
    }
  }

  // Get popular service providers (most liked)
  Stream<List<ServiceProviderModel>> getPopularServiceProviders({
    int limit = 10,
    String? state,
    String? city,
  }) {
    Query query = _firestore
        .collection(_collectionName)
        .where('isDeleted', isEqualTo: false)
        .where('isAvailable', isEqualTo: true);

    if (state != null && state.isNotEmpty) {
      query = query.where('state', isEqualTo: state);
    }

    if (city != null && city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }

    query = query.orderBy('totalLikes', descending: true).limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceProviderModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get recent service providers
  Stream<List<ServiceProviderModel>> getRecentServiceProviders({
    int limit = 10,
    String? state,
    String? city,
  }) {
    Query query = _firestore
        .collection(_collectionName)
        .where('isDeleted', isEqualTo: false)
        .where('isAvailable', isEqualTo: true);

    if (state != null && state.isNotEmpty) {
      query = query.where('state', isEqualTo: state);
    }

    if (city != null && city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceProviderModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get service providers by category
  Stream<List<ServiceProviderModel>> getServiceProvidersByCategory(
    ServiceCategory category, {
    String? state,
    String? city,
    int limit = 20,
  }) {
    Query query = _firestore
        .collection(_collectionName)
        .where('serviceCategory', isEqualTo: category.stringValue)
        .where('isDeleted', isEqualTo: false)
        .where('isAvailable', isEqualTo: true);

    if (state != null && state.isNotEmpty) {
      query = query.where('state', isEqualTo: state);
    }

    if (city != null && city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceProviderModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get statistics for admin
  Future<Map<String, int>> getAdminStatistics() async {
    try {
      final totalQuery = await _firestore
          .collection(_collectionName)
          .get();

      final pendingQuery = await _firestore
          .collection(_collectionName)
          .where('isVerified', isEqualTo: false)
          .where('isDeleted', isEqualTo: false)
          .get();

      final availableQuery = await _firestore
          .collection(_collectionName)
          .where('isAvailable', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .get();

      final deletedQuery = await _firestore
          .collection(_collectionName)
          .where('isDeleted', isEqualTo: true)
          .get();

      return {
        'total': totalQuery.size,
        'pending': pendingQuery.size,
        'available': availableQuery.size,
        'deleted': deletedQuery.size,
      };
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }
}