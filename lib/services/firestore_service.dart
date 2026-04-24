import 'package:bangla_hub/constants/app_constants.dart';
import 'package:bangla_hub/models/business_model.dart';
import 'package:bangla_hub/models/event_model.dart';
import 'package:bangla_hub/models/job_posting_model.dart';
import 'package:bangla_hub/models/service_provider_model.dart';
import 'package:bangla_hub/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Operations
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .set(user.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error creating user: $e');
      }
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      print('📤 Updating user in Firestore: ${user.id}');
      print('📤 Profile image exists: ${user.profileImageUrl != null}');
      print('📤 Profile image length: ${user.profileImageUrl?.length ?? 0}');
      
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .update(user.toMap());
      
      print('✅ User updated successfully in Firestore');
    } catch (e) {
      print('❌ Error updating user: $e');
      if (kDebugMode) {
        print('Error updating user: $e');
      }
      rethrow;
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      print('📥 Getting user from Firestore: $userId');
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      
      if (doc.exists) {
        print('✅ User found in Firestore');
        return UserModel.fromMap(doc.data()!, userId);
      }
      print('❌ User not found');
      return null;
    } catch (e) {
      print('❌ Error getting user: $e');
      return null;
    }
  }

  Future<List<UserModel>> getUsersBatch(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    
    try {
      final List<UserModel> users = [];
      
      for (int i = 0; i < userIds.length; i += 30) {
        final end = (i + 30) < userIds.length ? i + 30 : userIds.length;
        final batch = userIds.sublist(i, end);
        
        final querySnapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        for (var doc in querySnapshot.docs) {
          users.add(UserModel.fromMap(doc.data(), doc.id));
        }
      }
      
      return users;
    } catch (e) {
      print('Error batch getting users: $e');
      return [];
    }
  }



  // Event Operations
  Future<void> createEvent(EventModel event) async {
    try {
      print('📝 Creating event in Firestore: ${event.title}');
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(event.id)
          .set(event.toMap());
      print('✅ Event created in Firestore with ID: ${event.id}');
    } catch (e) {
      if (kDebugMode) {
        print('Error creating event: $e');
      }
      rethrow;
    }
  }

  Future<void> updateEvent(EventModel event) async {
    try {
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(event.id)
          .update(event.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error updating event: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting event: $e');
      }
      rethrow;
    }
  }

  Future<void> updateEventStatus(String eventId, String status) async {
    try {
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating event status: $e');
      }
      rethrow;
    }
  }

  Stream<List<EventModel>> getUpcomingEvents({
    String? category,
    String? stateFilter,
  }) {
    print('🔍 getUpcomingEvents called with category: $category, stateFilter: $stateFilter');
    
    var query = _firestore
        .collection(AppConstants.eventsCollection)
        .where('status', isEqualTo: 'approved')
              .where('isDeleted', isEqualTo: false)  // ✅ Add this filter

        .where('eventDate', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('eventDate');

    if (category != null && category.isNotEmpty && category != 'all') {
      query = query.where('category', isEqualTo: category);
      print('📍 Applied category filter: $category');
    }

    if (stateFilter != null && stateFilter.isNotEmpty) {
      query = query.where('state', isEqualTo: stateFilter);
      print('📍 Applied state filter: $stateFilter');
    }

    return query.snapshots().map((snapshot) {
      print('📊 Found ${snapshot.docs.length} upcoming events');
      if (snapshot.docs.isNotEmpty) {
        snapshot.docs.take(3).forEach((doc) {
          final data = doc.data();
          print('  - Event: ${data['title']}, State: ${data['state']}');
        });
      }
      return snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<EventModel>> getPastEvents({
    String? category,
    String? stateFilter,
  }) {
    print('🔍 getPastEvents called with category: $category, stateFilter: $stateFilter');
    
    var query = _firestore
        .collection(AppConstants.eventsCollection)
        .where('status', isEqualTo: 'approved')
        .where('isDeleted', isEqualTo: false)
        .where('eventDate', isLessThan: Timestamp.now())
        .orderBy('eventDate', descending: true);

    if (category != null && category.isNotEmpty && category != 'all') {
      query = query.where('category', isEqualTo: category);
      print('📍 Applied category filter: $category');
    }

    if (stateFilter != null && stateFilter.isNotEmpty) {
      query = query.where('state', isEqualTo: stateFilter);
      print('📍 Applied state filter: $stateFilter');
    }

    return query.snapshots().map((snapshot) {
      print('📊 Found ${snapshot.docs.length} past events');
      return snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<EventModel>> getPendingEvents() {
    return _firestore
        .collection(AppConstants.eventsCollection)
        .where('status', isEqualTo: 'pending')
              .where('isDeleted', isEqualTo: false)  // ✅ Add this filter

        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromMap(doc.data(), doc.id))
            .toList());
  }

// In firestore_service.dart, verify getUserEvents method:

Stream<List<EventModel>> getUserEvents(String userId) {
  return _firestore
      .collection(AppConstants.eventsCollection)
      .where('createdBy', isEqualTo: userId)  // ✅ This ensures only user's events
            .where('isDeleted', isEqualTo: false)  // ✅ Add this filter

      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        print('📊 Firestore returned ${snapshot.docs.length} events for user $userId');
        return snapshot.docs
            .map((doc) => EventModel.fromMap(doc.data(), doc.id))
            .toList();
      });
}

  Stream<List<EventModel>> searchEvents(String query, {
    String? category,
    String? stateFilter,
  }) {
    if (query.length < 2) {
      return Stream.value([]);
    }

    var collection = _firestore
        .collection(AppConstants.eventsCollection)
        .where('status', isEqualTo: 'approved')
        .where('eventDate', isGreaterThanOrEqualTo: Timestamp.now());

    if (category != null && category.isNotEmpty && category != 'all') {
      collection = collection.where('category', isEqualTo: category);
    }

    if (stateFilter != null && stateFilter.isNotEmpty) {
      collection = collection.where('state', isEqualTo: stateFilter);
    }

    return collection.snapshots().map((snapshot) {
      final queryLower = query.toLowerCase();
      return snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .where((event) =>
              event.title.toLowerCase().contains(queryLower) ||
              event.organizer.toLowerCase().contains(queryLower) ||
              event.location.toLowerCase().contains(queryLower))
          .toList();
    });
  }

  Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .get();
      
      if (doc.exists) {
        return EventModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting event: $e');
      }
      return null;
    }
  }


  // In FirestoreService class, make sure you have this method:



  // Interested Users Operations
  Future<void> addInterestedUser(String eventId, String userId) async {
    try {
      final batch = _firestore.batch();
      
      final eventInterestedRef = _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .collection('interested_users')
          .doc(userId);
      
      batch.set(eventInterestedRef, {
        'userId': userId,
        'interestedAt': FieldValue.serverTimestamp(),
      });
      
      final eventRef = _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId);
      
      batch.update(eventRef, {
        'totalInterested': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final userInterestedRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('interested_events')
          .doc(eventId);
      
      batch.set(userInterestedRef, {
        'eventId': eventId,
        'interestedAt': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error adding interested user: $e');
      }
      rethrow;
    }
  }

  Future<void> removeInterestedUser(String eventId, String userId) async {
    try {
      final batch = _firestore.batch();
      
      final eventInterestedRef = _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .collection('interested_users')
          .doc(userId);
      
      batch.delete(eventInterestedRef);
      
      final eventRef = _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId);
      
      batch.update(eventRef, {
        'totalInterested': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final userInterestedRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('interested_events')
          .doc(eventId);
      
      batch.delete(userInterestedRef);
      
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error removing interested user: $e');
      }
      rethrow;
    }
  }

  Future<bool> isUserInterested(String eventId, String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .collection('interested_users')
          .doc(userId)
          .get();
      
      return doc.exists;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if user is interested: $e');
      }
      return false;
    }
  }

  Stream<List<String>> getInterestedUsers(String eventId) {
    return _firestore
        .collection(AppConstants.eventsCollection)
        .doc(eventId)
        .collection('interested_users')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()['userId'] as String)
            .toList());
  }

  Stream<List<String>> getUserInterestedEvents(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection('interested_events')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()['eventId'] as String)
            .toList());
  }

  // Business Partner Operations
  Future<void> createBusinessPartnerRequest(BusinessPartnerRequest request) async {
    try {
      await _firestore
          .collection(AppConstants.businessPartnersCollection)
          .doc(request.id)
          .set(request.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error creating business partner request: $e');
      }
      rethrow;
    }
  }

  Stream<List<BusinessPartnerRequest>> getBusinessPartnerRequests() {
    return _firestore
        .collection(AppConstants.businessPartnersCollection)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BusinessPartnerRequest.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Business Operations
  Future<void> createBusiness(BusinessModel business) async {
    try {
      await _firestore
          .collection(AppConstants.businessesCollection)
          .doc(business.id)
          .set(business.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error creating business: $e');
      }
      rethrow;
    }
  }

  Stream<List<BusinessModel>> getBusinesses() {
    return _firestore
        .collection(AppConstants.businessesCollection)
        .where('isVerified', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BusinessModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}