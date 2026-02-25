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
  Future<String> saveHomePageData(Map<String, dynamic> data, {String? docId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user found',
      );
    }

    final uid = user.uid;
    print('FirestoreService.saveHomePageData: called by uid=$uid');
    final docRef = _firestore
      .collection('users')
      .doc(uid)
      .collection('homepageData')
      .doc(docId); // use provided docId or auto-generate when null

    final payload = {
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'ownerUid': uid,
    };

    await docRef.set(payload);
    return docRef.id;
  }

  /// Update an existing homepageData document by document id.
  /// Uses merge so it won't overwrite unrelated fields.
  Future<void> updateHomePageData(String docId, Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user found',
      );
    }

    final uid = user.uid;
    print('FirestoreService.updateHomePageData: called uid=$uid docId=$docId');
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('homepageData')
        .doc(docId);

    final payload = {
      ...data,
      'lastModifiedAt': FieldValue.serverTimestamp(),
      'ownerUid': uid,
    };

    await docRef.set(payload, SetOptions(merge: true));
  }

  /// Saves vaccination status for Profile Overview (keyed by child name).
  Future<void> saveVaccinationStatus({
    required String firstName,
    required String lastName,
    required Map<String, String> statuses,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final key = '${firstName.trim()}_${lastName.trim()}'.toLowerCase();
    if (key == '_') return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('vaccinationStatus')
        .doc(key)
        .set({
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'statuses': statuses,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Returns the current user's barangay ID, or null if not set.
  Future<String?> getCurrentUserBarangayId() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.data()?['barangayId'] as String?;
  }

  /// Returns the current user's barangay display name (e.g. "Barangay Alapang"), or empty string if not set.
  Future<String> getCurrentUserBarangayName() async {
    final user = _auth.currentUser;
    if (user == null) return '';
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final data = userDoc.data();
    final fromUser = data?['barangay'] as String?;
    if (fromUser != null && fromUser.trim().isNotEmpty) return fromUser.trim();
    final barangayId = data?['barangayId'] as String?;
    if (barangayId == null || barangayId.isEmpty) return '';
    final barDoc = await _firestore.collection('barangays').doc(barangayId).get();
    final name = barDoc.data()?['name'] as String?;
    return (name != null && name.trim().isNotEmpty) ? name.trim() : barangayId;
  }

  /// Saves vaccination status to the barangay patient doc so Profile Overview (shared mode) shows it.
  /// Maps home-page status keys to the keys expected by VaccinationStatusSection.
  Future<void> saveVaccinationStatusToBarangayPatient({
    required String barangayId,
    required String patientId,
    required String firstName,
    required String lastName,
    required Map<String, String> statuses,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    // Map home-page keys to profile vaccine keys; default others to Pending
    const profileKeys = [
      'bcg', 'hepatitisB', 'opv', 'ipv', 'dtap', 'hib', 'rotaV', 'pcv', 'mmr',
      'typhoid', 'hepatitisA', 'varicella',
    ];
    final flat = <String, String>{};
    for (final k in profileKeys) {
      flat[k] = 'Pending';
    }
    flat['bcg'] = statuses['bcg'] ?? 'Pending';
    flat['hepatitisB'] = statuses['hepatitisB'] ?? 'Pending';
    flat['dtap'] = statuses['dptPentavalent'] ?? 'Pending';
    flat['opv'] = statuses['opv'] ?? statuses['opvIpv'] ?? 'Pending';
    flat['ipv'] = statuses['ipv'] ?? statuses['opvIpv'] ?? 'Pending';
    flat['mmr'] = statuses['measlesMmr'] ?? 'Pending';
    flat['pcv'] = statuses['pcv'] ?? 'Pending';

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['fullName'] ?? userDoc.data()?['username'] ?? user?.email ?? 'Unknown';

    final ref = _firestore
        .collection('barangays')
        .doc(barangayId)
        .collection('patients')
        .doc(patientId)
        .collection('vaccination')
        .doc('record');

    await ref.set({
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'lastReviewDate': FieldValue.serverTimestamp(),
      'lastModifiedBy': user.uid,
      'lastModifiedByName': userName,
      'updatedAt': FieldValue.serverTimestamp(),
      ...flat,
    }, SetOptions(merge: true));
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


/// Save patient data to barangay-specific patient list
Future<String> savePatientToBarangay(Map<String, dynamic> patientData) async {
  final user = _auth.currentUser;
  if (user == null) {
    throw FirebaseAuthException(
      code: 'no-current-user',
      message: 'No authenticated user found',
    );
  }

  print('💾 Saving patient to barangay...');

   print('💾 Saving patient to barangay...');
  
  // ── ADD THIS BLOCK ──────────────────────────────────────────
  final userDocDebug = await _firestore.collection('users').doc(user.uid).get();
  print('🔍 User UID: ${user.uid}');
  print('🔍 User doc exists: ${userDocDebug.exists}');
  print('🔍 User doc fields: ${userDocDebug.data()?.keys.toList()}');
  print('🔍 barangayId: ${userDocDebug.data()?['barangayId']}');
  // ── END ADD ─────────────────────────────────────────────────
  
  // Get user's barangay
  final userDoc = await _firestore.collection('users').doc(user.uid).get();
  final barangayId = userDoc.data()?['barangayId'] as String?;

  if (barangayId == null || barangayId.isEmpty) {
    print('❌ User has no barangay assigned');
    throw Exception('User has no barangay assigned');
  }

  print('✅ User barangayId: $barangayId');

  // Save patient to barangay's patients collection
  final patientRef = _firestore
      .collection('barangays')
      .doc(barangayId)
      .collection('patients')
      .doc(); // auto-generate ID

  final payload = {
    ...patientData,
    'createdAt': FieldValue.serverTimestamp(),
    'createdBy': user.uid,
    'createdByName': userDoc.data()?['fullName'] ?? userDoc.data()?['username'] ?? 'Unknown',
    'barangayId': barangayId,
    'barangay': userDoc.data()?['barangay'] ?? '',
    'isDeleted': false,  // ← REQUIRED by Firestore rules
    'lastModifiedBy': user.uid,  // ← Add this for future updates
    'lastModifiedAt': FieldValue.serverTimestamp(),
  };

  await patientRef.set(payload);
  print('✅ Patient saved with ID: ${patientRef.id}');
  
  return patientRef.id;
}


/// Get all patients from user's barangay
Future<List<Map<String, dynamic>>> getPatientsFromBarangay() async {
  final user = _auth.currentUser;
  if (user == null) {
    print('❌ No user logged in');
    return [];
  }

  try {
    print('📋 Getting patients from barangay...');
    
    // Get user's barangay
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final barangayId = userDoc.data()?['barangayId'] as String?;

    if (barangayId == null || barangayId.isEmpty) {
      print('❌ User has no barangayId');
      return [];
    }

    print('✅ User barangayId: $barangayId');

    // Get all patients from this barangay (excluding deleted ones)
    final snapshot = await _firestore
        .collection('barangays')
        .doc(barangayId)
        .collection('patients')
        .where('isDeleted', isEqualTo: false)  // ← Filter out deleted patients
        .orderBy('createdAt', descending: true)
        .get();

    print('✅ Found ${snapshot.docs.length} patients');

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    
  } catch (e) {
    print('❌ Error getting patients from barangay: $e');
    return [];
  }
}

/// Get archived patients (5+ years) from user's barangay.
/// Fetches non-deleted patients and filters for isArchived == true.
Future<List<Map<String, dynamic>>> getArchivedPatientsFromBarangay() async {
  final patients = await getPatientsFromBarangay();
  return patients.where((p) => p['isArchived'] == true).toList();
}

/// Get today's screened count from barangay
Future<int> getTodayScreenedCountFromBarangay() async {
  final user = _auth.currentUser;
  if (user == null) {
    print('❌ No user logged in');
    return 0;
  }

  try {
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final barangayId = userDoc.data()?['barangayId'] as String?;

    if (barangayId == null || barangayId.isEmpty) {
      print('❌ No barangayId found');
      return 0;
    }

    print('📊 Counting today\'s screenings for barangayId: $barangayId');

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('barangays')
        .doc(barangayId)
        .collection('patients')
        .where('isDeleted', isEqualTo: false)  // ← Only count non-deleted
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    print('✅ Today\'s count: ${snapshot.docs.length}');
    return snapshot.docs.length;
    
  } catch (e) {
    print('❌ Error counting today\'s screenings: $e');
    return 0;
  }
}

// ============================================================================
// PATIENT ASSESSMENTS - Barangay shared
// ============================================================================

/// Save assessment to barangay patient's assessments subcollection
Future<String> saveAssessmentToBarangayPatient({
  required String patientId,
  required Map<String, dynamic> assessmentData,
}) async {
  final user = _auth.currentUser;
  if (user == null) {
    throw FirebaseAuthException(
      code: 'no-current-user',
      message: 'No authenticated user found',
    );
  }

  // Get user's barangay
  final userDoc = await _firestore.collection('users').doc(user.uid).get();
  final barangayId = userDoc.data()?['barangayId'] as String?;

  if (barangayId == null || barangayId.isEmpty) {
    throw Exception('User has no barangay assigned');
  }

  // Create assessment document
  final assessmentRef = _firestore
      .collection('barangays')
      .doc(barangayId)
      .collection('patients')
      .doc(patientId)
      .collection('assessments')
      .doc(); // auto-generate ID

  final payload = {
    ...assessmentData,
    'createdAt': FieldValue.serverTimestamp(),
    'createdBy': user.uid,
    'createdByName': userDoc.data()?['fullName'] ?? userDoc.data()?['username'] ?? 'Unknown',
    'barangayId': barangayId,
  };

  await assessmentRef.set(payload);
  return assessmentRef.id;
}

/// Get all assessments for a specific patient
Future<List<Map<String, dynamic>>> getAssessmentsForBarangayPatient(String patientId) async {
  final user = _auth.currentUser;
  if (user == null) return [];

  // Get user's barangay
  final userDoc = await _firestore.collection('users').doc(user.uid).get();
  final barangayId = userDoc.data()?['barangayId'] as String?;

  if (barangayId == null) return [];

  // Get all assessments for this patient
  final snapshot = await _firestore
      .collection('barangays')
      .doc(barangayId)
      .collection('patients')
      .doc(patientId)
      .collection('assessments')
      .orderBy('createdAt', descending: false) // ascending for chronological order
      .get();

  return snapshot.docs.map((doc) {
    final data = doc.data();
    data['id'] = doc.id;
    return data;
  }).toList();
}

/// Update an existing assessment
Future<void> updateAssessmentInBarangayPatient({
  required String patientId,
  required String assessmentId,
  required Map<String, dynamic> updatedData,
}) async {
  final user = _auth.currentUser;
  if (user == null) {
    throw FirebaseAuthException(
      code: 'no-current-user',
      message: 'No authenticated user found',
    );
  }

  // Get user's barangay
  final userDoc = await _firestore.collection('users').doc(user.uid).get();
  final barangayId = userDoc.data()?['barangayId'] as String?;

  if (barangayId == null || barangayId.isEmpty) {
    throw Exception('User has no barangay assigned');
  }

  // Update the assessment record
  await _firestore
      .collection('barangays')
      .doc(barangayId)
      .collection('patients')
      .doc(patientId)
      .collection('assessments')
      .doc(assessmentId)
      .update({
    ...updatedData,
    'updatedAt': FieldValue.serverTimestamp(),
    'lastModifiedBy': user.uid,
    'lastModifiedByName': userDoc.data()?['fullName'] ?? userDoc.data()?['username'] ?? 'Unknown',
  });
}

// Add this method to your existing FirestoreService class

// In firestore_service.dart, add this method:
// ============================================================================
// ADD THIS METHOD TO YOUR FirestoreService class
// Replace the existing getRecentAssessments() method with this one
// ============================================================================

Future<List<Map<String, dynamic>>> getRecentAssessments({int limit = 50}) async {
  try {
    print('📋 getRecentAssessments() called');
    
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ No user logged in');
      return [];
    }

    print('✅ User UID: ${user.uid}');
    
    // Get user's barangay
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    
    if (!userDoc.exists) {
      print('❌ User document does not exist');
      return [];
    }
    
    final userData = userDoc.data()!;
    print('📄 User data: $userData');
    
    // Use 'barangayId' field (NOT 'barangay')
    final barangayId = userData['barangayId'] as String?;

    if (barangayId == null || barangayId.isEmpty) {
      print('❌ User has no barangayId assigned');
      print('   Available fields: ${userData.keys.toList()}');
      return [];
    }

    print('✅ User barangayId: $barangayId');

    // Get recent patients from the barangay's patient list
    final querySnapshot = await _firestore
        .collection('barangays')
        .doc(barangayId)
        .collection('patients')
        .where('isDeleted', isEqualTo: false)  // ← Filter out deleted patients
        .orderBy('createdAt', descending: true)  // ← Use 'createdAt' NOT 'timestamp'
        .limit(limit)
        .get();

    print('✅ Found ${querySnapshot.docs.length} patient records');

    final notifications = querySnapshot.docs.map((doc) {
      final data = doc.data();
      
      // Debug: Print first record to see structure
      if (doc == querySnapshot.docs.first) {
        print('📝 Sample patient data structure:');
        print('   Has demographic: ${data.containsKey('demographic')}');
        print('   Has createdAt: ${data.containsKey('createdAt')}');
        print('   Has timestamp: ${data.containsKey('timestamp')}');
        print('   Keys: ${data.keys.toList()}');
      }
      
      return {
        'id': doc.id,
        'firstName': data['demographic']?['firstName'] ?? '',
        'lastName': data['demographic']?['lastName'] ?? '',
        'age': data['demographic']?['age'] ?? '',
        'sex': data['demographic']?['sex'] ?? '',
        'timestamp': data['createdAt'],  // ← Use 'createdAt' as the timestamp
        'synced': true,
      };
    }).toList();
    
    print('✅ Returning ${notifications.length} notifications');
    return notifications;
    
  } catch (e, stackTrace) {
    print('❌ Error fetching recent assessments: $e');
    print('Stack trace: $stackTrace');
    return [];
  }
}

/// Create a notification when a patient is added
Future<void> createPatientNotification({
  required String barangayId,
  required String patientId,
  required Map<String, dynamic> patientData,
}) async {
  final user = _auth.currentUser;
  if (user == null) return;

  try {
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final creatorName = userDoc.data()?['fullName'] ?? 
                       userDoc.data()?['username'] ?? 
                       user.email ?? 
                       'Unknown';

    // Create notification in barangay's notifications collection
    await _firestore
        .collection('barangays')
        .doc(barangayId)
        .collection('notifications')
        .add({
      'type': 'new_patient',
      'patientId': patientId,
      'patientName': '${patientData['demographic']?['firstName'] ?? ''} ${patientData['demographic']?['lastName'] ?? ''}',
      'patientAge': patientData['demographic']?['age'] ?? '',
      'patientSex': patientData['demographic']?['sex'] ?? '',
      'createdBy': user.uid,
      'createdByName': creatorName,
      'createdAt': FieldValue.serverTimestamp(),
      'barangayId': barangayId,
      'read': false,
    });

    print('✅ Notification created for barangay: $barangayId');
  } catch (e) {
    print('❌ Error creating notification: $e');
  }
}

/// Get notifications for the user's barangay
Future<List<Map<String, dynamic>>> getBarangayNotifications({int limit = 50}) async {
  final user = _auth.currentUser;
  if (user == null) {
    print('❌ No user logged in');
    return [];
  }

  try {
    // Get user's barangay
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final barangayId = userDoc.data()?['barangayId'] as String?;

    if (barangayId == null || barangayId.isEmpty) {
      print('❌ User has no barangayId');
      return [];
    }

    print('📋 Getting notifications for barangay: $barangayId');

    // Get notifications from barangay
    final snapshot = await _firestore
        .collection('barangays')
        .doc(barangayId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    print('✅ Found ${snapshot.docs.length} notifications');

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  } catch (e) {
    print('❌ Error getting notifications: $e');
    return [];
  }
}

/// Mark notification as read
Future<void> markNotificationAsRead(String notificationId) async {
  final user = _auth.currentUser;
  if (user == null) return;

  try {
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final barangayId = userDoc.data()?['barangayId'] as String?;

    if (barangayId == null) return;

    await _firestore
        .collection('barangays')
        .doc(barangayId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  } catch (e) {
    print('❌ Error marking notification as read: $e');
  }
}



// ============================================================================
// ADD THESE METHODS TO YOUR FirestoreService class
// Paste them just before the last closing } of the class
// ============================================================================

  /// Get upcoming calendar events for the user's barangay (today and future)
  Stream<List<Map<String, dynamic>>> getUpcomingEventsStream({int limit = 3}) async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield <Map<String, dynamic>>[];
      return;
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final barangayId = userDoc.data()?['barangayId'] as String?;

    if (barangayId == null || barangayId.isEmpty) {
      yield <Map<String, dynamic>>[];
      return;
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    yield* _firestore
        .collection('barangays')
        .doc(barangayId)
        .collection('calendarEvents')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .orderBy('date', descending: false)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  /// Save a calendar event to the barangay's calendarEvents collection
  Future<String> saveCalendarEvent(Map<String, dynamic> eventData) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user found',
      );
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final barangayId = userDoc.data()?['barangayId'] as String?;

    if (barangayId == null || barangayId.isEmpty) {
      throw Exception('User has no barangay assigned');
    }

    final creatorName = userDoc.data()?['fullName'] ??
        userDoc.data()?['username'] ??
        user.email ??
        'Unknown';

    final ref = _firestore
        .collection('barangays')
        .doc(barangayId)
        .collection('calendarEvents')
        .doc();

    await ref.set({
      ...eventData,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': user.uid,
      'createdByName': creatorName,
      'barangayId': barangayId,
    });

    return ref.id;
  }

  /// Update an existing calendar event
  Future<void> updateCalendarEvent(
      String eventId, Map<String, dynamic> eventData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final barangayId = userDoc.data()?['barangayId'] as String?;
    if (barangayId == null || barangayId.isEmpty) return;

    await _firestore
        .collection('barangays')
        .doc(barangayId)
        .collection('calendarEvents')
        .doc(eventId)
        .update({
      ...eventData,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastModifiedBy': user.uid,
    });
  }

  /// Delete a calendar event
  Future<void> deleteCalendarEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final barangayId = userDoc.data()?['barangayId'] as String?;
    if (barangayId == null || barangayId.isEmpty) return;

    await _firestore
        .collection('barangays')
        .doc(barangayId)
        .collection('calendarEvents')
        .doc(eventId)
        .delete();
  }


  // ============================================================================
// ADD THESE 2 METHODS TO YOUR FirestoreService class
// Paste just before the last closing } of the class
// ============================================================================

  /// Called when a calendar event is saved — creates a notification entry
  /// in barangays/{barangayId}/calendarNotifications
  Future<void> createCalendarEventNotification({
    required String barangayId,
    required String eventId,
    required Map<String, dynamic> eventData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final creatorName = userDoc.data()?['fullName'] ??
          userDoc.data()?['username'] ??
          user.email ??
          'Unknown';

      await _firestore
          .collection('barangays')
          .doc(barangayId)
          .collection('calendarNotifications')
          .add({
        'type': 'new_event',
        'eventId': eventId,
        'eventTitle': eventData['title'] ?? '',
        'eventTime': eventData['time'] ?? '',
        'eventDate': eventData['date'],
        'eventDescription': eventData['description'] ?? '',
        'colorValue': eventData['colorValue'] ?? 0xFFF5A962,
        'createdBy': user.uid,
        'createdByName': creatorName,
        'createdAt': FieldValue.serverTimestamp(),
        'barangayId': barangayId,
        'read': false,
      });

      print('✅ Calendar event notification created');
    } catch (e) {
      print('❌ Error creating calendar event notification: $e');
    }
  }

  /// Fetch calendar event notifications for the user's barangay
  Future<List<Map<String, dynamic>>> getCalendarEventNotifications(
      {int limit = 50}) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final barangayId = userDoc.data()?['barangayId'] as String?;

      if (barangayId == null || barangayId.isEmpty) return [];

      final snapshot = await _firestore
          .collection('barangays')
          .doc(barangayId)
          .collection('calendarNotifications')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting calendar notifications: $e');
      return [];
    }
  }

  /// Mark a calendar notification as read
  Future<void> markCalendarNotificationAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final barangayId = userDoc.data()?['barangayId'] as String?;
      if (barangayId == null) return;

      await _firestore
          .collection('barangays')
          .doc(barangayId)
          .collection('calendarNotifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('❌ Error marking calendar notification as read: $e');
    }
  }


Future<Map<String, int>> getTodayStatusCounts() async {
  final user = _auth.currentUser;
  if (user == null) return {};

  try {
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final barangayId = userDoc.data()?['barangayId'] as String?;
    if (barangayId == null || barangayId.isEmpty) return {};

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('barangays')
        .doc(barangayId)
        .collection('patients')
        .where('isDeleted', isEqualTo: false)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final counts = {
      'Underweight': 0,
      'Overweight': 0,
      'Stunted': 0,
      'At Risk': 0,
    };

    for (final doc in snapshot.docs) {
      final anthropometric = doc.data()['anthropometric'] as Map<String, dynamic>?;
      if (anthropometric == null) continue;

      final wfa  = (anthropometric['weightForAge']    as String? ?? '').toLowerCase();
      final hfa  = (anthropometric['heightForAge']    as String? ?? '').toLowerCase();
      final wfh  = (anthropometric['weightForHeight'] as String? ?? '').toLowerCase();
      final bmi  = (anthropometric['bmi']             as String? ?? '').toLowerCase();

      // ── Underweight (includes severely underweight) ───────────────
      if (wfa.contains('underweight') || bmi.contains('underweight')) {
        counts['Underweight'] = counts['Underweight']! + 1;
      }

      // ── Overweight / Obese (includes "at risk of overweight") ─────
      // Matches: "overweight", "obese", "at risk of overweight"
      if (wfa.contains('overweight') || wfa.contains('obese') ||
          wfh.contains('overweight') || wfh.contains('obese') ||
          bmi.contains('overweight') || bmi.contains('obese')) {
        counts['Overweight'] = counts['Overweight']! + 1;
      }

      // ── Stunted (includes severely stunted) ───────────────────────
      if (hfa.contains('stunted')) {
        counts['Stunted'] = counts['Stunted']! + 1;
      }

      // ── At Risk (wasted / severe wasting / at risk of overweight) ─
      if (wfh.contains('wasted') ||
          wfa.contains('at risk') ||
          bmi.contains('at risk') ||
          wfh.contains('at risk')) {
        counts['At Risk'] = counts['At Risk']! + 1;
      }
    }

    print('✅ Status counts: $counts');
    return counts;

  } catch (e) {
    print('❌ Error getting status counts: $e');
    return {};
  }
}

 double? _extractZScore(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final match = RegExp(r'^-?\d+(\.\d+)?').firstMatch(raw.trim());
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  // Extract BMI z-score from strings like "18.2 | 0.10 (Normal)".
  double? _extractBmiZScore(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final trimmed = raw.trim();
    if (!trimmed.contains('|')) return null;
    final parts = trimmed.split('|');
    if (parts.length < 2) return null;
    final afterPipe = parts[1].trim();
    final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(afterPipe);
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  /// Overall status counts for ALL non-deleted patients in the user's barangay.
  /// Uses WHO SD thresholds — same logic as _buildAssessmentRemarks.
 /* Future<Map<String, int>> getStatusCounts() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final barangayId = userDoc.data()?['barangayId'] as String?;
      if (barangayId == null || barangayId.isEmpty) return {};

      debugPrint('📊 getStatusCounts() for barangayId: $barangayId');

      final snapshot = await _firestore
          .collection('barangays')
          .doc(barangayId)
          .collection('patients')
          .where('isDeleted', isEqualTo: false)
          .get();

      final counts = {
        'Underweight': 0,
        'Overweight/Obese': 0,
        'Stunted': 0,
        'At Risk': 0,
        'Normal': 0,
      };

      for (final doc in snapshot.docs) {
        final anthropometric =
            doc.data()['anthropometric'] as Map<String, dynamic>?;
        if (anthropometric == null) continue;

        final double? wfa =
            _extractZScore(anthropometric['weightForAge']?.toString());
        final double? hfa =
            _extractZScore(anthropometric['heightForAge']?.toString());
        final double? wfh =
            _extractZScore(anthropometric['weightForHeight']?.toString());
        final double? bmi =
            _extractZScore(anthropometric['bmi']?.toString());

        // Skip docs with no z-scores at all
        if (wfa == null && hfa == null && wfh == null && bmi == null) {
          continue;
        }

        final tags = <String>{};

        // Weight-for-Age: Underweight < -2 SD | At Risk -2 to -1 SD
        if (wfa != null) {
          if (wfa < -2) {
            tags.add('Underweight');
          } else if (wfa >= -2 && wfa < -1) {
            tags.add('At Risk');
          }
        }

        // Height-for-Age: Stunted < -2 SD | At Risk -2 to -1 SD
        if (hfa != null) {
          if (hfa < -2) {
            tags.add('Stunted');
          } else if (hfa >= -2 && hfa < -1) {
            tags.add('At Risk');
          }
        }

        // Weight-for-Height: Overweight/Obese > +1 SD | At Risk -2 to -1 SD
        if (wfh != null) {
          if (wfh > 1) {
            tags.add('Overweight/Obese');
          } else if (wfh >= -2 && wfh < -1) {
            tags.add('At Risk');
          }
        }

        // BMI: Overweight/Obese > +2 SD | At Risk -2 to -1 SD
        if (bmi != null) {
          if (bmi > 2) {
            tags.add('Overweight/Obese');
          } else if (bmi >= -2 && bmi < -1) {
            tags.add('At Risk');
          }
        }

        if (tags.isEmpty) {
          // All z-scores within healthy range → Normal
          counts['Normal'] = counts['Normal']! + 1;
        } else {
          // A patient can belong to multiple statuses
          for (final tag in tags) {
            counts[tag] = counts[tag]! + 1;
          }
        }
      }

      debugPrint('✅ Status counts: $counts');
      return counts;
    } catch (e) {
      debugPrint('❌ Error getting status counts: $e');
      return {};
    }
  }*/
  Future<Map<String, int>> getStatusCounts() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final barangayId = userDoc.data()?['barangayId'] as String?;
      if (barangayId == null || barangayId.isEmpty) return {};

      debugPrint('📊 getStatusCounts() for barangayId: $barangayId');

      final snapshot = await _firestore
          .collection('barangays')
          .doc(barangayId)
          .collection('patients')
          .where('isDeleted', isEqualTo: false)
          .get();

      // Group barangay patients by first/last name (same as PatientListTab)
      // and keep only the most recent record per child. Skip archived.
      final Map<String, Map<String, dynamic>> latestByKey = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['isArchived'] == true) continue;

        final rawDemo = data['demographic'];
        final Map<String, dynamic> demographic;
        if (rawDemo is Map<String, dynamic>) {
          demographic = rawDemo;
        } else if (rawDemo is Map) {
          demographic = Map<String, dynamic>.from(rawDemo);
        } else {
          demographic = <String, dynamic>{};
        }

        final firstName = (demographic['firstName'] ?? '').toString();
        final lastName = (demographic['lastName'] ?? '').toString();
        final key =
            '${firstName.toLowerCase().trim()}_${lastName.toLowerCase().trim()}';
        if (key.isEmpty || key == '_') continue;

        final createdAt = data['createdAt'] as Timestamp?;
        final existing = latestByKey[key];
        if (existing == null) {
          latestByKey[key] = data;
        } else {
          final existingTs = existing['createdAt'] as Timestamp?;
          final existingTime =
              existingTs != null ? existingTs.toDate() : DateTime(1970);
          final thisTime =
              createdAt != null ? createdAt.toDate() : DateTime(1970);
          if (thisTime.isAfter(existingTime)) {
            latestByKey[key] = data;
          }
        }
      }

      final counts = {
        'Underweight': 0,
        'Overweight/Obese': 0,
        'Stunted': 0,
        'At Risk': 0,
        'Normal': 0,
      };

      void _applyStatusFromData(Map<String, dynamic> data) {
        final rawAnthro = data['anthropometric'];
        Map<String, dynamic>? anthropometric;
        if (rawAnthro is Map<String, dynamic>) {
          anthropometric = rawAnthro;
        } else if (rawAnthro is Map) {
          anthropometric = Map<String, dynamic>.from(rawAnthro);
        } else {
          anthropometric = null;
        }
        if (anthropometric == null) return;

        final double? wfa =
            _extractZScore(anthropometric['weightForAge']?.toString());
        final double? hfa =
            _extractZScore(anthropometric['heightForAge']?.toString());
        final double? wfh =
            _extractZScore(anthropometric['weightForHeight']?.toString());
        final double? bmi =
            _extractBmiZScore(anthropometric['bmi']?.toString());

        // Skip records with no usable z-scores.
        if (wfa == null && hfa == null && wfh == null && bmi == null) return;

        // Same priority as _buildAssessmentRemarks / PatientListTab.

        // Priority 1: Underweight (Weight-for-Age < -2 SD)
        if (wfa != null && wfa < -2) {
          counts['Underweight'] = counts['Underweight']! + 1;
          return;
        }

        // Priority 2: Stunted (Height-for-Age < -2 SD)
        if (hfa != null && hfa < -2) {
          counts['Stunted'] = counts['Stunted']! + 1;
          return;
        }

        // Priority 3: Overweight/Obese (Weight-for-Height > +1 SD or BMI > +2 SD)
        if ((wfh != null && wfh > 1) || (bmi != null && bmi > 2)) {
          counts['Overweight/Obese'] =
              counts['Overweight/Obese']! + 1;
          return;
        }

        // Priority 4: At Risk (any indicator -2 to -1 SD)
        final atRisk = (wfa != null && wfa >= -2 && wfa < -1) ||
            (hfa != null && hfa >= -2 && hfa < -1) ||
            (wfh != null && wfh >= -2 && wfh < -1) ||
            (bmi != null && bmi >= -2 && bmi < -1);
        if (atRisk) {
          counts['At Risk'] = counts['At Risk']! + 1;
          return;
        }

        // Priority 5: Normal
        counts['Normal'] = counts['Normal']! + 1;
      }

      // Apply status for each barangay child (grouped by name).
      for (final data in latestByKey.values) {
        _applyStatusFromData(data);
      }

      // Also include homepageData-only patients (same rule as PatientListTab).
      final homeSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('homepageData')
          .get();

      final existingKeys = latestByKey.keys.toSet();

      for (final doc in homeSnapshot.docs) {
        final data = doc.data();
        if (data['isDeleted'] == true) continue;

        final rawDemo = data['demographic'];
        final Map<String, dynamic> demographic;
        if (rawDemo is Map<String, dynamic>) {
          demographic = rawDemo;
        } else if (rawDemo is Map) {
          demographic = Map<String, dynamic>.from(rawDemo);
        } else {
          demographic = <String, dynamic>{};
        }

        final firstName = (demographic['firstName'] ?? '').toString();
        final lastName = (demographic['lastName'] ?? '').toString();
        final key =
            '${firstName.toLowerCase().trim()}_${lastName.toLowerCase().trim()}';
        if (key.isEmpty || key == '_' || existingKeys.contains(key)) continue;

        _applyStatusFromData(data);
      }

      debugPrint('✅ Status counts: $counts');
      return counts;
    } catch (e) {
      debugPrint('❌ Error getting status counts: $e');
      return {};
    }
  }
}


