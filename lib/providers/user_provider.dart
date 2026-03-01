import 'package:bangla_hub/models/user_model.dart';
import 'package:bangla_hub/services/firestore_service.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  UserModel? _currentUser;
  Map<String, UserModel> _usersCache = {};
  bool _isLoading = false;
  
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  
  Future<void> loadUser(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Check cache first
      if (_usersCache.containsKey(userId)) {
        _currentUser = _usersCache[userId];
      } else {
        _currentUser = await _firestoreService.getUser(userId);
        if (_currentUser != null) {
          _usersCache[userId] = _currentUser!;
        }
      }
    } catch (e) {
      print('Error loading user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updateUser(UserModel user) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestoreService.updateUser(user);
      _currentUser = user;
      _usersCache[user.id] = user;
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Check cache first
      if (_usersCache.containsKey(userId)) {
        return _usersCache[userId];
      }
      
      final user = await _firestoreService.getUser(userId);
      if (user != null) {
        _usersCache[userId] = user;
      }
      return user;
    } catch (e) {
      print('Error getting user by id: $e');
      return null;
    }
  }
  
  void clearCurrentUser() {
    _currentUser = null;
    notifyListeners();
  }
  
  void cacheUser(UserModel user) {
    _usersCache[user.id] = user;
  }
  
  String getDisplayName(String userId) {
    if (_usersCache.containsKey(userId)) {
      final user = _usersCache[userId];
      return '${user?.firstName} ${user?.lastName}';
    }
    return 'Unknown User';
  }
}