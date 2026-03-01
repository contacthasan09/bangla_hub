import 'dart:convert';
import 'dart:io';
import 'package:bangla_hub/models/user_model.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/user_app/home_screen.dart';
import 'package:bangla_hub/screens/user_app/welcome_screen.dart';
import 'package:bangla_hub/services/auth_service.dart';
import 'package:bangla_hub/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAdminMode = false;
  
  // Colors for dialogs
  final Color _bangladeshGreen = Color(0xFF006A4E);
  final Color _bangladeshRed = Color(0xFFF42A41);
  
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdminMode => _isAdminMode;
  bool get isLoggedIn => _user != null;
  
  // Add userStream getter for auth state changes
  Stream<User?> get userStream => _firebaseAuth.authStateChanges();
  
  AuthProvider() {
    _loadStoredUser();
    _setupAuthListener();
  }
  
  // Set up auth state listener
  void _setupAuthListener() {
    userStream.listen((User? firebaseUser) {
      if (firebaseUser != null) {
        // Firebase user is logged in, load user data from Firestore
        _loadUserData(firebaseUser.uid);
      } else {
        // Firebase user logged out
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
      
      if (isLoggedIn) {
        final userId = prefs.getString('userId');
        final isAdmin = prefs.getBool('isAdmin') ?? false;
        
        if (userId != null) {
          _user = await _firestoreService.getUser(userId);
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

  // Add this method to your AuthProvider class

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

      // Check if admin login
      if (email == AuthService.adminEmail && password == AuthService.adminPassword) {
        await _handleAdminLogin(email);
      } else {
        await _handleRegularUserLogin(email, password, context);
      }
    } catch (e) {
      _error = e.toString();
      
      // Check if error is about email verification
    /*  if (e.toString().startsWith('EMAIL_NOT_VERIFIED:')) {
        final parts = e.toString().split(':');
        if (parts.length >= 3) {
          final userId = parts[1];
          final userEmail = parts[2];
          
          // Wait 2 seconds then show verification dialog
          await Future.delayed(Duration(seconds: 2));
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showVerificationRequiredDialog(context, userId, userEmail);
          });  
        }
      }  */
      
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
      // Create admin user if not exists
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
    
    // Store admin session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', _user!.id);
    await prefs.setString('userEmail', email);
    await prefs.setBool('isLoggedIn', true);
    await prefs.setBool('isAdmin', true);
    
    notifyListeners();
  }
  
  Future<void> _handleRegularUserLogin(String email, String password, BuildContext context) async {
    final firebaseUser = await _authService.signInWithEmail(
      email: email,
      password: password,
    );
    
    if (firebaseUser != null) {
      // Get user data from Firestore
      _user = await _firestoreService.getUser(firebaseUser.uid);
      
      if (_user == null) {
        await _authService.signOut();
        throw 'User data not found. Please contact support.';
      }
      
      // CRITICAL: Check Firebase Auth verification status
      // Firebase Auth is the source of truth for email verification
    /*  if (!firebaseUser.emailVerified) {
        await _authService.signOut();
        throw 'EMAIL_NOT_VERIFIED:${firebaseUser.uid}:$email';
      } */
      
      // Update Firestore to sync with Firebase Auth status
    /*  if (!_user!.isEmailVerified) {
        final updatedUser = _user!.copyWith(
          isEmailVerified: true,
          updatedAt: DateTime.now(),
        );
        await _firestoreService.updateUser(updatedUser);
        _user = updatedUser;
      }  */
      
      // Store user session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', firebaseUser.uid);
      await prefs.setString('userEmail', email);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isAdmin', false);
      
      _isAdminMode = false;
      notifyListeners();
    }
  }
  
/*  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String location,
    File? profileImageFile,
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

      // Convert image to base64 if exists
      String? base64Image;
      if (profileImageFile != null) {
        try {
          final bytes = await profileImageFile.readAsBytes();
          base64Image = base64Encode(bytes);
          // Add data URL prefix for web compatibility
          base64Image = 'data:image/jpeg;base64,$base64Image';
        } catch (e) {
          print('Error converting image: $e');
          // Don't throw error, just continue without image
        }
      }

      // Create user data
      final userData = UserModel(
        id: _uuid.v4(),
        email: email,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        location: location,
        profileImageUrl: base64Image,
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

      // Sign up with Firebase Auth
      final firebaseUser = await _authService.signUpWithEmail(
        email: email,
        password: password,
        userData: userData,
      );

      if (firebaseUser != null) {
        _user = userData.copyWith(id: firebaseUser.uid);
        
        // Store user session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', firebaseUser.uid);
        await prefs.setString('userEmail', email);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setBool('isAdmin', false);
        
        _isAdminMode = false;
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _bangladeshGreen,
            content: Text('✅ Account created successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Show verification dialog after a delay
        await Future.delayed(Duration(seconds: 2));
      //  _showVerificationSuccessDialog(context, firebaseUser.uid, email);

        // 👉 NAVIGATE TO REGISTER SCREEN
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const HomeScreen(),
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
  }   */

 // In your AuthProvider class
Future<void> signUp({
  required String email,
  required String password,
  required String firstName,
  required String lastName,
  required String phoneNumber,
  required String location,
  File? profileImageFile,
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

    // Convert image to base64 if exists
    String? base64Image;
    if (profileImageFile != null) {
      try {
        final bytes = await profileImageFile.readAsBytes();
        base64Image = base64Encode(bytes);
        base64Image = 'data:image/jpeg;base64,$base64Image';
      } catch (e) {
        print('Error converting image: $e');
      }
    }

    // Create user data
    final userData = UserModel(
      id: _uuid.v4(),
      email: email,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      location: location,
      profileImageUrl: base64Image,
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

    // Sign up with Firebase Auth
    final firebaseUser = await _authService.signUpWithEmail(
      email: email,
      password: password,
      userData: userData,
    );

    if (firebaseUser != null) {
      _user = userData.copyWith(id: firebaseUser.uid);
      
      // Store user session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', firebaseUser.uid);
      await prefs.setString('userEmail', email);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isAdmin', false);
      
      _isAdminMode = false;
      notifyListeners();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _bangladeshGreen,
          content: Text('✅ Account created successfully!'),
          duration: Duration(seconds: 2),
        ),
      );

      // 👉 NAVIGATE TO WELCOME SCREEN (Instead of HomeScreen)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => WelcomeScreen(
            onComplete: () {
              // After welcome screen, go to HomeScreen
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
          ),
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

    // Validate password requirements
    if (newPassword.length < 8) {
      throw 'Password must be at least 8 characters long';
    }

    // Check if user is logged in
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw 'User not logged in';
    }

    // Re-authenticate user with current password
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

    // Update to new password
    await user.updatePassword(newPassword);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Password updated successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    // Clear all password fieldss
  //  _currentPasswordController.clear();
  //  _newPasswordController.clear();
  //  _confirmPasswordController.clear();

  } catch (e) {
    _error = e.toString();
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}


  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _authService.signOut();
      
      _user = null;
      _isAdminMode = false;
      
      // Clear stored session
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.remove('userEmail');
      await prefs.setBool('isLoggedIn', false);
      await prefs.setBool('isAdmin', false);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
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
  
  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestoreService.updateUser(updatedUser);
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add method to check current authentication status
  Future<bool> checkCurrentAuthStatus() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final userData = await _firestoreService.getUser(user.uid);
        if (userData != null) {
          _user = userData;
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
  
  // NEW: Check email verification on startup
  Future<void> checkEmailVerificationOnStartup() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
        if (user.emailVerified) {
          // Update Firestore if verified
          await _firestore
              .collection('users')
              .doc(user.uid)
              .update({
                'isEmailVerified': true,
                'updatedAt': FieldValue.serverTimestamp(),
              });
          
          // Update local state
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
  
  // NEW: Check and sync email verification
  Future<bool> checkAndSyncEmailVerification(String userId) async {
    try {
      // Check Firebase Auth verification status
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
        final isVerified = user.emailVerified;
        
        if (isVerified) {
          // Update Firestore
          await _firestore
              .collection('users')
              .doc(userId)
              .update({
                'isEmailVerified': true,
                'updatedAt': FieldValue.serverTimestamp(),
              });
          
          // Update local user data
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
  
  // Verification dialog methods
/*  void _showVerificationSuccessDialog(BuildContext context, String userId, String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.verified_user_rounded, color: _bangladeshGreen),
            SizedBox(width: 10),
            Text(
              'Verify Your Email',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎉 Account created successfully!'),
            SizedBox(height: 15),
            Text('A verification link has been sent to:'),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bangladeshGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _bangladeshGreen.withOpacity(0.3)),
              ),
              child: Text(
                email,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(height: 15),
            Text(
              '📨 Please check your inbox and click the verification link to activate your account.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 10),
            Text(
              '⚠️ You must verify your email before logging in.',
              style: TextStyle(fontSize: 14, color: Colors.orange[800]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Navigate to login screen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
            child: Text('Go to Login'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _authService.sendEmailVerification();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: _bangladeshGreen,
                    content: Text('✅ Verification email sent again!'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: _bangladeshRed,
                    content: Text('❌ Failed to send email'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _bangladeshGreen,
            ),
            child: Text('Resend Email'),
          ),
        ],
      ),
    );
  }
  
  void _showVerificationRequiredDialog(BuildContext context, String userId, String email) async {
    // First check current verification status
    final isVerified = await checkAndSyncEmailVerification(userId);
    
    if (isVerified) {
      // If already verified, show success message and return
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _bangladeshGreen,
          content: Text('✅ Email verified! You can now login.'),
          duration: Duration(seconds: 3),
        ),
      );
      
      // Close the dialog if it's open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return;
    }
    
    // If not verified, show the dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.email_rounded, color: _bangladeshGreen),
            SizedBox(width: 10),
            Text('Email Verification Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please verify your email address before logging in.'),
            SizedBox(height: 10),
            Text('Verification link was sent to:'),
            SizedBox(height: 5),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _bangladeshGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(email),
            ),
            SizedBox(height: 10),
            Text('Check your inbox and spam folder.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Get the current user and resend verification
                final user = _firebaseAuth.currentUser;
                if (user != null && user.email == email) {
                  await user.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: _bangladeshGreen,
                      content: Text('✅ Verification email sent!'),
                    ),
                  );
                } else {
                  // If no user is logged in, use the service
                  await _authService.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: _bangladeshGreen,
                      content: Text('✅ Verification email sent!'),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: _bangladeshRed,
                    content: Text('❌ Failed to send email'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _bangladeshGreen,
            ),
            child: Text('Resend Email'),
          ),
        ],
      ),
    );
  }  */
}