import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../patient_list.dart';
import '../../services/anthropometric_calculator.dart';
import '../../services/firestore_service.dart';
import '../../services/local_db_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/age_utils.dart';
import 'widgets/profile_info_card.dart';
import 'widgets/assessment_table.dart';
import 'widgets/trends_section.dart';
import 'widgets/status_sections.dart';
import 'widgets/overall_nutritional_status.dart';
import 'widgets/vaccination_status.dart';
import 'widgets/deworming_status.dart';
import 'widgets/parent_contact_tab.dart';
import 'edit_patient_demographics_screen.dart';
import 'package:flutter/foundation.dart';

class PatientProfileOverview extends StatefulWidget {
  final Patient patient;
  final int initialTabIndex;
  final bool isSharedPatient;
  final String? sharedPatientId;
  final String? barangayId;

  const PatientProfileOverview({
    super.key,
    required this.patient,
    this.initialTabIndex = 0,
    this.isSharedPatient = false,
    this.sharedPatientId,
    this.barangayId,
  });

  @override
  State<PatientProfileOverview> createState() => _PatientProfileOverviewState();
}

class _PatientProfileOverviewState extends State<PatientProfileOverview>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<Map<String, dynamic>> _assessments = [];
  bool _loading = true;
  late int _currentTabIndex;

  bool _preferPhoneCall = true;
  bool _preferSMS = false;

  late Patient _patientSnapshot;
  bool _patientUpdated = false;
  Map<String, dynamic>? _rootDemographic;

  @override
  void initState() {
    super.initState();
    _patientSnapshot = widget.patient;
    _currentTabIndex = widget.initialTabIndex;

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        Navigator.pop(context);
      }
    });

    _fetchAssessments();
    _loadContactPreferences();
    _loadRootPatient();
  }

  bool get _canEditPatient =>
      _patientSnapshot.docId.isNotEmpty && !_patientSnapshot.isArchived;

  Map<String, dynamic>? get _effectiveDemographic {
    if (_rootDemographic != null && _rootDemographic!.isNotEmpty) {
      return _rootDemographic;
    }
    if (_assessments.isEmpty) return null;
    final demoRaw = _assessments.last['demographic'];
    if (demoRaw is Map<String, dynamic>) return demoRaw;
    if (demoRaw is Map) return Map<String, dynamic>.from(demoRaw);
    return null;
  }

  Future<void> _loadRootPatient() async {
    if (_patientSnapshot.docId.isEmpty) return;

    try {
      final online = kIsWeb
          ? true
          : await ConnectivityService.instance.checkOnline();
      if (!online) return;

      final data = await FirestoreService()
          .getBarangayPatientById(_patientSnapshot.docId);
      if (data == null || !mounted) return;

      final rawDemo = data['demographic'];
      Map<String, dynamic>? demo;
      if (rawDemo is Map<String, dynamic>) {
        demo = rawDemo;
      } else if (rawDemo is Map) {
        demo = Map<String, dynamic>.from(rawDemo);
      }

      final rawPrefs = data['contactPreferences'];
      Map<String, dynamic> prefs = {};
      if (rawPrefs is Map<String, dynamic>) {
        prefs = rawPrefs;
      } else if (rawPrefs is Map) {
        prefs = Map<String, dynamic>.from(rawPrefs);
      }

      setState(() {
        _rootDemographic = demo;
        if (prefs.isNotEmpty) {
          _preferPhoneCall = prefs['phoneCall'] ?? true;
          _preferSMS = prefs['sms'] ?? false;
        }
      });
    } catch (e) {
      debugPrint('Error loading root patient: $e');
    }
  }

  Future<void> _openEditPatient() async {
    if (!_canEditPatient) return;

    final online = kIsWeb
        ? true
        : await ConnectivityService.instance.checkOnline();
    if (!online) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connect to the internet to edit patient profile.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    final result = await Navigator.push<Patient>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditPatientDemographicsScreen(patient: _patientSnapshot),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _patientSnapshot = result;
        _patientUpdated = true;
      });
      await _loadRootPatient();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Contact preferences ────────────────────────────────────────────────────
  Future<void> _loadContactPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || widget.patient.docId.isEmpty) return;

      final online = kIsWeb
          ? true
          : await ConnectivityService.instance.checkOnline();
      if (!online || LocalDbService.instance.offlineAuthenticated) {
        await LocalDbService.instance.init();
        final all = await LocalDbService.instance
            .getAllRecords(includeDeleted: true);
        final match = all.firstWhere(
            (r) =>
                (r['id'] == widget.patient.docId) ||
                (r['firestoreId'] == widget.patient.docId),
            orElse: () => {});
        if (match.isNotEmpty) {
          final rawData = match['data'];
          Map<String, dynamic>? data;
          if (rawData is Map<String, dynamic>) {
            data = rawData;
          } else if (rawData is Map) {
            data = Map<String, dynamic>.from(rawData);
          }
          Map<String, dynamic> prefs = {};
          if (data != null) {
            final rawPrefs = data['contactPreferences'];
            if (rawPrefs is Map<String, dynamic>) {
              prefs = rawPrefs;
            } else if (rawPrefs is Map) {
              prefs = Map<String, dynamic>.from(rawPrefs);
            }
          }
          if (mounted) {
            setState(() {
              _preferPhoneCall = prefs['phoneCall'] ?? true;
              _preferSMS = prefs['sms'] ?? false;
            });
          }
        }
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('homepageData')
          .doc(widget.patient.docId)
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        Map<String, dynamic> prefs = {};
        final rawPrefs = data['contactPreferences'];
        if (rawPrefs is Map<String, dynamic>) {
          prefs = rawPrefs;
        } else if (rawPrefs is Map) {
          prefs = Map<String, dynamic>.from(rawPrefs);
        }
        if (mounted) {
          setState(() {
            _preferPhoneCall = prefs['phoneCall'] ?? true;
            _preferSMS = prefs['sms'] ?? false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading contact preferences: $e');
    }
  }

  Future<void> _saveContactPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || widget.patient.docId.isEmpty) return;

      final online = kIsWeb
          ? true
          : await ConnectivityService.instance.checkOnline();
      if (!online || LocalDbService.instance.offlineAuthenticated) {
        await LocalDbService.instance.init();
        final all = await LocalDbService.instance
            .getAllRecords(includeDeleted: true);
        final matchIndex = all.indexWhere((r) =>
            (r['id'] == widget.patient.docId) ||
            (r['firestoreId'] == widget.patient.docId));
        if (matchIndex >= 0) {
          for (final key in LocalDbService.instance.box.keys) {
            final value = LocalDbService.instance.box.get(key);
            if (value is Map) {
              if ((value['id'] == widget.patient.docId) ||
                  (value['firestoreId'] == widget.patient.docId)) {
                final updated = Map<String, dynamic>.from(value);
                final data =
                    Map<String, dynamic>.from(updated['data'] ?? {});
                data['contactPreferences'] = {
                  'phoneCall': _preferPhoneCall,
                  'sms': _preferSMS
                };
                updated['data'] = data;
                updated['lastModified'] =
                    DateTime.now().toIso8601String();
                await LocalDbService.instance.box.put(key, updated);
                break;
              }
            }
          }
        } else {
          final data = {
            'contactPreferences': {
              'phoneCall': _preferPhoneCall,
              'sms': _preferSMS
            }
          };
          await LocalDbService.instance.saveLocalRecord(data,
              synced: false, firestoreId: widget.patient.docId);
        }
        return;
      }

      final prefs = {
        'phoneCall': _preferPhoneCall,
        'sms': _preferSMS,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('homepageData')
          .doc(_patientSnapshot.docId)
          .set({'contactPreferences': prefs}, SetOptions(merge: true));

      if (_patientSnapshot.docId.isNotEmpty) {
        await FirestoreService().updatePatientContactPreferencesInBarangay(
          patientId: _patientSnapshot.docId,
          contactPreferences: prefs,
        );
      }
    } catch (e) {
      debugPrint('Error saving contact preferences: $e');
    }
  }

  // ── Assessment fetching ────────────────────────────────────────────────────
  Map<String, dynamic> _extractAssessment(
      Map<String, dynamic> data, String docId) {
    final anthropometric = data['anthropometric'] ?? {};
    final createdAt = data['createdAt'];
    DateTime? measurementDate;
    final dateOfMeasurement =
        anthropometric['dateOfMeasurement']?.toString() ?? '';
    if (dateOfMeasurement.isNotEmpty) {
      measurementDate = _parseDate(dateOfMeasurement);
    }
    if (measurementDate == null && createdAt != null) {
      if (createdAt is Timestamp) {
        measurementDate = createdAt.toDate();
      } else if (createdAt is String) {
        measurementDate = DateTime.tryParse(createdAt);
      } else if (createdAt is DateTime) {
        measurementDate = createdAt;
      }
    }
    return {
      'id': data['id'] ?? docId,
      'date': measurementDate,
      'height': anthropometric['height'] ?? '',
      'weight': anthropometric['weight'] ?? '',
      'muac': anthropometric['muac'] ?? '',
      'weightForAge': anthropometric['weightForAge'] ?? '',
      'heightForAge': anthropometric['heightForAge'] ?? '',
      'weightForHeight': anthropometric['weightForHeight'] ?? '',
      'bmi': anthropometric['bmi'] ?? '',
      'healthStatus': data['healthStatus'],
      'dietary': data['dietary'],
      'oral': data['oral'],
      'deworming': data['deworming'],
      'vaccination': data['vaccination'],
      'allergies': data['allergies'],
      'demographic': data['demographic'],
      'familyPlanning': data['familyPlanning'],
      'nutritionEnvironment': data['nutritionEnvironment'],
      'vitaminA': data['vitaminA'],
      'docId': docId,
      'dewormingOnly': data['dewormingOnly'] == true,
    };
  }

  bool _namesMatch(String storedFirst, String storedLast) {
    final patientFirst = _patientSnapshot.firstName.trim().toLowerCase();
    final patientLast = _patientSnapshot.lastName.trim().toLowerCase();
    final first = storedFirst.trim().toLowerCase();
    final last = storedLast.trim().toLowerCase();
    if (first == patientFirst && last == patientLast) return true;
    return '$first $last' == '$patientFirst $patientLast';
  }

  Map<String, String>? _computeLocalVaccinationStatuses() {
    if (_assessments.isEmpty) return null;

    Map<String, dynamic>? latest;
    for (var i = _assessments.length - 1; i >= 0; i--) {
      if (_assessments[i]['vaccination'] != null) {
        latest = _assessments[i];
        break;
      }
    }
    if (latest == null) return null;

    final rawVacc = latest['vaccination'];
    Map<String, dynamic> vaccination;
    if (rawVacc is Map<String, dynamic>) {
      vaccination = rawVacc;
    } else if (rawVacc is Map) {
      vaccination = Map<String, dynamic>.from(rawVacc);
    } else {
      return null;
    }

    int doseCount(String vaccine) {
      final raw = vaccination[vaccine];
      Map<String, dynamic>? doses;
      if (raw is Map<String, dynamic>) {
        doses = raw;
      } else if (raw is Map) {
        doses = Map<String, dynamic>.from(raw);
      }
      if (doses == null) return 0;
      return doses.entries
          .where((e) =>
              !e.key.endsWith('_date') &&
              e.key != 'nextDoseDate' &&
              e.value == true)
          .length;
    }

    String doseLabelForCount(int count) {
      if (count <= 0) return 'Pending';
      switch (count) {
        case 1:
          return '1st dose';
        case 2:
          return '2nd dose';
        case 3:
          return '3rd dose';
        case 4:
          return '4th dose';
        case 5:
          return '5th dose';
        default:
          return 'Booster';
      }
    }

    String vaccineStatus(String name) =>
        doseLabelForCount(doseCount(name));

    final opvCount = doseCount('OPV');
    final ipvCount = doseCount('IPV');

    return <String, String>{
      'bcg': vaccineStatus('BCG'),
      'hepatitisB': vaccineStatus('Hepatitis B'),
      'opv': vaccineStatus('OPV'),
      'ipv': vaccineStatus('IPV'),
      'dtap': vaccineStatus('DTwP/DTaP-Hib-IPV'),
      'pcv': vaccineStatus('PCV'),
      'rv': vaccineStatus('RV'),
      'influenza': vaccineStatus('Influenza'),
      'mmr': vaccineStatus('MMR/MR'),
      'measlesMmr': vaccineStatus('Measles/MMR'),
      'jev': vaccineStatus('JEV'),
      'varicella': vaccineStatus('Varicella'),
      'hepatitisA': vaccineStatus('Hepatitis A'),
      'rabies': vaccineStatus('Rabies'),
      'meningococcal': vaccineStatus('Meningococcal'),
      'cholera': vaccineStatus('Cholera'),
      'typhoid': vaccineStatus('Typhoid'),
      'opvIpv': doseLabelForCount(
          opvCount > ipvCount ? opvCount : ipvCount),
    };
  }

  Future<void> _fetchAssessments() async {
    try {
      final firestoreService = FirestoreService();
      final user = FirebaseAuth.instance.currentUser;
      final List<Map<String, dynamic>> matched = [];

      // 1) Always load local cached assessments (offline-first)
      try {
        await LocalDbService.instance.init();
        final localRecords = await LocalDbService.instance
            .getAllRecords(includeDeleted: false);

        for (final record in localRecords) {
          final rawData = record['data'];
          Map<String, dynamic>? data;
          if (rawData is Map<String, dynamic>) {
            data = rawData;
          } else if (rawData is Map) {
            data = Map<String, dynamic>.from(rawData);
          }
          if (data == null) continue;
          final demographic = data['demographic'] ?? {};
          final firstName = (demographic['firstName'] ?? '').toString();
          final lastName = (demographic['lastName'] ?? '').toString();
          final nameField = (demographic['name'] ?? '').toString();

          bool matchesByName = _namesMatch(firstName, lastName);
          if (!matchesByName && nameField.isNotEmpty) {
            final parts = nameField.trim().split(RegExp(r'\s+'));
            final derivedFirst = parts.isNotEmpty ? parts.first : '';
            final derivedLast =
                parts.length > 1 ? parts.sublist(1).join(' ') : '';
            matchesByName = _namesMatch(derivedFirst, derivedLast);
          }

          if (!matchesByName) continue;

          final createdAtString =
              (record['lastModified'] ?? record['timestamp'])?.toString();
          if (createdAtString != null) {
            data['createdAt'] = createdAtString;
          }

          final docId = (record['firestoreId'] as String?) ??
              (record['id'] as String?) ??
              widget.patient.docId;

          matched.add(_extractAssessment(data, docId));
        }
      } catch (e) {
        debugPrint('[ProfileOverview] Error loading local assessments: $e');
      }

      if (user == null) {
        final finalList = List<Map<String, dynamic>>.from(matched)
          ..sort((a, b) =>
              (a['date'] as DateTime?)?.compareTo(
                  b['date'] as DateTime? ?? DateTime(1970)) ??
              0);
        setState(() {
          _assessments = finalList;
          _loading = false;
        });
        return;
      }

      // 2) When online, enrich with Firestore data
      final online = kIsWeb
          ? true
          : await ConnectivityService.instance.checkOnline();
      if (online) {
        if (widget.isSharedPatient && widget.sharedPatientId != null) {
          final assessments = await firestoreService
              .getAssessmentsForBarangayPatient(widget.sharedPatientId!);
          matched.addAll(
            assessments
                .map((a) => _extractAssessment(a, a['id'] ?? ''))
                .toList(),
          );
        } else {
          try {
            final barangayAssessments = await firestoreService
                .getAssessmentsForBarangayPatient(widget.patient.docId);
            matched.addAll(
              barangayAssessments
                  .map((a) => _extractAssessment(a, a['id'] ?? ''))
                  .toList(),
            );
          } catch (e) {
            debugPrint(
                '[ProfileOverview] Error fetching barangay assessments: $e');
          }

          try {
            final snapshot = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('homepageData')
                .get();
            Map<String, dynamic>? fallbackByDocId;

            for (var doc in snapshot.docs) {
              final data = doc.data();
              final demographic = data['demographic'] ?? {};
              final firstName =
                  (demographic['firstName'] ?? '').toString();
              final lastName =
                  (demographic['lastName'] ?? '').toString();
              final nameField = (demographic['name'] ?? '').toString();
              if (doc.id == widget.patient.docId) {
                fallbackByDocId = data;
              }
              if (_namesMatch(firstName, lastName)) {
                matched.add(_extractAssessment(data, doc.id));
              } else if (nameField.isNotEmpty) {
                final parts = nameField.trim().split(RegExp(r'\s+'));
                final derivedFirst =
                    parts.isNotEmpty ? parts.first : '';
                final derivedLast = parts.length > 1
                    ? parts.sublist(1).join(' ')
                    : '';
                if (_namesMatch(derivedFirst, derivedLast)) {
                  matched.add(_extractAssessment(data, doc.id));
                }
              }
            }

            if (matched.isEmpty && fallbackByDocId != null) {
              matched.add(_extractAssessment(
                  fallbackByDocId, widget.patient.docId));
            }
          } catch (e) {
            debugPrint(
                '[ProfileOverview] Error fetching user homepageData: $e');
          }
        }
      }

      // 3) De-duplicate and sort
      final patientDocId = widget.patient.docId;
      final unique = <String, Map<String, dynamic>>{};
      for (var a in matched) {
        final dateMs =
            (a['date'] as DateTime?)?.millisecondsSinceEpoch ?? 0;
        final contentKey = '$dateMs-${a['weight']}-${a['height']}';
        final existing = unique[contentKey];
        if (existing == null) {
          unique[contentKey] = a;
        } else {
          final existingIsFromFirestore =
              existing['docId'] != patientDocId;
          final currentIsFromFirestore = a['docId'] != patientDocId;
          if (currentIsFromFirestore && !existingIsFromFirestore) {
            unique[contentKey] = a;
          }
        }
      }
      final finalList = unique.values.toList()
        ..sort((a, b) =>
            (a['date'] as DateTime?)?.compareTo(
                b['date'] as DateTime? ?? DateTime(1970)) ??
            0);

      setState(() {
        _assessments = finalList;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching assessments: $e');
      setState(() => _loading = false);
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split(RegExp(r'[-/]'));
      if (parts.length == 3) {
        final month = int.tryParse(parts[0]);
        final day = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (month != null && day != null && year != null) {
          return DateTime(year, month, day);
        }
      }
      return DateTime.tryParse(dateStr);
    } catch (_) {
      return null;
    }
  }

  // ── Tab bodies ─────────────────────────────────────────────────────────────
  Widget _buildProfileTab() {
    final patient = _patientSnapshot;
    final latestDemo = _effectiveDemographic;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          ProfileInfoCard(
            patient: patient,
            latestDemographic: latestDemo,
            onEditTap: _canEditPatient ? _openEditPatient : null,
          ),
          const SizedBox(height: 20),

          AssessmentTable(
            patientId: widget.sharedPatientId ?? widget.patient.docId,
            assessments: _assessments
                .where((a) => a['dewormingOnly'] != true)
                .toList(),
            loading: _loading,
            onAddAssessment: _showAddAssessmentSheet,
            saveNewAssessment: null,

            // ── DELETE ──────────────────────────────────────────────────────
            onDeleteAssessment: (assessmentId, patientId) async {
              if (assessmentId.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Cannot delete: this assessment was created '
                        'offline and has not been synced yet.',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }

              try {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .get();
                final barangayId =
                    userDoc.data()?['barangayId'] as String?;

                if (barangayId == null || barangayId.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Cannot delete: no barangay assigned.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('barangays')
                    .doc(barangayId)
                    .collection('patients')
                    .doc(patientId)
                    .collection('assessments')
                    .doc(assessmentId)
                    .delete();

                await LocalDbService.instance.init();
                await LocalDbService.instance
                    .softDeleteByFirestoreId(assessmentId);

                if (mounted) {
                  // ✅ Remove directly from local list — instant UI update
                  setState(() {
                    _assessments.removeWhere(
                      (a) =>
                          a['id']?.toString() == assessmentId ||
                          a['docId']?.toString() == assessmentId,
                    );
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Assessment deleted.'),
                      backgroundColor: Color(0xFF2E8B7B),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error deleting assessment: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },

            // ── EDIT ────────────────────────────────────────────────────────
            onEditAssessment: (updated, assessmentId, patientId) async {
              if (assessmentId.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Cannot edit: this assessment was created '
                        'offline and has not been synced yet.',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }

              try {
                final firestoreService = FirestoreService();

                String formattedDate = '';
                if (updated['date'] is DateTime) {
                  final d = updated['date'] as DateTime;
                  formattedDate =
                      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
                }

                final patient = widget.patient;
                final result = AnthropometricCalculator.calculate(
                  weightStr: updated['weight']?.toString() ?? '',
                  heightStr: updated['height']?.toString() ?? '',
                  ageStr: patient.dateOfBirth.trim().isNotEmpty &&
                          formattedDate.trim().isNotEmpty
                      ? ''
                      : patient.age.toString(),
                  sexStr: patient.sex,
                  dobStr: patient.dateOfBirth,
                  measurementDateStr: formattedDate,
                );

                final anthropometricPayload = {
                  'dateOfMeasurement': formattedDate,
                  'height': updated['height']?.toString() ?? '',
                  'weight': updated['weight']?.toString() ?? '',
                  'muac': updated['muac']?.toString() ?? '',
                  'weightForAge':
                      result?.weightForAge ?? updated['weightForAge'] ?? '',
                  'heightForAge':
                      result?.heightForAge ?? updated['heightForAge'] ?? '',
                  'weightForHeight':
                      result?.weightForHeight ?? updated['weightForHeight'] ?? '',
                  'bmi': result?.bmi ?? updated['bmi'] ?? '',
                };

                await firestoreService.updateAssessmentInBarangayPatient(
                  patientId: patientId,
                  assessmentId: assessmentId,
                  updatedData: {'anthropometric': anthropometricPayload},
                );

                await LocalDbService.instance.init();
                await LocalDbService.instance
                    .updateAssessmentByFirestoreId(
                  firestoreId: assessmentId,
                  anthropometric: anthropometricPayload,
                );

                if (mounted) {
                  // ✅ Replace in-place — no duplicate, matches by id or docId
                  setState(() {
                    final index = _assessments.indexWhere(
                      (a) =>
                          a['id']?.toString() == assessmentId ||
                          a['docId']?.toString() == assessmentId,
                    );
                    if (index != -1) {
                      _assessments[index] = {
                        ..._assessments[index],
                        'height': anthropometricPayload['height'],
                        'weight': anthropometricPayload['weight'],
                        'muac': anthropometricPayload['muac'],
                        'date': updated['date'],
                        'weightForAge': anthropometricPayload['weightForAge'],
                        'heightForAge': anthropometricPayload['heightForAge'],
                        'weightForHeight':
                            anthropometricPayload['weightForHeight'],
                        'bmi': anthropometricPayload['bmi'],
                      };
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Assessment updated.'),
                      backgroundColor: Color(0xFF2E8B7B),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error editing assessment: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),

          const SizedBox(height: 20),
          TrendsSection(assessments: _assessments),
          const SizedBox(height: 20),
          StatusSections(assessments: _assessments),
          const SizedBox(height: 20),
          OverallNutritionalStatusSection(assessments: _assessments),
          const SizedBox(height: 24),
          VaccinationStatusSection(
            firstName: patient.firstName,
            lastName: patient.lastName,
            patientId: patient.docId,
            barangayId: patient.barangayId,
            useSharedStorage: true,
            localStatuses: _computeLocalVaccinationStatuses(),
            localLastReviewDate: _assessments.isNotEmpty
                ? _assessments.last['date'] as DateTime?
                : null,
          ),
          const SizedBox(height: 20),
          DewormingStatusSection(
            assessments: _assessments,
            onEditTap: _showEditDewormingSheet,
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTabBody() {
    switch (_currentTabIndex) {
      case 0:
        return _buildProfileTab();
      case 1:
        return ParentContactTab(
          patient: _patientSnapshot,
          latestDemographic: _effectiveDemographic,
          preferPhoneCall: _preferPhoneCall,
          preferSMS: _preferSMS,
          onEditProfileTap: _canEditPatient ? _openEditPatient : null,
          onPhoneCallChanged: (v) {
            setState(() => _preferPhoneCall = v ?? false);
            _saveContactPreferences();
          },
          onSMSChanged: (v) {
            setState(() => _preferSMS = v ?? false);
            _saveContactPreferences();
          },
        );
      default:
        return _buildProfileTab();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E8B7B),
              Color(0xFF5CAA7F),
              Color(0xFF8BC88A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.35),
                    Colors.transparent,
                  ]),
                ),
              ),
              Expanded(child: _buildTabBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(
                    context,
                    _patientUpdated ? _patientSnapshot : null,
                  ),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1.2),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_patientSnapshot.firstName} ${_patientSnapshot.lastName}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isSharedPatient)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.35), width: 1),
                  ),
                  child: const Text('SHARED',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.8)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.white.withOpacity(0.28), width: 1),
            ),
            child: Row(
              children: [
                _buildInlineTab(0, Icons.bar_chart_rounded, 'Overview'),
                Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.2)),
                _buildInlineTab(
                    1, Icons.contact_page_outlined, 'Parent Contact'),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildInlineTab(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Edit Deworming ─────────────────────────────────────────────────────────
  void _showEditDewormingSheet() {
    Map<String, dynamic>? latestWithDeworming;
    for (var i = _assessments.length - 1; i >= 0; i--) {
      if (_assessments[i]['deworming'] != null) {
        latestWithDeworming = _assessments[i];
        break;
      }
    }
    final raw = latestWithDeworming?['deworming'];
    final Map<String, dynamic> existing = raw is Map<String, dynamic>
        ? raw
        : (raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{});

    final dateLastCtrl = TextEditingController(
      text: (existing['dateOfLastDeworming'] ?? '').toString().trim(),
    );
    const List<String> dewormingDrugs = ['Albendazole', 'Mebendazole'];
    final existingDrug = (existing['drugGiven'] ?? '').toString().trim();
    String? selectedDrug =
        dewormingDrugs.contains(existingDrug) ? existingDrug : null;
    final adverseCtrl = TextEditingController(
      text: (existing['adverseReactions'] ?? '').toString().trim(),
    );
    final nextDateCtrl = TextEditingController(
      text: (existing['nextDewormingDate'] ?? '').toString().trim(),
    );
    bool isNA = existing['isNA'] == true;
    bool saving = false;
    String? errorMessage;

    const kOrange = Color(0xFFF08030);
    const kSurface = Color(0xFFFFFFFF);
    const kSurfaceDim = Color(0xFFFAFAFA);
    const kBorder = Color(0xFFE8E8ED);
    const kInk = Color(0xFF1C1C1E);
    const kInkMid = Color(0xFF6C6C70);
    const kRCard = 18.0;
    const kRInner = 12.0;

    Widget buildField({
      required BuildContext ctx,
      required TextEditingController controller,
      required String label,
      required String hint,
      required IconData icon,
      TextInputType keyboardType = TextInputType.text,
      VoidCallback? onTap,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kInkMid,
                    letterSpacing: 1.0)),
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: onTap != null,
            onTap: onTap,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: kInk),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: kInkMid.withOpacity(0.55)),
              prefixIcon: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: kOrange.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: kOrange),
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: kSurfaceDim,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRInner),
                borderSide: const BorderSide(color: kBorder, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRInner),
                borderSide: const BorderSide(color: kBorder, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRInner),
                borderSide:
                    const BorderSide(color: kOrange, width: 2),
              ),
            ),
          ),
        ],
      );
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(kRCard)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kOrange.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                                Icons.medication_liquid_rounded,
                                color: kOrange,
                                size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text('Edit Deworming Status',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: kInk,
                                  letterSpacing: -0.3)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      CheckboxListTile(
                        value: isNA,
                        onChanged: (v) =>
                            setSheetState(() => isNA = v ?? false),
                        title: const Text('Not applicable',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: kInk)),
                        activeColor: kOrange,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity:
                            ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 12),
                      buildField(
                        ctx: ctx,
                        controller: dateLastCtrl,
                        label: 'DATE OF LAST DEWORMING',
                        hint: 'MM / DD / YYYY',
                        icon: Icons.calendar_today_outlined,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (c, child) => Theme(
                              data: Theme.of(c).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: kOrange,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            dateLastCtrl.text =
                                '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
                            setSheetState(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 2, bottom: 6),
                            child: const Text('MEDICATION GIVEN',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: kInkMid,
                                    letterSpacing: 1.0)),
                          ),
                          DropdownButtonFormField<String?>(
                            value: selectedDrug,
                            decoration: InputDecoration(
                              prefixIcon: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 8, 8, 8),
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: kOrange.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.vaccines_rounded,
                                      size: 15, color: kOrange),
                                ),
                              ),
                              prefixIconConstraints:
                                  const BoxConstraints(minWidth: 0, minHeight: 0),
                              filled: true,
                              fillColor: kSurfaceDim,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(kRInner),
                                borderSide: const BorderSide(
                                    color: kBorder, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(kRInner),
                                borderSide: const BorderSide(
                                    color: kBorder, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(kRInner),
                                borderSide: const BorderSide(
                                    color: kOrange, width: 2),
                              ),
                            ),
                            hint: const Text('Select medication',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: kInkMid)),
                            items: dewormingDrugs
                                .map((String drug) =>
                                    DropdownMenuItem<String?>(
                                      value: drug,
                                      child: Text(drug,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: kInk)),
                                    ))
                                .toList(),
                            onChanged: (String? value) => setSheetState(
                                () => selectedDrug = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      buildField(
                        ctx: ctx,
                        controller: adverseCtrl,
                        label: 'ADVERSE REACTIONS (if any)',
                        hint: 'Leave blank if none',
                        icon: Icons.warning_amber_rounded,
                      ),
                      const SizedBox(height: 10),
                      buildField(
                        ctx: ctx,
                        controller: nextDateCtrl,
                        label: 'NEXT DEWORMING DATE',
                        hint: 'MM / DD / YYYY',
                        icon: Icons.event_rounded,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 2)),
                            builder: (c, child) => Theme(
                              data: Theme.of(c).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: kOrange,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            nextDateCtrl.text =
                                '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
                            setSheetState(() {});
                          }
                        },
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(errorMessage!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.red,
                                fontWeight: FontWeight.w500)),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  setSheetState(
                                      () => errorMessage = null);
                                  final deworming = {
                                    'dateOfLastDeworming':
                                        dateLastCtrl.text.trim(),
                                    'isNA': isNA,
                                    'drugGiven': selectedDrug ?? '',
                                    'adverseReactions':
                                        adverseCtrl.text.trim(),
                                    'nextDewormingDate':
                                        nextDateCtrl.text.trim(),
                                  };
                                  setSheetState(() => saving = true);
                                  try {
                                    final patient = widget.patient;
                                    final firestore = FirestoreService();

                                    Map<String, dynamic>
                                        buildDewormingPayload(
                                            Map<String, dynamic>
                                                dewormingData) {
                                      final now = DateTime.now();
                                      final dateStr =
                                          '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';
                                      return {
                                        'demographic': {
                                          'firstName': patient.firstName,
                                          'lastName': patient.lastName,
                                          'age': patient.age.toString(),
                                          'sex': patient.sex,
                                          'address': patient.address,
                                          'dateOfBirth':
                                              patient.dateOfBirth,
                                          'mother': patient.motherName,
                                          'motherContact':
                                              patient.motherContact,
                                          'father': patient.fatherName,
                                          'fatherContact':
                                              patient.fatherContact,
                                        },
                                        'anthropometric': {
                                          'dateOfMeasurement': dateStr,
                                          'weight': '',
                                          'height': '',
                                          'muac': '',
                                          'weightForAge': '',
                                          'weightForHeight': '',
                                          'heightForAge': '',
                                          'bmi': '',
                                        },
                                        'healthStatus': {
                                          'diarrhea': false,
                                          'fever': false,
                                          'cough': false,
                                          'other': false,
                                          'medications': false,
                                        },
                                        'dietary': {
                                          'purelyBreastfed': null,
                                          'cfAge': '',
                                          'cfFrequency': '',
                                          'cfFoods': '',
                                          'mealFrequency': '',
                                        },
                                        'deworming': dewormingData,
                                        'oral': {'overallRisk': null},
                                        'dewormingOnly': true,
                                        'isDeleted': false,
                                      };
                                    }

                                    String? assessmentId;
                                    try {
                                      final freshAssessments =
                                          await firestore
                                              .getAssessmentsForBarangayPatient(
                                                  patient.docId);
                                      if (freshAssessments.isNotEmpty) {
                                        assessmentId =
                                            freshAssessments.last['id']
                                                as String?;
                                      }
                                    } catch (e) {
                                      debugPrint(
                                          '[Deworming] Could not fetch fresh assessments: $e');
                                    }

                                    final canUpdate =
                                        assessmentId != null &&
                                            assessmentId.isNotEmpty;
                                    bool saved = false;

                                    if (canUpdate) {
                                      try {
                                        await firestore
                                            .updateAssessmentInBarangayPatient(
                                          patientId: patient.docId,
                                          assessmentId: assessmentId,
                                          updatedData: {
                                            'deworming': deworming
                                          },
                                        );
                                        saved = true;
                                      } catch (e) {
                                        debugPrint(
                                            '[Deworming] Update failed ($e)');
                                        if (!e
                                            .toString()
                                            .contains('not-found') &&
                                            !e
                                                .toString()
                                                .contains('NOT_FOUND')) {
                                          rethrow;
                                        }
                                      }
                                    }

                                    if (!saved) {
                                      await firestore
                                          .saveAssessmentToBarangayPatient(
                                        patientId: patient.docId,
                                        assessmentData:
                                            buildDewormingPayload(
                                                deworming),
                                      );
                                    }

                                    if (mounted) {
                                      setState(() => _loading = true);
                                      await _fetchAssessments();
                                    }
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Deworming status updated.'),
                                          backgroundColor:
                                              Color(0xFF2E8B7B),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint(
                                        'Error saving deworming: $e');
                                    setSheetState(() {
                                      saving = false;
                                      errorMessage =
                                          'Failed to save. Try again.';
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: saving
                                ? kOrange.withOpacity(0.6)
                                : kOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white),
                                )
                              : const Text('Save',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                            foregroundColor: kInkMid),
                        child: const Text('Cancel',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Add Assessment Sheet ───────────────────────────────────────────────────
  void _showAddAssessmentSheet() {
    final visitDateCtrl = TextEditingController();
    final visitTimeCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final heightCtrl = TextEditingController();
    final muacCtrl = TextEditingController();

    if (visitDateCtrl.text.trim().isEmpty) {
      visitDateCtrl.text = formatDateForDisplay(DateTime.now());
    }

    bool saving = false;
    String? errorMessage;

    const kOrange = Color(0xFFF08030);
    const kOrangeLight = Color(0xFFF5A962);
    const kAmberBg = Color(0xFFFFF6EE);
    const kSurface = Color(0xFFFFFFFF);
    const kSurfaceDim = Color(0xFFFAFAFA);
    const kBorder = Color(0xFFE8E8ED);
    const kInk = Color(0xFF1C1C1E);
    const kInkMid = Color(0xFF6C6C70);
    const kRCard = 18.0;
    const kRInner = 12.0;

    Widget buildField({
      required BuildContext ctx,
      required TextEditingController controller,
      required String label,
      required String hint,
      required IconData icon,
      TextInputType keyboardType = TextInputType.text,
      VoidCallback? onTap,
      bool readOnly = false,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kInkMid,
                    letterSpacing: 1.0)),
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: onTap != null,
            onTap: onTap,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: kInk),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: kInkMid.withOpacity(0.55)),
              prefixIcon: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: kOrange.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: kOrange),
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: kSurfaceDim,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRInner),
                borderSide: const BorderSide(color: kBorder, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRInner),
                borderSide: const BorderSide(color: kBorder, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRInner),
                borderSide: const BorderSide(color: kOrange, width: 2),
              ),
            ),
          ),
        ],
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(kRCard)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 5,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [kOrangeLight, kOrange]),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin:
                                const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: kBorder,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: kOrange.withOpacity(0.10),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                  Icons.add_chart_outlined,
                                  color: kOrange,
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text('New Assessment',
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: kInk,
                                          letterSpacing: -0.3)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_patientSnapshot.firstName} ${_patientSnapshot.lastName}',
                                    style: const TextStyle(
                                        fontSize: 13, color: kInkMid),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.isSharedPatient)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [kOrangeLight, kOrange]),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.people_rounded,
                                        size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('Shared',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1, color: kBorder),
                        ),
                        if (errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: kAmberBg,
                              borderRadius:
                                  BorderRadius.circular(kRInner),
                              border: Border.all(
                                  color: kOrange.withOpacity(0.40),
                                  width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                    Icons.warning_amber_rounded,
                                    color: kOrange,
                                    size: 17),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(errorMessage!,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: kOrange)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('VISIT DATE & TIME',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: kInkMid,
                                  letterSpacing: 1.2)),
                        ),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                            child: buildField(
                              ctx: ctx,
                              controller: visitDateCtrl,
                              label: 'DATE OF VISIT',
                              hint: 'Auto-filled from device date',
                              icon: Icons.calendar_today_outlined,
                              onTap: null,
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: buildField(
                              ctx: ctx,
                              controller: visitTimeCtrl,
                              label: 'TIME OF VISIT',
                              hint: 'e.g. 10:30 AM',
                              icon: Icons.schedule_outlined,
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: ctx,
                                  initialTime: TimeOfDay.now(),
                                  builder: (c, child) => Theme(
                                    data: Theme.of(c).copyWith(
                                      colorScheme:
                                          const ColorScheme.light(
                                              primary: kOrange,
                                              onPrimary: Colors.white,
                                              surface: Colors.white),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) {
                                  final hour =
                                      picked.hourOfPeriod == 0
                                          ? 12
                                          : picked.hourOfPeriod;
                                  final minute = picked.minute
                                      .toString()
                                      .padLeft(2, '0');
                                  final period =
                                      picked.period == DayPeriod.am
                                          ? 'AM'
                                          : 'PM';
                                  setSheetState(() {
                                    visitTimeCtrl.text =
                                        '$hour:$minute $period';
                                  });
                                }
                              },
                            ),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('MEASUREMENT DETAILS',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: kInkMid,
                                  letterSpacing: 1.2)),
                        ),
                        const SizedBox(height: 10),
                        buildField(
                          ctx: ctx,
                          controller: dateCtrl,
                          label: 'DATE OF MEASUREMENT',
                          hint: 'MM / DD / YYYY',
                          icon: Icons.calendar_today_outlined,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (c, child) => Theme(
                                data: Theme.of(c).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: kOrange,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              dateCtrl.text =
                                  '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
                              if (errorMessage != null) {
                                setSheetState(() => errorMessage = null);
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: buildField(
                                ctx: ctx,
                                controller: weightCtrl,
                                label: 'WEIGHT (kg)',
                                hint: 'e.g. 9.5',
                                icon: Icons.monitor_weight_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: buildField(
                                ctx: ctx,
                                controller: heightCtrl,
                                label: 'HEIGHT (cm)',
                                hint: 'e.g. 80',
                                icon: Icons.height,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        buildField(
                          ctx: ctx,
                          controller: muacCtrl,
                          label: 'MUAC (cm)',
                          hint: 'e.g. 16.0',
                          icon: Icons.straighten,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: saving
                                ? null
                                : () async {
                                    setSheetState(() {
                                      errorMessage = null;
                                      saving = true;
                                    });
                                    if (dateCtrl.text.trim().isEmpty ||
                                        weightCtrl.text.trim().isEmpty ||
                                        heightCtrl.text.trim().isEmpty) {
                                      setSheetState(() {
                                        errorMessage =
                                            'Date, weight, and height are required.';
                                        saving = false;
                                      });
                                      return;
                                    }
                                    await _saveNewAssessment(
                                      date: dateCtrl.text.trim(),
                                      weight: weightCtrl.text.trim(),
                                      height: heightCtrl.text.trim(),
                                      muac: muacCtrl.text.trim(),
                                      visitDate:
                                          visitDateCtrl.text.trim(),
                                      visitTime:
                                          visitTimeCtrl.text.trim(),
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: saving
                                  ? kOrange.withOpacity(0.6)
                                  : kOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white),
                                  )
                                : const Text('Save Assessment',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                              foregroundColor: kInkMid),
                          child: const Text('Cancel',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Save New Assessment ────────────────────────────────────────────────────
  Future<void> _saveNewAssessment({
    required String date,
    required String weight,
    required String height,
    required String muac,
    String? visitDate,
    String? visitTime,
    bool? diarrhea,
    bool? fever,
    bool? cough,
    bool? other,
    bool? medications,
    bool? purelyBreastfed,
    String? cfAge,
    String? cfFreq,
    String? cfFood,
    String? mealFreq,
    String? dewormDate,
    bool? dewormNA,
    String? drugGiven,
    String? adverseReactions,
    String? nextDewormDate,
    String? overallRisk,
  }) async {
    final patient = widget.patient;

    final result = AnthropometricCalculator.calculate(
      weightStr: weight,
      heightStr: height,
      ageStr: patient.dateOfBirth.trim().isNotEmpty &&
              date.trim().isNotEmpty
          ? ''
          : patient.age.toString(),
      sexStr: patient.sex,
      dobStr: patient.dateOfBirth,
      measurementDateStr: date,
    );

    final bool wflSaved = result != null &&
        result.weightForHeight != null &&
        result.weightForHeight!.trim().isNotEmpty;

    final normalizedVisitDate = visitDate != null && visitDate.trim().isNotEmpty
        ? parseDate(visitDate.trim())
        : null;

    final data = {
      'visitDate': normalizedVisitDate != null
          ? formatDateForStorage(normalizedVisitDate)
          : '',
      'visitTime': visitTime ?? '',
      'demographic': {
        'firstName': patient.firstName,
        'lastName': patient.lastName,
        'age': patient.age.toString(),
        'sex': patient.sex,
        'address': patient.address,
        'dateOfBirth': patient.dateOfBirth,
        'mother': patient.motherName,
        'motherContact': patient.motherContact,
        'father': patient.fatherName,
        'fatherContact': patient.fatherContact,
      },
      'anthropometric': {
        'dateOfMeasurement': date,
        'weight': weight,
        'height': height,
        'muac': muac,
        'weightForAge': result?.weightForAge ?? '',
        'weightForHeight': result?.weightForHeight ?? '',
        'heightForAge': result?.heightForAge ?? '',
        'bmi': result?.bmi ?? '',
      },
      'healthStatus': {
        'diarrhea': diarrhea ?? false,
        'fever': fever ?? false,
        'cough': cough ?? false,
        'other': other ?? false,
        'medications': medications ?? false,
      },
      'dietary': {
        'purelyBreastfed': purelyBreastfed,
        'cfAge': cfAge ?? '',
        'cfFrequency': cfFreq ?? '',
        'cfFoods': cfFood ?? '',
        'mealFrequency': mealFreq ?? '',
      },
      'deworming': {
        'dateOfLastDeworming': dewormDate ?? '',
        'isNA': dewormNA ?? false,
        'drugGiven': drugGiven,
        'adverseReactions': adverseReactions ?? '',
        'nextDewormingDate': nextDewormDate ?? '',
      },
      'oral': {
        'overallRisk': overallRisk,
      },
    };

    final firestore = FirestoreService();

    try {
      await firestore.saveAssessmentToBarangayPatient(
        patientId: patient.docId,
        assessmentData: data,
      );

      await LocalDbService.instance
          .saveLocalRecord(data, synced: true, firestoreId: patient.docId);

      if (mounted) {
        setState(() => _loading = true);
        await _fetchAssessments();
        final String saveMessage = wflSaved
            ? 'Assessment saved!'
            : 'Assessment saved. Weight for Length/Height was not calculated '
                '(age/height may be outside WHO range).';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(saveMessage),
            backgroundColor: const Color(0xFF2E8B7B),
            duration: wflSaved
                ? const Duration(seconds: 2)
                : const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving assessment: $e');

      await LocalDbService.instance.saveLocalRecord(data, synced: false);

      if (mounted) {
        setState(() => _loading = true);
        await _fetchAssessments();
      }
    }
  }
}