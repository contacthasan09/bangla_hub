// providers/auth_provider.dart - Complete updated version

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bangla_hub/models/user_model.dart';
import 'package:bangla_hub/providers/location_filter_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/user_app/home_screen.dart';
import 'package:bangla_hub/screens/user_app/welcome_screen.dart';
import 'package:bangla_hub/services/auth_service.dart';
import 'package:bangla_hub/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Separate ValueNotifier for profile image (does NOT trigger full rebuilds)
  final ValueNotifier<String?> _profileImageNotifier = ValueNotifier<String?>(null);
  ValueNotifier<String?> get profileImageNotifier => _profileImageNotifier;
  
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  String? _errorMessage;
  bool _isAdminMode = false;
  bool _isGuestMode = false;
  
  final Color _bangladeshGreen = const Color(0xFF006A4E);
  final Color _bangladeshRed = const Color(0xFFF42A41);
  
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdminMode => _isAdminMode;
  bool get isLoggedIn => _user != null;
  bool get isGuestMode => _isGuestMode;
  
  Stream<User?> get userStream => _firebaseAuth.authStateChanges();
  
  AuthProvider() {
    _loadStoredUser();
    _setupAuthListener();
  }
  
  void _setupAuthListener() {
    userStream.listen((User? firebaseUser) {
      if (firebaseUser != null) {
        _loadUserData(firebaseUser.uid);
      } else {
        _user = null;
        _isAdminMode = false;
        notifyListeners();
      }
    });
  }
  
  Future<void> _loadUserData(String userId) async {
    try {
      final userData = await _firestoreService.getUser(userId);
      if (userData != null) {
        _user = userData;
        _profileImageNotifier.value = _user?.profileImageUrl;
        _isAdminMode = userData.isAdmin;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }
  
  Future<void> _loadStoredUser() async {
    try {
      _isLoading = true;
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final isGuest = prefs.getBool('isGuestMode') ?? false;
      
      if (isGuest) {
        _isGuestMode = true;
        _user = null;
        _isAdminMode = false;
        notifyListeners();
      } else if (isLoggedIn) {
        final userId = prefs.getString('userId');
        final isAdmin = prefs.getBool('isAdmin') ?? false;
        
        if (userId != null) {
          _user = await _firestoreService.getUser(userId);
          if (_user != null) {
            _profileImageNotifier.value = _user?.profileImageUrl;
          }
          _isAdminMode = isAdmin;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error loading stored user: $e');
    } finally {
      _isLoading = false;
    }
  }
  
  // ✅ NEW: Update ONLY profile image - NO notifyListeners()
  Future<void> updateProfileImageOnly(String imageUrl) async {
    if (_user == null) return;
    
    try {
      final updatedUser = _user!.copyWithProfileImage(imageUrl);
      await _firestoreService.updateUser(updatedUser);
      _user = updatedUser;
      
      // Only update the ValueNotifier - NO notifyListeners()
      _profileImageNotifier.value = imageUrl;
      
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.updatePhotoURL(imageUrl);
      }
      
      print('✅ Profile image updated silently (no rebuild)');
    } catch (e) {
      print('❌ Error updating profile image: $e');
      rethrow;
    }
  }
  
  // ✅ MODIFIED: Update user profile with minimal rebuilds
  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      _isLoading = true;
      
      // Check if only profile image changed
      final bool onlyImageChanged = 
          _user?.profileImageUrl != updatedUser.profileImageUrl &&
          _user?.firstName == updatedUser.firstName &&
          _user?.lastName == updatedUser.lastName &&
          _user?.phoneNumber == updatedUser.phoneNumber &&
          _user?.location == updatedUser.location;
      
      // Only notify main listeners if non-image data changed
      if (!onlyImageChanged) {
        notifyListeners();
      }
      
      await _firestoreService.updateUser(updatedUser);
      _user = updatedUser;
      
      // Always update the profile image notifier
      _profileImageNotifier.value = _user?.profileImageUrl;
      
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null && updatedUser.profileImageUrl != null) {
        await firebaseUser.updatePhotoURL(updatedUser.profileImageUrl);
      }
      
      print('✅ User profile updated${onlyImageChanged ? " (image only, no rebuild)" : ""}');
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Error updating user profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      if (_user?.profileImageUrl != updatedUser?.profileImageUrl) {
        // Don't notify again
      } else {
        notifyListeners();
      }
    }
  }
  
  // ✅ MODIFIED: Refresh user data without full rebuild for image changes
  Future<void> refreshUserData() async {
    if (_user != null) {
      try {
        print('🔄 Refreshing user data...');
        final refreshedUser = await _firestoreService.getUser(_user!.id);
        if (refreshedUser != null) {
          final oldImageUrl = _user?.profileImageUrl;
          final newImageUrl = refreshedUser.profileImageUrl;
          
          // Check if non-image data changed
          final bool nonImageDataChanged = 
              _user?.firstName != refreshedUser.firstName ||
              _user?.lastName != refreshedUser.lastName ||
              _user?.phoneNumber != refreshedUser.phoneNumber ||
              _user?.location != refreshedUser.location;
          
          // Update user object
          _user = refreshedUser;
          
          // Update profile image notifier if image changed
          if (oldImageUrl != newImageUrl) {
            _profileImageNotifier.value = newImageUrl;
            print('✅ Profile image updated in notifier');
          }
          
          // Only call notifyListeners() if non-image data changed
          if (nonImageDataChanged) {
            notifyListeners();
            print('✅ Non-image data changed, notified listeners');
          } else {
            print('✅ Only image changed or no changes, no full rebuild');
          }
        }
      } catch (e) {
        print('❌ Error refreshing user data: $e');
      }
    }
  }
  
  // Continue as guest method
  Future<void> continueAsGuest(BuildContext context) async {
    try {
      _isGuestMode = true;
      _user = null;
      _isAdminMode = false;
      
      unawaited(_storeGuestModeInBackground());
      
      final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
      unawaited(locationProvider.getUserLocation(showLoading: false));
      
      notifyListeners();
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      _error = e.toString();
      print('Error in guest mode: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFF42A41),
          content: Text('Could not continue as guest: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  Future<void> _storeGuestModeInBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuestMode', true);
      await prefs.setBool('isLoggedIn', false);
    } catch (e) {
      print('Error storing guest mode: $e');
    }
  }
  
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user by id: $e');
      return null;
    }
  }


  
  Future<void> signIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (email == AuthService.adminEmail && password == AuthService.adminPassword) {
        await _handleAdminLogin(email);
      } else {
        await _handleRegularUserLogin(email, password, context);
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  



  Future<void> _handleAdminLogin(String email) async {
    final adminQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: AuthService.adminEmail)
        .limit(1)
        .get();
    
    if (adminQuery.docs.isNotEmpty) {
      _user = UserModel.fromMap(adminQuery.docs.first.data(), adminQuery.docs.first.id);
      _isAdminMode = true;
    } else {
      final adminUser = UserModel(
        id: 'admin_${DateTime.now().millisecondsSinceEpoch}',
        email: AuthService.adminEmail,
        firstName: 'Admin',
        lastName: '',
        role: 'admin',
        isEmailVerified: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.createUser(adminUser);
      _user = adminUser;
      _isAdminMode = true;
    }
    
    if (_user != null) {
      _profileImageNotifier.value = _user?.profileImageUrl;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', _user!.id);
    await prefs.setString('userEmail', email);
    await prefs.setBool('isLoggedIn', true);
    await prefs.setBool('isAdmin', true);
    await prefs.setBool('isGuestMode', false);
    
    notifyListeners();
  }
  
  Future<void> _handleRegularUserLogin(String email, String password, BuildContext context) async {
    final firebaseUser = await _authService.signInWithEmail(
      email: email,
      password: password,
    );
    
    if (firebaseUser != null) {
      _user = await _firestoreService.getUser(firebaseUser.uid);
      
      if (_user == null) {
        await _authService.signOut();
        throw 'User data not found. Please contact support.';
      }
      
      _profileImageNotifier.value = _user?.profileImageUrl;
      
      final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
      await locationProvider.getUserLocation();
      
      if (locationProvider.currentUserLocation != null) {
        final updatedUser = _user!.copyWith(
          latitude: locationProvider.currentUserLocation!.latitude,
          longitude: locationProvider.currentUserLocation!.longitude,
          lastActiveAt: DateTime.now(),
        );
        await _firestoreService.updateUser(updatedUser);
        _user = updatedUser;
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', firebaseUser.uid);
      await prefs.setString('userEmail', email);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isAdmin', false);
      await prefs.setBool('isGuestMode', false);
      
      _isAdminMode = false;
      _isGuestMode = false;
      notifyListeners();
    }
  }
  
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String location,
    String? profileImageUrl,
    String? country,
    String? countryCode,
    double? latitude,
    double? longitude,
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (latitude == null || longitude == null) {
        final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
        await locationProvider.getUserLocation();
        
        if (locationProvider.currentUserLocation != null) {
          latitude = locationProvider.currentUserLocation!.latitude;
          longitude = locationProvider.currentUserLocation!.longitude;
        }
      }

      final userData = UserModel(
        id: _uuid.v4(),
        email: email,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        location: location,
        profileImageUrl: profileImageUrl,
        role: 'user',
        isEmailVerified: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        country: country,
        countryCode: countryCode,
        latitude: latitude,
        longitude: longitude,
      );

      final firebaseUser = await _authService.signUpWithEmail(
        email: email,
        password: password,
        userData: userData,
      );

      if (firebaseUser != null) {
        _user = userData.copyWith(id: firebaseUser.uid);
        _profileImageNotifier.value = _user?.profileImageUrl;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', firebaseUser.uid);
        await prefs.setString('userEmail', email);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setBool('isAdmin', false);
        await prefs.setBool('isGuestMode', false);
        
        _isAdminMode = false;
        _isGuestMode = false;
        notifyListeners();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _bangladeshGreen,
            content: const Text('✅ Account created successfully!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (newPassword.length < 8) {
        throw 'Password must be at least 8 characters long';
      }

      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'User not logged in';
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      try {
        await user.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password') {
          throw 'Current password is incorrect';
        } else if (e.code == 'user-mismatch') {
          throw 'Invalid credentials';
        } else if (e.code == 'invalid-credential') {
          throw 'Invalid password';
        } else if (e.code == 'too-many-requests') {
          throw 'Too many attempts. Try again later.';
        } else {
          throw 'Authentication failed: ${e.message}';
        }
      }

      await user.updatePassword(newPassword);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Password updated successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> signOut(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _authService.signOut();
      
      _user = null;
      _isAdminMode = false;
      _isGuestMode = false;
      _profileImageNotifier.value = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.remove('userEmail');
      await prefs.setBool('isLoggedIn', false);
      await prefs.setBool('isAdmin', false);
      await prefs.setBool('isGuestMode', false);
      await prefs.remove('selected_tab_index');
      
      final locationProvider = Provider.of<LocationFilterProvider>(
        context,
        listen: false,
      );
      locationProvider.clearForLogout();
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  


/*  Future<void> deleteAccount() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      print('🗑️ AuthProvider: Starting account deletion...');
      
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'No user logged in';
      }
      
      final userId = user.uid;
      print('📧 Deleting account for user: $userId');
      
      await _authService.deleteAccount();
      
      _user = null;
      _isAdminMode = false;
      _isGuestMode = false;
      _profileImageNotifier.value = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.remove('userEmail');
      await prefs.setBool('isLoggedIn', false);
      await prefs.setBool('isAdmin', false);
      await prefs.setBool('isGuestMode', false);
      await prefs.remove('selected_tab_index');
      await prefs.remove('user_location');
      await prefs.remove('user_latitude');
      await prefs.remove('user_longitude');
      
      notifyListeners();
      
      print('✅ AuthProvider: Account deleted successfully');
    } catch (e) {
      _error = e.toString();
      print('❌ AuthProvider error deleting account: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
*/

/* Future<void> deleteAccount(BuildContext context) async {
  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_bangladeshGreen, _bangladeshRed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(
              'Deleting your account...',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  
  try {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    print('🗑️ AuthProvider: Starting account deletion...');
    
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw 'No user logged in';
    }
    
    final userId = user.uid;
    print('📧 Deleting account for user: $userId');
    
    await _authService.deleteAccount();
    
    _user = null;
    _isAdminMode = false;
    _isGuestMode = false;
    _profileImageNotifier.value = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userEmail');
    await prefs.setBool('isLoggedIn', false);
    await prefs.setBool('isAdmin', false);
    await prefs.setBool('isGuestMode', false);
    await prefs.remove('selected_tab_index');
    await prefs.remove('user_location');
    await prefs.remove('user_latitude');
    await prefs.remove('user_longitude');
    
    notifyListeners();
    
    print('✅ AuthProvider: Account deleted successfully');
    
    // Close loading dialog
    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate to login screen after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  } catch (e) {
    _error = e.toString();
    print('❌ AuthProvider error deleting account: $e');
    
    // Close loading dialog
    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: _bangladeshRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

*/

Future<void> deleteAccount(BuildContext context) async {
  // Store the dialog context separately
  BuildContext? dialogContext;
  
  // Show loading dialog and store its context
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      dialogContext = ctx;
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_bangladeshGreen, _bangladeshRed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Text(
                'Deleting your account...',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  
  try {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    print('🗑️ AuthProvider: Starting account deletion...');
    
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw 'No user logged in';
    }
    
    final userId = user.uid;
    print('📧 Deleting account for user: $userId');
    
    await _authService.deleteAccount();
    
    _user = null;
    _isAdminMode = false;
    _isGuestMode = false;
    _profileImageNotifier.value = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userEmail');
    await prefs.setBool('isLoggedIn', false);
    await prefs.setBool('isAdmin', false);
    await prefs.setBool('isGuestMode', false);
    await prefs.remove('selected_tab_index');
    await prefs.remove('user_location');
    await prefs.remove('user_latitude');
    await prefs.remove('user_longitude');
    
    notifyListeners();
    
    print('✅ AuthProvider: Account deleted successfully');
    
    // Close loading dialog using the stored dialog context
    if (dialogContext != null && dialogContext!.mounted) {
      Navigator.pop(dialogContext!);
    }
    
    // Show success message using the original context
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Small delay for snackbar to show
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (context.mounted) {
        // Navigate to login screen and clear all history
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  } catch (e) {
    _error = e.toString();
    print('❌ AuthProvider error deleting account: $e');
    
    // Close loading dialog using the stored dialog context
    if (dialogContext != null && dialogContext!.mounted) {
      Navigator.pop(dialogContext!);
    }
    
    // Show error message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: _bangladeshRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
  Future<void> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _authService.resetPassword(email);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> sendVerificationEmail() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _authService.sendEmailVerification();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> checkEmailVerification() async {
    try {
      return await _authService.checkEmailVerification();
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> checkCurrentAuthStatus() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final userData = await _firestoreService.getUser(user.uid);
        if (userData != null) {
          _user = userData;
          _profileImageNotifier.value = _user?.profileImageUrl;
          _isAdminMode = userData.isAdmin;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking auth status: $e');
      return false;
    }
  }
  
  Future<void> checkEmailVerificationOnStartup() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
        if (user.emailVerified) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .update({
                'isEmailVerified': true,
                'updatedAt': FieldValue.serverTimestamp(),
              });
          
          if (_user != null) {
            _user = _user!.copyWith(isEmailVerified: true);
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('Error checking verification on startup: $e');
    }
  }
  
  Future<bool> checkAndSyncEmailVerification(String userId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
        final isVerified = user.emailVerified;
        
        if (isVerified) {
          await _firestore
              .collection('users')
              .doc(userId)
              .update({
                'isEmailVerified': true,
                'updatedAt': FieldValue.serverTimestamp(),
              });
          
          if (_user != null) {
            _user = _user!.copyWith(isEmailVerified: true);
            notifyListeners();
          }
          
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking verification status: $e');
      return false;
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _profileImageNotifier.dispose();
    super.dispose();
  }
}