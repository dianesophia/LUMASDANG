import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// Handles saving vaccination next-dose reminders to Firestore and
/// surfacing them as barangay notifications when the due date arrives.
class VaccineReminderService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  VaccineReminderService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db   = firestore ?? FirebaseFirestore.instance,
        _auth = auth     ?? FirebaseAuth.instance;

  // ── Save reminders after an assessment is saved ───────────────────────────
  /// Call this right after [FirestoreService.savePatientToBarangay] succeeds.
  ///
  /// [vaccinationData] is the map from [VaccinationForm.onDataChanged].
  /// [patientId]      is the Firestore doc ID returned by savePatientToBarangay.
  /// [patientInfo]    contains firstName, lastName, motherContact, fatherContact.
  Future<void> saveReminders({
    required String patientId,
    required Map<String, dynamic> vaccinationData,
    required Map<String, dynamic> patientInfo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc     = await _db.collection('users').doc(user.uid).get();
    final barangayId  = userDoc.data()?['barangayId'] as String?;
    if (barangayId == null || barangayId.isEmpty) return;

    final batch = _db.batch();

    for (final entry in vaccinationData.entries) {
      final vaccine   = entry.key;
      final doseMap   = entry.value as Map<String, dynamic>?;
      if (doseMap == null) continue;

      final nextDateStr = doseMap['nextDoseDate'] as String?;
      if (nextDateStr == null ||
          nextDateStr == 'All doses complete ✓' ||
          nextDateStr.isEmpty) continue;

      DateTime nextDate;
      try {
        nextDate = DateFormat('MMM dd, yyyy').parse(nextDateStr);
      } catch (_) {
        continue;
      }

      final ref = _db
          .collection('barangays')
          .doc(barangayId)
          .collection('vaccineReminders')
          .doc('${patientId}_$vaccine'); // one doc per patient-vaccine pair

      batch.set(
        ref,
        {
          'patientId':      patientId,
          'patientName':    '${patientInfo['firstName'] ?? ''} '
                            '${patientInfo['lastName'] ?? ''}'.trim(),
          'motherContact':  patientInfo['motherContact'] ?? '',
          'fatherContact':  patientInfo['fatherContact'] ?? '',
          'vaccine':        vaccine,
          'nextDoseDate':   Timestamp.fromDate(nextDate),
          'nextDoseDateStr':nextDateStr,
          'barangayId':     barangayId,
          'notified':       false,
          'createdAt':      FieldValue.serverTimestamp(),
          'createdBy':      user.uid,
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  // ── Check due reminders on app open ──────────────────────────────────────
  /// Call this from [HomePage.initState] (after sync).
  /// For every reminder whose [nextDoseDate] is today or in the past and
  /// hasn't been notified yet, this creates a barangay notification and
  /// marks the reminder as notified.
  Future<int> checkAndFireDueReminders() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final userDoc     = await _db.collection('users').doc(user.uid).get();
    final barangayId  = userDoc.data()?['barangayId'] as String?;
    if (barangayId == null || barangayId.isEmpty) return 0;

    final now        = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final snap = await _db
        .collection('barangays')
        .doc(barangayId)
        .collection('vaccineReminders')
        .where('notified',     isEqualTo: false)
        .where('nextDoseDate', isLessThanOrEqualTo: Timestamp.fromDate(
            startOfDay.add(const Duration(days: 1))))
        .get();

    if (snap.docs.isEmpty) return 0;

    final batch       = _db.batch();
    int firedCount    = 0;
    final creatorName = userDoc.data()?['fullName'] ??
                        userDoc.data()?['username'] ??
                        user.email ??
                        'System';

    for (final doc in snap.docs) {
      final data        = doc.data();
      final patientName = data['patientName'] as String? ?? 'Unknown';
      final vaccine     = data['vaccine']     as String? ?? '';
      final dateStr     = data['nextDoseDateStr'] as String? ?? '';
      final motherContact = data['motherContact'] as String? ?? '';
      final fatherContact = data['fatherContact'] as String? ?? '';
      final dueDate     = (data['nextDoseDate'] as Timestamp).toDate();
      final isOverdue   = dueDate.isBefore(startOfDay);

      // Create notification
      final notifRef = _db
          .collection('barangays')
          .doc(barangayId)
          .collection('notifications')
          .doc();

      batch.set(notifRef, {
        'type':           'vaccine_due',
        'patientId':      data['patientId'],
        'patientName':    patientName,
        'vaccine':        vaccine,
        'nextDoseDate':   data['nextDoseDate'],
        'nextDoseDateStr':dateStr,
        'motherContact':  motherContact,
        'fatherContact':  fatherContact,
        'isOverdue':      isOverdue,
        'createdBy':      user.uid,
        'createdByName':  creatorName,
        'createdAt':      FieldValue.serverTimestamp(),
        'barangayId':     barangayId,
        'read':           false,
      });

      // Mark reminder as notified
      batch.update(doc.reference, {
        'notified':   true,
        'notifiedAt': FieldValue.serverTimestamp(),
      });

      firedCount++;
    }

    await batch.commit();
    return firedCount;
  }

  // ── Delete reminders when a patient is deleted ────────────────────────────
  Future<void> deleteRemindersForPatient(String patientId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc    = await _db.collection('users').doc(user.uid).get();
    final barangayId = userDoc.data()?['barangayId'] as String?;
    if (barangayId == null || barangayId.isEmpty) return;

    final snap = await _db
        .collection('barangays')
        .doc(barangayId)
        .collection('vaccineReminders')
        .where('patientId', isEqualTo: patientId)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}