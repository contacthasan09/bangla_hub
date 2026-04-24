// providers/auth_provider.dart - Complete updated version

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bangla_hub/main.dart';
import 'package:bangla_hub/models/user_model.dart';
import 'package:bangla_hub/providers/location_filter_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/user_app/home_screen.dart';
import 'package:bangla_hub/screens/user_app/welcome_screen.dart';
import 'package:bangla_hub/services/auth_service.dart';
import 'package:bangla_hub/services/firestore_service.dart';
import 'package:bangla_hub/widgets/common/email_verification_dialog.dart';
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
    bool _isDialogShowing = false;
      bool _isDisposed = false;


    bool _dialogShownFromWrapper = false;
      bool _dialogShown = false;  // ✅ Add this variable


// Add a method to reset dialog flag
void resetDialogFlag() {
  _dialogShownFromWrapper = false;
}

  
  final Color _bangladeshGreen = const Color(0xFF006A4E);
  final Color _bangladeshRed = const Color(0xFFF42A41);
  final Color _bangladeshOrange = const Color(0xFFF39C12); // Orange color

  
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
      _checkEmailVerificationStatus(); // ✅ Add this

  }

  Future<void> _checkEmailVerificationStatus() async {
  await checkEmailVerificationStatus();
}

// In AuthProvider - Add this method

Future<void> checkEmailVerificationStatus() async {
  final user = _firebaseAuth.currentUser;
  if (user != null && _user != null) {
    await user.reload();
    final isVerified = user.emailVerified;
    
    // Update Firestore if needed
    if (_user!.isEmailVerified != isVerified) {
      await _firestore.collection('users').doc(_user!.id).update({
        'isEmailVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _user = _user!.copyWith(isEmailVerified: isVerified);
      notifyListeners();
      
      print('📧 Email verification status updated: $isVerified');
    }
  }
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
 /* Future<void> updateUserProfile(UserModel updatedUser) async {
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


*/


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
    
    // Update Firestore first
    await _firestoreService.updateUser(updatedUser);
    
    // Update local user object
    _user = updatedUser;
    
    // Update profile image notifier
    _profileImageNotifier.value = _user?.profileImageUrl;
    
    // Update Firebase Auth photo URL if changed
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null && updatedUser.profileImageUrl != null) {
      if (_user?.profileImageUrl != updatedUser.profileImageUrl) {
        await firebaseUser.updatePhotoURL(updatedUser.profileImageUrl);
      }
    }
    
    // Only notify listeners if non-image data changed
    // This prevents unnecessary rebuilds for image-only updates
    if (!onlyImageChanged) {
      notifyListeners();
      print('✅ User profile updated (with rebuild)');
    } else {
      print('✅ User profile updated (image only, no rebuild)');
    }
    
  } catch (e) {
    _errorMessage = e.toString();
    print('❌ Error updating user profile: $e');
    rethrow;
  } finally {
    _isLoading = false;
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

// In AuthProvider - Update signIn method

// In AuthProvider - Update signIn method
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
    print('🔴 Login error caught: $e');
    
    if (e.toString() == 'EMAIL_NOT_VERIFIED') {
      _isLoading = false;
      // AuthWrapper will handle showing the dialog
      notifyListeners();
      return;
    }
    
    _isLoading = false;
    notifyListeners();
    rethrow;
  }
  
  _isLoading = false;
  notifyListeners();
}





// In AuthProvider - Update showEmailVerificationDialog

void showEmailVerificationScreen(BuildContext context) {
  final email = _user?.email ?? '';
  if (email.isEmpty) {
    print('❌ Cannot show screen - email is empty');
    return;
  }
  
  print('📧 Navigating to email verification screen for: $email');
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EmailVerificationScreen(
        email: email,
        onVerified: () async {
          // Update local user data
          if (_user != null) {
            _user = _user!.copyWith(isEmailVerified: true);
            await _firestore.collection('users').doc(_user!.id).update({
              'isEmailVerified': true,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          notifyListeners();
          
          // Navigate to home
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        },
      ),
    ),
  );
}


Future<void> _resendVerificationEmail(BuildContext context, String email) async {
  try {
    final user = _firebaseAuth.currentUser;
    if (user != null && user.email == email) {
      await user.sendEmailVerification();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification email resent to $email'),
            backgroundColor: _bangladeshGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please sign in again to resend verification email.'),
            backgroundColor: _bangladeshOrange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend: ${e.toString()}'),
          backgroundColor: _bangladeshRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}




Future<void> checkAndUpdateVerificationStatus() async {
  final user = _firebaseAuth.currentUser;
  if (user != null) {
    await user.reload();
    final isVerified = user.emailVerified;
    
    if (_user != null && _user!.isEmailVerified != isVerified) {
      // Update Firestore
      await _firestore.collection('users').doc(_user!.id).update({
        'isEmailVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _user = _user!.copyWith(isEmailVerified: isVerified);
      notifyListeners();
    }
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
    print('🔵 Attempting login for: $email');
    
    try {
      final firebaseUser = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      
      print('🔵 Firebase user after signIn: ${firebaseUser?.uid ?? 'null'}');
      
      // ✅ If firebaseUser is null, login failed
      if (firebaseUser == null) {
        print('❌ Login failed - user is null');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // ✅ Get user from Firestore
      _user = await _firestoreService.getUser(firebaseUser.uid);
      
      // ✅ Check if user exists in Firestore
      if (_user == null) {
        print('❌ User not found in Firestore - signing out');
        await _authService.signOut();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User data not found. Please contact support.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // ✅ Check email verification status
      await firebaseUser.reload();
      final isEmailVerified = firebaseUser.emailVerified;
      
      print('✅ User found in Firestore: ${_user!.email}');
      print('📧 Email verified status: $isEmailVerified');
      
      // Save to SharedPreferences (do this early for both cases)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', firebaseUser.uid);
      await prefs.setString('userEmail', email);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isAdmin', false);
      await prefs.setBool('isGuestMode', false);
      
      _profileImageNotifier.value = _user?.profileImageUrl;
      _isAdminMode = false;
      _isGuestMode = false;
      
      // ✅ If email is NOT verified - keep user logged in but show verification screen
      if (!isEmailVerified) {
        print('📧 Email not verified - updating Firestore status');
        
        // Update Firestore verification status
        if (_user!.isEmailVerified != isEmailVerified) {
          await _firestore.collection('users').doc(_user!.id).update({
            'isEmailVerified': isEmailVerified,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          _user = _user!.copyWith(isEmailVerified: isEmailVerified);
        }
        
        notifyListeners();
        
        // Show verification screen (AuthWrapper will handle this)
        throw 'EMAIL_NOT_VERIFIED';
      }
      
      // ✅ Email is verified - proceed with normal login
      print('✅ Email verified - proceeding with login');
      
      // Update location in background without blocking
      _updateUserLocation(context);
      
      notifyListeners();
      
      // ✅ Navigate to home screen only if context is still valid
      if (context.mounted) {
        print('✅ Navigation to HomeScreen');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
      
    } catch (e) {
      print('❌ Login error in _handleRegularUserLogin: $e');
      
      // ✅ For EMAIL_NOT_VERIFIED, keep user data and let AuthWrapper handle navigation
      if (e.toString() == 'EMAIL_NOT_VERIFIED') {
        print('📧 EMAIL_NOT_VERIFIED - User will see verification screen');
        notifyListeners();
        rethrow;
      }
      
      // For all other errors, clear user data
      _user = null;
      notifyListeners();
      
      // Show error message only if context is valid
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
    }
  }

  // Helper method to update location in background without using mounted
  Future<void> _updateUserLocation(BuildContext context) async {
    try {
      // Small delay to ensure navigation completes first
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check if context is still valid using context.mounted
      if (!context.mounted) return;
      
      final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
      await locationProvider.getUserLocation();
      
      if (_user != null && locationProvider.currentUserLocation != null) {
        final updatedUser = _user!.copyWith(
          latitude: locationProvider.currentUserLocation!.latitude,
          longitude: locationProvider.currentUserLocation!.longitude,
          lastActiveAt: DateTime.now(),
        );
        await _firestoreService.updateUser(updatedUser);
        _user = updatedUser;
        
        // Only notify if not disposed
        if (!_isDisposed) {
          notifyListeners();
        }
        print('✅ User location updated');
      }
    } catch (e) {
      print('❌ Error updating location: $e');
    }
  }



// Add this helper method to update location in background
/* Future<void> _updateUserLocation(BuildContext context) async {
  try {
    // Small delay to ensure navigation completes first
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!context.mounted) return;
    
    final locationProvider = Provider.of<LocationFilterProvider>(context, listen: false);
    await locationProvider.getUserLocation();
    
    if (_user != null && locationProvider.currentUserLocation != null) {
      final updatedUser = _user!.copyWith(
        latitude: locationProvider.currentUserLocation!.latitude,
        longitude: locationProvider.currentUserLocation!.longitude,
        lastActiveAt: DateTime.now(),
      );
      await _firestoreService.updateUser(updatedUser);
      _user = updatedUser;
      if (mounted) notifyListeners();
      print('✅ User location updated');
    }
  } catch (e) {
    print('❌ Error updating location: $e');
  }
}   */



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

    // ... location code ...

    final userData = UserModel(
      id: _uuid.v4(),
      email: email,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      location: location,
      profileImageUrl: profileImageUrl,
      role: 'user',
      isEmailVerified: false,
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
      print('✅ Account created. Verification email sent to: $email');
      
      // ✅ IMPORTANT: Set the user after signup
      _user = userData.copyWith(id: firebaseUser.uid);
      _profileImageNotifier.value = _user?.profileImageUrl;
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', firebaseUser.uid);
      await prefs.setString('userEmail', email);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isAdmin', false);
      await prefs.setBool('isGuestMode', false);
      
      notifyListeners();
      
      // Close loading dialog
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // ✅ Navigate to EmailVerificationScreen
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(
              email: email,
              onVerified: () async {
                // Update local user data
                if (_user != null) {
                  _user = _user!.copyWith(isEmailVerified: true);
                  await _firestore.collection('users').doc(_user!.id).update({
                    'isEmailVerified': true,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                }
                notifyListeners();
                
                // Navigate to home screen
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              },
            ),
          ),
        );
      }
    }
  } catch (e) {
    _error = e.toString();
    print('❌ Signup error: $e');
    
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    if (context.mounted) {
      String errorMessage = 'Registration failed. Please try again.';
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'Email already in use.';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Password is too weak.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: _bangladeshRed),
      );
    }
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}








Future<void> _showVerificationDialog(BuildContext context, String email) async {
  Completer<void> completer = Completer<void>();
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(Icons.email_rounded, color: _bangladeshGreen, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Verify Your Email',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: _bangladeshGreen,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A verification link has been sent to:',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bangladeshGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                email,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _bangladeshGreen,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please check your email and click the verification link to activate your account.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Check your spam folder if you don\'t see the email.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            // Close the dialog
            Navigator.of(dialogContext).pop();
            completer.complete();
            
            // Reset loading state
            _isLoading = false;
            _isDialogShowing = false;
            notifyListeners();
            
            // Clear any pending user data
            _user = null;
            
            // Navigate back to login screen
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
          child: Text(
            'Back to Login',
            style: TextStyle(color: _bangladeshRed),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            // Close current dialog
            Navigator.of(dialogContext).pop();
            _isDialogShowing = false;
            
            // Resend verification email
            await _resendVerificationEmail(context, email);
            
            // Small delay before showing dialog again
            Future.delayed(const Duration(milliseconds: 500), () {
              // Use the original context, not dialogContext
              if (context.mounted) {
                _showVerificationDialog(context, email);
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _bangladeshGreen,
          ),
          child: const Text('Resend Email'),
        ),
      ],
    ),
  );
  
  return completer.future;
}

// In AuthProvider - Update syncEmailVerificationStatus
Future<void> syncEmailVerificationStatus() async {
  final firebaseUser = _firebaseAuth.currentUser;
  if (firebaseUser != null && _user != null) {
    await firebaseUser.reload();
    final isVerified = firebaseUser.emailVerified;
    
    if (_user!.isEmailVerified != isVerified) {
      // Update Firestore
      await _firestore.collection('users').doc(_user!.id).update({
        'isEmailVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update local user
      _user = _user!.copyWith(isEmailVerified: isVerified);
      notifyListeners();
      
      print('📧 Email verification status synced: $isVerified');
      
      // If now verified, notify user
      if (isVerified) {
        print('🎉 Email verified! User can now access the app.');
      }
    }
  }
}


 
 
/*  Future<void> updatePassword({
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
  
*/


Future<void> updatePassword({
  required String currentPassword,
  required String newPassword,
  required BuildContext context,
}) async {
  try {
    _isLoading = true;
    _error = null;
    // Don't call notifyListeners() here to prevent rebuild
    // notifyListeners(); // REMOVE THIS LINE
    
    // Validation
    if (newPassword.length < 8) {
      throw 'Password must be at least 8 characters long';
    }
    
    if (currentPassword == newPassword) {
      throw 'New password must be different from current password';
    }

    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw 'User not logged in';
    }

    // Re-authenticate user
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    try {
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          throw 'Current password is incorrect';
        case 'user-mismatch':
          throw 'Invalid credentials';
        case 'invalid-credential':
          throw 'Current password is incorrect';
        case 'too-many-requests':
          throw 'Too many failed attempts. Please try again later.';
        case 'network-request-failed':
          throw 'Network error. Please check your connection.';
        default:
          throw 'Authentication failed: ${e.message}';
      }
    }

    // Update password
    await user.updatePassword(newPassword);

    // Only show snackbar if context is still valid
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Password updated successfully!'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    
    print('✅ Password updated successfully');
    
    // Don't call notifyListeners() here either - password change doesn't need UI rebuild
    
  } catch (e) {
    _error = e.toString();
    print('❌ Password update error: $e');
    rethrow;
  } finally {
    _isLoading = false;
    // Don't call notifyListeners() here
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
    
    // Clear any pending auth state
    await Future.delayed(const Duration(milliseconds: 100));
    
    notifyListeners();
    
    print('✅ User signed out completely');
  } catch (e) {
    _error = e.toString();
    print('❌ Sign out error: $e');
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}


/* Future<void> deleteAccount(BuildContext context) async {
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

*/

/* Future<void> deleteAccount(BuildContext context) async {
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
    
    // Perform deletion
    await _authService.deleteAccount();
    
    // Clear local data
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
    
    // ✅ Close loading dialog first
    if (dialogContext != null && dialogContext!.mounted) {
      Navigator.pop(dialogContext!);
      // Small delay to ensure dialog is fully closed
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    // ✅ Check if original context is still valid before showing snackbar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Wait for snackbar to be visible
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // ✅ Navigate to login screen only if context is still valid
    if (context.mounted) {
      // Clear all routes and navigate to login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
    
  } catch (e) {
    _error = e.toString();
    print('❌ AuthProvider error deleting account: $e');
    
    // ✅ Close loading dialog on error
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

*/


Future<void> deleteAccount(BuildContext context, {String? password}) async {
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
    
    // Perform deletion with password for re-authentication
    await _authService.deleteAccount(password: password);
    
    // Clear local data
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
    
    // ✅ Close loading dialog
    if (dialogContext != null && dialogContext!.mounted) {
      Navigator.pop(dialogContext!);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    // ✅ Show success message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // ✅ Navigate to login screen and clear all routes
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
    
  } catch (e) {
    _error = e.toString();
    print('❌ AuthProvider error deleting account: $e');
    
    // Close loading dialog on error
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
        _isDisposed = true;

    _profileImageNotifier.dispose();
    super.dispose();
  }
}