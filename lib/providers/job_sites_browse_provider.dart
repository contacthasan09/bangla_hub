// lib/providers/job_sites_browse_provider.dart

import 'dart:async';
import 'package:bangla_hub/models/job_sites_browse_model.dart';
import 'package:bangla_hub/services/job_sites_browse_service.dart';
import 'package:flutter/material.dart';

class JobSitesBrowseProvider with ChangeNotifier {
  final JobSitesService _service = JobSitesService();
  
  List<JobSite> _jobSites = [];
  List<JobSite> _filteredSites = [];
  JobSite? _selectedSite;
  bool _isLoading = false;
  bool _isInitialized = false;
  String _error = '';
  String _searchQuery = '';
  JobSiteCategory? _selectedCategory;
  Map<String, dynamic> _clickStats = {};

  StreamSubscription? _sitesSubscription;
  bool _isDisposed = false;
  bool _isInitializing = false; // Add this flag

  // Getters
  List<JobSite> get jobSites => _jobSites;
  List<JobSite> get filteredSites => _filteredSites;
  JobSite? get selectedSite => _selectedSite;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String get error => _error;
  String get searchQuery => _searchQuery;
  JobSiteCategory? get selectedCategory => _selectedCategory;
  Map<String, dynamic> get clickStats => _clickStats;

  // Initialize
  Future<void> initialize() async {
    // Prevent multiple simultaneous initializations
    if (_isInitializing) {
      print('⏳ Already initializing...');
      return;
    }

    // Prevent multiple initializations
    if (_isInitialized) {
      print('✅ Provider already initialized');
      return;
    }

    // Don't initialize if disposed
    if (_isDisposed) {
      print('❌ Cannot initialize disposed provider');
      return;
    }
    
    _isInitializing = true;
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      print('🔄 Initializing provider...');
      await _service.initializeDefaultSites(); // This now also updates logos
      _subscribeToSites();
      await loadClickStatistics();
      _isInitialized = true;
      _isLoading = false;
      _isInitializing = false;
      print('✅ Provider initialized successfully');
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize: $e';
      _isLoading = false;
      _isInitialized = false;
      _isInitializing = false;
      print('❌ Initialization error: $e');
      notifyListeners();
    }
  }

  // Subscribe to real-time updates with proper error handling
  void _subscribeToSites() {
    // Cancel any existing subscription first
    _cancelSubscription();
    
    print('🔄 Subscribing to job sites stream...');
    
    _sitesSubscription = _service.getAllJobSitesStream().listen(
      (sites) {
        // Don't update if disposed
        if (_isDisposed) return;
        
        print('📦 Received ${sites.length} sites in stream');
        _jobSites = sites;
        _applyFilters();
        notifyListeners();
      },
      onError: (error) {
        if (_isDisposed) return;
        print('❌ Stream error: $error');
        _error = 'Stream error: $error';
        notifyListeners();
      },
      onDone: () {
        print('📡 Stream completed');
        if (!_isDisposed) {
          _sitesSubscription = null;
        }
      },
      cancelOnError: false,
    );
  }

  // Properly cancel subscription
  void _cancelSubscription() {
    if (_sitesSubscription != null) {
      print('🛑 Cancelling existing stream subscription');
      _sitesSubscription!.cancel();
      _sitesSubscription = null;
    }
  }

  // Load all job sites (one-time fetch)
  Future<void> loadJobSites({bool adminView = false}) async {
    // Don't load if disposed
    if (_isDisposed) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      _jobSites = await _service.getAllJobSites(includeInactive: adminView);
      print('📦 Loaded ${_jobSites.length} job sites');
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load job sites: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ Load job sites error: $e');
    }
  }

  // Load click statistics
  Future<void> loadClickStatistics() async {
    if (_isDisposed) return;
    
    try {
      _clickStats = await _service.getClickStatistics();
      notifyListeners();
    } catch (e) {
      print('❌ Failed to load click stats: $e');
    }
  }

  // Apply search and category filters
  void _applyFilters() {
    if (_isDisposed) return;
    
    _filteredSites = _jobSites.where((site) {
      // Apply category filter
      if (_selectedCategory != null && site.category != _selectedCategory) {
        return false;
      }
      
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        return site.name.toLowerCase().contains(query) ||
               site.description.toLowerCase().contains(query) ||
               site.domain.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();
    
    print('🔍 Filtered sites: ${_filteredSites.length} of ${_jobSites.length}');
  }

  // Set search query
  void setSearchQuery(String query) {
    if (_isDisposed) return;
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Set category filter
  void setCategoryFilter(JobSiteCategory? category) {
    if (_isDisposed) return;
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    if (_isDisposed) return;
    _searchQuery = '';
    _selectedCategory = null;
    _applyFilters();
    notifyListeners();
  }

  // Get site by ID
  Future<JobSite?> getSiteById(String id) async {
    if (_isDisposed) return null;
    
    _isLoading = true;
    notifyListeners();

    try {
      final sites = await _service.getAllJobSites(includeInactive: true);
      _selectedSite = sites.firstWhere((site) => site.id == id);
      _isLoading = false;
      notifyListeners();
      return _selectedSite;
    } catch (e) {
      _error = 'Failed to get site: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ Get site by ID error: $e');
      return null;
    }
  }

  // Add or update job site
  Future<bool> saveJobSite(JobSite site) async {
    if (_isDisposed) return false;
    
    _isLoading = true;
    notifyListeners();

    try {
      await _service.saveJobSite(site);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save job site: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ Save job site error: $e');
      return false;
    }
  }

  // Delete job site (soft delete)
  Future<bool> deleteJobSite(String id) async {
    if (_isDisposed) return false;
    
    _isLoading = true;
    notifyListeners();

    try {
      await _service.deleteJobSite(id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete job site: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ Delete job site error: $e');
      return false;
    }
  }

  // Permanently delete job site
  Future<bool> permanentDeleteJobSite(String id) async {
    if (_isDisposed) return false;
    
    _isLoading = true;
    notifyListeners();

    try {
      await _service.permanentDeleteJobSite(id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to permanently delete job site: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ Permanent delete error: $e');
      return false;
    }
  }

  // Record site click
  Future<void> recordSiteClick(String siteId, String siteName) async {
    if (_isDisposed) return;
    
    try {
      await _service.recordSiteClick(siteId, siteName);
      await loadClickStatistics();
    } catch (e) {
      print('❌ Failed to record click: $e');
    }
  }

  // Reset to default sites
  Future<bool> resetToDefault() async {
    if (_isDisposed) return false;
    
    _isLoading = true;
    notifyListeners();

    try {
      await _service.resetToDefault();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to reset: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ Reset error: $e');
      return false;
    }
  }

  // Force update logos (can be called from admin)
  Future<bool> forceUpdateLogos() async {
    if (_isDisposed) return false;
    
    _isLoading = true;
    notifyListeners();

    try {
      await _service.forceUpdateLogos();
      await refresh(); // Refresh data after update
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update logos: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ Update logos error: $e');
      return false;
    }
  }

  // Get sites by category
  List<JobSite> getSitesByCategory(JobSiteCategory category) {
    return _jobSites.where((site) => site.category == category).toList();
  }

  // Get all categories with site counts
  Map<JobSiteCategory, int> getCategoryCounts() {
    final counts = <JobSiteCategory, int>{};
    for (var category in JobSiteCategory.values) {
      counts[category] = _jobSites.where((site) => site.category == category).length;
    }
    return counts;
  }

  // Refresh data manually
  Future<void> refresh() async {
    if (_isDisposed) return;
    
    print('🔄 Manual refresh triggered');
    _cancelSubscription();
    _subscribeToSites();
    await loadClickStatistics();
  }

  // Proper dispose method
  @override
  void dispose() {
    print('🗑️ Disposing JobSitesBrowseProvider');
    _isDisposed = true;
    _cancelSubscription();
    super.dispose();
  }
}