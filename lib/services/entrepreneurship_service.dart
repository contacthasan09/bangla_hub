import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/entrepreneurship_models.dart';

class EntrepreneurshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection names
  final String _networkingCollection = 'networking_business_partners';
  final String _jobPostingsCollection = 'job_postings';
  final String _businessPromotionCollection = 'small_business_promotions';
  final String _partnerRequestCollection = 'business_partner_requests';

  // ====================== NETWORKING BUSINESS PARTNERS ======================

  Future<void> addNetworkingBusinessPartner(NetworkingBusinessPartner partner) async {
    try {
      await _firestore
          .collection(_networkingCollection)
          .add(partner.toMap());
    } catch (e) {
      throw Exception('Failed to add business partner: $e');
    }
  }

  Future<void> updateNetworkingBusinessPartner(String id, NetworkingBusinessPartner partner) async {
    try {
      await _firestore
          .collection(_networkingCollection)
          .doc(id)
          .update(partner.toMap());
    } catch (e) {
      throw Exception('Failed to update business partner: $e');
    }
  }

  Stream<List<NetworkingBusinessPartner>> getNetworkingBusinessPartners({
    String? state,
    String? city,
    String? industry,
    BusinessType? businessType,
    String? searchQuery,
    bool includeDeleted = false,
  }) {
    try {
      Query query = _firestore.collection(_networkingCollection);

      if (!includeDeleted) {
        query = query.where('isDeleted', isEqualTo: false);
      }

      if (state != null && state.isNotEmpty) {
        query = query.where('state', isEqualTo: state);
      }

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      if (industry != null && industry.isNotEmpty) {
        query = query.where('industry', isEqualTo: industry);
      }

      if (businessType != null) {
        query = query.where('businessType', isEqualTo: businessType.toString());
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase().trim();
        if (searchLower.isNotEmpty) {
          query = query.where('searchKeywords', arrayContains: searchLower);
        }
      }

      query = query.orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => NetworkingBusinessPartner.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get business partners: $e');
    }
  }

  Future<NetworkingBusinessPartner?> getNetworkingBusinessPartnerById(String id) async {
    try {
      final doc = await _firestore
          .collection(_networkingCollection)
          .doc(id)
          .get();

      if (doc.exists) {
        return NetworkingBusinessPartner.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get business partner: $e');
    }
  }

  Future<void> toggleNetworkingBusinessPartnerLike(String id, String userId) async {
    try {
      final doc = await _firestore
          .collection(_networkingCollection)
          .doc(id)
          .get();

      if (!doc.exists) {
        throw Exception('Business partner not found');
      }

      final data = doc.data()!;
      List<String> likedByUsers = List<String>.from(data['likedByUsers'] ?? []);
      
      if (likedByUsers.contains(userId)) {
        likedByUsers.remove(userId);
      } else {
        likedByUsers.add(userId);
      }

      await _firestore
          .collection(_networkingCollection)
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

  // ====================== JOB POSTINGS ======================

  Future<void> addJobPosting(JobPosting job) async {
    try {
      await _firestore
          .collection(_jobPostingsCollection)
          .add(job.toMap());
    } catch (e) {
      throw Exception('Failed to add job posting: $e');
    }
  }

  Future<void> updateJobPosting(String id, JobPosting job) async {
    try {
      await _firestore
          .collection(_jobPostingsCollection)
          .doc(id)
          .update(job.toMap());
    } catch (e) {
      throw Exception('Failed to update job posting: $e');
    }
  }

  Stream<List<JobPosting>> getJobPostings({
    String? state,
    String? city,
    JobType? jobType,
    ExperienceLevel? experienceLevel,
    String? searchQuery,
    bool includeExpired = false,
    bool includeDeleted = false,
  }) {
    try {
      Query query = _firestore.collection(_jobPostingsCollection);

      if (!includeDeleted) {
        query = query.where('isDeleted', isEqualTo: false);
      }

      if (!includeExpired) {
        query = query.where('isActive', isEqualTo: true);
      }

      if (state != null && state.isNotEmpty) {
        query = query.where('state', isEqualTo: state);
      }

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      if (jobType != null) {
        query = query.where('jobType', isEqualTo: jobType.toString());
      }

      if (experienceLevel != null) {
        query = query.where('experienceLevel', isEqualTo: experienceLevel.toString());
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase().trim();
        if (searchLower.isNotEmpty) {
          query = query.where('searchKeywords', arrayContains: searchLower);
        }
      }

      query = query.orderBy('isUrgent', descending: true)
                  .orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => JobPosting.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get job postings: $e');
    }
  }

  Future<JobPosting?> getJobPostingById(String id) async {
    try {
      final doc = await _firestore
          .collection(_jobPostingsCollection)
          .doc(id)
          .get();

      if (doc.exists) {
        return JobPosting.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get job posting: $e');
    }
  }

  // ====================== SMALL BUSINESS PROMOTIONS ======================

  Future<void> addBusinessPromotion(SmallBusinessPromotion promotion) async {
    try {
      await _firestore
          .collection(_businessPromotionCollection)
          .add(promotion.toMap());
    } catch (e) {
      throw Exception('Failed to add business promotion: $e');
    }
  }

  Future<void> updateBusinessPromotion(String id, SmallBusinessPromotion promotion) async {
    try {
      await _firestore
          .collection(_businessPromotionCollection)
          .doc(id)
          .update(promotion.toMap());
    } catch (e) {
      throw Exception('Failed to update business promotion: $e');
    }
  }

  Stream<List<SmallBusinessPromotion>> getBusinessPromotions({
    String? state,
    String? city,
    String? searchQuery,
    bool includeDeleted = false,
    bool featuredOnly = false,
  }) {
    try {
      Query query = _firestore.collection(_businessPromotionCollection);

      if (!includeDeleted) {
        query = query.where('isDeleted', isEqualTo: false);
      }

      if (state != null && state.isNotEmpty) {
        query = query.where('state', isEqualTo: state);
      }

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      if (featuredOnly) {
        query = query.where('isFeatured', isEqualTo: true);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase().trim();
        if (searchLower.isNotEmpty) {
          query = query.where('searchKeywords', arrayContains: searchLower);
        }
      }

      query = query.orderBy('isFeatured', descending: true)
                  .orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => SmallBusinessPromotion.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get business promotions: $e');
    }
  }

  Future<SmallBusinessPromotion?> getBusinessPromotionById(String id) async {
    try {
      final doc = await _firestore
          .collection(_businessPromotionCollection)
          .doc(id)
          .get();

      if (doc.exists) {
        return SmallBusinessPromotion.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get business promotion: $e');
    }
  }

  // ====================== BUSINESS PARTNER REQUESTS ======================

  Future<void> addBusinessPartnerRequest(BusinessPartnerRequest request) async {
    try {
      await _firestore
          .collection(_partnerRequestCollection)
          .add(request.toMap());
    } catch (e) {
      throw Exception('Failed to add business partner request: $e');
    }
  }

  Future<void> updateBusinessPartnerRequest(String id, BusinessPartnerRequest request) async {
    try {
      await _firestore
          .collection(_partnerRequestCollection)
          .doc(id)
          .update(request.toMap());
    } catch (e) {
      throw Exception('Failed to update business partner request: $e');
    }
  }

  Stream<List<BusinessPartnerRequest>> getBusinessPartnerRequests({
    String? state,
    String? city,
    PartnerType? partnerType,
    BusinessType? businessType,
    String? industry,
    String? searchQuery,
    bool includeDeleted = false,
  }) {
    try {
      Query query = _firestore.collection(_partnerRequestCollection);

      if (!includeDeleted) {
        query = query.where('isDeleted', isEqualTo: false);
      }

      if (state != null && state.isNotEmpty) {
        query = query.where('state', isEqualTo: state);
      }

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      if (partnerType != null) {
        query = query.where('partnerType', isEqualTo: partnerType.toString());
      }

      if (businessType != null) {
        query = query.where('businessType', isEqualTo: businessType.toString());
      }

      if (industry != null && industry.isNotEmpty) {
        query = query.where('industry', isEqualTo: industry);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase().trim();
        if (searchLower.isNotEmpty) {
          query = query.where('searchKeywords', arrayContains: searchLower);
        }
      }

      query = query.orderBy('isUrgent', descending: true)
                  .orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => BusinessPartnerRequest.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get business partner requests: $e');
    }
  }

  Future<BusinessPartnerRequest?> getBusinessPartnerRequestById(String id) async {
    try {
      final doc = await _firestore
          .collection(_partnerRequestCollection)
          .doc(id)
          .get();

      if (doc.exists) {
        return BusinessPartnerRequest.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get business partner request: $e');
    }
  }

  // ====================== UNIFIED METHODS ======================

  Future<void> incrementViewCount(EntrepreneurshipCategory category, String id) async {
    try {
      String collection;
      String fieldName;
      
      switch (category) {
        case EntrepreneurshipCategory.networkingBusinessPartner:
          collection = _networkingCollection;
          fieldName = 'totalViews';
          break;
        case EntrepreneurshipCategory.smallBusinessPromotion:
          collection = _businessPromotionCollection;
          fieldName = 'totalViews';
          break;
        case EntrepreneurshipCategory.lookingForBusinessPartner:
          collection = _partnerRequestCollection;
          fieldName = 'totalViews';
          break;
        case EntrepreneurshipCategory.jobPostings:
          collection = _jobPostingsCollection;
          fieldName = 'totalViews';
          break;
      }

      await _firestore
          .collection(collection)
          .doc(id)
          .update({
            fieldName: FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to increment view count: $e');
    }
  }

  Future<void> incrementResponseCount(String id) async {
    try {
      await _firestore
          .collection(_partnerRequestCollection)
          .doc(id)
          .update({
            'totalResponses': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to increment response count: $e');
    }
  }

  // Get statistics for admin
  Future<Map<String, dynamic>> getAdminStatistics() async {
    try {
      final networkingSnapshot = await _firestore
          .collection(_networkingCollection)
          .get();
      final jobsSnapshot = await _firestore
          .collection(_jobPostingsCollection)
          .get();
      final promotionSnapshot = await _firestore
          .collection(_businessPromotionCollection)
          .get();
      final partnerSnapshot = await _firestore
          .collection(_partnerRequestCollection)
          .get();

      return {
        'networkingPartners': networkingSnapshot.size,
        'jobPostings': jobsSnapshot.size,
        'businessPromotions': promotionSnapshot.size,
        'partnerRequests': partnerSnapshot.size,
        'total': networkingSnapshot.size + jobsSnapshot.size + 
                promotionSnapshot.size + partnerSnapshot.size,
      };
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }

  // Get popular items
  Stream<List<NetworkingBusinessPartner>> getPopularBusinessPartners({int limit = 5}) {
    return _firestore
        .collection(_networkingCollection)
        .where('isDeleted', isEqualTo: false)
        .where('isActive', isEqualTo: true)
        .orderBy('totalLikes', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NetworkingBusinessPartner.fromFirestore(doc))
            .toList());
  }

  Stream<List<JobPosting>> getUrgentJobs({int limit = 5}) {
    return _firestore
        .collection(_jobPostingsCollection)
        .where('isDeleted', isEqualTo: false)
        .where('isActive', isEqualTo: true)
        .where('isUrgent', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobPosting.fromFirestore(doc))
            .toList());
  }

  Stream<List<SmallBusinessPromotion>> getFeaturedPromotions({int limit = 5}) {
    return _firestore
        .collection(_businessPromotionCollection)
        .where('isDeleted', isEqualTo: false)
        .where('isActive', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SmallBusinessPromotion.fromFirestore(doc))
            .toList());
  }
}