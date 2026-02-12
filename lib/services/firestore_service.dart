import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'dart:convert';


class FirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  //final FirebaseStorage _storage;  // Add this

  FirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    //FirebaseStorage? storage,  // Add this
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
        //_storage = storage ?? FirebaseStorage.instance;  // Add this

  // Add these getters
  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;
  //FirebaseStorage get storage => _storage;


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


  /// CHANGE USERNAME
/// Updates username in both users and usernames collections
Future<bool> changeUsername({
  required String newUsername,
  required BuildContext context,
}) async {
  print('========================================');
  print('FirestoreService.changeUsername called');
  print('========================================');
  
  try {
    final user = _auth.currentUser;
    
    if (user == null) {
      print('No user logged in');
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

    final uid = user.uid;
    print('User UID: $uid');
    print('New username: $newUsername');
    
    // Step 1: Check if new username is available
    print('Step 1: Checking username availability...');
    final usernameDoc = await _firestore
        .collection('usernames')
        .doc(newUsername.toLowerCase())
        .get();
    
    if (usernameDoc.exists) {
      print('Username already taken');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Username is already taken"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
    print('Username is available');
    
    // Step 2: Get current username from user document
    print('Step 2: Getting current username...');
    final userDoc = await _firestore
        .collection('users')
        .doc(uid)
        .get();
    
    final currentUsername = userDoc.data()?['username'] as String?;
    print('Current username: $currentUsername');
    
    // Step 3: Update using batch write for atomicity
    print('Step 3: Updating username in Firestore...');
    final batch = _firestore.batch();
    
    // Update username in users collection
  batch.set(
  _firestore.collection('users').doc(uid),
  {
    'username': newUsername,
    'updatedAt': FieldValue.serverTimestamp(),
  },
  SetOptions(merge: true),
);

    
    // Add new username mapping
    batch.set(
      _firestore.collection('usernames').doc(newUsername.toLowerCase()),
      {
        'email': user.email,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    
    // Delete old username mapping if it exists
    if (currentUsername != null && currentUsername.isNotEmpty) {
      batch.delete(
        _firestore.collection('usernames').doc(currentUsername.toLowerCase()),
      );
    }
    
    await batch.commit();
    print('Username updated successfully');
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username updated successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    return true;
    
  } on FirebaseException catch (e) {
    print('========================================');
    print('FirebaseException: ${e.code}');
    print('Message: ${e.message}');
    print('========================================');
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.message}"),
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
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    
    return false;
  }
}

/// CHANGE EMAIL
/// Updates email in Firebase Auth, Firestore, and requires re-authentication
 /// CHANGE EMAIL - FIXED VERSION
  Future<bool> changeEmail({
    required String currentPassword,
    required String newEmail,
    required BuildContext context,
  }) async {
    print('FirestoreService.changeEmail called');
    
    try {
      final user = _auth.currentUser;
      
      if (user == null || user.email == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No user logged in"), backgroundColor: Colors.red),
          );
        }
        return false;
      }

      final uid = user.uid;
      final oldEmail = user.email!;
      
      // Validate email
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(newEmail)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid email format"), backgroundColor: Colors.red),
          );
        }
        return false;
      }
      
      if (newEmail.toLowerCase() == oldEmail.toLowerCase()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("This is already your current email"), backgroundColor: Colors.orange),
          );
        }
        return false;
      }
      
      // Get username before signing out
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final username = userDoc.data()?['username'] as String?;
      
      // Sign out and re-authenticate
      await _auth.signOut();
      
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: oldEmail,
        password: currentPassword,
      ).timeout(const Duration(seconds: 15));
      
      // Update email in Firebase Auth
      await userCred.user!.verifyBeforeUpdateEmail(newEmail).timeout(
  const Duration(seconds: 15),
);

      // Send verification email
      await userCred.user!.sendEmailVerification();
      
      // Update Firestore
      final batch = _firestore.batch();
      
      batch.update(
        _firestore.collection('users').doc(uid),
        {
          'email': newEmail,
          'emailVerified': false,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      
      if (username != null && username.isNotEmpty) {
        batch.update(
          _firestore.collection('usernames').doc(username.toLowerCase()),
          {
            'email': newEmail,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }
      
      await batch.commit();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Verification email sent to $newEmail"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
      return true;
      
    } on FirebaseAuthException catch (e) {
      String msg = "Failed to change email";
      
      switch (e.code) {
        case "wrong-password":
        case "invalid-credential":
          msg = "Current password is incorrect";
          break;
        case "email-already-in-use":
          msg = "This email is already in use";
          break;
        case "invalid-email":
          msg = "Invalid email format";
          break;
        default:
          msg = e.message ?? "An error occurred";
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }

/// UPDATE DISPLAY NAME
  Future<bool> updateDisplayName({
    required String displayName,
    required BuildContext context,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await user.updateDisplayName(displayName);
      
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Display name updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }


 /// UPDATE PROFILE PICTURE - Upload to Firebase Storage

Future<String> updateProfilePicture(
  String uid,
  String imagePath,
) async {
  try {
    final file = File(imagePath);

    final bytes = await file.readAsBytes();

    String base64Image = base64Encode(bytes);

    await _firestore.collection('users').doc(uid).update({
      'profilePicture': base64Image,
    });

    return base64Image;
  } catch (e) {
    print("Upload error: $e");
    rethrow;
  }
}



/// GET USER PROFILE DATA
Future<Map<String, dynamic>?> getUserProfile() async {
  try {
    final user = _auth.currentUser;
    
    if (user == null) {
      print('No user logged in');
      return null;
    }

    final uid = user.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    
    if (doc.exists) {
      return doc.data();
    }
    
    return null;
    
  } catch (e) {
    print('Error getting user profile: $e');
    return null;
  }
}



  Future<int> getTodayScreenedCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('homepageData')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    return snapshot.docs.length;
  }
}

}
