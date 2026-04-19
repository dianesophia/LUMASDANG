import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'dart:convert';


class FirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // Add these getters
  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;


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
      .doc(docId);

    final payload = {
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'ownerUid': uid,
    };

    await docRef.set(payload);
    return docRef.id;
  }

  /// Update an existing homepageData document by document id.
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
    required String middleName,
    required String lastName,
    required Map<String, String> statuses,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final key = '${firstName.trim()}_${middleName.trim()}_${lastName.trim()}'.toLowerCase();
    if (key == '_') return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('vaccinationStatus')
        .doc(key)
        .set({
      'firstName': firstName.trim(),
      'middleName': middleName.trim(),
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

  /// Returns the current user's barangay display name, or empty string if not set.
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

  /// Saves vaccination status to the barangay patient doc.
  /// ── UPDATED: profileKeys and flat map now include all 17 new vaccines ──
  Future<void> saveVaccinationStatusToBarangayPatient({
  required String barangayId,
  required String patientId,
  required String firstName,
  required String middleName,
  required String lastName,
  required Map<String, String> statuses,
}) async {
  final user = _auth.currentUser;
  if (user == null) return;

  // ── Updated to match all 25 vaccines in _vaccineNames ──
  const profileKeys = [
    'bcg',
    'hepatitisB',
    'pentavalent',       // NEW
    'oralPolio',         // NEW
    'ipv',
    'phenumococcal',     // NEW
    'rotavirus',         // NEW
    'measles',           // NEW
    'mmr',
    'hepatitisA',
    'chickenpox',        // NEW
    'typhoid',
    'pneumo23',          // NEW
    'flu',               // NEW
    'opv',
    'dtapHib',
    'pcv',
    'influenza',
    'mmrMr',             // NEW
    'measlesMmr',
    'jev',
    'varicella',
    'rabies',
    'meningococcal',
    'cholera',
  ];

    // Only write vaccines that are present in `statuses`.
    // This avoids resetting previously-saved vaccines to `Pending` when the
    // user updates only a subset in the form.
    final flat = <String, String>{};
    for (final k in profileKeys) {
      final v = statuses[k];
      if (v != null) flat[k] = v;
    }

  // ... rest of your method stays the same

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['fullName'] ??
        userDoc.data()?['username'] ??
        user.email ??
        'Unknown';

    final ref = _firestore
        .collection('barangays')
        .doc(barangayId)
        .collection('patients')
        .doc(patientId)
        .collection('vaccination')
        .doc('record');

    await ref.set({
      'firstName':          firstName.trim(),
      'middleName':         middleName.trim(),
      'lastName':           lastName.trim(),
      'lastReviewDate':     FieldValue.serverTimestamp(),
      'lastModifiedBy':     user.uid,
      'lastModifiedByName': userName,
      'updatedAt':          FieldValue.serverTimestamp(),
      ...flat,
    }, SetOptions(merge: true));
  }

  /// SOFT DELETE USER: marks all user's records as deleted
  Future<void> softDeleteUser(String uid) async {
    final userDoc = _firestore.collection('users').doc(uid);
    final snapshot = await userDoc.collection('homepageData').get();
    for (var doc in snapshot.docs) {
      await doc.reference.update({'isDeleted': true});
    }
    await userDoc.set({'isDeleted': true}, SetOptions(merge: true));
  }

  /// CHANGE PASSWORD
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
      
      print('Step 1: Signing out...');
      await _auth.signOut();
      print('Signed out successfully');
      
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
      
      print('Step 2: Getting current username...');
      final userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      
      final currentUsername = userDoc.data()?['username'] as String?;
      print('Current username: $currentUsername');
      
      print('Step 3: Updating username in Firestore...');
      final batch = _firestore.batch();
      
      batch.set(
        _firestore.collection('users').doc(uid),
        {
          'username': newUsername,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        _firestore.collection('usernames').doc(newUsername.toLowerCase()),
        {
          'email': user.email,
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
      
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
      
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final username = userDoc.data()?['username'] as String?;
      
      await _auth.signOut();
      
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: oldEmail,
        password: currentPassword,
      ).timeout(const Duration(seconds: 15));
      
      await userCred.user!.verifyBeforeUpdateEmail(newEmail).timeout(
        const Duration(seconds: 15),
      );

      await userCred.user!.sendEmailVerification();
      
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

  /// UPDATE PROFILE PICTURE
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
  
    final userDocDebug = await _firestore.collection('users').doc(user.uid).get();
    print('🔍 User UID: ${user.uid}');
    print('🔍 User doc exists: ${userDocDebug.exists}');
    print('🔍 User doc fields: ${userDocDebug.data()?.keys.toList()}');
    print('🔍 barangayId: ${userDocDebug.data()?['barangayId']}');
  
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final barangayId = userDoc.data()?['barangayId'] as String?;

    if (barangayId == null || barangayId.isEmpty) {
      print('❌ User has no barangay assigned');
      throw Exception('User has no barangay assigned');
    }

    print('✅ User barangayId: $barangayId');

    final patientRef = _firestore
        .collection('barangays')
        .doc(barangayId)
        .collection('patients')
        .doc();

    final payload = {
      ...patientData,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': user.uid,
      'createdByName': userDoc.data()?['fullName'] ?? userDoc.data()?['username'] ?? 'Unknown',
      'barangayId': barangayId,
      'barangay': userDoc.data()?['barangay'] ?? '',
      'isDeleted': false,
      'lastModifiedBy': user.uid,
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
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final barangayId = userDoc.data()?['barangayId'] as String?;

      if (barangayId == null || barangayId.isEmpty) {
        print('❌ User has no barangayId');
        return [];
      }

      print('✅ User barangayId: $barangayId');

      final snapshot = await _firestore
          .collection('barangays')
          .doc(barangayId)
          .collection('patients')
          .where('isDeleted', isEqualTo: false)
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
          .where('isDeleted', isEqualTo: false)
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

  // ── PATIENT ASSESSMENTS - Barangay shared ──────────────────────────────────

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

  final userDoc = await _firestore.collection('users').doc(user.uid).get();
  final barangayId = userDoc.data()?['barangayId'] as String?;

  if (barangayId == null || barangayId.isEmpty) {
    throw Exception('User has no barangay assigned');
  }

  // ✅ Convert DateTime → Timestamp
  final sanitized = assessmentData.map((k, v) {
    if (v is DateTime) return MapEntry(k, Timestamp.fromDate(v));
    return MapEntry(k, v);
  });

  final assessmentRef = _firestore
      .collection('barangays')
      .doc(barangayId)
      .collection('patients')
      .doc(patientId)
      .collection('assessments')
      .doc();

  final payload = {
    ...sanitized,
    'createdAt': FieldValue.serverTimestamp(),
    'createdBy': user.uid,
    'createdByName': userDoc.data()?['fullName'] ??
        userDoc.data()?['username'] ??
        'Unknown',
    'barangayId': barangayId,
  };

  await assessmentRef.set(payload);
  return assessmentRef.id;
}

  /// Get all assessments for a specific patient
  Future<List<Map<String, dynamic>>> getAssessmentsForBarangayPatient(String patientId) async {
  final user = _auth.currentUser;
  if (user == null) return [];

  final userDoc = await _firestore.collection('users').doc(user.uid).get();
  final barangayId = userDoc.data()?['barangayId'] as String?;
  if (barangayId == null) return [];

  final snapshot = await _firestore
      .collection('barangays')
      .doc(barangayId)
      .collection('patients')
      .doc(patientId)
      .collection('assessments')
      .orderBy('createdAt', descending: false)
      .get();

  return snapshot.docs.map((doc) {
    final data = doc.data();
    data['id'] = doc.id;

    // ✅ Convert Timestamp → DateTime so AssessmentTable can use it directly
    if (data['date'] is Timestamp) {
      data['date'] = (data['date'] as Timestamp).toDate();
    }
    if (data['createdAt'] is Timestamp) {
      data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
    }

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

  final userDoc = await _firestore.collection('users').doc(user.uid).get();
  final barangayId = userDoc.data()?['barangayId'] as String?;

  if (barangayId == null || barangayId.isEmpty) {
    throw Exception('User has no barangay assigned');
  }

  // ✅ Convert any DateTime values → Timestamp before writing to Firestore
  final sanitized = updatedData.map((k, v) {
    if (v is DateTime) return MapEntry(k, Timestamp.fromDate(v));
    if (v is Map) {
      return MapEntry(k, (v).map((mk, mv) =>
          MapEntry(mk, mv is DateTime ? Timestamp.fromDate(mv) : mv)));
    }
    return MapEntry(k, v);
  });

  // ✅ Use set+merge so it never throws "document not found"
  await _firestore
      .collection('barangays')
      .doc(barangayId)
      .collection('patients')
      .doc(patientId)
      .collection('assessments')
      .doc(assessmentId)
      .set({
    ...sanitized,
    'updatedAt': FieldValue.serverTimestamp(),
    'lastModifiedBy': user.uid,
    'lastModifiedByName': userDoc.data()?['fullName'] ??
        userDoc.data()?['username'] ??
        'Unknown',
  }, SetOptions(merge: true)); // ✅ merge so existing fields aren't wiped
}

  /// Get recent assessments / patient notifications
  /// ── UPDATED: now includes visitDate and visitTime fields ──
  Future<List<Map<String, dynamic>>> getRecentAssessments({int limit = 50}) async {
    try {
      print('📋 getRecentAssessments() called');
      
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return [];
      }

      print('✅ User UID: ${user.uid}');
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        print('❌ User document does not exist');
        return [];
      }
      
      final userData = userDoc.data()!;
      print('📄 User data: $userData');
      
      final barangayId = userData['barangayId'] as String?;

      if (barangayId == null || barangayId.isEmpty) {
        print('❌ User has no barangayId assigned');
        print('   Available fields: ${userData.keys.toList()}');
        return [];
      }

      print('✅ User barangayId: $barangayId');

      final querySnapshot = await _firestore
          .collection('barangays')
          .doc(barangayId)
          .collection('patients')
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      print('✅ Found ${querySnapshot.docs.length} patient records');

      final notifications = querySnapshot.docs.map((doc) {
        final data = doc.data();
        
        if (doc == querySnapshot.docs.first) {
          print('📝 Sample patient data structure:');
          print('   Has demographic: ${data.containsKey('demographic')}');
          print('   Has createdAt: ${data.containsKey('createdAt')}');
          print('   Has visitDate: ${data.containsKey('visitDate')}');
          print('   Has visitTime: ${data.containsKey('visitTime')}');
          print('   Keys: ${data.keys.toList()}');
        }
        
        return {
          'id':         doc.id,
          'firstName':  data['demographic']?['firstName']  ?? '',
          'middleName': data['demographic']?['middleName'] ?? '',
          'lastName':   data['demographic']?['lastName']   ?? '',
          'age':        data['demographic']?['age']        ?? '',
          'sex':        data['demographic']?['sex']        ?? '',
          'timestamp':  data['createdAt'],
          // ── NEW: visit date & time ────────────────────────────────
          'visitDate':  data['visitDate'] ?? '',
          'visitTime':  data['visitTime'] ?? '',
          // ─────────────────────────────────────────────────────────
          'synced':     true,
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
  /// ── UPDATED: now includes visitDate and visitTime in the notification ──
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

      await _firestore
          .collection('barangays')
          .doc(barangayId)
          .collection('notifications')
          .add({
        'type':         'new_patient',
        'patientId':    patientId,
        'patientName':  '${patientData['demographic']?['firstName'] ?? ''} ${patientData['demographic']?['middleName'] ?? ''} ${patientData['demographic']?['lastName'] ?? ''}',
        'patientAge':   patientData['demographic']?['age'] ?? '',
        'patientSex':   patientData['demographic']?['sex'] ?? '',
        // ── NEW: visit date & time ────────────────────────────────
        'visitDate':    patientData['visitDate'] ?? '',
        'visitTime':    patientData['visitTime'] ?? '',
        // ─────────────────────────────────────────────────────────
        'createdBy':     user.uid,
        'createdByName': creatorName,
        'createdAt':     FieldValue.serverTimestamp(),
        'barangayId':    barangayId,
        'read':          false,
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
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final barangayId = userDoc.data()?['barangayId'] as String?;

      if (barangayId == null || barangayId.isEmpty) {
        print('❌ User has no barangayId');
        return [];
      }

      print('📋 Getting notifications for barangay: $barangayId');

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

  /// Get upcoming calendar events for the user's barangay
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

  /// Called when a calendar event is saved — creates a notification entry
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
        'type':             'new_event',
        'eventId':          eventId,
        'eventTitle':       eventData['title'] ?? '',
        'eventTime':        eventData['time'] ?? '',
        'eventDate':        eventData['date'],
        'eventDescription': eventData['description'] ?? '',
        'colorValue':       eventData['colorValue'] ?? 0xFFF5A962,
        'createdBy':        user.uid,
        'createdByName':    creatorName,
        'createdAt':        FieldValue.serverTimestamp(),
        'barangayId':       barangayId,
        'read':             false,
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

        final wfa = (anthropometric['weightForAge']    as String? ?? '').toLowerCase();
        final hfa = (anthropometric['heightForAge']    as String? ?? '').toLowerCase();
        final wfh = (anthropometric['weightForHeight'] as String? ?? '').toLowerCase();
        final bmi = (anthropometric['bmi']             as String? ?? '').toLowerCase();

        if (wfa.contains('underweight') || bmi.contains('underweight')) {
          counts['Underweight'] = counts['Underweight']! + 1;
        }
        if (wfa.contains('overweight') || wfa.contains('obese') ||
            wfh.contains('overweight') || wfh.contains('obese') ||
            bmi.contains('overweight') || bmi.contains('obese')) {
          counts['Overweight'] = counts['Overweight']! + 1;
        }
        if (hfa.contains('stunted')) {
          counts['Stunted'] = counts['Stunted']! + 1;
        }
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

        final firstName  = (demographic['firstName']  ?? '').toString();
        final middleName = (demographic['middleName'] ?? '').toString();
        final lastName   = (demographic['lastName']   ?? '').toString();
        final key =
            '${firstName.toLowerCase().trim()}_${middleName.toLowerCase().trim()}_${lastName.toLowerCase().trim()}';
        if (key.isEmpty || key == '_') continue;

        final createdAt = data['createdAt'] as Timestamp?;
        final existing  = latestByKey[key];
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
        'Underweight':     0,
        'Overweight/Obese': 0,
        'Stunted':         0,
        'At Risk':         0,
        'Normal':          0,
      };

      void applyStatusFromData(Map<String, dynamic> data) {
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

        final double? wfa = _extractZScore(anthropometric['weightForAge']?.toString());
        final double? hfa = _extractZScore(anthropometric['heightForAge']?.toString());
        final double? wfh = _extractZScore(anthropometric['weightForHeight']?.toString());
        final double? bmi = _extractBmiZScore(anthropometric['bmi']?.toString());

        if (wfa == null && hfa == null && wfh == null && bmi == null) return;

        if (wfa != null && wfa < -2) {
          counts['Underweight'] = counts['Underweight']! + 1;
          return;
        }
        if (hfa != null && hfa < -2) {
          counts['Stunted'] = counts['Stunted']! + 1;
          return;
        }
        if ((wfh != null && wfh > 1) || (bmi != null && bmi > 2)) {
          counts['Overweight/Obese'] = counts['Overweight/Obese']! + 1;
          return;
        }
        final atRisk = (wfa != null && wfa >= -2 && wfa < -1) ||
            (hfa != null && hfa >= -2 && hfa < -1) ||
            (wfh != null && wfh >= -2 && wfh < -1) ||
            (bmi != null && bmi >= -2 && bmi < -1);
        if (atRisk) {
          counts['At Risk'] = counts['At Risk']! + 1;
          return;
        }
        counts['Normal'] = counts['Normal']! + 1;
      }

      for (final data in latestByKey.values) {
        applyStatusFromData(data);
      }

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

        final firstName  = (demographic['firstName']  ?? '').toString();
        final middleName = (demographic['middleName'] ?? '').toString();
        final lastName   = (demographic['lastName']   ?? '').toString();
        final key =
            '${firstName.toLowerCase().trim()}_${middleName.toLowerCase().trim()}_${lastName.toLowerCase().trim()}';
        if (key.isEmpty || key == '_' || existingKeys.contains(key)) continue;

        applyStatusFromData(data);
      }

      debugPrint('✅ Status counts: $counts');
      return counts;
    } catch (e) {
      debugPrint('❌ Error getting status counts: $e');
      return {};
    }
  }
}