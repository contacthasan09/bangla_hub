import 'dart:async';
import 'package:bangla_hub/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/entrepreneurship_models.dart';
import '../services/entrepreneurship_service.dart';

class EntrepreneurshipProvider with ChangeNotifier {
  final EntrepreneurshipService _service = EntrepreneurshipService();

  // State for different categories
  List<NetworkingBusinessPartner> _businessPartners = [];
  List<JobPosting> _jobPostings = [];
  List<SmallBusinessPromotion> _businessPromotions = [];
  List<BusinessPartnerRequest> _partnerRequests = [];

  // Selected items
  NetworkingBusinessPartner? _selectedBusinessPartner;
  JobPosting? _selectedJobPosting;
  SmallBusinessPromotion? _selectedBusinessPromotion;
  BusinessPartnerRequest? _selectedPartnerRequest;

  // Loading and error states
  bool _isLoading = false;
  String _error = '';

  // Add this at the top with other variables
final Map<String, UserModel?> _userCache = {};

// Add getter
Map<String, UserModel?> get userCache => _userCache;

// Add method to get user by ID
UserModel? getUserById(String userId) {
  return _userCache[userId];
}

  // Filter states for each category
  Map<EntrepreneurshipCategory, Map<String, dynamic>> _filters = {
    EntrepreneurshipCategory.networkingBusinessPartner: {},
    EntrepreneurshipCategory.jobPostings: {},
    EntrepreneurshipCategory.smallBusinessPromotion: {},
    EntrepreneurshipCategory.lookingForBusinessPartner: {},
  };

  // Search query for each category
  String _searchQuery = '';

  // Stream subscriptions
  StreamSubscription? _businessPartnersSubscription;
  StreamSubscription? _jobPostingsSubscription;
  StreamSubscription? _businessPromotionsSubscription;
  StreamSubscription? _partnerRequestsSubscription;

  // Stream controllers
  final StreamController<NetworkingBusinessPartner?> _selectedBusinessPartnerController =
      StreamController<NetworkingBusinessPartner?>.broadcast();
  final StreamController<JobPosting?> _selectedJobPostingController =
      StreamController<JobPosting?>.broadcast();
  final StreamController<SmallBusinessPromotion?> _selectedBusinessPromotionController =
      StreamController<SmallBusinessPromotion?>.broadcast();
  final StreamController<BusinessPartnerRequest?> _selectedPartnerRequestController =
      StreamController<BusinessPartnerRequest?>.broadcast();

  // Getters
  List<NetworkingBusinessPartner> get businessPartners => _businessPartners;
  List<JobPosting> get jobPostings => _jobPostings;
  List<SmallBusinessPromotion> get businessPromotions => _businessPromotions;
  List<BusinessPartnerRequest> get partnerRequests => _partnerRequests;

  NetworkingBusinessPartner? get selectedBusinessPartner => _selectedBusinessPartner;
  JobPosting? get selectedJobPosting => _selectedJobPosting;
  SmallBusinessPromotion? get selectedBusinessPromotion => _selectedBusinessPromotion;
  BusinessPartnerRequest? get selectedPartnerRequest => _selectedPartnerRequest;

  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;

  // Stream getters
  Stream<NetworkingBusinessPartner?> get selectedBusinessPartnerStream =>
      _selectedBusinessPartnerController.stream;
  Stream<JobPosting?> get selectedJobPostingStream =>
      _selectedJobPostingController.stream;
  Stream<SmallBusinessPromotion?> get selectedBusinessPromotionStream =>
      _selectedBusinessPromotionController.stream;
  Stream<BusinessPartnerRequest?> get selectedPartnerRequestStream =>
      _selectedPartnerRequestController.stream;

  // Filter getters
  Map<String, dynamic> getFiltersForCategory(EntrepreneurshipCategory category) {
    return _filters[category] ?? {};
  }

  // Setters
  void setSearchQuery(String query) {
    _searchQuery = query;
    loadBusinessPartners(); // Reload with new search query
    notifyListeners();
  }

  void setFilter(EntrepreneurshipCategory category, String key, dynamic value) {
    if (!_filters.containsKey(category)) {
      _filters[category] = {};
    }
    _filters[category]![key] = value;
    
    // Reload data with new filters
    switch (category) {
      case EntrepreneurshipCategory.networkingBusinessPartner:
        loadBusinessPartners();
        break;
      case EntrepreneurshipCategory.jobPostings:
        loadJobPostings();
        break;
      case EntrepreneurshipCategory.smallBusinessPromotion:
        loadBusinessPromotions();
        break;
      case EntrepreneurshipCategory.lookingForBusinessPartner:
        loadPartnerRequests();
        break;
    }
    notifyListeners();
  }

  void clearFilter(EntrepreneurshipCategory category, String key) {
    if (_filters.containsKey(category)) {
      _filters[category]!.remove(key);
    }
    
    // Reload data with updated filters
    switch (category) {
      case EntrepreneurshipCategory.networkingBusinessPartner:
        loadBusinessPartners();
        break;
      case EntrepreneurshipCategory.jobPostings:
        loadJobPostings();
        break;
      case EntrepreneurshipCategory.smallBusinessPromotion:
        loadBusinessPromotions();
        break;
      case EntrepreneurshipCategory.lookingForBusinessPartner:
        loadPartnerRequests();
        break;
    }
    notifyListeners();
  }

  void clearAllFilters(EntrepreneurshipCategory category) {
    _filters[category] = {};
    
    // Reload data without filters
    switch (category) {
      case EntrepreneurshipCategory.networkingBusinessPartner:
        loadBusinessPartners();
        break;
      case EntrepreneurshipCategory.jobPostings:
        loadJobPostings();
        break;
      case EntrepreneurshipCategory.smallBusinessPromotion:
        loadBusinessPromotions();
        break;
      case EntrepreneurshipCategory.lookingForBusinessPartner:
        loadPartnerRequests();
        break;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _businessPartnersSubscription?.cancel();
    _jobPostingsSubscription?.cancel();
    _businessPromotionsSubscription?.cancel();
    _partnerRequestsSubscription?.cancel();
    
    _selectedBusinessPartnerController.close();
    _selectedJobPostingController.close();
    _selectedBusinessPromotionController.close();
    _selectedPartnerRequestController.close();
    super.dispose();
  }

  // ====================== NETWORKING BUSINESS PARTNERS ======================

  Future<void> loadBusinessPartners({bool adminView = false}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    print('📊 EntrepreneurshipProvider: Loading business partners...');
    print('📊 Admin view: $adminView');
    print('📊 Search query: $_searchQuery');

    try {
      // Cancel previous subscription
      await _businessPartnersSubscription?.cancel();

      final filters = getFiltersForCategory(EntrepreneurshipCategory.networkingBusinessPartner);
      print('📊 Filters: $filters');
      
      final stream = _service.getNetworkingBusinessPartners(
        state: filters['state'],
        city: filters['city'],
        industry: filters['industry'],
        businessType: filters['businessType'],
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        includeDeleted: adminView,
      );

      _businessPartnersSubscription = stream.listen(
        (partners) {
          print('📊 Received ${partners.length} partners from stream');
          _businessPartners = partners;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          print('❌ Stream error: $error');
          _error = 'Failed to load business partners: $error';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('❌ Failed to load business partners: $e');
      _error = 'Failed to load business partners: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

/*  Future<void> loadVerifiedBusinessPartners() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    print('📊 Loading verified business partners...');

    try {
      // Cancel previous subscription
      await _businessPartnersSubscription?.cancel();

      final filters = getFiltersForCategory(EntrepreneurshipCategory.networkingBusinessPartner);
      
      final stream = _service.getNetworkingBusinessPartners(
        state: filters['state'],
        city: filters['city'],
        industry: filters['industry'],
        businessType: filters['businessType'],
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        includeDeleted: false,
      );

      _businessPartnersSubscription = stream.listen(
        (partners) {
          // Filter to only show verified and active partners
          _businessPartners = partners
              .where((p) => p.isVerified && p.isActive && !p.isDeleted)
              .toList();
          print('📊 Verified partners: ${_businessPartners.length} out of ${partners.length} total');
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          print('❌ Stream error: $error');
          _error = 'Failed to load business partners: $error';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('❌ Failed to load business partners: $e');
      _error = 'Failed to load business partners: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
*/

// In entrepreneurship_provider.dart, modify loadVerifiedBusinessPartners:

Future<void> loadVerifiedBusinessPartners() async {
  _isLoading = true;
  _error = '';
  notifyListeners();

  try {
    await _businessPartnersSubscription?.cancel();

    final filters = getFiltersForCategory(EntrepreneurshipCategory.networkingBusinessPartner);
    
    final stream = _service.getNetworkingBusinessPartners(
      state: filters['state'],
      city: filters['city'],
      industry: filters['industry'],
      businessType: filters['businessType'],
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      includeDeleted: false,
    );

    _businessPartnersSubscription = stream.listen(
      (partners) {
        // Filter to only show verified and active partners
        _businessPartners = partners
            .where((p) => p.isVerified && p.isActive && !p.isDeleted)
            .toList();
        print('📊 Verified partners: ${_businessPartners.length} out of ${partners.length} total');
        
        // Immediately load all user profiles
        _loadAllUserProfiles(_businessPartners);
        
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        print('❌ Stream error: $error');
        _error = 'Failed to load business partners: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  } catch (e) {
    print('❌ Failed to load business partners: $e');
    _error = 'Failed to load business partners: $e';
    _isLoading = false;
    notifyListeners();
  }
}

// Add this method to provider to load users
Future<void> _loadAllUserProfiles(List<NetworkingBusinessPartner> partners) async {
  final userIds = partners.map((p) => p.createdBy).toSet().toList();
  
  // Create a map to store users (you'll need to add this to provider)
  // Add: final Map<String, UserModel?> _userCache = {};
  
  try {
    // Batch fetch users
    const batchSize = 10;
    for (var i = 0; i < userIds.length; i += batchSize) {
      final end = (i + batchSize < userIds.length) ? i + batchSize : userIds.length;
      final batch = userIds.sublist(i, end);
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      
      for (var doc in querySnapshot.docs) {
        final user = UserModel.fromMap(doc.data(), doc.id);
        _userCache[doc.id] = user;
      }
    }
    notifyListeners();
  } catch (e) {
    print('❌ Error loading users: $e');
  }
}


  Future<void> loadPopularBusinessPartners() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _businessPartnersSubscription?.cancel();
      
      final stream = _service.getPopularBusinessPartners();
      _businessPartnersSubscription = stream.listen((partners) {
        _businessPartners = partners;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to load popular business partners: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<NetworkingBusinessPartner?> getBusinessPartnerById(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final partner = await _service.getNetworkingBusinessPartnerById(id);
      _selectedBusinessPartner = partner;
      _selectedBusinessPartnerController.add(partner);
      _isLoading = false;
      notifyListeners();
      return partner;
    } catch (e) {
      _error = 'Failed to get business partner: $e';
      _selectedBusinessPartnerController.add(null);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> addBusinessPartner(NetworkingBusinessPartner partner) async {
    _isLoading = true;
    notifyListeners();

    print('📤 Adding business partner: ${partner.businessName}');

    try {
      await _service.addNetworkingBusinessPartner(partner);
      print('✅ Business partner added successfully');
      _isLoading = false;
      notifyListeners();
      
      // Reload the list to show the new partner
      await loadBusinessPartners();
      
      return true;
    } catch (e) {
      print('❌ Failed to add business partner: $e');
      _error = 'Failed to add business partner: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBusinessPartner(String id, NetworkingBusinessPartner partner) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.updateNetworkingBusinessPartner(id, partner);
      
      final index = _businessPartners.indexWhere((p) => p.id == id);
      if (index != -1) {
        _businessPartners[index] = partner;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update business partner: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleBusinessPartnerLike(String id, String userId) async {
    try {
      await _service.toggleNetworkingBusinessPartnerLike(id, userId);
      
      final index = _businessPartners.indexWhere((p) => p.id == id);
      if (index != -1) {
        final partner = _businessPartners[index];
        final updatedLikedByUsers = List<String>.from(partner.likedByUsers);
        
        if (updatedLikedByUsers.contains(userId)) {
          updatedLikedByUsers.remove(userId);
        } else {
          updatedLikedByUsers.add(userId);
        }
        
        _businessPartners[index] = NetworkingBusinessPartner(
          id: partner.id,
          businessName: partner.businessName,
          ownerName: partner.ownerName,
          email: partner.email,
          phone: partner.phone,
          address: partner.address,
          state: partner.state,
          city: partner.city,
          businessType: partner.businessType,
          industry: partner.industry,
          description: partner.description,
          website: partner.website,
          licenseNumber: partner.licenseNumber,
          taxId: partner.taxId,
          yearsInBusiness: partner.yearsInBusiness,
          servicesOffered: partner.servicesOffered,
          targetMarkets: partner.targetMarkets,
          logoImageBase64: partner.logoImageBase64,
          galleryImagesBase64: partner.galleryImagesBase64,
          businessHours: partner.businessHours,
          languagesSpoken: partner.languagesSpoken,
          isVerified: partner.isVerified,
          isActive: partner.isActive,
          isDeleted: partner.isDeleted,
          rating: partner.rating,
          totalReviews: partner.totalReviews,
          totalLikes: updatedLikedByUsers.length,
          likedByUsers: updatedLikedByUsers,
          createdBy: partner.createdBy,
          createdAt: partner.createdAt,
          updatedAt: DateTime.now(),
          additionalInfo: partner.additionalInfo,
          certifications: partner.certifications,
          socialMediaLinks: partner.socialMediaLinks,
        );
        
        if (_selectedBusinessPartner?.id == id) {
          _selectedBusinessPartner = _businessPartners[index];
          _selectedBusinessPartnerController.add(_selectedBusinessPartner);
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

  // ====================== JOB POSTINGS ======================

  Future<void> loadJobPostings({bool adminView = false, bool includeExpired = false}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _jobPostingsSubscription?.cancel();
      
      final filters = getFiltersForCategory(EntrepreneurshipCategory.jobPostings);
      final stream = _service.getJobPostings(
        state: filters['state'],
        city: filters['city'],
        jobType: filters['jobType'],
        experienceLevel: filters['experienceLevel'],
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        includeExpired: includeExpired,
        includeDeleted: adminView,
      );

      _jobPostingsSubscription = stream.listen(
        (jobs) {
          _jobPostings = jobs;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _error = 'Failed to load job postings: $error';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Failed to load job postings: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUrgentJobs() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _jobPostingsSubscription?.cancel();
      
      final stream = _service.getUrgentJobs();
      _jobPostingsSubscription = stream.listen((jobs) {
        _jobPostings = jobs;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to load urgent jobs: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<JobPosting?> getJobPostingById(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final job = await _service.getJobPostingById(id);
      _selectedJobPosting = job;
      _selectedJobPostingController.add(job);
      _isLoading = false;
      notifyListeners();
      return job;
    } catch (e) {
      _error = 'Failed to get job posting: $e';
      _selectedJobPostingController.add(null);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> addJobPosting(JobPosting job) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.addJobPosting(job);
      _isLoading = false;
      notifyListeners();
      
      // Reload the list
      await loadJobPostings();
      
      return true;
    } catch (e) {
      _error = 'Failed to add job posting: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateJobPosting(String id, JobPosting job) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.updateJobPosting(id, job);
      
      final index = _jobPostings.indexWhere((j) => j.id == id);
      if (index != -1) {
        _jobPostings[index] = job;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update job posting: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ====================== SMALL BUSINESS PROMOTIONS ======================

  Future<void> loadBusinessPromotions({bool adminView = false}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _businessPromotionsSubscription?.cancel();
      
      final filters = getFiltersForCategory(EntrepreneurshipCategory.smallBusinessPromotion);
      final stream = _service.getBusinessPromotions(
        state: filters['state'],
        city: filters['city'],
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        includeDeleted: adminView,
        featuredOnly: filters['featuredOnly'] ?? false,
      );

      _businessPromotionsSubscription = stream.listen(
        (promotions) {
          _businessPromotions = promotions;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _error = 'Failed to load business promotions: $error';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Failed to load business promotions: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFeaturedPromotions() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _businessPromotionsSubscription?.cancel();
      
      final stream = _service.getFeaturedPromotions();
      _businessPromotionsSubscription = stream.listen((promotions) {
        _businessPromotions = promotions;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to load featured promotions: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SmallBusinessPromotion?> getBusinessPromotionById(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final promotion = await _service.getBusinessPromotionById(id);
      _selectedBusinessPromotion = promotion;
      _selectedBusinessPromotionController.add(promotion);
      _isLoading = false;
      notifyListeners();
      return promotion;
    } catch (e) {
      _error = 'Failed to get business promotion: $e';
      _selectedBusinessPromotionController.add(null);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> addBusinessPromotion(SmallBusinessPromotion promotion) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.addBusinessPromotion(promotion);
      _isLoading = false;
      notifyListeners();
      
      // Reload the list
      await loadBusinessPromotions();
      
      return true;
    } catch (e) {
      _error = 'Failed to add business promotion: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBusinessPromotion(String id, SmallBusinessPromotion promotion) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.updateBusinessPromotion(id, promotion);
      
      final index = _businessPromotions.indexWhere((p) => p.id == id);
      if (index != -1) {
        _businessPromotions[index] = promotion;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update business promotion: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }



  // ====================== BUSINESS PARTNER REQUESTS ======================

  Future<void> loadPartnerRequests({bool adminView = false}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _partnerRequestsSubscription?.cancel();
      
      final filters = getFiltersForCategory(EntrepreneurshipCategory.lookingForBusinessPartner);
      final stream = _service.getBusinessPartnerRequests(
        state: filters['state'],
        city: filters['city'],
        partnerType: filters['partnerType'],
        businessType: filters['businessType'],
        industry: filters['industry'],
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        includeDeleted: adminView,
      );

      _partnerRequestsSubscription = stream.listen(
        (requests) {
          _partnerRequests = requests;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _error = 'Failed to load partner requests: $error';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Failed to load partner requests: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<BusinessPartnerRequest?> getPartnerRequestById(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final request = await _service.getBusinessPartnerRequestById(id);
      _selectedPartnerRequest = request;
      _selectedPartnerRequestController.add(request);
      _isLoading = false;
      notifyListeners();
      return request;
    } catch (e) {
      _error = 'Failed to get partner request: $e';
      _selectedPartnerRequestController.add(null);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> addPartnerRequest(BusinessPartnerRequest request) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.addBusinessPartnerRequest(request);
      _isLoading = false;
      notifyListeners();
      
      // Reload the list
      await loadPartnerRequests();
      
      return true;
    } catch (e) {
      _error = 'Failed to add partner request: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePartnerRequest(String id, BusinessPartnerRequest request) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.updateBusinessPartnerRequest(id, request);
      
      final index = _partnerRequests.indexWhere((r) => r.id == id);
      if (index != -1) {
        _partnerRequests[index] = request;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update partner request: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ====================== UTILITY METHODS ======================

  Future<void> incrementViewCount(EntrepreneurshipCategory category, String id) async {
    try {
      await _service.incrementViewCount(category, id);
    } catch (e) {
      _error = 'Failed to increment view count: $e';
      notifyListeners();
    }
  }

  Future<bool> incrementResponseCount(String id) async {
    try {
      await _service.incrementResponseCount(id);
      
      final index = _partnerRequests.indexWhere((r) => r.id == id);
      if (index != -1) {
        final request = _partnerRequests[index];
        _partnerRequests[index] = BusinessPartnerRequest(
          id: request.id,
          title: request.title,
          description: request.description,
          partnerType: request.partnerType,
          businessType: request.businessType,
          industry: request.industry,
          location: request.location,
          state: request.state,
          city: request.city,
          budgetMin: request.budgetMin,
          budgetMax: request.budgetMax,
          investmentDuration: request.investmentDuration,
          skillsRequired: request.skillsRequired,
          responsibilities: request.responsibilities,
          contactName: request.contactName,
          contactEmail: request.contactEmail,
          contactPhone: request.contactPhone,
          preferredMeetingMethod: request.preferredMeetingMethod,
          additionalDocumentsBase64: request.additionalDocumentsBase64,
          isVerified: request.isVerified,
          isActive: request.isActive,
          isDeleted: request.isDeleted,
          isUrgent: request.isUrgent,
          totalViews: request.totalViews,
          totalResponses: request.totalResponses + 1,
          createdBy: request.createdBy,
          createdAt: request.createdAt,
          updatedAt: DateTime.now(),
          category: request.category,
          tags: request.tags,
          additionalInfo: request.additionalInfo,
        );
        
        if (_selectedPartnerRequest?.id == id) {
          _selectedPartnerRequest = _partnerRequests[index];
          _selectedPartnerRequestController.add(_selectedPartnerRequest);
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to increment response count: $e';
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> getAdminStatistics() async {
    try {
      return await _service.getAdminStatistics();
    } catch (e) {
      _error = 'Failed to get statistics: $e';
      notifyListeners();
      return {
        'networkingPartners': 0,
        'jobPostings': 0,
        'businessPromotions': 0,
        'partnerRequests': 0,
        'total': 0,
      };
    }
  }

  // Clear all data
  void clearAll() {
    _businessPartners.clear();
    _jobPostings.clear();
    _businessPromotions.clear();
    _partnerRequests.clear();
    
    _selectedBusinessPartner = null;
    _selectedJobPosting = null;
    _selectedBusinessPromotion = null;
    _selectedPartnerRequest = null;
    
    _filters.clear();
    _searchQuery = '';
    _error = '';
    
    notifyListeners();
  }

  // Clear specific category data
  void clearCategory(EntrepreneurshipCategory category) {
    switch (category) {
      case EntrepreneurshipCategory.networkingBusinessPartner:
        _businessPartners.clear();
        _selectedBusinessPartner = null;
        _selectedBusinessPartnerController.add(null);
        _businessPartnersSubscription?.cancel();
        break;
      case EntrepreneurshipCategory.jobPostings:
        _jobPostings.clear();
        _selectedJobPosting = null;
        _selectedJobPostingController.add(null);
        _jobPostingsSubscription?.cancel();
        break;
      case EntrepreneurshipCategory.smallBusinessPromotion:
        _businessPromotions.clear();
        _selectedBusinessPromotion = null;
        _selectedBusinessPromotionController.add(null);
        _businessPromotionsSubscription?.cancel();
        break;
      case EntrepreneurshipCategory.lookingForBusinessPartner:
        _partnerRequests.clear();
        _selectedPartnerRequest = null;
        _selectedPartnerRequestController.add(null);
        _partnerRequestsSubscription?.cancel();
        break;
    }
    clearAllFilters(category);
    notifyListeners();
  }

  // Get items by category
  dynamic getItemsByCategory(EntrepreneurshipCategory category) {
    switch (category) {
      case EntrepreneurshipCategory.networkingBusinessPartner:
        return _businessPartners;
      case EntrepreneurshipCategory.jobPostings:
        return _jobPostings;
      case EntrepreneurshipCategory.smallBusinessPromotion:
        return _businessPromotions;
      case EntrepreneurshipCategory.lookingForBusinessPartner:
        return _partnerRequests;
    }
  }

  // Set selected item by category
  void setSelectedItem(EntrepreneurshipCategory category, dynamic item) {
    switch (category) {
      case EntrepreneurshipCategory.networkingBusinessPartner:
        _selectedBusinessPartner = item;
        _selectedBusinessPartnerController.add(item);
        break;
      case EntrepreneurshipCategory.jobPostings:
        _selectedJobPosting = item;
        _selectedJobPostingController.add(item);
        break;
      case EntrepreneurshipCategory.smallBusinessPromotion:
        _selectedBusinessPromotion = item;
        _selectedBusinessPromotionController.add(item);
        break;
      case EntrepreneurshipCategory.lookingForBusinessPartner:
        _selectedPartnerRequest = item;
        _selectedPartnerRequestController.add(item);
        break;
    }
    notifyListeners();
  }

  // Get selected item by category
  dynamic getSelectedItem(EntrepreneurshipCategory category) {
    switch (category) {
      case EntrepreneurshipCategory.networkingBusinessPartner:
        return _selectedBusinessPartner;
      case EntrepreneurshipCategory.jobPostings:
        return _selectedJobPosting;
      case EntrepreneurshipCategory.smallBusinessPromotion:
        return _selectedBusinessPromotion;
      case EntrepreneurshipCategory.lookingForBusinessPartner:
        return _selectedPartnerRequest;
    }
  }
}