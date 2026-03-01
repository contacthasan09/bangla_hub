import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/education_models.dart';

class EducationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection names
  final String _tutoringCollection = 'tutoring_services';
  final String _admissionsCollection = 'admissions_guidance';
  final String _banglaClassesCollection = 'bangla_classes';
  final String _sportsClubsCollection = 'sports_clubs';

  // ====================== TUTORING SERVICES ======================

  Future<void> addTutoringService(TutoringService service) async {
    try {
      await _firestore
          .collection(_tutoringCollection)
          .add(service.toMap());
    } catch (e) {
      throw Exception('Failed to add tutoring service: $e');
    }
  }

  Future<void> updateTutoringService(String id, TutoringService service) async {
    try {
      await _firestore
          .collection(_tutoringCollection)
          .doc(id)
          .update(service.toMap());
    } catch (e) {
      throw Exception('Failed to update tutoring service: $e');
    }
  }

  Stream<List<TutoringService>> getTutoringServices({
    String? state,
    String? city,
    TutoringSubject? subject,
    EducationLevel? level,
    TeachingMethod? teachingMethod,
    String? searchQuery,
    bool includeDeleted = false,
  }) {
    try {
      Query query = _firestore.collection(_tutoringCollection);

      if (!includeDeleted) {
        query = query.where('isDeleted', isEqualTo: false);
      }

      if (state != null && state.isNotEmpty) {
        query = query.where('state', isEqualTo: state);
      }

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      if (subject != null) {
        query = query.where('subjects', arrayContains: subject.toString());
      }

      if (level != null) {
        query = query.where('levels', arrayContains: level.toString());
      }

      if (teachingMethod != null) {
        query = query.where('teachingMethods', arrayContains: teachingMethod.toString());
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase().trim();
        if (searchLower.isNotEmpty) {
          query = query.where('searchKeywords', arrayContains: searchLower);
        }
      }

      query = query.orderBy('rating', descending: true)
                  .orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => TutoringService.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get tutoring services: $e');
    }
  }

  Future<TutoringService?> getTutoringServiceById(String id) async {
    try {
      final doc = await _firestore
          .collection(_tutoringCollection)
          .doc(id)
          .get();

      if (doc.exists) {
        return TutoringService.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get tutoring service: $e');
    }
  }

  Future<void> toggleTutoringServiceLike(String id, String userId) async {
    try {
      final doc = await _firestore
          .collection(_tutoringCollection)
          .doc(id)
          .get();

      if (!doc.exists) {
        throw Exception('Tutoring service not found');
      }

      final data = doc.data()!;
      List<String> likedByUsers = List<String>.from(data['likedByUsers'] ?? []);
      
      if (likedByUsers.contains(userId)) {
        likedByUsers.remove(userId);
      } else {
        likedByUsers.add(userId);
      }

      await _firestore
          .collection(_tutoringCollection)
          .doc(id)
          .update({
            'totalLikes': likedByUsers.length,
            'likedByUsers': likedByUsers,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  // ====================== ADMISSIONS GUIDANCE ======================

  Future<void> addAdmissionsGuidance(AdmissionsGuidance guidance) async {
    try {
      await _firestore
          .collection(_admissionsCollection)
          .add(guidance.toMap());
    } catch (e) {
      throw Exception('Failed to add admissions guidance: $e');
    }
  }

  Future<void> updateAdmissionsGuidance(String id, AdmissionsGuidance guidance) async {
    try {
      await _firestore
          .collection(_admissionsCollection)
          .doc(id)
          .update(guidance.toMap());
    } catch (e) {
      throw Exception('Failed to update admissions guidance: $e');
    }
  }

  Stream<List<AdmissionsGuidance>> getAdmissionsGuidance({
    String? state,
    String? city,
    String? specialization,
    String? country,
    String? searchQuery,
    bool includeDeleted = false,
  }) {
    try {
      Query query = _firestore.collection(_admissionsCollection);

      if (!includeDeleted) {
        query = query.where('isDeleted', isEqualTo: false);
      }

      if (state != null && state.isNotEmpty) {
        query = query.where('state', isEqualTo: state);
      }

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      if (specialization != null && specialization.isNotEmpty) {
        query = query.where('specializations', arrayContains: specialization);
      }

      if (country != null && country.isNotEmpty) {
        query = query.where('countries', arrayContains: country);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase().trim();
        if (searchLower.isNotEmpty) {
          query = query.where('searchKeywords', arrayContains: searchLower);
        }
      }

      query = query.orderBy('rating', descending: true)
                  .orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => AdmissionsGuidance.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get admissions guidance: $e');
    }
  }

  Future<AdmissionsGuidance?> getAdmissionsGuidanceById(String id) async {
    try {
      final doc = await _firestore
          .collection(_admissionsCollection)
          .doc(id)
          .get();

      if (doc.exists) {
        return AdmissionsGuidance.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get admissions guidance: $e');
    }
  }

  // ====================== BANGLA CLASSES ======================

  Future<void> addBanglaClass(BanglaClass banglaClass) async {
    try {
      await _firestore
          .collection(_banglaClassesCollection)
          .add(banglaClass.toMap());
    } catch (e) {
      throw Exception('Failed to add Bangla class: $e');
    }
  }

  Future<void> updateBanglaClass(String id, BanglaClass banglaClass) async {
    try {
      await _firestore
          .collection(_banglaClassesCollection)
          .doc(id)
          .update(banglaClass.toMap());
    } catch (e) {
      throw Exception('Failed to update Bangla class: $e');
    }
  }

  Stream<List<BanglaClass>> getBanglaClasses({
    String? state,
    String? city,
    String? classType,
    TeachingMethod? teachingMethod,
    String? searchQuery,
    bool includeDeleted = false,
  }) {
    try {
      Query query = _firestore.collection(_banglaClassesCollection);

      if (!includeDeleted) {
        query = query.where('isDeleted', isEqualTo: false);
      }

      if (state != null && state.isNotEmpty) {
        query = query.where('state', isEqualTo: state);
      }

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      if (classType != null && classType.isNotEmpty) {
        query = query.where('classTypes', arrayContains: classType);
      }

      if (teachingMethod != null) {
        query = query.where('teachingMethods', arrayContains: teachingMethod.toString());
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase().trim();
        if (searchLower.isNotEmpty) {
          query = query.where('searchKeywords', arrayContains: searchLower);
        }
      }

      query = query.orderBy('rating', descending: true)
                  .orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => BanglaClass.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get Bangla classes: $e');
    }
  }

  Future<BanglaClass?> getBanglaClassById(String id) async {
    try {
      final doc = await _firestore
          .collection(_banglaClassesCollection)
          .doc(id)
          .get();

      if (doc.exists) {
        return BanglaClass.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get Bangla class: $e');
    }
  }

  Future<void> updateBanglaClassEnrollment(String id, int enrolledStudents) async {
    try {
      await _firestore
          .collection(_banglaClassesCollection)
          .doc(id)
          .update({
            'enrolledStudents': enrolledStudents,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to update enrollment: $e');
    }
  }

  // ====================== SPORTS CLUBS ======================

  Future<void> addSportsClub(SportsClub club) async {
    try {
      await _firestore
          .collection(_sportsClubsCollection)
          .add(club.toMap());
    } catch (e) {
      throw Exception('Failed to add sports club: $e');
    }
  }

  Future<void> updateSportsClub(String id, SportsClub club) async {
    try {
      await _firestore
          .collection(_sportsClubsCollection)
          .doc(id)
          .update(club.toMap());
    } catch (e) {
      throw Exception('Failed to update sports club: $e');
    }
  }

  Stream<List<SportsClub>> getSportsClubs({
    String? state,
    String? city,
    SportsType? sportType,
    String? ageGroup,
    String? searchQuery,
    bool includeDeleted = false,
  }) {
    try {
      Query query = _firestore.collection(_sportsClubsCollection);

      if (!includeDeleted) {
        query = query.where('isDeleted', isEqualTo: false);
      }

      if (state != null && state.isNotEmpty) {
        query = query.where('state', isEqualTo: state);
      }

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      if (sportType != null) {
        query = query.where('sportType', isEqualTo: sportType.toString());
      }

      if (ageGroup != null && ageGroup.isNotEmpty) {
        query = query.where('ageGroups', arrayContains: ageGroup);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase().trim();
        if (searchLower.isNotEmpty) {
          query = query.where('searchKeywords', arrayContains: searchLower);
        }
      }

      query = query.orderBy('rating', descending: true)
                  .orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => SportsClub.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get sports clubs: $e');
    }
  }

  Future<SportsClub?> getSportsClubById(String id) async {
    try {
      final doc = await _firestore
          .collection(_sportsClubsCollection)
          .doc(id)
          .get();

      if (doc.exists) {
        return SportsClub.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get sports club: $e');
    }
  }

  Future<void> updateSportsClubMembership(String id, int currentMembers) async {
    try {
      await _firestore
          .collection(_sportsClubsCollection)
          .doc(id)
          .update({
            'currentMembers': currentMembers,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to update membership: $e');
    }
  }

  Future<void> toggleSportsClubLike(String id, String userId) async {
    try {
      final doc = await _firestore
          .collection(_sportsClubsCollection)
          .doc(id)
          .get();

      if (!doc.exists) {
        throw Exception('Sports club not found');
      }

      final data = doc.data()!;
      List<String> likedByUsers = List<String>.from(data['likedByUsers'] ?? []);
      
      if (likedByUsers.contains(userId)) {
        likedByUsers.remove(userId);
      } else {
        likedByUsers.add(userId);
      }

      await _firestore
          .collection(_sportsClubsCollection)
          .doc(id)
          .update({
            'totalLikes': likedByUsers.length,
            'likedByUsers': likedByUsers,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  // ====================== UNIFIED METHODS ======================

  Future<void> incrementViewCount(EducationCategory category, String id) async {
    try {
      String collection;
      String fieldName;
      
      switch (category) {
        case EducationCategory.tutoringHomework:
          collection = _tutoringCollection;
          fieldName = 'totalViews';
          break;
        case EducationCategory.schoolCollegeAdmissions:
          collection = _admissionsCollection;
          fieldName = 'totalViews';
          break;
        case EducationCategory.banglaLanguageCulture:
          collection = _banglaClassesCollection;
          fieldName = 'totalViews';
          break;
        case EducationCategory.localSports:
          collection = _sportsClubsCollection;
          fieldName = 'totalViews';
          break;
      }

      await _firestore
          .collection(collection)
          .doc(id)
          .update({
            'totalViews': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to increment view count: $e');
    }
  }

  // Get statistics for admin
  Future<Map<String, dynamic>> getAdminStatistics() async {
    try {
      final tutoringSnapshot = await _firestore
          .collection(_tutoringCollection)
          .get();
      final admissionsSnapshot = await _firestore
          .collection(_admissionsCollection)
          .get();
      final banglaSnapshot = await _firestore
          .collection(_banglaClassesCollection)
          .get();
      final sportsSnapshot = await _firestore
          .collection(_sportsClubsCollection)
          .get();

      return {
        'tutoringServices': tutoringSnapshot.size,
        'admissionsGuidance': admissionsSnapshot.size,
        'banglaClasses': banglaSnapshot.size,
        'sportsClubs': sportsSnapshot.size,
        'total': tutoringSnapshot.size + admissionsSnapshot.size + 
                banglaSnapshot.size + sportsSnapshot.size,
      };
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }

  // Get popular items
  Stream<List<TutoringService>> getPopularTutoringServices({int limit = 5}) {
    return _firestore
        .collection(_tutoringCollection)
        .where('isDeleted', isEqualTo: false)
        .where('isActive', isEqualTo: true)
        .orderBy('totalLikes', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TutoringService.fromFirestore(doc))
            .toList());
  }

  Stream<List<SportsClub>> getPopularSportsClubs({int limit = 5}) {
    return _firestore
        .collection(_sportsClubsCollection)
        .where('isDeleted', isEqualTo: false)
        .where('isActive', isEqualTo: true)
        .orderBy('totalLikes', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SportsClub.fromFirestore(doc))
            .toList());
  }

  Stream<List<BanglaClass>> getAvailableBanglaClasses({int limit = 5}) {
    return _firestore
        .collection(_banglaClassesCollection)
        .where('isDeleted', isEqualTo: false)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BanglaClass.fromFirestore(doc))
            .toList());
  }

  // Get items by category
  Stream<List<dynamic>> getItemsByCategory(EducationCategory category, {
    String? state,
    String? city,
    String? searchQuery,
  }) {
    switch (category) {
      case EducationCategory.tutoringHomework:
        return getTutoringServices(
          state: state,
          city: city,
          searchQuery: searchQuery,
        ).map((list) => list as List<dynamic>);
      case EducationCategory.schoolCollegeAdmissions:
        return getAdmissionsGuidance(
          state: state,
          city: city,
          searchQuery: searchQuery,
        ).map((list) => list as List<dynamic>);
      case EducationCategory.banglaLanguageCulture:
        return getBanglaClasses(
          state: state,
          city: city,
          searchQuery: searchQuery,
        ).map((list) => list as List<dynamic>);
      case EducationCategory.localSports:
        return getSportsClubs(
          state: state,
          city: city,
          searchQuery: searchQuery,
        ).map((list) => list as List<dynamic>);
    }
  }
}