// providers/event_provider.dart
import 'dart:async';
import 'package:bangla_hub/models/event_model.dart';
import 'package:bangla_hub/providers/location_filter_provider.dart';
import 'package:bangla_hub/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class EventProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = const Uuid();
  
  // Data lists
  List<EventModel> _upcomingEvents = [];
  List<EventModel> _pastEvents = [];
  List<EventModel> _myEvents = [];
  List<EventModel> _pendingEvents = [];
  List<EventModel> _searchedEvents = [];
  List<EventModel> _interestedEvents = [];
  Set<String> _userInterestedEventIds = {};
  
  // State variables
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isDisposed = false;
  String? _error;
  String? _selectedCategory;
  String _searchQuery = '';
  String? _currentStateFilter;
  
  // Per-event loading states for interest buttons
  final Map<String, bool> _interestButtonLoadingStates = {};
  
  // Track if initial data has been loaded
  bool get isInitialized => _isInitialized;
  
  // Stream subscriptions
  StreamSubscription? _upcomingSubscription;
  StreamSubscription? _pastSubscription;
  StreamSubscription? _pendingSubscription;
  StreamSubscription? _interestedSubscription;
  StreamSubscription? _userEventsSubscription;
  StreamSubscription? _searchSubscription;
  
  // Debounce timer for search
  Timer? _debounceTimer;
  
  // Getters
  List<EventModel> get upcomingEvents => _upcomingEvents;
  List<EventModel> get pastEvents => _pastEvents;
  List<EventModel> get myEvents => _myEvents;
  List<EventModel> get pendingEvents => _pendingEvents;
  List<EventModel> get searchedEvents => _searchedEvents;
  List<EventModel> get interestedEvents => _interestedEvents;
  Set<String> get userInterestedEventIds => _userInterestedEventIds;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String? get currentStateFilter => _currentStateFilter;
  
  // Getter for per-event loading state
  bool isInterestButtonLoading(String eventId) {
    return _interestButtonLoadingStates[eventId] ?? false;
  }
  
  EventProvider() {
    _loadEvents();
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    
    // Cancel all subscriptions
    _upcomingSubscription?.cancel();
    _pastSubscription?.cancel();
    _pendingSubscription?.cancel();
    _interestedSubscription?.cancel();
    _userEventsSubscription?.cancel();
    _searchSubscription?.cancel();
    _debounceTimer?.cancel();
    
    super.dispose();
  }
  
  // Safe methods to prevent build-phase updates
  void _safeUpdate(VoidCallback fn) {
    if (_isDisposed) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        fn();
      }
    });
  }
  
  void _safeSetLoading(bool value) {
    if (_isDisposed) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _isLoading = value;
        notifyListeners();
      }
    });
  }
  
  void _safeSetError(String value) {
    if (_isDisposed) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _error = value;
        notifyListeners();
      }
    });
  }
  
  // Sync with global location filter
  void syncWithLocationFilter(LocationFilterProvider locationProvider) {
    String? newFilter = locationProvider.isFilterActive ? locationProvider.selectedState : null;
    
    if (_currentStateFilter != newFilter) {
      print('📍 EventProvider syncing with location filter: $newFilter (was: $_currentStateFilter)');
      updateStateFilter(newFilter);
    } else {
      print('📍 EventProvider filter already in sync: $_currentStateFilter');
    }
  }
  
  // Method to update state filter
  void updateStateFilter(String? state) {
    if (_isDisposed) return;
    
    print('📍 EventProvider.updateStateFilter called with state: $state (current: $_currentStateFilter)');
    if (_currentStateFilter != state) {
      _currentStateFilter = state;
      print('📍 State filter changed to: $_currentStateFilter - reloading events');
      _loadEvents(); // Reload events with new filter
    } else {
      print('📍 State filter unchanged, no reload needed');
    }
  }
  
  // Initial load of events
  Future<void> _loadEvents() async {
    if (_isDisposed) return;
    
    try {
      _safeSetLoading(true);
      print('📍 _loadEvents called with state filter: $_currentStateFilter');
      print('📍 Selected category: $_selectedCategory');
      
      // Cancel existing subscriptions
      _upcomingSubscription?.cancel();
      _pastSubscription?.cancel();
      _pendingSubscription?.cancel();
      
      // Listen to upcoming events with state filter
      _upcomingSubscription = _firestoreService
          .getUpcomingEvents(
            category: _selectedCategory,
            stateFilter: _currentStateFilter,
          )
          .listen((events) {
        _safeUpdate(() {
          print('📊 Received ${events.length} upcoming events with filter: $_currentStateFilter');
          _upcomingEvents = events;
          _updateInterestedEvents();
          _checkInitialized();
        });
      }, onError: (error) {
        print('❌ Error loading upcoming events: $error');
        _safeSetError(error.toString());
      });
      
      // Listen to past events with state filter
      _pastSubscription = _firestoreService
          .getPastEvents(
            category: _selectedCategory,
            stateFilter: _currentStateFilter,
          )
          .listen((events) {
        _safeUpdate(() {
          print('📊 Received ${events.length} past events with filter: $_currentStateFilter');
          _pastEvents = events;
          _updateInterestedEvents();
          _checkInitialized();
        });
      }, onError: (error) {
        print('❌ Error loading past events: $error');
        _safeSetError(error.toString());
      });
      
      // Listen to pending events (for admin)
      _pendingSubscription = _firestoreService.getPendingEvents().listen((events) {
        _safeUpdate(() {
          _pendingEvents = events;
        });
      }, onError: (error) {
        print('❌ Error loading pending events: $error');
        _safeSetError(error.toString());
      });
      
    } catch (e) {
      print('❌ Error in _loadEvents: $e');
      _safeSetError(e.toString());
    } finally {
      _safeSetLoading(false);
    }
  }
  
  // Load events with specific state filter
  Future<void> loadEventsWithFilter({String? state}) async {
    print('📍 loadEventsWithFilter called with state: $state');
    _currentStateFilter = state;
    await _loadEvents();
  }
  
  void _checkInitialized() {
    if (!_isDisposed && !_isInitialized) {
      _isInitialized = true;
      _safeUpdate(() {
        notifyListeners();
      });
    }
  }

  // Get approved events with state filter
  Stream<List<EventModel>> getApprovedEventsWithFilter({String? stateFilter}) {
    Query query = FirebaseFirestore.instance
        .collection('events_approved')
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true);
    
    if (stateFilter != null && stateFilter.isNotEmpty) {
      query = query.where('state', isEqualTo: stateFilter);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }
  
  // Load user's interested events
  Future<void> loadUserInterestedEvents(String userId) async {
    if (_isDisposed) return;
    
    try {
      // Cancel existing subscription
      _interestedSubscription?.cancel();
      
      // Get list of event IDs user is interested in
      _interestedSubscription = _firestoreService.getUserInterestedEvents(userId).listen((eventIds) {
        _safeUpdate(() {
          _userInterestedEventIds = eventIds.toSet();
          _updateInterestedEvents();
        });
      }, onError: (error) {
        _safeSetError(error.toString());
      });
      
    } catch (e) {
      _safeSetError(e.toString());
    }
  }
  
  // Check if user is interested in an event
  Future<bool> isUserInterested(String eventId, String userId) async {
    try {
      return await _firestoreService.isUserInterested(eventId, userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking user interest: $e');
      }
      return false;
    }
  }
  
  // Update interested count in all lists
  void _updateEventInterestedCount(String eventId, int change) {
    if (_isDisposed) return;
    
    bool updated = false;
    
    // Helper function to update a single list with validation
    void updateList(List<EventModel> list) {
      final index = list.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        final event = list[index];
        // Ensure count never goes below 0
        final newCount = (event.totalInterested + change).clamp(0, double.infinity).toInt();
        list[index] = event.copyWith(totalInterested: newCount);
        updated = true;
      }
    }
    
    // Update all lists
    updateList(_upcomingEvents);
    updateList(_pastEvents);
    updateList(_myEvents);
    updateList(_pendingEvents);
    updateList(_searchedEvents);
    updateList(_interestedEvents);
    
    // Trigger UI update if any list was updated
    if (updated && !_isDisposed) {
      _safeUpdate(() {
        notifyListeners();
      });
    }
  }
  
  // Update interested events list
  void _updateInterestedEvents() {
    if (_isDisposed) return;
    
    _interestedEvents = [
      ..._upcomingEvents.where((event) => _userInterestedEventIds.contains(event.id)),
      ..._pastEvents.where((event) => _userInterestedEventIds.contains(event.id)),
    ];
    
    // Sort by date (upcoming first, then past)
    _interestedEvents.sort((a, b) {
      if (a.isUpcoming && !b.isUpcoming) return -1;
      if (!a.isUpcoming && b.isUpcoming) return 1;
      return b.eventDate.compareTo(a.eventDate);
    });
  }
  
  // Toggle user interest in an event
  Future<void> toggleUserInterest(String eventId, String userId) async {
    if (_isDisposed) return;
    
    // Prevent double taps
    if (_interestButtonLoadingStates[eventId] == true) return;
    
    // Set loading state for this specific event
    _interestButtonLoadingStates[eventId] = true;
    _safeUpdate(() {
      notifyListeners();
    });
    
    try {
      final isCurrentlyInterested = await _firestoreService.isUserInterested(eventId, userId);
      
      // Optimistic update - update UI immediately
      _safeUpdate(() {
        if (isCurrentlyInterested) {
          _userInterestedEventIds.remove(eventId);
          _updateEventInterestedCount(eventId, -1);
        } else {
          _userInterestedEventIds.add(eventId);
          _updateEventInterestedCount(eventId, 1);
        }
        _updateInterestedEvents();
      });
      
      // Perform actual Firestore operation
      if (isCurrentlyInterested) {
        await _firestoreService.removeInterestedUser(eventId, userId);
      } else {
        await _firestoreService.addInterestedUser(eventId, userId);
      }
      
    } catch (e) {
      // Revert optimistic update on error
      _safeUpdate(() {
        if (_userInterestedEventIds.contains(eventId)) {
          _userInterestedEventIds.remove(eventId);
          _updateEventInterestedCount(eventId, -1);
        } else {
          _userInterestedEventIds.add(eventId);
          _updateEventInterestedCount(eventId, 1);
        }
        _updateInterestedEvents();
      });
      
      _safeSetError(e.toString());
      rethrow;
    } finally {
      // Clear loading state for this specific event
      _interestButtonLoadingStates[eventId] = false;
      _safeUpdate(() {
        notifyListeners();
      });
    }
  }
  
  // Add user interest in an event
  Future<void> addUserInterest(String eventId, String userId) async {
    if (_isDisposed) return;
    
    if (_interestButtonLoadingStates[eventId] == true) return;
    
    _interestButtonLoadingStates[eventId] = true;
    _safeUpdate(() {
      notifyListeners();
    });
    
    try {
      // Optimistic update
      _safeUpdate(() {
        _userInterestedEventIds.add(eventId);
        _updateEventInterestedCount(eventId, 1);
        _updateInterestedEvents();
      });
      
      await _firestoreService.addInterestedUser(eventId, userId);
      
    } catch (e) {
      // Revert on error
      _safeUpdate(() {
        _userInterestedEventIds.remove(eventId);
        _updateEventInterestedCount(eventId, -1);
        _updateInterestedEvents();
      });
      
      _safeSetError(e.toString());
      rethrow;
    } finally {
      _interestButtonLoadingStates[eventId] = false;
      _safeUpdate(() {
        notifyListeners();
      });
    }
  }
  
  // Remove user interest from an event
  Future<void> removeUserInterest(String eventId, String userId) async {
    if (_isDisposed) return;
    
    if (_interestButtonLoadingStates[eventId] == true) return;
    
    _interestButtonLoadingStates[eventId] = true;
    _safeUpdate(() {
      notifyListeners();
    });
    
    try {
      // Optimistic update
      _safeUpdate(() {
        _userInterestedEventIds.remove(eventId);
        _updateEventInterestedCount(eventId, -1);
        _updateInterestedEvents();
      });
      
      await _firestoreService.removeInterestedUser(eventId, userId);
      
    } catch (e) {
      // Revert on error
      _safeUpdate(() {
        _userInterestedEventIds.add(eventId);
        _updateEventInterestedCount(eventId, 1);
        _updateInterestedEvents();
      });
      
      _safeSetError(e.toString());
      rethrow;
    } finally {
      _interestButtonLoadingStates[eventId] = false;
      _safeUpdate(() {
        notifyListeners();
      });
    }
  }
  
  // Get all users interested in an event
  Stream<List<String>> getInterestedUsers(String eventId) {
    return _firestoreService.getInterestedUsers(eventId);
  }
  
  // Get event by ID
  Future<EventModel?> getEventById(String eventId, String userId) async {
    try {
      final event = await _firestoreService.getEventById(eventId);
      return event;
    } catch (e) {
      _safeSetError(e.toString());
      return null;
    }
  }
  
  // Load user's created events
  Future<void> loadUserEvents(String userId) async {
    if (_isDisposed) return;
    
    try {
      _safeSetLoading(true);
      
      _userEventsSubscription?.cancel();
      
      _userEventsSubscription = _firestoreService.getUserEvents(userId).listen((events) {
        _safeUpdate(() {
          _myEvents = events;
        });
      }, onError: (error) {
        _safeSetError(error.toString());
      });
      
    } catch (e) {
      _safeSetError(e.toString());
    } finally {
      _safeSetLoading(false);
    }
  }

  // Create new event
  Future<void> createEvent({
    required String title,
    required String organizer,
    required String contactPerson,
    required String contactEmail,
    required String contactPhone,
    required DateTime eventDate,
    required String location,
    required String description,
    required String category,
    String? bannerImageUrl,
    required bool isFree,
    Map<String, double>? ticketPrices,
    String? paymentInfo,
    required String createdBy,
    double? latitude,
    double? longitude,
    String? state,
    String? city,
  }) async {
    if (_isDisposed) return;
    
    try {
      _safeSetLoading(true);
      
      print('📝 Creating event with image: ${bannerImageUrl != null ? "Yes" : "No"}');
      print('📍 Location coordinates: lat=$latitude, lng=$longitude, state=$state, city=$city');
      
      final event = EventModel(
        id: _uuid.v4(),
        title: title,
        organizer: organizer,
        contactPerson: contactPerson,
        contactEmail: contactEmail,
        contactPhone: contactPhone,
        eventDate: eventDate,
        location: location,
        description: description,
        category: category,
        bannerImageUrl: bannerImageUrl,
        isFree: isFree,
        ticketPrices: ticketPrices,
        paymentInfo: paymentInfo,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        status: 'pending',
        totalInterested: 0,
        latitude: latitude,
        longitude: longitude,
        state: state,
        city: city,
      );
      
      await _firestoreService.createEvent(event);
      
      print('✅ Event created successfully with ID: ${event.id}');
      
      _safeUpdate(() {
        _myEvents.insert(0, event);
        _pendingEvents.insert(0, event);
        notifyListeners();
      });
      
    } catch (e) {
      print('❌ Error creating event: $e');
      _safeSetError(e.toString());
      rethrow;
    } finally {
      _safeSetLoading(false);
    }
  } 

  // Update event
  Future<void> updateEvent(EventModel event) async {
    if (_isDisposed) return;
    
    try {
      _safeSetLoading(true);
      
      final updatedEvent = event.copyWith(updatedAt: DateTime.now());
      await _firestoreService.updateEvent(updatedEvent);
      
      _safeUpdate(() {
        _updateEventInList(_upcomingEvents, updatedEvent);
        _updateEventInList(_pastEvents, updatedEvent);
        _updateEventInList(_myEvents, updatedEvent);
        _updateEventInList(_pendingEvents, updatedEvent);
        _updateEventInList(_searchedEvents, updatedEvent);
        _updateEventInList(_interestedEvents, updatedEvent);
        notifyListeners();
      });
      
    } catch (e) {
      _safeSetError(e.toString());
      rethrow;
    } finally {
      _safeSetLoading(false);
    }
  }
  
  // Update event status
  Future<void> updateEventStatus(String eventId, String status) async {
    if (_isDisposed) return;
    
    try {
      _safeSetLoading(true);
      
      await _firestoreService.updateEventStatus(eventId, status);
      
      _safeUpdate(() {
        final eventIndex = _pendingEvents.indexWhere((e) => e.id == eventId);
        if (eventIndex != -1) {
          var event = _pendingEvents[eventIndex];
          event = event.copyWith(status: status, updatedAt: DateTime.now());
          _pendingEvents[eventIndex] = event;
          
          if (status == 'approved') {
            if (event.isPast) {
              _pastEvents.insert(0, event);
            } else {
              _upcomingEvents.insert(0, event);
            }
            _pendingEvents.removeAt(eventIndex);
          }
        }
        notifyListeners();
      });
      
    } catch (e) {
      _safeSetError(e.toString());
      rethrow;
    } finally {
      _safeSetLoading(false);
    }
  }
  
  // Delete event
  Future<void> deleteEvent(String eventId) async {
    if (_isDisposed) return;
    
    try {
      _safeSetLoading(true);
      
      await _firestoreService.deleteEvent(eventId);
      
      _safeUpdate(() {
        _upcomingEvents.removeWhere((event) => event.id == eventId);
        _pastEvents.removeWhere((event) => event.id == eventId);
        _myEvents.removeWhere((event) => event.id == eventId);
        _pendingEvents.removeWhere((event) => event.id == eventId);
        _searchedEvents.removeWhere((event) => event.id == eventId);
        _interestedEvents.removeWhere((event) => event.id == eventId);
        _userInterestedEventIds.remove(eventId);
        notifyListeners();
      });
      
    } catch (e) {
      _safeSetError(e.toString());
      rethrow;
    } finally {
      _safeSetLoading(false);
    }
  }
  
  // Search events with debounce
  Future<void> searchEvents(String query, {String? category}) async {
    if (_isDisposed) return;
    
    // Debounce search to prevent too many requests
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (_isDisposed) return;
      
      _searchQuery = query;
      
      if (query.isEmpty || query.length < 2) {
        _safeUpdate(() {
          _searchedEvents = [];
          notifyListeners();
        });
        return;
      }
      
      try {
        _searchSubscription?.cancel();
        
        _searchSubscription = _firestoreService
            .searchEvents(
              query, 
              category: category,
              stateFilter: _currentStateFilter,
            )
            .listen((events) {
          _safeUpdate(() {
            _searchedEvents = events;
            notifyListeners();
          });
        }, onError: (error) {
          _safeSetError(error.toString());
        });
        
      } catch (e) {
        _safeSetError(e.toString());
      }
    });
  }
  
  // Filter events by category
  Future<void> filterEventsByCategory(String? category) async {
    if (_isDisposed) return;
    
    _selectedCategory = category;
    
    try {
      _safeSetLoading(true);
      
      _upcomingSubscription?.cancel();
      _pastSubscription?.cancel();
      
      _upcomingSubscription = _firestoreService
          .getUpcomingEvents(
            category: category,
            stateFilter: _currentStateFilter,
          )
          .listen((events) {
        _safeUpdate(() {
          _upcomingEvents = events;
          _updateInterestedEvents();
          notifyListeners();
        });
      }, onError: (error) {
        _safeSetError(error.toString());
      });
      
      _pastSubscription = _firestoreService
          .getPastEvents(
            category: category,
            stateFilter: _currentStateFilter,
          )
          .listen((events) {
        _safeUpdate(() {
          _pastEvents = events;
          _updateInterestedEvents();
          notifyListeners();
        });
      }, onError: (error) {
        _safeSetError(error.toString());
      });
      
    } catch (e) {
      _safeSetError(e.toString());
    } finally {
      _safeSetLoading(false);
    }
  }
  
  // Get events by category
  List<EventModel> getEventsByCategory(String category) {
    return _upcomingEvents.where((event) => event.category == category).toList();
  }
  
  // Get event categories
  List<String> getEventCategories() {
    final categories = _upcomingEvents.map((e) => e.category).toSet().toList();
    categories.sort();
    return categories;
  }
  
  // Clear search
  void clearSearch() {
    if (_isDisposed) return;
    
    _searchQuery = '';
    _searchSubscription?.cancel();
    
    _safeUpdate(() {
      _searchedEvents = [];
      notifyListeners();
    });
  }
  
  // Clear category filter
  void clearCategoryFilter() {
    if (_isDisposed) return;
    
    _selectedCategory = null;
    _loadEvents();
  }
  
  // Clear error
  void clearError() {
    if (_isDisposed) return;
    
    _safeUpdate(() {
      _error = null;
      notifyListeners();
    });
  }
  
  // Helper method to update event in a list
  void _updateEventInList(List<EventModel> list, EventModel updatedEvent) {
    final index = list.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      list[index] = updatedEvent;
    }
  }
  
  // Reset provider
  void reset() {
    _upcomingEvents.clear();
    _pastEvents.clear();
    _myEvents.clear();
    _pendingEvents.clear();
    _searchedEvents.clear();
    _interestedEvents.clear();
    _userInterestedEventIds.clear();
    _error = null;
    _selectedCategory = null;
    _searchQuery = '';
    _currentStateFilter = null;
    _interestButtonLoadingStates.clear();
    _isInitialized = false;
    notifyListeners();
  }
}