import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:lumasdang/services/local_db_service.dart';
import 'package:lumasdang/services/auth_service.dart';
import 'dart:io';

class FirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final AuthService _authService;

  FirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    AuthService? authService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _authService = authService ?? AuthService();

  /// ================= Change Password =================
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required BuildContext context,
  }) async {
    debugPrint('FirestoreService.changePassword started');
    try {
      // Initialize LocalDbService if not already initialized
      debugPrint('Initializing LocalDbService...');
      await LocalDbService.instance.init();
      debugPrint('LocalDbService initialized');

      // Validate new password
      debugPrint('Validating new password...');
      final passwordError = _authService.validatePassword(newPassword);
      if (passwordError != null) {
        debugPrint('Password validation failed: $passwordError');
        throw Exception(passwordError);
      }
      debugPrint('Password validation passed');

      // Re-authenticate user
      debugPrint('Re-authenticating user...');
      await _authService.reauthenticate(currentPassword);
      debugPrint('User re-authenticated successfully');

      // Update password in Firebase Auth
      debugPrint('Updating password in Firebase Auth...');
      await _authService.changePassword(newPassword);
      debugPrint('Password updated in Firebase Auth');

      // Update password in Hive local DB (if needed for session)
      debugPrint('Updating local cache...');
      await LocalDbService.instance.setUserInfo('last_password_change', DateTime.now().toIso8601String());
      debugPrint('Local cache updated');

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password successfully updated"),
            backgroundColor: Colors.green,
          ),
        );
      }
      debugPrint('Change password completed successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      String message = "Password update failed";
      if (e.code == 'wrong-password') message = "Current password is incorrect";
      if (e.code == 'weak-password') message = "New password is too weak";
      if (e.code == 'requires-recent-login') message = "Please log in again and try";

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('General exception in changePassword: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error occurred: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  /// ================= Profile Management =================

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? email,
    String? photoURL,
    BuildContext? context,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user found',
      );
    }

    try {
      // Initialize LocalDbService if not already initialized
      await LocalDbService.instance.init();

      // Update Firebase Auth profile
      await _authService.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );

      // Update Firestore document
      final userData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) userData['displayName'] = displayName;
      if (email != null) userData['email'] = email;
      if (photoURL != null) userData['photoURL'] = photoURL;

      await _firestore.collection('users').doc(user.uid).set(
        userData,
        SetOptions(merge: true),
      );

      // Update local cache
      if (displayName != null) {
        await LocalDbService.instance.setUserInfo('displayName', displayName);
      }
      if (email != null) {
        await LocalDbService.instance.setUserInfo('email', email);
      }
      if (photoURL != null) {
        await LocalDbService.instance.setUserInfo('photoURL', photoURL);
      }

      // Show success message
      if (context?.mounted == true) {
        ScaffoldMessenger.of(context!).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Profile update failed";
      if (e.code == 'email-already-in-use') message = "Email is already in use";
      if (e.code == 'invalid-email') message = "Invalid email address";

      if (context?.mounted == true) {
        ScaffoldMessenger.of(context!).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    } catch (e) {
      if (context?.mounted == true) {
        ScaffoldMessenger.of(context!).showSnackBar(
          SnackBar(
            content: Text("An error occurred: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  /// ================= Image Upload =================

  // Upload profile image to Firebase Storage
  Future<String> uploadProfileImage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user found',
      );
    }

    try {
      // Create a reference to the profile image
      final storageRef = _storage
          .ref()
          .child('users')
          .child(user.uid)
          .child('profile')
          .child('profile_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Upload the file
      final uploadTask = await storageRef.putFile(imageFile);

      // Get download URL
      final downloadURL = await uploadTask.ref.getDownloadURL();
      
      return downloadURL;
    } on FirebaseException catch (e) {
      debugPrint('Storage error: ${e.code} - ${e.message}');
      throw Exception('Failed to upload image: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected upload error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete old profile image
  Future<void> deleteOldProfileImage(String? oldImageUrl) async {
    if (oldImageUrl == null || oldImageUrl.isEmpty) return;

    try {
      final ref = _storage.refFromURL(oldImageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting old profile image: $e');
      // Don't throw here, as this is not critical
    }
  }

  /// ================= Existing Methods =================

  Future<String> saveHomePageData(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user found',
      );
    }

    final uid = user.uid;
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('homepageData')
        .doc(); // auto id

    final payload = {
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'ownerUid': uid,
    };

    await docRef.set(payload);
    return docRef.id;
  }

  /// Soft delete user: marks all user's records as deleted
  Future<void> softDeleteUser(String uid) async {
    final userDoc = _firestore.collection('users').doc(uid);

    // Soft delete all documents in "homepageData" subcollection
    final snapshot = await userDoc.collection('homepageData').get();
    for (var doc in snapshot.docs) {
      await doc.reference.update({'isDeleted': true});
    }

    // Optionally, mark the user document itself as deleted
    await userDoc.set({'isDeleted': true}, SetOptions(merge: true));
  }
}
