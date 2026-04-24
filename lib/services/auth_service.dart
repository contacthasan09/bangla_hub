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

// In AuthService - Update signUpWithEmail

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
      // ✅ SEND EMAIL VERIFICATION
      await result.user!.sendEmailVerification();
      print('📧 Verification email sent to: $email');
      
      // Update userData with Firebase UID
      final updatedUserData = userData.copyWith(
        id: result.user!.uid,
        isEmailVerified: false,
      );
      
      // Create user in Firestore
      await _firestoreService.createUser(updatedUserData);
      print('📧 User created in Firestore with isEmailVerified: false');
      
    
      
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




// In AuthService.dart - Corrected method without fetchSignInMethodsForEmail

Future<User?> signInWithEmail({
  required String email,
  required String password,
}) async {
  try {
    // Check if admin login
    if (email == adminEmail && password == adminPassword) {
      final adminQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: adminEmail)
          .limit(1)
          .get();
      
      if (adminQuery.docs.isEmpty) {
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
      return null;
    }
    
    // Regular user login
    final UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final User? user = result.user;
    
    if (user != null) {
      await user.reload();
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📧 EMAIL VERIFICATION CHECK');
      print('📧 Email: $email');
      print('📧 Firebase Auth Verified: ${user.emailVerified}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // ✅ Check email verification - but DON'T sign out
      if (!user.emailVerified) {
        print('❌ Email not verified - user will be shown verification screen');
        
        // Try to send verification email (if not rate limited)
        try {
          await user.sendEmailVerification();
          print('📧 Verification email sent to: $email');
        } catch (emailError) {
          print('⚠️ Could not send verification email: $emailError');
          // Don't throw, just continue - user can resend later
        }
        
        // ✅ IMPORTANT: Return the user even if email not verified
        // Don't sign out - keep user logged in
        return user;
      }
      
      // Check if user exists in Firestore
      final userData = await _firestoreService.getUser(user.uid);
      if (userData == null) {
        print('❌ User not found in Firestore');
        await _auth.signOut();
        throw 'Account data not found. Please contact support.';
      }
      
      // Update Firestore if needed
      if (!userData.isEmailVerified && user.emailVerified) {
        print('📧 Updating Firestore isEmailVerified to true');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'isEmailVerified': true,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }
      
      print('✅ Login successful');
    }
    
    return user;
  } on FirebaseAuthException catch (e) {
    print('❌ FirebaseAuth error: ${e.code}');
    
    // Handle too-many-requests
    if (e.code == 'too-many-requests') {
      throw 'Too many attempts. Please try again later.';
    }
    
    switch (e.code) {
      case 'user-not-found':
        throw 'No account found for this email. Please sign up first.';
      case 'wrong-password':
        throw 'Incorrect password. Please try again.';
      case 'user-disabled':
        throw 'Your account has been disabled. Contact support.';
      case 'invalid-credential':
        throw 'Invalid email or password.';
      case 'invalid-email':
        throw 'Please enter a valid email address.';
      default:
        throw 'Login failed: ${e.message}';
    }
  } catch (e) {
    print('❌ General error: $e');
    if (e.toString() == 'EMAIL_NOT_VERIFIED') {
      rethrow;
    }
    throw e.toString();
  }
}










Future<bool> checkRealEmailVerificationStatus(String email) async {
  try {
    // This will show the actual status from Firebase Auth
    final user = _auth.currentUser;
    if (user != null && user.email == email) {
      await user.reload();
      print('🔍 REAL EMAIL VERIFICATION STATUS: ${user.emailVerified}');
      print('🔍 User UID: ${user.uid}');
      print('🔍 User Email: ${user.email}');
      return user.emailVerified;
    }
    return false;
  } catch (e) {
    print('❌ Error checking verification: $e');
    return false;
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



/* Future<void> deleteAccount() async {
  try {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    
    final userId = user.uid;
    print('🗑️ Starting account deletion for user: $userId');
    
    // Show loading indicator (handled by UI)
    
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

*/


/* Future<void> deleteAccount({String? password}) async {
  try {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    
    final userId = user.uid;
    print('🗑️ Starting account deletion for user: $userId');
    
    // ✅ Re-authenticate user if password is provided
    if (password != null && user.email != null) {
      try {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        print('✅ User re-authenticated successfully');
      } on FirebaseAuthException catch (e) {
        print('❌ Re-authentication failed: ${e.code}');
        if (e.code == 'wrong-password') {
          throw 'wrong-password';
        } else if (e.code == 'invalid-credential') {
          throw 'invalid-credential';
        } else {
          throw 'Please enter your current password to delete your account.';
        }
      } catch (e) {
        print('❌ Re-authentication failed: $e');
        throw 'Please enter your current password to delete your account.';
      }
    }
    
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
    } else if (e.code == 'wrong-password') {
      throw 'wrong-password';
    } else if (e.code == 'invalid-credential') {
      throw 'invalid-credential';
    } else {
      throw 'Failed to delete account: ${e.message}';
    }
  } catch (e) {
    print('❌ Unexpected error: $e');
    if (e.toString() == 'wrong-password') {
      rethrow;
    }
    if (e.toString() == 'invalid-credential') {
      rethrow;
    }
    throw 'Failed to delete account. Please try again later.';
  }
}
 
 */


Future<void> deleteAccount({String? password}) async {
  try {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    
    final userId = user.uid;
    print('🗑️ Starting account deletion for user: $userId');
    
    // ✅ Re-authenticate user if password is provided
    if (password != null && user.email != null) {
      try {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        print('✅ User re-authenticated successfully');
      } on FirebaseAuthException catch (e) {
        print('❌ Re-authentication failed: ${e.code}');
        if (e.code == 'wrong-password') {
          throw 'wrong-password';
        } else if (e.code == 'invalid-credential') {
          throw 'invalid-credential';
        } else {
          throw 'Please enter your current password to delete your account.';
        }
      } catch (e) {
        print('❌ Re-authentication failed: $e');
        throw 'Please enter your current password to delete your account.';
      }
    }
    
    // 1. Mark user document as deleted (instead of deleting)
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
          'isActive': false,
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
          'email': '[deleted_${userId.substring(0, 8)}]',
          'firstName': '[Deleted User]',
          'lastName': '',
          'phoneNumber': null,
          'location': null,
          'profileImageUrl': null,
        });
    print('✅ User document marked as deleted');
    
    // 2. Mark user's events as deleted
    final eventsSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('createdBy', isEqualTo: userId)
        .get();
    
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in eventsSnapshot.docs) {
      final eventRef = FirebaseFirestore.instance.collection('events').doc(doc.id);
      batch.update(eventRef, {
        'status': 'deleted',
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    print('✅ Marked ${eventsSnapshot.docs.length} events as deleted');
    
    // 3. Mark user's interested events
    final interestedEventsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('interested_events')
        .get();
    
    final interestedBatch = FirebaseFirestore.instance.batch();
    for (var doc in interestedEventsSnapshot.docs) {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('interested_events')
          .doc(doc.id);
      interestedBatch.delete(ref);
    }
    await interestedBatch.commit();
    print('✅ Deleted ${interestedEventsSnapshot.docs.length} interested events');
    
    // 4. Mark user's job postings as deleted
    final jobsSnapshot = await FirebaseFirestore.instance
        .collection('job_postings')
        .where('postedBy', isEqualTo: userId)
        .get();
    
    final jobsBatch = FirebaseFirestore.instance.batch();
    for (var doc in jobsSnapshot.docs) {
      jobsBatch.update(doc.reference, {
        'isDeleted': true,
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    }
    await jobsBatch.commit();
    print('✅ Marked ${jobsSnapshot.docs.length} job postings as deleted');
    
    // 5. Mark user's business promotions
    final promotionsSnapshot = await FirebaseFirestore.instance
        .collection('small_business_promotions')
        .where('postedBy', isEqualTo: userId)
        .get();
    
    final promotionsBatch = FirebaseFirestore.instance.batch();
    for (var doc in promotionsSnapshot.docs) {
      promotionsBatch.update(doc.reference, {
        'isDeleted': true,
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    }
    await promotionsBatch.commit();
    print('✅ Marked ${promotionsSnapshot.docs.length} business promotions as deleted');
    
    // 6. Mark user's service provider listings
    final servicesSnapshot = await FirebaseFirestore.instance
        .collection('service_providers')
        .where('createdBy', isEqualTo: userId)
        .get();
    
    final servicesBatch = FirebaseFirestore.instance.batch();
    for (var doc in servicesSnapshot.docs) {
      servicesBatch.update(doc.reference, {
        'isDeleted': true,
        'isAvailable': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    }
    await servicesBatch.commit();
    print('✅ Marked ${servicesSnapshot.docs.length} service provider listings as deleted');
    
    // 7. Mark user's business partner requests
    final partnerRequestsSnapshot = await FirebaseFirestore.instance
        .collection('business_partner_requests')
        .where('createdBy', isEqualTo: userId)
        .get();
    
    final partnerBatch = FirebaseFirestore.instance.batch();
    for (var doc in partnerRequestsSnapshot.docs) {
      partnerBatch.update(doc.reference, {
        'isDeleted': true,
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    }
    await partnerBatch.commit();
    print('✅ Marked ${partnerRequestsSnapshot.docs.length} business partner requests as deleted');
    
    // 8. Mark user's networking business partners
    final networkingSnapshot = await FirebaseFirestore.instance
        .collection('networking_business_partners')
        .where('createdBy', isEqualTo: userId)
        .get();
    
    final networkingBatch = FirebaseFirestore.instance.batch();
    for (var doc in networkingSnapshot.docs) {
      networkingBatch.update(doc.reference, {
        'isDeleted': true,
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    }
    await networkingBatch.commit();
    print('✅ Marked ${networkingSnapshot.docs.length} networking business partners as deleted');
    
    // 9. Mark user's tutoring services
    final tutoringSnapshot = await FirebaseFirestore.instance
        .collection('tutoring_services')
        .where('createdBy', isEqualTo: userId)
        .get();
    
    final tutoringBatch = FirebaseFirestore.instance.batch();
    for (var doc in tutoringSnapshot.docs) {
      tutoringBatch.update(doc.reference, {
        'isDeleted': true,
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    }
    await tutoringBatch.commit();
    print('✅ Marked ${tutoringSnapshot.docs.length} tutoring services as deleted');
    
    // 10. Mark user's admissions guidance
    final admissionsSnapshot = await FirebaseFirestore.instance
        .collection('admissions_guidance')
        .where('createdBy', isEqualTo: userId)
        .get();
    
    final admissionsBatch = FirebaseFirestore.instance.batch();
    for (var doc in admissionsSnapshot.docs) {
      admissionsBatch.update(doc.reference, {
        'isDeleted': true,
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    }
    await admissionsBatch.commit();
    print('✅ Marked ${admissionsSnapshot.docs.length} admissions guidance entries as deleted');
    
    // 11. Mark user's Bangla classes
    final banglaClassesSnapshot = await FirebaseFirestore.instance
        .collection('bangla_classes')
        .where('createdBy', isEqualTo: userId)
        .get();
    
    final banglaBatch = FirebaseFirestore.instance.batch();
    for (var doc in banglaClassesSnapshot.docs) {
      banglaBatch.update(doc.reference, {
        'isDeleted': true,
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    }
    await banglaBatch.commit();
    print('✅ Marked ${banglaClassesSnapshot.docs.length} Bangla classes as deleted');
    
    // 12. Mark user's sports clubs
    final sportsClubsSnapshot = await FirebaseFirestore.instance
        .collection('sports_clubs')
        .where('createdBy', isEqualTo: userId)
        .get();
    
    final sportsBatch = FirebaseFirestore.instance.batch();
    for (var doc in sportsClubsSnapshot.docs) {
      sportsBatch.update(doc.reference, {
        'isDeleted': true,
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    }
    await sportsBatch.commit();
    print('✅ Marked ${sportsClubsSnapshot.docs.length} sports clubs as deleted');
    
    // 13. Finally, delete the Firebase Auth account
    await user.delete();
    print('✅ Firebase Auth account deleted');
    
    print('🎉 Account and all associated data marked as deleted successfully');
    
  } on FirebaseAuthException catch (e) {
    print('❌ FirebaseAuth error: ${e.code} - ${e.message}');
    if (e.code == 'requires-recent-login') {
      throw 'For security reasons, please log in again before deleting your account.';
    } else if (e.code == 'wrong-password') {
      throw 'wrong-password';
    } else if (e.code == 'invalid-credential') {
      throw 'invalid-credential';
    } else {
      throw 'Failed to delete account: ${e.message}';
    }
  } catch (e) {
    print('❌ Unexpected error: $e');
    if (e.toString() == 'wrong-password') {
      rethrow;
    }
    if (e.toString() == 'invalid-credential') {
      rethrow;
    }
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