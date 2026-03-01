import 'package:bangla_hub/models/event_model.dart';
import 'package:bangla_hub/services/firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class EventProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = const Uuid();
  
  List<EventModel> _upcomingEvents = [];
  List<EventModel> _pastEvents = [];
  List<EventModel> _myEvents = [];
  List<EventModel> _pendingEvents = [];
  List<EventModel> _searchedEvents = [];
  List<EventModel> _interestedEvents = [];
  Set<String> _userInterestedEventIds = {};
  
  bool _isLoading = false;
  String? _error;
  String? _selectedCategory;
  String _searchQuery = '';
  
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
  
  EventProvider() {
    _loadEvents();
  }
  
  Future<void> _loadEvents() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Listen to upcoming events
      _firestoreService.getUpcomingEvents().listen((events) {
        _upcomingEvents = events;
        notifyListeners();
      });
      
      // Listen to past events
      _firestoreService.getPastEvents().listen((events) {
        _pastEvents = events;
        notifyListeners();
      });
      
      // Listen to pending events (for admin)
      _firestoreService.getPendingEvents().listen((events) {
        _pendingEvents = events;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load user's interested events
  Future<void> loadUserInterestedEvents(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Get list of event IDs user is interested in
      _firestoreService.getUserInterestedEvents(userId).listen((eventIds) {
        _userInterestedEventIds = eventIds.toSet();
        
        // Filter interested events from upcoming and past events
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
        
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
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
  
  // Toggle user interest in an event
  Future<void> toggleUserInterest(String eventId, String userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final isCurrentlyInterested = await _firestoreService.isUserInterested(eventId, userId);
      
      if (isCurrentlyInterested) {
        await _firestoreService.removeInterestedUser(eventId, userId);
        _userInterestedEventIds.remove(eventId);
      } else {
        await _firestoreService.addInterestedUser(eventId, userId);
        _userInterestedEventIds.add(eventId);
      }
      
      // Update interested events list
      await _updateEventInterestedCount(eventId, isCurrentlyInterested ? -1 : 1);
      
      // Re-filter interested events
      _interestedEvents = [
        ..._upcomingEvents.where((event) => _userInterestedEventIds.contains(event.id)),
        ..._pastEvents.where((event) => _userInterestedEventIds.contains(event.id)),
      ];
      
      // Sort by date
      _interestedEvents.sort((a, b) {
        if (a.isUpcoming && !b.isUpcoming) return -1;
        if (!a.isUpcoming && b.isUpcoming) return 1;
        return b.eventDate.compareTo(a.eventDate);
      });
      
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add user interest in an event
  Future<void> addUserInterest(String eventId, String userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestoreService.addInterestedUser(eventId, userId);
      _userInterestedEventIds.add(eventId);
      
      // Update interested count
      await _updateEventInterestedCount(eventId, 1);
      
      // Update interested events list
      _interestedEvents = [
        ..._upcomingEvents.where((event) => _userInterestedEventIds.contains(event.id)),
        ..._pastEvents.where((event) => _userInterestedEventIds.contains(event.id)),
      ];
      
      // Sort by date
      _interestedEvents.sort((a, b) {
        if (a.isUpcoming && !b.isUpcoming) return -1;
        if (!a.isUpcoming && b.isUpcoming) return 1;
        return b.eventDate.compareTo(a.eventDate);
      });
      
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Remove user interest from an event
  Future<void> removeUserInterest(String eventId, String userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestoreService.removeInterestedUser(eventId, userId);
      _userInterestedEventIds.remove(eventId);
      
      // Update interested count
      await _updateEventInterestedCount(eventId, -1);
      
      // Update interested events list
      _interestedEvents = [
        ..._upcomingEvents.where((event) => _userInterestedEventIds.contains(event.id)),
        ..._pastEvents.where((event) => _userInterestedEventIds.contains(event.id)),
      ];
      
      // Sort by date
      _interestedEvents.sort((a, b) {
        if (a.isUpcoming && !b.isUpcoming) return -1;
        if (!a.isUpcoming && b.isUpcoming) return 1;
        return b.eventDate.compareTo(a.eventDate);
      });
      
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get all users interested in an event
  Stream<List<String>> getInterestedUsers(String eventId) {
    return _firestoreService.getInterestedUsers(eventId);
  }
  
  // Update event's interested count in local lists
  Future<void> _updateEventInterestedCount(String eventId, int change) async {
    // Update in upcoming events
    final upcomingIndex = _upcomingEvents.indexWhere((e) => e.id == eventId);
    if (upcomingIndex != -1) {
      final event = _upcomingEvents[upcomingIndex];
      final newCount = event.totalInterested + change;
      _upcomingEvents[upcomingIndex] = event.copyWith(totalInterested: newCount);
    }
    
    // Update in past events
    final pastIndex = _pastEvents.indexWhere((e) => e.id == eventId);
    if (pastIndex != -1) {
      final event = _pastEvents[pastIndex];
      final newCount = event.totalInterested + change;
      _pastEvents[pastIndex] = event.copyWith(totalInterested: newCount);
    }
    
    // Update in my events
    final myIndex = _myEvents.indexWhere((e) => e.id == eventId);
    if (myIndex != -1) {
      final event = _myEvents[myIndex];
      final newCount = event.totalInterested + change;
      _myEvents[myIndex] = event.copyWith(totalInterested: newCount);
    }
    
    // Update in pending events
    final pendingIndex = _pendingEvents.indexWhere((e) => e.id == eventId);
    if (pendingIndex != -1) {
      final event = _pendingEvents[pendingIndex];
      final newCount = event.totalInterested + change;
      _pendingEvents[pendingIndex] = event.copyWith(totalInterested: newCount);
    }
    
    // Update in searched events
    final searchedIndex = _searchedEvents.indexWhere((e) => e.id == eventId);
    if (searchedIndex != -1) {
      final event = _searchedEvents[searchedIndex];
      final newCount = event.totalInterested + change;
      _searchedEvents[searchedIndex] = event.copyWith(totalInterested: newCount);
    }
    
    // Update in interested events
    final interestedIndex = _interestedEvents.indexWhere((e) => e.id == eventId);
    if (interestedIndex != -1) {
      final event = _interestedEvents[interestedIndex];
      final newCount = event.totalInterested + change;
      _interestedEvents[interestedIndex] = event.copyWith(totalInterested: newCount);
    }
    
    notifyListeners();
  }
  
  // Get event by ID with updated interested status
  Future<EventModel?> getEventById(String eventId, String userId) async {
    try {
      final event = await _firestoreService.getEventById(eventId);
      if (event != null) {
        // Check if user is interested
        final isInterested = await isUserInterested(eventId, userId);
        // Note: You might want to store isInterested separately or create a wrapper
        return event;
      }
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  // Existing methods (keep your existing methods here)
  
  Future<void> loadUserEvents(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _firestoreService.getUserEvents(userId).listen((events) {
        _myEvents = events;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
/*  Future<void> createEvent({
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
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
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
        status: 'pending', // Events start as pending
        totalInterested: 0, // Start with 0 interested
      );
      
      await _firestoreService.createEvent(event);
      
      // Add to my events
      _myEvents.insert(0, event);
      
      // Add to pending if admin
      _pendingEvents.insert(0, event);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }   */

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
  String? bannerImageUrl, // This will be the base64 string
  required bool isFree,
  Map<String, double>? ticketPrices,
  String? paymentInfo,
  required String createdBy,
}) async {
  try {
    _isLoading = true;
    notifyListeners();
    
    print('📝 Creating event with image: ${bannerImageUrl != null ? "Yes" : "No"}');
    if (bannerImageUrl != null) {
      print('🖼️ Image string length: ${bannerImageUrl.length}');
      print('🖼️ Image preview: ${bannerImageUrl.substring(0, 100)}...');
    }
    
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
      bannerImageUrl: bannerImageUrl, // Base64 string goes here
      isFree: isFree,
      ticketPrices: ticketPrices,
      paymentInfo: paymentInfo,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      status: 'pending',
      totalInterested: 0,
    );
    
    await _firestoreService.createEvent(event);
    
    print('✅ Event created successfully with ID: ${event.id}');
    
    // Add to my events
    _myEvents.insert(0, event);
    
    // Add to pending if admin
    _pendingEvents.insert(0, event);
    
    notifyListeners();
  } catch (e) {
    _error = e.toString();
    print('❌ Error creating event: $_error');
    notifyListeners();
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
} 


  Future<void> updateEvent(EventModel event) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final updatedEvent = event.copyWith(updatedAt: DateTime.now());
      await _firestoreService.updateEvent(updatedEvent);
      
      // Update in lists
      _updateEventInList(_upcomingEvents, updatedEvent);
      _updateEventInList(_pastEvents, updatedEvent);
      _updateEventInList(_myEvents, updatedEvent);
      _updateEventInList(_pendingEvents, updatedEvent);
      _updateEventInList(_searchedEvents, updatedEvent);
      _updateEventInList(_interestedEvents, updatedEvent);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updateEventStatus(String eventId, String status) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestoreService.updateEventStatus(eventId, status);
      
      // Find and update event in all lists
      final eventIndex = _pendingEvents.indexWhere((e) => e.id == eventId);
      if (eventIndex != -1) {
        var event = _pendingEvents[eventIndex];
        event = event.copyWith(status: status, updatedAt: DateTime.now());
        _pendingEvents[eventIndex] = event;
        
        // Move to appropriate list based on date and status
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
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> deleteEvent(String eventId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestoreService.deleteEvent(eventId);
      
      // Remove from all lists
      _upcomingEvents.removeWhere((event) => event.id == eventId);
      _pastEvents.removeWhere((event) => event.id == eventId);
      _myEvents.removeWhere((event) => event.id == eventId);
      _pendingEvents.removeWhere((event) => event.id == eventId);
      _searchedEvents.removeWhere((event) => event.id == eventId);
      _interestedEvents.removeWhere((event) => event.id == eventId);
      _userInterestedEventIds.remove(eventId);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> searchEvents(String query, {String? category}) async {
    _searchQuery = query;
    
    if (query.isEmpty || query.length < 2) {
      _searchedEvents = [];
      notifyListeners();
      return;
    }
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Use Firestore search with minimum 2 characters
      _firestoreService.searchEvents(query, category: category).listen((events) {
        _searchedEvents = events;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> filterEventsByCategory(String? category) async {
    _selectedCategory = category;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Clear existing streams and set up filtered streams
      _firestoreService.getUpcomingEvents(category: category).listen((events) {
        _upcomingEvents = events;
        notifyListeners();
      });
      
      _firestoreService.getPastEvents(category: category).listen((events) {
        _pastEvents = events;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  List<EventModel> getEventsByCategory(String category) {
    return _upcomingEvents.where((event) => event.category == category).toList();
  }
  
  List<String> getEventCategories() {
    final categories = _upcomingEvents.map((e) => e.category).toSet().toList();
    categories.sort();
    return categories;
  }
  
  void clearSearch() {
    _searchQuery = '';
    _searchedEvents = [];
    notifyListeners();
  }
  
  void clearCategoryFilter() {
    _selectedCategory = null;
    _loadEvents(); // Reload without category filter
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  void _updateEventInList(List<EventModel> list, EventModel updatedEvent) {
    final index = list.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      list[index] = updatedEvent;
    }
  }
}