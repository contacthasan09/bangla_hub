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

  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user: $e');
      }
      return null;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .update(user.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user: $e');
      }
      rethrow;
    }
  }

  // Event Operations
  Future<void> createEvent(EventModel event) async {
    try {
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(event.id)
          .set(event.toMap());
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

  // Get events with filtering
  Stream<List<EventModel>> getUpcomingEvents({String? category}) {
    var query = _firestore
        .collection(AppConstants.eventsCollection)
        .where('status', isEqualTo: 'approved')
        .where('eventDate', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('eventDate');

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => EventModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  Stream<List<EventModel>> getPastEvents({String? category}) {
    var query = _firestore
        .collection(AppConstants.eventsCollection)
        .where('status', isEqualTo: 'approved')
        .where('eventDate', isLessThan: Timestamp.now())
        .orderBy('eventDate', descending: true);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => EventModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  Stream<List<EventModel>> getPendingEvents() {
    return _firestore
        .collection(AppConstants.eventsCollection)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<EventModel>> getUserEvents(String userId) {
    return _firestore
        .collection(AppConstants.eventsCollection)
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Search events with minimum 2 characters requirement
  Stream<List<EventModel>> searchEvents(String query, {String? category}) {
    if (query.length < 2) {
      return Stream.value([]); // Return empty if less than 2 characters
    }

    var collection = _firestore.collection(AppConstants.eventsCollection)
        .where('status', isEqualTo: 'approved')
        .where('eventDate', isGreaterThanOrEqualTo: Timestamp.now());

    if (category != null && category.isNotEmpty) {
      collection = collection.where('category', isEqualTo: category);
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

  // Get event by ID
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

  // Add these methods to your FirestoreService class

// Interested Users Operations
Future<void> addInterestedUser(String eventId, String userId) async {
  try {
    final batch = _firestore.batch();
    
    // Add user to event's interested subcollection
    final eventInterestedRef = _firestore
        .collection(AppConstants.eventsCollection)
        .doc(eventId)
        .collection('interested_users')
        .doc(userId);
    
    batch.set(eventInterestedRef, {
      'userId': userId,
      'interestedAt': FieldValue.serverTimestamp(),
    });
    
    // Increment totalInterested count in event document
    final eventRef = _firestore
        .collection(AppConstants.eventsCollection)
        .doc(eventId);
    
    batch.update(eventRef, {
      'totalInterested': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Add event to user's interested events subcollection
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
    
    // Remove user from event's interested subcollection
    final eventInterestedRef = _firestore
        .collection(AppConstants.eventsCollection)
        .doc(eventId)
        .collection('interested_users')
        .doc(userId);
    
    batch.delete(eventInterestedRef);
    
    // Decrement totalInterested count in event document
    final eventRef = _firestore
        .collection(AppConstants.eventsCollection)
        .doc(eventId);
    
    batch.update(eventRef, {
      'totalInterested': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Remove event from user's interested events subcollection
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

  // Community Services Operations
/*  Stream<List<ServiceProviderModel>> getServicesByCategory(String category) { 
    return _firestore
        .collection(AppConstants.servicesCollection)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceProviderModel.fromMap(doc.data(), doc.id))
            .toList());
  }  */

/*  Future<void> addServiceProvider(ServiceProviderModel service) async {
    try {
      await _firestore
          .collection(AppConstants.servicesCollection)
          .doc(service.id)
          .set(service.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error adding service: $e');
      }
      rethrow;
    }
  }  */

  // Job Operations
/*  Future<void> createJobPosting(JobPostingModel job) async {
    try {
      await _firestore
          .collection(AppConstants.jobsCollection)
          .doc(job.id)
          .set(job.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error creating job: $e');
      }
      rethrow;
    }
  }

  Stream<List<JobPostingModel>> getJobPostings() {
    return _firestore
        .collection(AppConstants.jobsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobPostingModel.fromMap(doc.data(), doc.id))
            .toList());
  }  */

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

  // Search Operations
/*  Stream<List<ServiceProviderModel>> searchServices(String query) {
    return _firestore
        .collection(AppConstants.servicesCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceProviderModel.fromMap(doc.data(), doc.id))
            .where((service) =>
                service.name.toLowerCase().contains(query.toLowerCase()) ||
                service.description.toLowerCase().contains(query.toLowerCase()) ||
                service.category.toLowerCase().contains(query.toLowerCase()))
            .toList());
  }   */
}