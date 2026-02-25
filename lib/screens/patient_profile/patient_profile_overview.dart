import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../patient_list.dart';
import '../../services/anthropometric_calculator.dart';
import '../../services/firestore_service.dart';
import '../../services/local_db_service.dart';
import '../../services/connectivity_service.dart';
import 'widgets/profile_info_card.dart';
import 'widgets/assessment_table.dart';
import 'widgets/trends_section.dart';
import 'widgets/status_sections.dart';
import 'widgets/overall_nutritional_status.dart';
import 'widgets/vaccination_status.dart';
import 'widgets/deworming_status.dart';
import 'widgets/parent_contact_tab.dart';
import 'package:lumasdang/screens/shared/app_buttom_navbar.dart'; // ← adjust path if needed

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
  // ── Bottom nav tab controller ──────────────────────────────────────────────
  late final TabController _tabController;

  List<Map<String, dynamic>> _assessments = [];
  bool _loading = true;
  late int _currentTabIndex;

  bool _preferPhoneCall = true;
  bool _preferSMS = false;


  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        Navigator.pop(context);
      }
    });

    _fetchAssessments();
    _loadContactPreferences();
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

      final online = await ConnectivityService.instance.checkOnline();
      if (!online || LocalDbService.instance.offlineAuthenticated) {
        // Try to load from local DB
        await LocalDbService.instance.init();
        final all = await LocalDbService.instance.getAllRecords(includeDeleted: true);
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
    } catch (e) { debugPrint('Error loading contact preferences: $e'); }
  }

  Future<void> _saveContactPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || widget.patient.docId.isEmpty) return;

      final online = await ConnectivityService.instance.checkOnline();
      if (!online || LocalDbService.instance.offlineAuthenticated) {
        await LocalDbService.instance.init();
        // Update local record if exists, otherwise create a minimal record
        final all = await LocalDbService.instance.getAllRecords(includeDeleted: true);
        final matchIndex = all.indexWhere((r) => (r['id'] == widget.patient.docId) || (r['firestoreId'] == widget.patient.docId));
        if (matchIndex >= 0) {
          // fetch the underlying box key by scanning box
          for (final key in LocalDbService.instance.box.keys) {
            final value = LocalDbService.instance.box.get(key);
            if (value is Map) {
              if ((value['id'] == widget.patient.docId) || (value['firestoreId'] == widget.patient.docId)) {
                final updated = Map<String, dynamic>.from(value);
                final data = Map<String, dynamic>.from(updated['data'] ?? {});
                data['contactPreferences'] = {'phoneCall': _preferPhoneCall, 'sms': _preferSMS};
                updated['data'] = data;
                updated['lastModified'] = DateTime.now().toIso8601String();
                await LocalDbService.instance.box.put(key, updated);
                break;
              }
            }
          }
        } else {
          // Create a new minimal local record
          final data = {'contactPreferences': {'phoneCall': _preferPhoneCall, 'sms': _preferSMS}};
          await LocalDbService.instance.saveLocalRecord(data, synced: false, firestoreId: widget.patient.docId);
        }
        return;
      }

      await FirebaseFirestore.instance
          .collection('users').doc(user.uid)
          .collection('homepageData').doc(widget.patient.docId)
          .set({'contactPreferences': {'phoneCall': _preferPhoneCall, 'sms': _preferSMS}},
              SetOptions(merge: true));
    } catch (e) { debugPrint('Error saving contact preferences: $e'); }
  }

  // ── Assessment fetching ────────────────────────────────────────────────────
  Map<String, dynamic> _extractAssessment(Map<String, dynamic> data, String docId) {
    final anthropometric = data['anthropometric'] ?? {};
    final createdAt = data['createdAt'];
    DateTime? measurementDate;
    final dateOfMeasurement = anthropometric['dateOfMeasurement']?.toString() ?? '';
    if (dateOfMeasurement.isNotEmpty) measurementDate = _parseDate(dateOfMeasurement);
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
      'docId': docId,
    };
  }

  bool _namesMatch(String storedFirst, String storedLast) {
    final patientFirst = widget.patient.firstName.trim().toLowerCase();
    final patientLast = widget.patient.lastName.trim().toLowerCase();
    final first = storedFirst.trim().toLowerCase();
    final last = storedLast.trim().toLowerCase();
    if (first == patientFirst && last == patientLast) return true;
    return '$first $last' == '$patientFirst $patientLast';
  }

  Map<String, String>? _computeLocalVaccinationStatuses() {
    if (_assessments.isEmpty) return null;

    // Find the most recent assessment that has vaccination data.
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

    Map<String, dynamic>? dosesFor(String vaccine) {
      final raw = vaccination[vaccine];
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return null;
    }

    int highestDoseNumber(String vaccine) {
      final doses = dosesFor(vaccine);
      if (doses == null) return 0;
      const birth = 'BIRTH';
      const m1_5 = '1½';
      const m2_5 = '2½';
      const m3_5 = '3½';
      const m9 = '9';
      const y1 = '1 YR';
      List<String> relevantHeaders;
      switch (vaccine) {
        case 'BCG':
          relevantHeaders = [birth];
          break;
        case 'HEP B':
          relevantHeaders = [birth, m1_5, m2_5];
          break;
        case 'PENTAVALENT':
          relevantHeaders = [m1_5, m2_5, m3_5, y1];
          break;
        case 'OPV':
          relevantHeaders = [birth, m2_5, m9];
          break;
        case 'IPV':
          relevantHeaders = [m1_5, m2_5, m3_5, y1];
          break;
        case 'PCV':
          relevantHeaders = [m1_5, m2_5, m3_5, y1];
          break;
        case 'MMR':
          relevantHeaders = [m9, y1];
          break;
        default:
          relevantHeaders = [birth, m1_5, m2_5, m3_5, m9, y1];
      }
      for (int i = relevantHeaders.length - 1; i >= 0; i--) {
        if (doses[relevantHeaders[i]] == true) return i + 1;
      }
      return 0;
    }

    String doseLabelForNumber(int number) {
      if (number <= 0) return 'Pending';
      switch (number) {
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
        doseLabelForNumber(highestDoseNumber(name));
    final opvNumber = highestDoseNumber('OPV');
    final ipvNumber = highestDoseNumber('IPV');

    // Keys here must match _vaccines keys in VaccinationStatusSection.
    return <String, String>{
      'bcg': vaccineStatus('BCG'),
      'hepatitisB': vaccineStatus('HEP B'),
      'dtap': vaccineStatus('PENTAVALENT'),
      'opv': vaccineStatus('OPV'),
      'ipv': vaccineStatus('IPV'),
      'mmr': vaccineStatus('MMR'),
      'pcv': vaccineStatus('PCV'),
    };
  }

  Future<void> _fetchAssessments() async {
    try {
      final firestoreService = FirestoreService();
      final user = FirebaseAuth.instance.currentUser;
      final List<Map<String, dynamic>> matched = [];

      // 1) Always load local cached assessments (offline‑first)
      try {
        await LocalDbService.instance.init();
        final localRecords =
            await LocalDbService.instance.getAllRecords(includeDeleted: false);

        for (final record in localRecords) {
          final rawData = record['data'] as Map<String, dynamic>?;
          if (rawData == null) continue;

          final data = Map<String, dynamic>.from(rawData);
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

          // Attach a createdAt value usable by _extractAssessment.
          final createdAtString =
              (record['lastModified'] ?? record['timestamp'])?.toString();
          if (createdAtString != null) {
            data['createdAt'] = createdAtString;
          }

          final docId =
              (record['firestoreId'] as String?) ??
              (record['id'] as String?) ??
              widget.patient.docId;

          matched.add(_extractAssessment(data, docId));
        }
      } catch (e) {
        debugPrint('[ProfileOverview] Error loading local assessments: $e');
      }

      // If there is no Firebase user, we can still show the local data.
      if (user == null) {
        final finalList = List<Map<String, dynamic>>.from(matched)
          ..sort((a, b) =>
              (a['date'] as DateTime?)
                  ?.compareTo(b['date'] as DateTime? ?? DateTime(1970)) ?? 0);
        setState(() {
          _assessments = finalList;
          _loading = false;
        });
        return;
      }

      // 2) When online, enrich with Firestore data
      final online = await ConnectivityService.instance.checkOnline();
      if (online) {
        if (widget.isSharedPatient && widget.sharedPatientId != null) {
          final assessments = await firestoreService
              .getAssessmentsForBarangayPatient(widget.sharedPatientId!);
          matched.addAll(
            assessments.map((a) => _extractAssessment(a, a['id'])).toList(),
          );
        } else {
          // Barangay‑level shared assessments for this patient
          try {
            final barangayAssessments = await firestoreService
                .getAssessmentsForBarangayPatient(widget.patient.docId);
            matched.addAll(
              barangayAssessments
                  .map((a) => _extractAssessment(a, a['id']))
                  .toList(),
            );
          } catch (e) {
            debugPrint(
                '[ProfileOverview] Error fetching barangay assessments: $e');
          }

          // Legacy user‑scoped homepageData assessments
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
              final firstName = (demographic['firstName'] ?? '').toString();
              final lastName = (demographic['lastName'] ?? '').toString();
              final nameField = (demographic['name'] ?? '').toString();
              if (doc.id == widget.patient.docId) {
                fallbackByDocId = data;
              }
              if (_namesMatch(firstName, lastName)) {
                matched.add(_extractAssessment(data, doc.id));
              } else if (nameField.isNotEmpty) {
                final parts = nameField.trim().split(RegExp(r'\s+'));
                final derivedFirst = parts.isNotEmpty ? parts.first : '';
                final derivedLast =
                    parts.length > 1 ? parts.sublist(1).join(' ') : '';
                if (_namesMatch(derivedFirst, derivedLast)) {
                  matched.add(_extractAssessment(data, doc.id));
                }
              }
            }

            if (matched.isEmpty && fallbackByDocId != null) {
              matched.add(
                  _extractAssessment(fallbackByDocId, widget.patient.docId));
            }
          } catch (e) {
            debugPrint(
                '[ProfileOverview] Error fetching user homepageData: $e');
          }
        }
      }

      // 3) De‑duplicate and sort all sources together
      final unique = <String, Map<String, dynamic>>{};
      for (var a in matched) {
        final key =
            '${a['docId']}-${(a['date'] as DateTime?)?.millisecondsSinceEpoch ?? 0}';
        unique.putIfAbsent(key, () => a);
      }
      final finalList = unique.values.toList()
        ..sort((a, b) =>
            (a['date'] as DateTime?)
                ?.compareTo(b['date'] as DateTime? ?? DateTime(1970)) ?? 0);

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
    } catch (_) { return null; }
  }

  // ── Tab bodies ─────────────────────────────────────────────────────────────
  Widget _buildProfileTab() {
    final patient = widget.patient;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          ProfileInfoCard(patient: patient),
          const SizedBox(height: 20),
          AssessmentTable(
            patientId: widget.sharedPatientId ?? widget.patient.docId,
            assessments: _assessments,
            loading: _loading,
            onAddAssessment: _showAddAssessmentSheet,
            saveNewAssessment: null,
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
          DewormingStatusSection(assessments: _assessments),
          const SizedBox(height: 24),

          // ── Return button ─────────────────────────────────────────────
          /*GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withOpacity(0.35), width: 1),
              ),
              /*child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Return to Dashboard',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ],
              ),*/
            ),
          ),*/
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
          patient: widget.patient,
          preferPhoneCall: _preferPhoneCall,
          preferSMS: _preferSMS,
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
      // ── BOTTOM NAV BAR ────────────────────────────────────────────────────
      //bottomNavigationBar: AppBottomNavBar(controller: _tabController),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E8B7B),
              Color(0xFF5CAA7F),
              Color(0xFF8BC88A)
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

  // ── Top bar with inline tab switcher ──────────────────────────────────────
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
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.35), width: 1.2),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${widget.patient.firstName} ${widget.patient.lastName}',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

  // ── Add assessment sheet ───────────────────────────────────────────────────
  /*void _showAddAssessmentSheet() {
    final dateCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final heightCtrl = TextEditingController();
    final muacCtrl = TextEditingController();
    bool saving = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2E8B7B), Color(0xFF5CAA7F)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border:
                  Border.all(color: Colors.white.withOpacity(0.28), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.35), width: 1),
                        ),
                        child: const Icon(Icons.add_chart_outlined,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('New Assessment',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3)),
                            Text(
                                '${widget.patient.firstName} ${widget.patient.lastName}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.7))),
                          ],
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
                                color: Colors.white.withOpacity(0.35),
                                width: 1),
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
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.35),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFDC2626).withOpacity(0.5),
                            width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(errorMessage!,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _buildSheetField(
                    ctx: ctx,
                    controller: dateCtrl,
                    label: 'Date of Measurement',
                    hint: 'MM/DD/YYYY',
                    icon: Icons.calendar_today_outlined,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
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
                  _buildSheetField(
                    ctx: ctx,
                    controller: weightCtrl,
                    label: 'Weight (kg)',
                    hint: 'e.g. 9.5',
                    icon: Icons.monitor_weight_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                  ),
                  const SizedBox(height: 10),
                  _buildSheetField(
                    ctx: ctx,
                    controller: heightCtrl,
                    label: 'Height (cm)',
                    hint: 'e.g. 80',
                    icon: Icons.height,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                  ),
                  const SizedBox(height: 10),
                  _buildSheetField(
                    ctx: ctx,
                    controller: muacCtrl,
                    label: 'MUAC (cm)',
                    hint: 'e.g. 16',
                    icon: Icons.straighten,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: saving
                        ? null
                        : () async {
                            if (dateCtrl.text.trim().isEmpty ||
                                weightCtrl.text.trim().isEmpty ||
                                heightCtrl.text.trim().isEmpty) {
                              setSheetState(() => errorMessage =
                                  'Please fill in date, weight, and height.');
                              return;
                            }
                            setSheetState(
                                () { errorMessage = null; saving = true; });
                            await _saveNewAssessment(
                              date: dateCtrl.text.trim(),
                              weight: weightCtrl.text.trim(),
                              height: heightCtrl.text.trim(),
                              muac: muacCtrl.text.trim(),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: saving
                            ? const Color(0xFF1B2A3B).withOpacity(0.5)
                            : const Color(0xFF1B2A3B),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: saving
                            ? []
                            : [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4)),
                              ],
                      ),
                      child: Center(
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_outlined,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Save Assessmentdd',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          letterSpacing: 0.4)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }*/

  /*void _showAddAssessmentSheet() {
  final dateCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final muacCtrl = TextEditingController();

  bool saving = false;
  String? errorMessage;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 245, 246, 246),
                  Color.fromARGB(255, 251, 253, 252),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.28),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.add_chart_outlined,
                          color: Color.fromARGB(255, 228, 119, 9),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'New Assessment',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color.fromARGB(255, 233, 42, 9),
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              '${widget.patient.firstName} ${widget.patient.lastName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.isSharedPatient)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.35),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'SHARED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Divider
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Error message
                  if (errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFDC2626).withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Fields
                  _buildSheetField(
                    ctx: ctx,
                    controller: dateCtrl,
                    label: 'Date of Measurement',
                    hint: 'MM/DD/YYYY',
                    icon: Icons.calendar_today_outlined,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
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

                  _buildSheetField(
                    ctx: ctx,
                    controller: weightCtrl,
                    label: 'Weight (kg)',
                    hint: 'e.g. 9.5',
                    icon: Icons.monitor_weight_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 10),

                  _buildSheetField(
                    ctx: ctx,
                    controller: heightCtrl,
                    label: 'Height (cm)',
                    hint: 'e.g. 80',
                    icon: Icons.height,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 10),

                  _buildSheetField(
                    ctx: ctx,
                    controller: muacCtrl,
                    label: 'MUAC (cm)',
                    hint: 'e.g. 16',
                    icon: Icons.straighten,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),

                  const SizedBox(height: 22),

                  // ✅ ElevatedButton
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (dateCtrl.text.trim().isEmpty ||
                                  weightCtrl.text.trim().isEmpty ||
                                  heightCtrl.text.trim().isEmpty) {
                                setSheetState(() => errorMessage =
                                    'Please fill in date, weight, and height.');
                                return;
                              }

                              setSheetState(() {
                                errorMessage = null;
                                saving = true;
                              });

                              await _saveNewAssessment(
                                date: dateCtrl.text.trim(),
                                weight: weightCtrl.text.trim(),
                                height: heightCtrl.text.trim(),
                                muac: muacCtrl.text.trim(),
                              );

                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                      style: ElevatedButton.styleFrom(
                       // backgroundColor:
                           // saving ? _orange.withOpacity(0.6) : _orange,
                            backgroundColor: saving
                              ? const Color(0xFFF59E0B).withOpacity(0.6)
                              : const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_outlined, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Save Assessment',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}*/


/*void _showAddAssessmentSheet() {
  final dateCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final muacCtrl = TextEditingController();

  bool saving = false;
  String? errorMessage;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 255, 255, 255),
                  Color(0xFF5CAA7F),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.28),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.add_chart_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'New Assessment',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              '${widget.patient.firstName} ${widget.patient.lastName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.isSharedPatient)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.35),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'SHARED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Divider
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Error message
                  if (errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFDC2626).withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Fields
                  _buildSheetField(
                    ctx: ctx,
                    controller: dateCtrl,
                    label: 'Date of Measurement',
                    hint: 'MM/DD/YYYY',
                    icon: Icons.calendar_today_outlined,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
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

                  _buildSheetField(
                    ctx: ctx,
                    controller: weightCtrl,
                    label: 'Weight (kg)',
                    hint: 'e.g. 9.5',
                    icon: Icons.monitor_weight_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 10),

                  _buildSheetField(
                    ctx: ctx,
                    controller: heightCtrl,
                    label: 'Height (cm)',
                    hint: 'e.g. 80',
                    icon: Icons.height,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 10),

                  _buildSheetField(
                    ctx: ctx,
                    controller: muacCtrl,
                    label: 'MUAC (cm)',
                    hint: 'e.g. 16',
                    icon: Icons.straighten,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),

                  const SizedBox(height: 22),

                  // ✅ WHITE BUTTON WITH ORANGE CONTENT
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (dateCtrl.text.trim().isEmpty ||
                                  weightCtrl.text.trim().isEmpty ||
                                  heightCtrl.text.trim().isEmpty) {
                                setSheetState(() => errorMessage =
                                    'Please fill in date, weight, and height.');
                                return;
                              }

                              setSheetState(() {
                                errorMessage = null;
                                saving = true;
                              });

                              await _saveNewAssessment(
                                date: dateCtrl.text.trim(),
                                weight: weightCtrl.text.trim(),
                                height: heightCtrl.text.trim(),
                                muac: muacCtrl.text.trim(),
                              );

                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: saving
                            ? Colors.white.withOpacity(0.7)
                            : Colors.white,
                        foregroundColor:
                            const Color(0xFFF59E0B), // ORANGE
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
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
                                color: Color(0xFFF59E0B),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_outlined, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Save Assessment',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}*/
// ─────────────────────────────────────────────────────────────────────────────
//  _showAddAssessmentSheet — consistent with VaccinationStatusSection style
// ─────────────────────────────────────────────────────────────────────────────

void _showAddAssessmentSheet() {
  final dateCtrl   = TextEditingController();
  final weightCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final muacCtrl   = TextEditingController();

  bool    saving       = false;
  String? errorMessage;

  // ── Design Tokens (matches VaccinationStatusSection) ──────────────────────
  const kOrange       = Color(0xFFF08030);
  const kOrangeLight  = Color(0xFFF5A962);
  const kAmberBg      = Color(0xFFFFF6EE);
  const kSurface      = Color(0xFFFFFFFF);
  const kSurfaceDim   = Color(0xFFFAFAFA);
  const kBorder       = Color(0xFFE8E8ED);
  const kInk          = Color(0xFF1C1C1E);
  const kInkMid       = Color(0xFF6C6C70);
  const kRCard        = 18.0;
  const kRInner       = 12.0;

  // ── Shared field builder ───────────────────────────────────────────────────
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
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: kInkMid,
              letterSpacing: 1.0,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: onTap != null,
          onTap: onTap,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kInk,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: kInkMid.withOpacity(0.55),
            ),
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
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: kSurfaceDim,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(kRCard)),
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

                // ── Orange accent bar (matches card top accent) ────────────
                Container(
                  height: 5,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kOrangeLight, kOrange],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // ── Drag handle ────────────────────────────────────
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: kBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // ── Header row ─────────────────────────────────────
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kOrange.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add_chart_outlined,
                              color: kOrange,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'New Assessment',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: kInk,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.patient.firstName} ${widget.patient.lastName}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: kInkMid,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // SHARED badge — matches _sharedBadge() style
                          if (widget.isSharedPatient)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [kOrangeLight, kOrange]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people_rounded,
                                      size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Shared',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // ── Divider ────────────────────────────────────────
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: kBorder),
                      ),

                      // ── Error banner ───────────────────────────────────
                      if (errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: kAmberBg,
                            borderRadius: BorderRadius.circular(kRInner),
                            border: Border.all(
                              color: kOrange.withOpacity(0.40),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: kOrange, size: 17),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: kOrange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── Section label ──────────────────────────────────
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'MEASUREMENT DETAILS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: kInkMid,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Date field ─────────────────────────────────────
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

                      // ── Weight + Height side by side ───────────────────
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

                      // ── MUAC ───────────────────────────────────────────
                      buildField(
                        ctx: ctx,
                        controller: muacCtrl,
                        label: 'MUAC (cm)',
                        hint: 'e.g. 16.0',
                        icon: Icons.straighten,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),

                      const SizedBox(height: 22),

                      // ── Save button — matches VaccinationStatusSection ─
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (dateCtrl.text.trim().isEmpty ||
                                      weightCtrl.text.trim().isEmpty ||
                                      heightCtrl.text.trim().isEmpty) {
                                    setSheetState(() => errorMessage =
                                        'Date, weight, and height are required.');
                                    return;
                                  }
                                  setSheetState(() {
                                    errorMessage = null;
                                    saving = true;
                                  });
                                  await _saveNewAssessment(
                                    date:   dateCtrl.text.trim(),
                                    weight: weightCtrl.text.trim(),
                                    height: heightCtrl.text.trim(),
                                    muac:   muacCtrl.text.trim(),
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                saving ? kOrange.withOpacity(0.6) : kOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Assessment',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),

                      // ── Cancel link ────────────────────────────────────
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(foregroundColor: kInkMid),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
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


  Widget _buildSheetField({
    required BuildContext ctx,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.white.withOpacity(0.28), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: onTap != null,
        onTap: onTap,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.75)),
          hintText: hint,
          hintStyle: TextStyle(
              fontSize: 13, color: Colors.white.withOpacity(0.4)),
          prefixIcon:
              Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // (removed duplicate older implementation)

// ============================================================================
// SIMPLE FIX: Update _saveNewAssessment to save ALL data
// Replace your existing _saveNewAssessment method with this
// ============================================================================

Future<void> _saveNewAssessment({
  required String date,
  required String weight,
  required String height,
  required String muac,
  // Add optional parameters for complete data
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

  // Calculate anthropometric classifications. Use empty ageStr when DOB + measurement date exist
  // so the calculator uses exact age in months from dates (avoids age-in-years vs months confusion).
  final result = AnthropometricCalculator.calculate(
    weightStr: weight,
    heightStr: height,
    ageStr: patient.dateOfBirth.trim().isNotEmpty && date.trim().isNotEmpty
        ? ''
        : patient.age.toString(),
    sexStr: patient.sex,
    dobStr: patient.dateOfBirth,
    measurementDateStr: date,
  );

  // Track whether Weight for Length/Height (Lt/Ht) was saved and why not if missing
  final bool wflSaved = result != null &&
      result.weightForHeight != null &&
      result.weightForHeight!.trim().isNotEmpty;
  if (!wflSaved) {
    debugPrint(
      '[Lumasdang] Assessment save: Weight for Length/Height (Lt/Ht) will NOT be saved. '
      'weight=$weight, height=$height, DOB=${patient.dateOfBirth}, date=$date, sex=${patient.sex}. '
      'Reason: ${result == null ? "calculator returned null (see AnthropometricCalculator log above)" : "calculator did not return weightForHeight (often age/height outside WHO range)"}',
    );
  }

  // ✅ NOW INCLUDES ALL DATA - just like home page
  final data = {
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
    // ✅ ADD HEALTH STATUS
    'healthStatus': {
      'diarrhea': diarrhea ?? false,
      'fever': fever ?? false,
      'cough': cough ?? false,
      'other': other ?? false,
      'medications': medications ?? false,
    },
    // ✅ ADD DIETARY
    'dietary': {
      'purelyBreastfed': purelyBreastfed,
      'cfAge': cfAge ?? '',
      'cfFrequency': cfFreq ?? '',
      'cfFoods': cfFood ?? '',
      'mealFrequency': mealFreq ?? '',
    },
    // ✅ ADD DEWORMING
    'deworming': {
      'dateOfLastDeworming': dewormDate ?? '',
      'isNA': dewormNA ?? false,
      'drugGiven': drugGiven,
      'adverseReactions': adverseReactions ?? '',
      'nextDewormingDate': nextDewormDate ?? '',
    },
    // ✅ ADD ORAL ASSESSMENT
    'oral': {
      'overallRisk': overallRisk,
    },
  };

  final firestore = FirestoreService();
  
  try {
    // ✅ ALWAYS save to barangay shared storage
    await firestore.saveAssessmentToBarangayPatient(
      patientId: patient.docId,  // Use patient.docId directly
      assessmentData: data,
    );
    
    // Also save locally
    await LocalDbService.instance
        .saveLocalRecord(data, synced: true, firestoreId: patient.docId);
    
    if (mounted) {
      final String saveMessage = wflSaved
          ? '✅ Complete assessment saved to shared patient record!'
          : '✅ Assessment saved. Weight for Length/Height was not calculated (age/height may be outside WHO range: 0–2y length 45–110 cm, 2–5y height 65–120 cm). See console for details.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saveMessage),
          backgroundColor: const Color(0xFF2E8B7B),
          duration: wflSaved ? const Duration(seconds: 2) : const Duration(seconds: 5),
        ),
      );
    }
  } catch (e) {
    debugPrint('Error saving assessment: $e');
    
    // Fallback to local storage
    await LocalDbService.instance.saveLocalRecord(data, synced: false);
    
    if (mounted) {
      setState(() => _loading = true);
      await _fetchAssessments();
    }
  }
}
}