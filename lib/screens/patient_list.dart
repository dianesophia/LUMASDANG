import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'patient_profile/patient_profile_overview.dart';
// import 'opt_plus/opt_plus_screen.dart';
import 'lumasdang_records/lumasdang_records_screen.dart';
import 'archived_patients_screen.dart';
import '../services/age_utils.dart';
import '../services/auto_archive_preferences.dart';
import '../services/connectivity_service.dart';
import '../services/local_db_service.dart';
import 'shared/status_color.dart';
import 'package:flutter/foundation.dart';

// ==================== APP BOTTOM NAV BAR ====================

class AppBottomNavBar extends StatelessWidget {
  final TabController controller;
  final List<Tab>? tabs;

  const AppBottomNavBar({
    super.key,
    required this.controller,
    this.tabs,
  });

  static const List<Tab> _defaultTabs = [
    Tab(icon: Icon(Icons.home_outlined,          size: 22), text: 'Home'),
    Tab(icon: Icon(Icons.people_outline,         size: 22), text: 'Patients'),
    Tab(icon: Icon(Icons.notifications_outlined, size: 22), text: 'Alerts'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E8B7B), Color(0xFF5CAA7F)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: TabBar(
          controller: controller,
          tabs: tabs ?? _defaultTabs,
          indicator: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.55),
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

// ==================== PATIENT LIST SCREEN ====================

class PatientListScreen extends StatefulWidget {
  final ValueNotifier<int>? refreshTrigger;

  const PatientListScreen({super.key, this.refreshTrigger});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E8B7B), Color(0xFF5CAA7F)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              const Center(
                child: Text('Home', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              PatientListTab(refreshTrigger: widget.refreshTrigger),
              const Center(
                child: Text('Alerts', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(controller: _tabController),
    );
  }
}

// ==================== FILTER MODEL ====================

/// Holds all active filter state so it can be passed around cleanly.
class _FilterState {
  // Age range in months (null = no limit)
  int? ageMinMonths;
  int? ageMaxMonths;

  // Sex filter: null = all, 'Male' / 'Female'
  String? sex;

  // Malnutrition type: null = all, else one of the status labels
  String? malnutritionType;

  // Screened period: null = all, 'week' or 'month'
  String? screenedPeriod;

  bool get hasActiveFilters =>
      ageMinMonths != null ||
      ageMaxMonths != null ||
      sex != null ||
      malnutritionType != null ||
      screenedPeriod != null;

  void reset() {
    ageMinMonths = null;
    ageMaxMonths = null;
    sex = null;
    malnutritionType = null;
    screenedPeriod = null;
  }
}

// ==================== PATIENT LIST TAB ====================
class PatientListTab extends StatefulWidget {
  final ValueNotifier<int>? refreshTrigger;
  final bool showOnlyMalnourished;

  const PatientListTab({
    super.key,
    this.refreshTrigger,
    this.showOnlyMalnourished = false,
  });

  @override
  State<PatientListTab> createState() => _PatientListTabState();
}

class _PatientListTabState extends State<PatientListTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _sortAscending = true;
  String _searchQuery = '';
  bool _loading = true;
  List<Patient> _patients = [];
  bool _selectionMode = false;
  final Set<String> _selectedDocIds = {};
  bool _deleting = false;

  // ── NEW: filter state ──────────────────────────────────────────────────────
  final _FilterState _filters = _FilterState();

  // Age-group presets (months)
  static const List<_AgePreset> _agePresets = [
    _AgePreset('0–6 mo',   0,   6),
    _AgePreset('7–12 mo',  7,  12),
    _AgePreset('1–2 yrs', 13,  24),
    _AgePreset('2–3 yrs', 25,  36),
    _AgePreset('3–5 yrs', 37,  59),
  ];

  static const List<String> _sexOptions = ['Male', 'Female'];

  static const List<String> _malnutritionOptions = [
    'Underweight',
    'Stunted',
    'Overweight/Obese',
    'At Risk',
    'Normal',
  ];

  static const List<_PeriodOption> _periodOptions = [
    _PeriodOption('This Week',  'week'),
    _PeriodOption('This Month', 'month'),
  ];
  // ── END filter state ───────────────────────────────────────────────────────

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

  String _buildAssessmentRemarks(Map<String, dynamic> data, int assessmentCount) {
    if (assessmentCount == 0) return 'No assessments';

    final rawAnthro = data['anthropometric'];
    final Map<String, dynamic> anthropometric;
    if (rawAnthro is Map<String, dynamic>) {
      anthropometric = rawAnthro;
    } else if (rawAnthro is Map) {
      anthropometric = Map<String, dynamic>.from(rawAnthro);
    } else {
      anthropometric = <String, dynamic>{};
    }

    final double? weightForAge    = _extractZScore(anthropometric['weightForAge']?.toString());
    final double? heightForAge    = _extractZScore(anthropometric['heightForAge']?.toString());
    final double? weightForHeight = _extractZScore(anthropometric['weightForHeight']?.toString());
    final double? bmi             = _extractBmiZScore(anthropometric['bmi']?.toString());

    if (weightForAge == null && heightForAge == null &&
        weightForHeight == null && bmi == null) {
      return 'Assessment done';
    }

    if (weightForAge != null && weightForAge < -2) return 'Underweight';
    if (heightForAge != null && heightForAge < -2) return 'Stunted';
    if ((weightForHeight != null && weightForHeight > 1) ||
        (bmi != null && bmi > 2)) return 'Overweight/Obese';

    final atRisk = (weightForAge != null && weightForAge >= -2 && weightForAge < -1) ||
        (heightForAge != null && heightForAge >= -2 && heightForAge < -1) ||
        (weightForHeight != null && weightForHeight >= -2 && weightForHeight < -1) ||
        (bmi != null && bmi >= -2 && bmi < -1);
    if (atRisk) return 'At Risk';

    return 'Normal';
  }

  @override
  void initState() {
    super.initState();
    _fetchPatients();
    widget.refreshTrigger?.addListener(_onRefreshTriggered);
  }

  void _onRefreshTriggered() {
    if (mounted) _fetchPatients();
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedDocIds.clear();
    });
  }

  void _toggleSelection(Patient patient) {
    setState(() {
      if (_selectedDocIds.contains(patient.docId)) {
        _selectedDocIds.remove(patient.docId);
      } else {
        _selectedDocIds.add(patient.docId);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      final allVisibleIds = _filteredPatients.map((p) => p.docId).toSet();
      final allSelected = allVisibleIds.every((id) => _selectedDocIds.contains(id));
      if (allSelected) {
        _selectedDocIds.removeAll(allVisibleIds);
      } else {
        _selectedDocIds.addAll(allVisibleIds);
      }
    });
  }

  // ── SINGLE-ROW SOFT DELETE ─────────────────────────────────────────────────
  Future<void> _confirmAndSoftDeleteSingle(Patient patient) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xFFFFEDED),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Delete Patient Record?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF444444),
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'The record for '),
                        TextSpan(
                          text: '${patient.firstName} ${patient.lastName}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(
                          text: ' will be hidden from the patient list. '
                              'It can be restored later from the archived records.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2E8B7B),
                            side: const BorderSide(color: Color(0xFF2E8B7B)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancel',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(ctx, true),
                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                          label: const Text('Delete',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await _softDeletePatient(patient);
      if (mounted) {
        await _fetchPatients();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${patient.firstName} ${patient.lastName} has been deleted.'),
            backgroundColor: const Color(0xFF2E8B7B),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _softDeletePatient(Patient patient) async {
    final user = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;
    final deletedBy = user?.email ?? user?.uid ?? 'unknown';

    if (patient.barangayId.isNotEmpty) {
      final ref = firestore
          .collection('barangays')
          .doc(patient.barangayId)
          .collection('patients')
          .doc(patient.docId);
      final snap = await ref.get();
      if (snap.exists) {
        await ref.update({
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
          'deletedBy': deletedBy,
        });
        return;
      }
    }

    if (user != null) {
      final ref = firestore
          .collection('users')
          .doc(user.uid)
          .collection('homepageData')
          .doc(patient.docId);
      final snap = await ref.get();
      if (snap.exists) {
        await ref.update({
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
          'deletedBy': deletedBy,
        });
      }
    }
  }

  // ── BULK SOFT DELETE ───────────────────────────────────────────────────────
  Future<void> _confirmAndSoftDelete() async {
    if (_selectedDocIds.isEmpty) return;
    final count = _selectedDocIds.length;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xFFFFEDED),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.redAccent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Delete $count Record${count > 1 ? 's' : ''}?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                children: [
                  Text(
                    '$count patient record${count > 1 ? 's' : ''} will be hidden '
                    'from the patient list. They can be restored later from the '
                    'archived records.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF444444),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.orange.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'This action can be undone from Archived Records.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2E8B7B),
                            side: const BorderSide(color: Color(0xFF2E8B7B)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancel',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(ctx, true),
                          icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                          label: Text(
                            'Delete $count',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final firestore = FirebaseFirestore.instance;
      final deletedBy = user?.email ?? user?.uid ?? 'unknown';
      final batch = firestore.batch();
      var hasWrites = false;

      for (final patient in _patients) {
        if (!_selectedDocIds.contains(patient.docId)) continue;

        if (patient.barangayId.isNotEmpty) {
          final barangayRef = firestore
              .collection('barangays')
              .doc(patient.barangayId)
              .collection('patients')
              .doc(patient.docId);

          final barangaySnap = await barangayRef.get();
          if (barangaySnap.exists) {
            batch.update(barangayRef, {
              'isDeleted': true,
              'deletedAt': FieldValue.serverTimestamp(),
              'deletedBy': deletedBy,
            });
            hasWrites = true;
            continue;
          }
        }

        if (user != null) {
          final homeRef = firestore
              .collection('users')
              .doc(user.uid)
              .collection('homepageData')
              .doc(patient.docId);

          final homeSnap = await homeRef.get();
          if (homeSnap.exists) {
            batch.update(homeRef, {
              'isDeleted': true,
              'deletedAt': FieldValue.serverTimestamp(),
              'deletedBy': deletedBy,
            });
            hasWrites = true;
          }
        }
      }

      if (hasWrites) await batch.commit();

      if (mounted) {
        _exitSelectionMode();
        await _fetchPatients();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count record(s) deleted.'),
            backgroundColor: const Color(0xFF2E8B7B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _fetchPatients() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await LocalDbService.instance.init();
      final online = kIsWeb ? true : await ConnectivityService.instance.checkOnline();

      if (!online || LocalDbService.instance.offlineAuthenticated || user == null) {
        final records =
            await LocalDbService.instance.getAllRecords(includeDeleted: false);

        final Map<String, List<Map<String, dynamic>>> patientGroups = {};
        for (final record in records) {
          final rawData = record['data'];
          Map<String, dynamic>? data;
          if (rawData is Map<String, dynamic>) {
            data = rawData;
          } else if (rawData is Map) {
            data = Map<String, dynamic>.from(rawData);
          }
          if (data == null) continue;

          final rawDemo = data['demographic'];
          final Map<String, dynamic> demographic;
          if (rawDemo is Map<String, dynamic>) {
            demographic = rawDemo;
          } else if (rawDemo is Map) {
            demographic = Map<String, dynamic>.from(rawDemo);
          } else {
            demographic = <String, dynamic>{};
          }

          final key =
              '${(demographic['firstName'] ?? '').toString().toLowerCase().trim()}_'
              '${(demographic['lastName'] ?? '').toString().toLowerCase().trim()}';
          if (key.isEmpty || key == '_') continue;
          patientGroups.putIfAbsent(key, () => []);
          patientGroups[key]!.add(data);
        }

        setState(() {
          _patients = patientGroups.entries.map((entry) {
            final recordsForPatient = entry.value;
            final assessmentCount = recordsForPatient.length;

            recordsForPatient.sort((a, b) {
              final tsA = (a['lastModified'] as String?) ??
                  (a['createdAt'] as String?) ?? '';
              final tsB = (b['lastModified'] as String?) ??
                  (b['createdAt'] as String?) ?? '';
              final dA = DateTime.tryParse(tsA) ?? DateTime(1970);
              final dB = DateTime.tryParse(tsB) ?? DateTime(1970);
              return dB.compareTo(dA);
            });

            final mostRecent = recordsForPatient.first;
            final rawDemo = mostRecent['demographic'];
            final Map<String, dynamic> demographic;
            if (rawDemo is Map<String, dynamic>) {
              demographic = rawDemo;
            } else if (rawDemo is Map) {
              demographic = Map<String, dynamic>.from(rawDemo);
            } else {
              demographic = <String, dynamic>{};
            }

            final createdAtStr =
                mostRecent['lastModified'] as String? ??
                mostRecent['createdAt'] as String? ?? '';
            final lastVisit =
                DateTime.tryParse(createdAtStr) ?? DateTime.now();
            final assessmentRemarks =
                _buildAssessmentRemarks(mostRecent, assessmentCount);

            final ageMonths =
                ageInMonthsFromDemographic(demographic) ??
                int.tryParse(demographic['age']?.toString() ?? '0') ?? 0;

            return Patient(
              firstName: demographic['firstName'] ?? '',
              lastName: demographic['lastName'] ?? '',
              age: ageMonths,
              assessmentRemarks: assessmentRemarks,
              lastVisit: lastVisit,
              guardianContact: demographic['fatherContact'] ??
                  demographic['motherContact'] ?? '',
              avatarColor: const Color(0xFF2E8B7B),
              address: demographic['address'] ?? '',
              dateOfBirth: demographic['dateOfBirth'] ?? '',
              sex: demographic['sex'] ?? '',
              docId: (mostRecent['id'] as String?) ?? '',
              motherName: demographic['mother'] ?? '',
              motherContact: demographic['motherContact'] ?? '',
              fatherName: demographic['father'] ?? '',
              fatherContact: demographic['fatherContact'] ?? '',
              createdBy: mostRecent['createdByName'] ?? 'Unknown',
              barangayId: '',
              visitDate: mostRecent['visitDate'] ?? '',
              visitTime: mostRecent['visitTime'] ?? '',
              nextFollowUpDate: null,
              followUpNotes: (mostRecent['followUpNotes'] as String?) ?? '',
            );
          }).toList();
          _loading = false;
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final barangayId = userDoc.data()?['barangayId'] as String?;
      if (barangayId == null) {
        setState(() => _loading = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('barangays')
          .doc(barangayId)
          .collection('patients')
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final archivedDocIds = <String>{};
      final archiveBatch = FirebaseFirestore.instance.batch();
      var hasArchiveUpdates = false;
      final autoArchiveEnabled =
          await AutoArchivePreferences.isAutoArchiveEnabled();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['isArchived'] == true) {
          archivedDocIds.add(doc.id);
          continue;
        }
        if (!autoArchiveEnabled) continue;
        final demographic =
            (data['demographic'] ?? {}) as Map<String, dynamic>;
        final ageMonths = ageInMonthsFromDemographic(demographic);
        if (ageMonths != null && ageMonths >= 60) {
          archivedDocIds.add(doc.id);
          hasArchiveUpdates = true;
          final ref = FirebaseFirestore.instance
              .collection('barangays')
              .doc(barangayId)
              .collection('patients')
              .doc(doc.id);
          archiveBatch.update(ref, {
            'isArchived': true,
            'archivedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      if (hasArchiveUpdates) await archiveBatch.commit();

      final Map<String, List<QueryDocumentSnapshot>> patientGroups = {};
      for (var doc in snapshot.docs) {
        if (archivedDocIds.contains(doc.id)) continue;
        final data = doc.data();
        final demographic = data['demographic'] ?? {};
        final key =
            '${(demographic['firstName'] ?? '').toString().toLowerCase().trim()}_'
            '${(demographic['lastName'] ?? '').toString().toLowerCase().trim()}';
        if (key.isNotEmpty && key != '_') {
          patientGroups.putIfAbsent(key, () => []);
          patientGroups[key]!.add(doc);
        }
      }

      final List<Patient> barangayPatients = patientGroups.entries.map((entry) {
        final docs = entry.value;
        final assessmentCount = docs.length;
        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final timeA =
              (dataA['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final timeB =
              (dataB['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return timeB.compareTo(timeA);
        });

        final mostRecentDoc = docs.first;
        final data = mostRecentDoc.data() as Map<String, dynamic>;
        final demographic = data['demographic'] ?? {};
        final createdAt = data['createdAt'] as Timestamp?;
        final assessmentRemarks =
            _buildAssessmentRemarks(data, assessmentCount);

        final ageMonths = ageInMonthsFromDemographic(demographic) ??
            int.tryParse(demographic['age']?.toString() ?? '0') ?? 0;

        final nextFollowUpTs = data['nextFollowUpDate'] as Timestamp?;
        final followUpNotes = data['followUpNotes'] as String? ?? '';

        return Patient(
          firstName: demographic['firstName'] ?? '',
          lastName: demographic['lastName'] ?? '',
          age: ageMonths,
          assessmentRemarks: assessmentRemarks,
          lastVisit: createdAt?.toDate() ?? DateTime.now(),
          guardianContact: demographic['fatherContact'] ??
              demographic['motherContact'] ?? '',
          avatarColor: const Color(0xFF2E8B7B),
          address: demographic['address'] ?? '',
          dateOfBirth: demographic['dateOfBirth'] ?? '',
          sex: demographic['sex'] ?? '',
          docId: mostRecentDoc.id,
          motherName: demographic['mother'] ?? '',
          motherContact: demographic['motherContact'] ?? '',
          fatherName: demographic['father'] ?? '',
          fatherContact: demographic['fatherContact'] ?? '',
          createdBy: data['createdByName'] ?? 'Unknown',
          barangayId: barangayId,
          visitDate: data['visitDate'] ?? '',
          visitTime: data['visitTime'] ?? '',
          nextFollowUpDate: nextFollowUpTs?.toDate(),
          followUpNotes: followUpNotes,
        );
      }).toList();

      final homeSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('homepageData')
          .get();

      final existingKeys = <String>{};
      for (final p in barangayPatients) {
        final key =
            '${p.firstName.toLowerCase().trim()}_${p.lastName.toLowerCase().trim()}';
        existingKeys.add(key);
      }

      final List<Patient> extraPatients = [];
      for (final doc in homeSnapshot.docs) {
        final data = doc.data();
        if (data['isDeleted'] == true) continue;
        final demographic = data['demographic'] ?? {};
        final firstName = (demographic['firstName'] ?? '').toString();
        final lastName = (demographic['lastName'] ?? '').toString();
        final key =
            '${firstName.toLowerCase().trim()}_${lastName.toLowerCase().trim()}';
        if (key.isEmpty || key == '_' || existingKeys.contains(key)) continue;

        final createdAt = data['createdAt'] as Timestamp?;
        final assessmentRemarks = _buildAssessmentRemarks(data, 1);
        final nextFollowUpTs = data['nextFollowUpDate'] as Timestamp?;
        final followUpNotes = data['followUpNotes'] as String? ?? '';
        final ageMonths = ageInMonthsFromDemographic(demographic) ??
            int.tryParse(demographic['age']?.toString() ?? '0') ?? 0;

        if (autoArchiveEnabled && ageMonths >= 60) continue;

        extraPatients.add(
          Patient(
            firstName: firstName,
            lastName: lastName,
            age: ageMonths,
            assessmentRemarks: assessmentRemarks,
            lastVisit: createdAt?.toDate() ?? DateTime.now(),
            guardianContact: demographic['fatherContact'] ??
                demographic['motherContact'] ?? '',
            avatarColor: const Color(0xFF2E8B7B),
            address: demographic['address'] ?? '',
            dateOfBirth: demographic['dateOfBirth'] ?? '',
            sex: demographic['sex'] ?? '',
            docId: doc.id,
            motherName: demographic['mother'] ?? '',
            motherContact: demographic['motherContact'] ?? '',
            fatherName: demographic['father'] ?? '',
            fatherContact: demographic['fatherContact'] ?? '',
            createdBy: data['createdByName'] ?? 'Unknown',
            barangayId: barangayId,
            visitDate: data['visitDate'] ?? '',
            visitTime: data['visitTime'] ?? '',
            nextFollowUpDate: nextFollowUpTs?.toDate(),
            followUpNotes: followUpNotes,
          ),
        );
      }

      setState(() {
        _patients = [...barangayPatients, ...extraPatients];
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading patients: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // ── FILTERING ──────────────────────────────────────────────────────────────

  /// Returns true when [patient.lastVisit] falls inside the current week or
  /// month (whichever period is selected).
  bool _passesScreenedPeriod(Patient patient) {
    final period = _filters.screenedPeriod;
    if (period == null) return true;

    final now = DateTime.now();
    final visit = patient.lastVisit;

    if (period == 'week') {
      // ISO week: Monday → Sunday
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final end   = start.add(const Duration(days: 7));
      return !visit.isBefore(start) && visit.isBefore(end);
    } else if (period == 'month') {
      return visit.year == now.year && visit.month == now.month;
    }
    return true;
  }

  List<Patient> get _filteredPatients {
    final base = _patients.where((p) {
      // --- Text search ---
      final q = _searchQuery.toLowerCase();
      final matchesSearch = p.lastName.toLowerCase().contains(q) ||
          p.firstName.toLowerCase().contains(q) ||
          p.assessmentRemarks.toLowerCase().contains(q);
      if (!matchesSearch) return false;

      // --- Malnourished-only mode (existing feature) ---
      if (widget.showOnlyMalnourished && !_isMalnourished(p)) return false;

      // --- Age filter ---
      if (_filters.ageMinMonths != null && p.age < _filters.ageMinMonths!) return false;
      if (_filters.ageMaxMonths != null && p.age > _filters.ageMaxMonths!) return false;

      // --- Sex filter ---
      if (_filters.sex != null &&
          p.sex.toLowerCase() != _filters.sex!.toLowerCase()) return false;

      // --- Malnutrition type filter ---
      if (_filters.malnutritionType != null &&
          p.assessmentRemarks.toLowerCase() !=
              _filters.malnutritionType!.toLowerCase()) return false;

      // --- Screened period filter ---
      if (!_passesScreenedPeriod(p)) return false;

      return true;
    }).toList();

    base.sort((a, b) {
      final lastA = a.lastName.toLowerCase().trim();
      final lastB = b.lastName.toLowerCase().trim();
      var cmp = lastA.compareTo(lastB);
      if (cmp == 0) {
        final firstA = a.firstName.toLowerCase().trim();
        final firstB = b.firstName.toLowerCase().trim();
        cmp = firstA.compareTo(firstB);
      }
      return _sortAscending ? cmp : -cmp;
    });
    return base;
  }

  bool _isMalnourished(Patient p) {
    final status = p.assessmentRemarks.toLowerCase();
    return status.contains('underweight');
  }

  // ── FILTER BOTTOM SHEET ────────────────────────────────────────────────────
  void _showFilterSheet() {
    // Working copy so we can cancel without changing live filters.
    final working = _FilterState()
      ..ageMinMonths      = _filters.ageMinMonths
      ..ageMaxMonths      = _filters.ageMaxMonths
      ..sex               = _filters.sex
      ..malnutritionType  = _filters.malnutritionType
      ..screenedPeriod    = _filters.screenedPeriod;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title row
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded,
                            color: Color(0xFF2E8B7B), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Filter Patients',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const Spacer(),
                        if (working.hasActiveFilters)
                          TextButton(
                            onPressed: () {
                              setSheetState(() => working.reset());
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(60, 32),
                            ),
                            child: const Text('Reset all',
                                style: TextStyle(fontSize: 13)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── SECTION: Age Group ──────────────────────────────────
                    _filterSectionLabel('Age Group', Icons.child_care_rounded),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _agePresets.map((preset) {
                        final isSelected = working.ageMinMonths == preset.minMonths &&
                            working.ageMaxMonths == preset.maxMonths;
                        return _FilterChipWidget(
                          label: preset.label,
                          isSelected: isSelected,
                          onTap: () {
                            setSheetState(() {
                              if (isSelected) {
                                working.ageMinMonths = null;
                                working.ageMaxMonths = null;
                              } else {
                                working.ageMinMonths = preset.minMonths;
                                working.ageMaxMonths = preset.maxMonths;
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // ── SECTION: Sex ────────────────────────────────────────
                    _filterSectionLabel('Sex', Icons.wc_rounded),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _sexOptions.map((s) {
                        final isSelected = working.sex == s;
                        return _FilterChipWidget(
                          label: s,
                          icon: s == 'Male'
                              ? Icons.male_rounded
                              : Icons.female_rounded,
                          isSelected: isSelected,
                          onTap: () {
                            setSheetState(() {
                              working.sex = isSelected ? null : s;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // ── SECTION: Type of Malnutrition ───────────────────────
                    _filterSectionLabel(
                        'Type of Malnutrition', Icons.monitor_weight_outlined),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _malnutritionOptions.map((type) {
                        final isSelected = working.malnutritionType == type;
                        return _FilterChipWidget(
                          label: type,
                          isSelected: isSelected,
                          selectedColor: _statusChipColor(type),
                          onTap: () {
                            setSheetState(() {
                              working.malnutritionType = isSelected ? null : type;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // ── SECTION: Screened Period ────────────────────────────
                    _filterSectionLabel(
                        'Screened', Icons.calendar_month_rounded),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _periodOptions.map((p) {
                        final isSelected = working.screenedPeriod == p.value;
                        return _FilterChipWidget(
                          label: p.label,
                          icon: p.value == 'week'
                              ? Icons.view_week_outlined
                              : Icons.calendar_today_outlined,
                          isSelected: isSelected,
                          onTap: () {
                            setSheetState(() {
                              working.screenedPeriod = isSelected ? null : p.value;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // ── Apply / Cancel buttons ──────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2E8B7B),
                              side: const BorderSide(color: Color(0xFF2E8B7B)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Cancel',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _filters.ageMinMonths     = working.ageMinMonths;
                                _filters.ageMaxMonths     = working.ageMaxMonths;
                                _filters.sex              = working.sex;
                                _filters.malnutritionType = working.malnutritionType;
                                _filters.screenedPeriod   = working.screenedPeriod;
                              });
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E8B7B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            child: const Text('Apply Filters',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF2E8B7B)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Color _statusChipColor(String type) {
    switch (type.toLowerCase()) {
      case 'underweight':   return const Color(0xFFE53935);
      case 'stunted':       return const Color(0xFFFF7043);
      case 'overweight/obese': return const Color(0xFFFFA000);
      case 'at risk':       return const Color(0xFFFF8F00);
      case 'normal':        return const Color(0xFF43A047);
      default:              return const Color(0xFF2E8B7B);
    }
  }

  // ── ACTIVE FILTER SUMMARY CHIPS ────────────────────────────────────────────
  Widget _buildActiveFilterChips() {
    final chips = <Widget>[];

    if (_filters.ageMinMonths != null || _filters.ageMaxMonths != null) {
      final label = _agePresets.firstWhere(
        (p) =>
            p.minMonths == _filters.ageMinMonths &&
            p.maxMonths == _filters.ageMaxMonths,
        orElse: () => _AgePreset(
          '${_filters.ageMinMonths}–${_filters.ageMaxMonths} mo',
          _filters.ageMinMonths ?? 0,
          _filters.ageMaxMonths ?? 59,
        ),
      ).label;
      chips.add(_activeChip(label, () => setState(() {
        _filters.ageMinMonths = null;
        _filters.ageMaxMonths = null;
      })));
    }

    if (_filters.sex != null) {
      chips.add(_activeChip(_filters.sex!, () => setState(() {
        _filters.sex = null;
      })));
    }

    if (_filters.malnutritionType != null) {
      chips.add(_activeChip(_filters.malnutritionType!, () => setState(() {
        _filters.malnutritionType = null;
      })));
    }

    if (_filters.screenedPeriod != null) {
      final label = _periodOptions
          .firstWhere((p) => p.value == _filters.screenedPeriod)
          .label;
      chips.add(_activeChip(label, () => setState(() {
        _filters.screenedPeriod = null;
      })));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips),
      ),
    );
  }

  Widget _activeChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF2E8B7B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 13, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefreshTriggered);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    if (_patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_off_outlined,
                size: 40,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No patients found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a patient assessment to get started',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 8),
          _buildActiveFilterChips(),          // ← active filter pills
          const SizedBox(height: 4),
          _buildTopRow(),
          if (_selectionMode) ...[
            const SizedBox(height: 8),
            _buildSelectionBar(),
          ],
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: Colors.white.withOpacity(0.25), width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    _buildTableHeader(),
                    Expanded(child: _buildPatientList()),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildSortButton(),
        ],
      ),
    );
  }

  // ── SEARCH BAR ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search by name or status…',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.grey.shade400, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: Colors.grey.shade400, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // ── Filter button ─────────────────────────────────────────────────
        GestureDetector(
          onTap: _showFilterSheet,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _filters.hasActiveFilters
                  ? const Color(0xFF2E8B7B)
                  : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: _filters.hasActiveFilters
                      ? Colors.white
                      : const Color(0xFF2E8B7B),
                ),
                if (_filters.hasActiveFilters)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── TOP ROW ────────────────────────────────────────────────────────────────
  Widget _buildTopRow() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LumasdangRecordsScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2E8B7B),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.list_alt_rounded, size: 16),
                label: const Text(
                  'Lumasdang Records',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MalnourishedPatientsScreen(),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFB23A48),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.child_care_outlined, size: 16),
                label: const Text(
                  'Malnourished List',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ArchivedPatientsScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2E8B7B),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.archive_outlined, size: 16),
                label: const Text(
                  'Archived (5+ yrs)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              if (_selectionMode) ...[
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _toggleSelectAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _filteredPatients.every(
                                  (p) => _selectedDocIds.contains(p.docId))
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Select All',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline_rounded,
                  color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(
                '${_filteredPatients.length} Patient${_filteredPatients.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── SELECTION BAR ──────────────────────────────────────────────────────────
  Widget _buildSelectionBar() {
    final count = _selectedDocIds.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            count > 0
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            size: 18,
            color: count > 0 ? const Color(0xFF2E8B7B) : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            count == 0 ? 'Long-press a row to select' : '$count selected',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: count > 0 ? const Color(0xFF333333) : Colors.grey,
            ),
          ),
          const Spacer(),
          if (count > 0)
            TextButton.icon(
              onPressed: _deleting ? null : _confirmAndSoftDelete,
              icon: _deleting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.red),
                    )
                  : const Icon(Icons.delete_outline_rounded, size: 16),
              label: Text(_deleting ? 'Deleting…' : 'Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
          TextButton(
            onPressed: _deleting ? null : _exitSelectionMode,
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF2E8B7B))),
          ),
        ],
      ),
    );
  }

  // ── TABLE HEADER ───────────────────────────────────────────────────────────
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 46),
          _headerCell('Last Name', flex: 2),
          _headerCell('First Name', flex: 2),
          _headerCell('Age', flex: 1),
          _headerCell('Status', flex: 2),
          _headerCell('Last Visit', flex: 2),
          _headerCell('Contact', flex: 2),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white.withOpacity(0.85),
          letterSpacing: 0.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ── PATIENT LIST ───────────────────────────────────────────────────────────
  Widget _buildPatientList() {
    final patients = _filteredPatients;
    if (patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list_off_rounded,
                  size: 36, color: Colors.white.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(
                'No patients match the selected filters.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => _filters.reset()),
                child: const Text('Clear Filters',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: patients.length,
      itemBuilder: (context, index) =>
          _buildPatientRow(patients[index], index),
    );
  }

  // ── PATIENT ROW ────────────────────────────────────────────────────────────
  Widget _buildPatientRow(Patient patient, int index) {
    final isSelected = _selectedDocIds.contains(patient.docId);
    final statusColor = getStatusColor(patient.assessmentRemarks);

    final rowContent = Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF2E8B7B).withOpacity(0.15)
            : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: const Color(0xFF2E8B7B).withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: () {
            setState(() {
              _selectionMode = true;
              _selectedDocIds.add(patient.docId);
            });
          },
          onTap: () => _selectionMode
              ? _toggleSelection(patient)
              : _showPatientDetails(patient),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              children: [
                if (_selectionMode)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleSelection(patient),
                      activeColor: const Color(0xFF2E8B7B),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  )
                else
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E8B7B).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://ui-avatars.com/api/?name=${patient.firstName}+${patient.lastName}'
                        '&background=8BC88A&color=fff&size=56',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: const Color(0xFF2E8B7B),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),

                Expanded(
                  flex: 2,
                  child: Text(
                    patient.lastName,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Text(
                    patient.firstName,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF444444)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                Expanded(
                  flex: 1,
                  child: Text(
                    '${patient.age}m',
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF444444)),
                    textAlign: TextAlign.center,
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: statusColor.withOpacity(0.3), width: 0.8),
                      ),
                      child: Text(
                        patient.assessmentRemarks,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Text(
                    '${patient.lastVisit.month.toString().padLeft(2, '0')}/'
                    '${patient.lastVisit.day.toString().padLeft(2, '0')}/'
                    '${patient.lastVisit.year}',
                    style: const TextStyle(
                        fontSize: 9, color: Color(0xFF666666)),
                    textAlign: TextAlign.center,
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _contactIcon(
                        Icons.phone_rounded,
                        const Color(0xFF2E8B7B),
                        _selectionMode ? () {} : () => _handleCall(patient),
                      ),
                      const SizedBox(width: 4),
                      _contactIcon(
                        Icons.sms_rounded,
                        const Color(0xFFF5A962),
                        _selectionMode ? () {} : () => _handleMessage(patient),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (_selectionMode) return rowContent;

    return Dismissible(
      key: ValueKey(patient.docId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        await _confirmAndSoftDeleteSingle(patient);
        return false;
      },
      child: rowContent,
    );
  }

  Widget _contactIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 12, color: color),
      ),
    );
  }

  // ── SORT BUTTON ────────────────────────────────────────────────────────────
  Widget _buildSortButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => setState(() => _sortAscending = !_sortAscending),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _sortAscending
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 14,
                color: const Color(0xFF2E8B7B),
              ),
              const SizedBox(width: 6),
              Text(
                _sortAscending ? 'A → Z' : 'Z → A',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E8B7B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── CONTACT HANDLERS ───────────────────────────────────────────────────────
  String _sanitizePhone(String raw) =>
      raw.replaceAll(RegExp(r'[^\d+]'), '');

  Future<void> _handleCall(Patient patient) async {
    final number = _sanitizePhone(patient.guardianContact);
    if (number.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No guardian contact number to call'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open dialer for $number'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _handleMessage(Patient patient) async {
    final number = _sanitizePhone(patient.guardianContact);
    if (number.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No guardian contact number to message'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'sms', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open messaging app for $number'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ── PATIENT DETAIL DIALOG ──────────────────────────────────────────────────
  void _showPatientDetails(Patient patient) {
    final statusColor = getStatusColor(patient.assessmentRemarks);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E8B7B), Color(0xFF5CAA7F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://ui-avatars.com/api/?name=${patient.firstName}+${patient.lastName}'
                        '&background=ffffff&color=2E8B7B&size=96',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${patient.firstName} ${patient.lastName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 0.8),
                          ),
                          child: Text(
                            patient.assessmentRemarks,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _detailRow(Icons.cake_outlined, 'Age',
                      '${patient.age} months old'),
                  _detailRow(Icons.calendar_today_outlined, 'Last Visit',
                      '${patient.lastVisit.month}/${patient.lastVisit.day}/${patient.lastVisit.year}'),
                  if (patient.visitDate.isNotEmpty)
                    _detailRow(Icons.event_outlined, 'Visit Date',
                        patient.visitDate),
                  if (patient.visitTime.isNotEmpty)
                    _detailRow(Icons.schedule_outlined, 'Visit Time',
                        patient.visitTime),
                  _detailRow(
                    Icons.phone_outlined,
                    'Contact',
                    patient.guardianContact.isEmpty
                        ? '—'
                        : patient.guardianContact,
                  ),
                  _detailRow(Icons.person_outline_rounded, 'Added by',
                      patient.createdBy),
                  if (patient.nextFollowUpDate != null)
                    _detailRow(
                      Icons.event_available_outlined,
                      'Next Follow-up',
                      '${patient.nextFollowUpDate!.month}/${patient.nextFollowUpDate!.day}/${patient.nextFollowUpDate!.year}',
                    ),
                  if (patient.followUpNotes.isNotEmpty)
                    _detailRow(Icons.notes_outlined, 'Notes',
                        patient.followUpNotes),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _openFollowUpDialog(patient),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E8B7B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: const Text('Follow-up',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final result = await Navigator.push<Patient>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PatientProfileOverview(patient: patient),
                              ),
                            );
                            if (result != null && mounted) {
                              await _fetchPatients();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E8B7B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: const Text('View Profile',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _confirmAndSoftDeleteSingle(patient);
                          },
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 16),
                          label: const Text('Delete',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(
                                color: Colors.redAccent, width: 1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2E8B7B),
                            side: const BorderSide(color: Color(0xFF2E8B7B)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Close',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2E8B7B)),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF1A1A1A)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFollowUpDialog(Patient patient) async {
    DateTime selectedDate = patient.nextFollowUpDate ??
        DateTime.now().add(const Duration(days: 30));
    final notesController =
        TextEditingController(text: patient.followUpNotes);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Schedule Follow-up',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_available_outlined,
                        color: Color(0xFF2E8B7B)),
                    title: const Text(
                      'Follow-up Date',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    subtitle: Text(
                      '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: now,
                        lastDate:
                            now.add(const Duration(days: 365 * 3)),
                      );
                      if (picked != null) {
                        setStateDialog(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes for health worker (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF2E8B7B)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8B7B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'You must be online and signed in to save follow-ups'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        return;
      }

      DocumentReference targetRef;
      if (patient.barangayId.isNotEmpty) {
        targetRef = firestore
            .collection('barangays')
            .doc(patient.barangayId)
            .collection('patients')
            .doc(patient.docId);
      } else {
        targetRef = firestore
            .collection('users')
            .doc(user.uid)
            .collection('homepageData')
            .doc(patient.docId);
      }

      await targetRef.update({
        'nextFollowUpDate': Timestamp.fromDate(selectedDate),
        'followUpNotes': notesController.text.trim(),
        'followUpStatus': 'pending',
      });

      await _fetchPatients();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Follow-up saved successfully'),
            backgroundColor: const Color(0xFF2E8B7B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save follow-up: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}

// ==================== HELPER WIDGETS & MODELS ====================

/// A single selectable chip used inside the filter sheet.
class _FilterChipWidget extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const _FilterChipWidget({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = selectedColor ?? const Color(0xFF2E8B7B);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13,
                  color: isSelected ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgePreset {
  final String label;
  final int minMonths;
  final int maxMonths;
  const _AgePreset(this.label, this.minMonths, this.maxMonths);
}

class _PeriodOption {
  final String label;
  final String value;
  const _PeriodOption(this.label, this.value);
}

/// Standalone screen that shows only malnourished / underweight patients.
class MalnourishedPatientsScreen extends StatelessWidget {
  const MalnourishedPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Malnourished / Underweight'),
        backgroundColor: const Color(0xFF2E8B7B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E8B7B), Color(0xFF5CAA7F)],
          ),
        ),
        child: const SafeArea(
          child: PatientListTab(showOnlyMalnourished: true),
        ),
      ),
    );
  }
}

// ==================== PATIENT MODEL ====================
class Patient {
  final String lastName;
  final String firstName;
  final int age;
  final String assessmentRemarks;
  final DateTime lastVisit;
  final String guardianContact;
  final Color avatarColor;
  final String address;
  final String dateOfBirth;
  final String sex;
  final String docId;
  final String motherName;
  final String motherContact;
  final String fatherName;
  final String fatherContact;
  final String createdBy;
  final String barangayId;
  final bool isArchived;
  final String visitDate;
  final String visitTime;
  final DateTime? nextFollowUpDate;
  final String followUpNotes;

  Patient({
    required this.lastName,
    required this.firstName,
    required this.age,
    required this.assessmentRemarks,
    required this.lastVisit,
    required this.guardianContact,
    required this.avatarColor,
    this.address = '',
    this.dateOfBirth = '',
    this.sex = '',
    this.docId = '',
    this.motherName = '',
    this.motherContact = '',
    this.fatherName = '',
    this.fatherContact = '',
    this.createdBy = 'Unknown',
    this.barangayId = '',
    this.isArchived = false,
    this.visitDate = '',
    this.visitTime = '',
    this.nextFollowUpDate,
    this.followUpNotes = '',
  });
}