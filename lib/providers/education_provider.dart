import 'dart:async';
import 'package:flutter/material.dart';
import '../models/education_models.dart';
import '../services/education_service.dart';

class EducationProvider with ChangeNotifier {
  final EducationService _service = EducationService();

  // State for different categories
  List<TutoringService> _tutoringServices = [];
  List<AdmissionsGuidance> _admissionsGuidance = [];
  List<BanglaClass> _banglaClasses = [];
  List<SportsClub> _sportsClubs = [];

  // Selected items
  TutoringService? _selectedTutoringService;
  AdmissionsGuidance? _selectedAdmissionsGuidance;
  BanglaClass? _selectedBanglaClass;
  SportsClub? _selectedSportsClub;

  // Loading and error states
  bool _isLoading = false;
  String _error = '';

  // Filter states for each category
  Map<EducationCategory, Map<String, dynamic>> _filters = {
    EducationCategory.tutoringHomework: {},
    EducationCategory.schoolCollegeAdmissions: {},
    EducationCategory.banglaLanguageCulture: {},
    EducationCategory.localSports: {},
  };

  // Search query for each category
  String _searchQuery = '';

  // Stream controllers
  final StreamController<TutoringService?> _selectedTutoringController =
      StreamController<TutoringService?>.broadcast();
  final StreamController<AdmissionsGuidance?> _selectedAdmissionsController =
      StreamController<AdmissionsGuidance?>.broadcast();
  final StreamController<BanglaClass?> _selectedBanglaClassController =
      StreamController<BanglaClass?>.broadcast();
  final StreamController<SportsClub?> _selectedSportsClubController =
      StreamController<SportsClub?>.broadcast();

  // Getters
  List<TutoringService> get tutoringServices => _tutoringServices;
  List<AdmissionsGuidance> get admissionsGuidance => _admissionsGuidance;
  List<BanglaClass> get banglaClasses => _banglaClasses;
  List<SportsClub> get sportsClubs => _sportsClubs;

  TutoringService? get selectedTutoringService => _selectedTutoringService;
  AdmissionsGuidance? get selectedAdmissionsGuidance => _selectedAdmissionsGuidance;
  BanglaClass? get selectedBanglaClass => _selectedBanglaClass;
  SportsClub? get selectedSportsClub => _selectedSportsClub;

  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;

  // Stream getters
  Stream<TutoringService?> get selectedTutoringStream =>
      _selectedTutoringController.stream;
  Stream<AdmissionsGuidance?> get selectedAdmissionsStream =>
      _selectedAdmissionsController.stream;
  Stream<BanglaClass?> get selectedBanglaClassStream =>
      _selectedBanglaClassController.stream;
  Stream<SportsClub?> get selectedSportsClubStream =>
      _selectedSportsClubController.stream;

  // Filter getters
  Map<String, dynamic> getFiltersForCategory(EducationCategory category) {
    return _filters[category] ?? {};
  }

  // Setters
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(EducationCategory category, String key, dynamic value) {
    if (!_filters.containsKey(category)) {
      _filters[category] = {};
    }
    _filters[category]![key] = value;
    notifyListeners();
  }

  void clearFilter(EducationCategory category, String key) {
    if (_filters.containsKey(category)) {
      _filters[category]!.remove(key);
    }
    notifyListeners();
  }

  void clearAllFilters(EducationCategory category) {
    _filters[category] = {};
    notifyListeners();
  }

  // ====================== TUTORING SERVICES ======================

  Future<void> loadTutoringServices({bool adminView = false}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final filters = getFiltersForCategory(EducationCategory.tutoringHomework);
      final stream = _service.getTutoringServices(
        state: filters['state'],
        city: filters['city'],
        subject: filters['subject'],
        level: filters['level'],
        teachingMethod: filters['teachingMethod'],
        searchQuery: _searchQuery,
        includeDeleted: adminView,
      );

      stream.listen((services) {
        _tutoringServices = services;
        _isLoading = false;
        notifyListeners();
      }, onError: (error) {
        _error = 'Failed to load tutoring services: $error';
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to load tutoring services: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPopularTutoringServices() async {
    _isLoading = true;
    notifyListeners();

    try {
      final stream = _service.getPopularTutoringServices();
      stream.listen((services) {
        _tutoringServices = services;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to load popular tutoring services: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TutoringService?> getTutoringServiceById(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final service = await _service.getTutoringServiceById(id);
      _selectedTutoringService = service;
      _selectedTutoringController.add(service);
      _isLoading = false;
      notifyListeners();
      return service;
    } catch (e) {
      _error = 'Failed to get tutoring service: $e';
      _selectedTutoringController.add(null);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> addTutoringService(TutoringService service) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.addTutoringService(service);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add tutoring service: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTutoringService(String id, TutoringService service) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.updateTutoringService(id, service);
      
      final index = _tutoringServices.indexWhere((s) => s.id == id);
      if (index != -1) {
        _tutoringServices[index] = service;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update tutoring service: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleTutoringServiceLike(String id, String userId) async {
    try {
      await _service.toggleTutoringServiceLike(id, userId);
      
      final index = _tutoringServices.indexWhere((s) => s.id == id);
      if (index != -1) {
        final service = _tutoringServices[index];
        final updatedLikedByUsers = List<String>.from(service.likedByUsers);
        
        if (updatedLikedByUsers.contains(userId)) {
          updatedLikedByUsers.remove(userId);
        } else {
          updatedLikedByUsers.add(userId);
        }
        
        _tutoringServices[index] = TutoringService(
          id: service.id,
          category: service.category,
          tutorName: service.tutorName,
          organizationName: service.organizationName,
          email: service.email,
          phone: service.phone,
          address: service.address,
          state: service.state,
          city: service.city,
          subjects: service.subjects,
          levels: service.levels,
          teachingMethods: service.teachingMethods,
          description: service.description,
          hourlyRate: service.hourlyRate,
          experience: service.experience,
          qualifications: service.qualifications,
          profileImageBase64: service.profileImageBase64,
          galleryImagesBase64: service.galleryImagesBase64,
          availableDays: service.availableDays,
          availableTimes: service.availableTimes,
          languagesSpoken: service.languagesSpoken,
          isVerified: service.isVerified,
          isActive: service.isActive,
          isDeleted: service.isDeleted,
          rating: service.rating,
          totalReviews: service.totalReviews,
          totalLikes: updatedLikedByUsers.length,
          likedByUsers: updatedLikedByUsers,
          createdBy: service.createdBy,
          createdAt: service.createdAt,
          updatedAt: DateTime.now(),
          additionalInfo: service.additionalInfo,
          certifications: service.certifications,
          website: service.website,
          socialMediaLinks: service.socialMediaLinks,
          serviceAreas: service.serviceAreas,
        );
        
        if (_selectedTutoringService?.id == id) {
          _selectedTutoringService = _tutoringServices[index];
          _selectedTutoringController.add(_selectedTutoringService);
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

  // ====================== ADMISSIONS GUIDANCE ======================

  Future<void> loadAdmissionsGuidance({bool adminView = false}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final filters = getFiltersForCategory(EducationCategory.schoolCollegeAdmissions);
      final stream = _service.getAdmissionsGuidance(
        state: filters['state'],
        city: filters['city'],
        specialization: filters['specialization'],
        country: filters['country'],
        searchQuery: _searchQuery,
        includeDeleted: adminView,
      );

      stream.listen((guidanceList) {
        _admissionsGuidance = guidanceList;
        _isLoading = false;
        notifyListeners();
      }, onError: (error) {
        _error = 'Failed to load admissions guidance: $error';
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to load admissions guidance: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AdmissionsGuidance?> getAdmissionsGuidanceById(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final guidance = await _service.getAdmissionsGuidanceById(id);
      _selectedAdmissionsGuidance = guidance;
      _selectedAdmissionsController.add(guidance);
      _isLoading = false;
      notifyListeners();
      return guidance;
    } catch (e) {
      _error = 'Failed to get admissions guidance: $e';
      _selectedAdmissionsController.add(null);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> addAdmissionsGuidance(AdmissionsGuidance guidance) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.addAdmissionsGuidance(guidance);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add admissions guidance: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAdmissionsGuidance(String id, AdmissionsGuidance guidance) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.updateAdmissionsGuidance(id, guidance);
      
      final index = _admissionsGuidance.indexWhere((g) => g.id == id);
      if (index != -1) {
        _admissionsGuidance[index] = guidance;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update admissions guidance: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ====================== BANGLA CLASSES ======================

  Future<void> loadBanglaClasses({bool adminView = false}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final filters = getFiltersForCategory(EducationCategory.banglaLanguageCulture);
      final stream = _service.getBanglaClasses(
        state: filters['state'],
        city: filters['city'],
        classType: filters['classType'],
        teachingMethod: filters['teachingMethod'],
        searchQuery: _searchQuery,
        includeDeleted: adminView,
      );

      stream.listen((classes) {
        _banglaClasses = classes;
        _isLoading = false;
        notifyListeners();
      }, onError: (error) {
        _error = 'Failed to load Bangla classes: $error';
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to load Bangla classes: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAvailableBanglaClasses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final stream = _service.getAvailableBanglaClasses();
      stream.listen((classes) {
        _banglaClasses = classes;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to load available Bangla classes: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<BanglaClass?> getBanglaClassById(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final banglaClass = await _service.getBanglaClassById(id);
      _selectedBanglaClass = banglaClass;
      _selectedBanglaClassController.add(banglaClass);
      _isLoading = false;
      notifyListeners();
      return banglaClass;
    } catch (e) {
      _error = 'Failed to get Bangla class: $e';
      _selectedBanglaClassController.add(null);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> addBanglaClass(BanglaClass banglaClass) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.addBanglaClass(banglaClass);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add Bangla class: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBanglaClass(String id, BanglaClass banglaClass) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.updateBanglaClass(id, banglaClass);
      
      final index = _banglaClasses.indexWhere((c) => c.id == id);
      if (index != -1) {
        _banglaClasses[index] = banglaClass;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update Bangla class: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBanglaClassEnrollment(String id, int enrolledStudents) async {
    try {
      await _service.updateBanglaClassEnrollment(id, enrolledStudents);
      
      final index = _banglaClasses.indexWhere((c) => c.id == id);
      if (index != -1) {
        final banglaClass = _banglaClasses[index];
        _banglaClasses[index] = BanglaClass(
          id: banglaClass.id,
          category: banglaClass.category,
          instructorName: banglaClass.instructorName,
          organizationName: banglaClass.organizationName,
          email: banglaClass.email,
          phone: banglaClass.phone,
          address: banglaClass.address,
          state: banglaClass.state,
          city: banglaClass.city,
          classTypes: banglaClass.classTypes,
          teachingMethods: banglaClass.teachingMethods,
          description: banglaClass.description,
          classFee: banglaClass.classFee,
          schedule: banglaClass.schedule,
          classDuration: banglaClass.classDuration,
          maxStudents: banglaClass.maxStudents,
          qualifications: banglaClass.qualifications,
          profileImageBase64: banglaClass.profileImageBase64,
          galleryImagesBase64: banglaClass.galleryImagesBase64,
          languagesSpoken: banglaClass.languagesSpoken,
          isVerified: banglaClass.isVerified,
          isActive: banglaClass.isActive,
          isDeleted: banglaClass.isDeleted,
          rating: banglaClass.rating,
          totalReviews: banglaClass.totalReviews,
          totalLikes: banglaClass.totalLikes,
          likedByUsers: banglaClass.likedByUsers,
          enrolledStudents: enrolledStudents,
          createdBy: banglaClass.createdBy,
          createdAt: banglaClass.createdAt,
          updatedAt: DateTime.now(),
          additionalInfo: banglaClass.additionalInfo,
          certifications: banglaClass.certifications,
          website: banglaClass.website,
          socialMediaLinks: banglaClass.socialMediaLinks,
          serviceAreas: banglaClass.serviceAreas,
          culturalActivities: banglaClass.culturalActivities,
        );
        
        if (_selectedBanglaClass?.id == id) {
          _selectedBanglaClass = _banglaClasses[index];
          _selectedBanglaClassController.add(_selectedBanglaClass);
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update enrollment: $e';
      notifyListeners();
      return false;
    }
  }

  // ====================== SPORTS CLUBS ======================

  Future<void> loadSportsClubs({bool adminView = false}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final filters = getFiltersForCategory(EducationCategory.localSports);
      final stream = _service.getSportsClubs(
        state: filters['state'],
        city: filters['city'],
        sportType: filters['sportType'],
        ageGroup: filters['ageGroup'],
        searchQuery: _searchQuery,
        includeDeleted: adminView,
      );

      stream.listen((clubs) {
        _sportsClubs = clubs;
        _isLoading = false;
        notifyListeners();
      }, onError: (error) {
        _error = 'Failed to load sports clubs: $error';
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to load sports clubs: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPopularSportsClubs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final stream = _service.getPopularSportsClubs();
      stream.listen((clubs) {
        _sportsClubs = clubs;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to load popular sports clubs: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SportsClub?> getSportsClubById(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final club = await _service.getSportsClubById(id);
      _selectedSportsClub = club;
      _selectedSportsClubController.add(club);
      _isLoading = false;
      notifyListeners();
      return club;
    } catch (e) {
      _error = 'Failed to get sports club: $e';
      _selectedSportsClubController.add(null);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> addSportsClub(SportsClub club) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.addSportsClub(club);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add sports club: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSportsClub(String id, SportsClub club) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.updateSportsClub(id, club);
      
      final index = _sportsClubs.indexWhere((c) => c.id == id);
      if (index != -1) {
        _sportsClubs[index] = club;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update sports club: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSportsClubMembership(String id, int currentMembers) async {
    try {
      await _service.updateSportsClubMembership(id, currentMembers);
      
      final index = _sportsClubs.indexWhere((c) => c.id == id);
      if (index != -1) {
        final club = _sportsClubs[index];
        _sportsClubs[index] = SportsClub(
          id: club.id,
          category: club.category,
          clubName: club.clubName,
          sportType: club.sportType,
          coachName: club.coachName,
          email: club.email,
          phone: club.phone,
          address: club.address,
          state: club.state,
          city: club.city,
          venue: club.venue,
          description: club.description,
          ageGroups: club.ageGroups,
          skillLevels: club.skillLevels,
          membershipFee: club.membershipFee,
          schedule: club.schedule,
          equipmentProvided: club.equipmentProvided,
          coachQualifications: club.coachQualifications,
          logoImageBase64: club.logoImageBase64,
          galleryImagesBase64: club.galleryImagesBase64,
          amenities: club.amenities,
          isVerified: club.isVerified,
          isActive: club.isActive,
          isDeleted: club.isDeleted,
          rating: club.rating,
          totalReviews: club.totalReviews,
          totalLikes: club.totalLikes,
          likedByUsers: club.likedByUsers,
          currentMembers: currentMembers,
          maxMembers: club.maxMembers,
          createdBy: club.createdBy,
          createdAt: club.createdAt,
          updatedAt: DateTime.now(),
          additionalInfo: club.additionalInfo,
          achievements: club.achievements,
          website: club.website,
          socialMediaLinks: club.socialMediaLinks,
          tournaments: club.tournaments,
        );
        
        if (_selectedSportsClub?.id == id) {
          _selectedSportsClub = _sportsClubs[index];
          _selectedSportsClubController.add(_selectedSportsClub);
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update membership: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleSportsClubLike(String id, String userId) async {
    try {
      await _service.toggleSportsClubLike(id, userId);
      
      final index = _sportsClubs.indexWhere((c) => c.id == id);
      if (index != -1) {
        final club = _sportsClubs[index];
        final updatedLikedByUsers = List<String>.from(club.likedByUsers);
        
        if (updatedLikedByUsers.contains(userId)) {
          updatedLikedByUsers.remove(userId);
        } else {
          updatedLikedByUsers.add(userId);
        }
        
        _sportsClubs[index] = SportsClub(
          id: club.id,
          category: club.category,
          clubName: club.clubName,
          sportType: club.sportType,
          coachName: club.coachName,
          email: club.email,
          phone: club.phone,
          address: club.address,
          state: club.state,
          city: club.city,
          venue: club.venue,
          description: club.description,
          ageGroups: club.ageGroups,
          skillLevels: club.skillLevels,
          membershipFee: club.membershipFee,
          schedule: club.schedule,
          equipmentProvided: club.equipmentProvided,
          coachQualifications: club.coachQualifications,
          logoImageBase64: club.logoImageBase64,
          galleryImagesBase64: club.galleryImagesBase64,
          amenities: club.amenities,
          isVerified: club.isVerified,
          isActive: club.isActive,
          isDeleted: club.isDeleted,
          rating: club.rating,
          totalReviews: club.totalReviews,
          totalLikes: updatedLikedByUsers.length,
          likedByUsers: updatedLikedByUsers,
          currentMembers: club.currentMembers,
          maxMembers: club.maxMembers,
          createdBy: club.createdBy,
          createdAt: club.createdAt,
          updatedAt: DateTime.now(),
          additionalInfo: club.additionalInfo,
          achievements: club.achievements,
          website: club.website,
          socialMediaLinks: club.socialMediaLinks,
          tournaments: club.tournaments,
        );
        
        if (_selectedSportsClub?.id == id) {
          _selectedSportsClub = _sportsClubs[index];
          _selectedSportsClubController.add(_selectedSportsClub);
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

  // ====================== UTILITY METHODS ======================

  Future<void> incrementViewCount(EducationCategory category, String id) async {
    try {
      await _service.incrementViewCount(category, id);
    } catch (e) {
      _error = 'Failed to increment view count: $e';
      notifyListeners();
    }
  }

  // Clear all data
  void clearAll() {
    _tutoringServices.clear();
    _admissionsGuidance.clear();
    _banglaClasses.clear();
    _sportsClubs.clear();
    
    _selectedTutoringService = null;
    _selectedAdmissionsGuidance = null;
    _selectedBanglaClass = null;
    _selectedSportsClub = null;
    
    _filters.clear();
    _searchQuery = '';
    _error = '';
    
    notifyListeners();
  }

  // Clear specific category data
  void clearCategory(EducationCategory category) {
    switch (category) {
      case EducationCategory.tutoringHomework:
        _tutoringServices.clear();
        _selectedTutoringService = null;
        _selectedTutoringController.add(null);
        break;
      case EducationCategory.schoolCollegeAdmissions:
        _admissionsGuidance.clear();
        _selectedAdmissionsGuidance = null;
        _selectedAdmissionsController.add(null);
        break;
      case EducationCategory.banglaLanguageCulture:
        _banglaClasses.clear();
        _selectedBanglaClass = null;
        _selectedBanglaClassController.add(null);
        break;
      case EducationCategory.localSports:
        _sportsClubs.clear();
        _selectedSportsClub = null;
        _selectedSportsClubController.add(null);
        break;
    }
    clearAllFilters(category);
    notifyListeners();
  }

  // Dispose method
  void disposeProvider() {
    _selectedTutoringController.close();
    _selectedAdmissionsController.close();
    _selectedBanglaClassController.close();
    _selectedSportsClubController.close();
  }

  // Get items by category
  dynamic getItemsByCategory(EducationCategory category) {
    switch (category) {
      case EducationCategory.tutoringHomework:
        return _tutoringServices;
      case EducationCategory.schoolCollegeAdmissions:
        return _admissionsGuidance;
      case EducationCategory.banglaLanguageCulture:
        return _banglaClasses;
      case EducationCategory.localSports:
        return _sportsClubs;
    }
  }

  // Set selected item by category
  void setSelectedItem(EducationCategory category, dynamic item) {
    switch (category) {
      case EducationCategory.tutoringHomework:
        _selectedTutoringService = item;
        _selectedTutoringController.add(item);
        break;
      case EducationCategory.schoolCollegeAdmissions:
        _selectedAdmissionsGuidance = item;
        _selectedAdmissionsController.add(item);
        break;
      case EducationCategory.banglaLanguageCulture:
        _selectedBanglaClass = item;
        _selectedBanglaClassController.add(item);
        break;
      case EducationCategory.localSports:
        _selectedSportsClub = item;
        _selectedSportsClubController.add(item);
        break;
    }
    notifyListeners();
  }

  // Get selected item by category
  dynamic getSelectedItem(EducationCategory category) {
    switch (category) {
      case EducationCategory.tutoringHomework:
        return _selectedTutoringService;
      case EducationCategory.schoolCollegeAdmissions:
        return _selectedAdmissionsGuidance;
      case EducationCategory.banglaLanguageCulture:
        return _selectedBanglaClass;
      case EducationCategory.localSports:
        return _selectedSportsClub;
    }
  }

  // Get available filters for category
  List<String> getAvailableSubjects() {
    return TutoringSubject.values.map((s) => s.displayName).toList();
  }

  List<String> getAvailableLevels() {
    return EducationLevel.values.map((l) => l.displayName).toList();
  }

  List<String> getAvailableTeachingMethods() {
    return TeachingMethod.values.map((m) => m.displayName).toList();
  }

  List<String> getAvailableSportsTypes() {
    return SportsType.values.map((s) => s.displayName).toList();
  }
}