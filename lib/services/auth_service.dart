import 'package:bangla_hub/constants/app_constants.dart';
import 'package:bangla_hub/models/user_model.dart';
import 'package:bangla_hub/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Hardcoded admin credentials
  static const String adminEmail = 'admin@gmail.com';
  static const String adminPassword = '12345678';

  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required UserModel userData,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        // Send email verification
      //  await result.user!.sendEmailVerification();
        
        // Update userData with Firebase UID
        final updatedUserData = userData.copyWith(id: result.user!.uid);
        
        // Create user in Firestore
        await _firestoreService.createUser(updatedUserData);
        
        return result.user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw AppConstants.errorEmailInUse;
      } else if (e.code == 'weak-password') {
        throw AppConstants.errorWeakPassword;
      } else if (e.code == 'too-many-requests') {
        throw 'Too many attempts. Please try again later.';
      } else {
        throw AppConstants.errorGeneric;
      }
    } catch (e) {
      throw AppConstants.errorGeneric;
    }
  }



  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Check if admin login
      if (email == adminEmail && password == adminPassword) {
        // For admin, we need to check if admin exists in Firestore
        // If not, create admin user (only once)
        final adminQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: adminEmail)
            .limit(1)
            .get();
        
        if (adminQuery.docs.isEmpty) {
          // Create admin user
          final adminUser = UserModel(
            id: 'admin_${DateTime.now().millisecondsSinceEpoch}',
            email: adminEmail,
            firstName: 'Admin',
            lastName: 'User',
            role: 'admin',
            isEmailVerified: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await _firestoreService.createUser(adminUser);
        }
        
        // Return null user for admin (we'll handle admin auth differently)
        return null;
      }
      
      // Regular user login
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = result.user;
      
      // CRITICAL FIX: Check email verification BEFORE returning user
      
  /*    if (user != null && !user.emailVerified) {
        // Send verification email if not already sent recently
        try {
          await user.sendEmailVerification();
        } catch (e) {
          print('Could not send verification email: $e');
          // Continue anyway - email might have been sent recently
        }
        
        // IMPORTANT: Sign out immediately to prevent access
        await _auth.signOut();
        
        // Throw specific error that UI can catch
        throw 'EMAIL_NOT_VERIFIED:${user.uid}:$email';
      }  */
      
      return user;
    } on FirebaseAuthException catch (e) {
      // Firebase auth errors
      switch (e.code) {
        case 'user-not-found':
          throw 'No account found for this email. Please sign up first.';
        case 'wrong-password':
          throw 'Incorrect password. Please try again.';
        case 'user-disabled':
          throw 'Your account has been disabled. Contact support.';
        case 'too-many-requests':
          throw 'Too many login attempts. Try again later.';
        case 'invalid-credential':
          throw 'Invalid email or password.';
        case 'invalid-email':
          throw 'Please enter a valid email address.';
        case 'user-mismatch':
          throw 'Invalid credentials.';
        case 'requires-recent-login':
          throw 'Please log in again to continue.';
        default:
          throw 'Login failed. ${e.message}';
      }
    } catch (e) {
      if (e.toString().startsWith('EMAIL_NOT_VERIFIED:')) {
        rethrow; // Pass through to UI layer
      }
      throw 'Login failed. Please try again.';
    }
  }

    Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
      throw AppConstants.errorGeneric;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      // 1️⃣ Check if user exists in Firestore
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw 'No account found with this email';
      }

      // 2️⃣ Send reset email only if user exists
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        throw 'Invalid email address';
      } else {
        throw AppConstants.errorGeneric;
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw 'Failed to send verification email';
    }
  }

  Future<bool> checkEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> syncEmailVerificationStatus(String userId) async {
  try {
    final user = _auth.currentUser;
    if (user != null) {
      // Reload user to get latest verification status
      await user.reload();
      final isVerified = user.emailVerified;
      
      // Update Firestore with the current verification status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
            'isEmailVerified': isVerified,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      return isVerified;
    }
    return false;
  } catch (e) {
    print('Error syncing email verification: $e');
    return false;
  }
}

  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await _firestoreService.getUser(user.uid);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Stream<User?> get userStream => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not logged in';

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw 'Current password is incorrect';
      } else {
        throw AppConstants.errorGeneric;
      }
    } catch (e) {
      throw AppConstants.errorGeneric;
    }
  }

/*  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      throw AppConstants.errorGeneric;
    }
  }  */


  // Add/Replace this method in your AuthService class
Future<void> deleteAccount() async {
  try {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    
    final userId = user.uid;
    print('🗑️ Starting account deletion for user: $userId');
    
    // 1. Delete user document from Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .delete();
    print('✅ User document deleted');
    
    // 2. Delete user's events
    final eventsSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('createdBy', isEqualTo: userId)
        .get();
    
    for (var doc in eventsSnapshot.docs) {
      await doc.reference.delete();
    }
    print('✅ Deleted ${eventsSnapshot.docs.length} events');
    
    // 3. Delete user's interested events subcollection
    final interestedEventsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('interested_events')
        .get();
    
    for (var doc in interestedEventsSnapshot.docs) {
      await doc.reference.delete();
    }
    print('✅ Deleted ${interestedEventsSnapshot.docs.length} interested events');
    
    // 4. Delete user's job postings
    final jobsSnapshot = await FirebaseFirestore.instance
        .collection('job_postings')
        .where('postedBy', isEqualTo: userId)
        .get();
    
    for (var doc in jobsSnapshot.docs) {
      await doc.reference.delete();
    }
    print('✅ Deleted ${jobsSnapshot.docs.length} job postings');
    
    // 5. Delete user's business promotions
    final promotionsSnapshot = await FirebaseFirestore.instance
        .collection('small_business_promotions')
        .where('postedBy', isEqualTo: userId)
        .get();
    
    for (var doc in promotionsSnapshot.docs) {
      await doc.reference.delete();
    }
    print('✅ Deleted ${promotionsSnapshot.docs.length} business promotions');
    
    // 6. Delete user's service provider listings
    final servicesSnapshot = await FirebaseFirestore.instance
        .collection('service_providers')
        .where('userId', isEqualTo: userId)
        .get();
    
    for (var doc in servicesSnapshot.docs) {
      await doc.reference.delete();
    }
    print('✅ Deleted ${servicesSnapshot.docs.length} service provider listings');
    
    // 7. Delete user's business partner requests
    final partnerRequestsSnapshot = await FirebaseFirestore.instance
        .collection('business_partner_requests')
        .where('userId', isEqualTo: userId)
        .get();
    
    for (var doc in partnerRequestsSnapshot.docs) {
      await doc.reference.delete();
    }
    print('✅ Deleted ${partnerRequestsSnapshot.docs.length} business partner requests');
    
    // 8. Delete user's networking business partners
    final networkingSnapshot = await FirebaseFirestore.instance
        .collection('networking_business_partners')
        .where('userId', isEqualTo: userId)
        .get();
    
    for (var doc in networkingSnapshot.docs) {
      await doc.reference.delete();
    }
    print('✅ Deleted ${networkingSnapshot.docs.length} networking business partners');
    
    // 9. Delete user's tutoring services
    final tutoringSnapshot = await FirebaseFirestore.instance
        .collection('tutoring_services')
        .where('userId', isEqualTo: userId)
        .get();
    
    for (var doc in tutoringSnapshot.docs) {
      await doc.reference.delete();
    }
    print('✅ Deleted ${tutoringSnapshot.docs.length} tutoring services');
    
    // 10. Delete user's admissions guidance
    final admissionsSnapshot = await FirebaseFirestore.instance
        .collection('admissions_guidance')
        .where('userId', isEqualTo: userId)
        .get();
    
    for (var doc in admissionsSnapshot.docs) {
      await doc.reference.delete();
    }
    print('✅ Deleted ${admissionsSnapshot.docs.length} admissions guidance entries');
    
    // 11. Delete user's Bangla classes
    final banglaClassesSnapshot = await FirebaseFirestore.instance
        .collection('bangla_classes')
        .where('userId', isEqualTo: userId)
        .get();
    
    for (var doc in banglaClassesSnapshot.docs) {
      await doc.reference.delete();
    }
    print('✅ Deleted ${banglaClassesSnapshot.docs.length} Bangla classes');
    
    // 12. Delete user's sports clubs
    final sportsClubsSnapshot = await FirebaseFirestore.instance
        .collection('sports_clubs')
        .where('userId', isEqualTo: userId)
        .get();
    
    for (var doc in sportsClubsSnapshot.docs) {
      await doc.reference.delete();
    }
    print('✅ Deleted ${sportsClubsSnapshot.docs.length} sports clubs');
    
    // 13. Finally, delete the Firebase Auth account
    await user.delete();
    print('✅ Firebase Auth account deleted');
    
    print('🎉 Account and all associated data deleted successfully');
    
  } on FirebaseAuthException catch (e) {
    print('❌ FirebaseAuth error: ${e.code} - ${e.message}');
    if (e.code == 'requires-recent-login') {
      throw 'For security reasons, please log in again before deleting your account.';
    } else {
      throw 'Failed to delete account: ${e.message}';
    }
  } catch (e) {
    print('❌ Unexpected error: $e');
    throw 'Failed to delete account. Please try again later.';
  }
}

  // Check if user is admin by email
  bool isAdminEmail(String email) {
    return email == adminEmail;
  }

  // Method to resend verification email for specific user
  Future<void> resendVerificationEmail(String email, String password) async {
    try {
      // First sign in the user
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        // Send verification email
        await result.user!.sendEmailVerification();
        
        // Sign out immediately after sending
        await _auth.signOut();
      }
    } catch (e) {
      rethrow;
    }
  }
}