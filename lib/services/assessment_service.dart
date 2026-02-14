import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AssessmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save assessment for a specific patient
  Future<String> saveAssessment({
    required String patientId,
    required Map<String, dynamic> assessment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    // Get user's barangay
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final barangayId = userDoc.data()?['barangayId'] as String?;
    if (barangayId == null) throw Exception("User has no barangay assigned");

    // Add server timestamp
    final payload = {
      ...assessment,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': user.uid,
      'barangayId': barangayId,
    };

    // Save assessment under patient document
    final docRef = await _firestore
        .collection('barangays')
        .doc(barangayId)
        .collection('patients')
        .doc(patientId)
        .collection('assessments')
        .doc(); // auto id
    await docRef.set(payload);
    return docRef.id;
  }
}
