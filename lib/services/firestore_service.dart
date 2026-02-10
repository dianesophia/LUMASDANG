import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Saves a map containing data from HomePage under:
  /// users/{uid}/homepageData/{autoId}
  /// Returns the generated document id on success.
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

  /// SOFT DELETE USER: marks all user's records as deleted
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

  /// CHANGE PASSWORD - Using sign-out/sign-in method (more reliable)
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required BuildContext context,
  }) async {
    print('========================================');
    print('FirestoreService.changePassword called');
    print('========================================');
    
    try {
      final user = _auth.currentUser;
      
      if (user == null || user.email == null) {
        print('No user or email found');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No user logged in"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }

      final email = user.email!;
      print('User email: $email');
      
      // Step 1: Sign out
      print('Step 1: Signing out...');
      await _auth.signOut();
      print('Signed out successfully');
      
      // Step 2: Sign back in with current password to verify it's correct
      print('Step 2: Signing in with current password...');
      UserCredential userCred;
      
      try {
        userCred = await _auth.signInWithEmailAndPassword(
          email: email,
          password: currentPassword,
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Sign-in timed out');
          },
        );
        print('Sign-in successful');
      } catch (e) {
        print('Sign-in failed: $e');
        rethrow;
      }
      
      // Step 3: Update password
      print('Step 3: Updating password...');
      try {
        await userCred.user!.updatePassword(newPassword).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Password update timed out');
          },
        );
        print('Password updated successfully');
      } catch (e) {
        print('Password update failed: $e');
        rethrow;
      }
      
      print('Change password completed successfully');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password updated successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      return true;
      
    } on FirebaseAuthException catch (e) {
      print('========================================');
      print('FirebaseAuthException: ${e.code}');
      print('Message: ${e.message}');
      print('========================================');
      
      String msg = "Failed to change password";
      
      switch (e.code) {
        case "wrong-password":
        case "invalid-credential":
        case "invalid-email":
          msg = "Current password is incorrect";
          break;
        case "weak-password":
          msg = "New password is too weak (minimum 6 characters)";
          break;
        case "network-request-failed":
          msg = "Network error. Please check your internet connection.";
          break;
        case "too-many-requests":
          msg = "Too many attempts. Please try again later.";
          break;
        case "user-not-found":
          msg = "User account not found";
          break;
        default:
          msg = e.message ?? "An error occurred";
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
      return false;
      
    } catch (e) {
      print('========================================');
      print('General exception: $e');
      print('========================================');
      
      String msg = "Error: $e";
      if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
        msg = "Connection timeout. Please check your internet and try again.";
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
      return false;
    }
  }
}