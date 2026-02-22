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
import '../../services/assessment_service.dart';
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

  static const _tabTitles = ['PROFILE', 'PARENT CONTACT'];

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

  // ── Snackbar ───────────────────────────────────────────────────────────────
  void _snack(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontSize: 13)),
      backgroundColor: color ?? const Color(0xFF2E8B7B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Contact preferences ────────────────────────────────────────────────────
  Future<void> _loadContactPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || widget.patient.docId.isEmpty) return;
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid)
          .collection('homepageData').doc(widget.patient.docId).get();
      if (doc.exists) {
        final prefs = (doc.data() ?? {})['contactPreferences'] as Map<String, dynamic>? ?? {};
        if (mounted) setState(() {
          _preferPhoneCall = prefs['phoneCall'] ?? true;
          _preferSMS = prefs['sms'] ?? false;
        });
      }
    } catch (e) { debugPrint('Error loading contact preferences: $e'); }
  }

  Future<void> _saveContactPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || widget.patient.docId.isEmpty) return;
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
    final createdAt = data['createdAt'] as Timestamp?;
    DateTime? measurementDate;
    final dateOfMeasurement = anthropometric['dateOfMeasurement']?.toString() ?? '';
    if (dateOfMeasurement.isNotEmpty) measurementDate = _parseDate(dateOfMeasurement);
    measurementDate ??= createdAt?.toDate();
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

  Future<void> _fetchAssessments() async {
    try {
      final firestoreService = FirestoreService();
      if (widget.isSharedPatient && widget.sharedPatientId != null) {
        final assessments = await firestoreService
            .getAssessmentsForBarangayPatient(widget.sharedPatientId!);
        final processed = assessments
            .map((a) => _extractAssessment(a, a['id']))
            .toList();
        processed.sort((a, b) =>
            (a['date'] as DateTime?)
                ?.compareTo(b['date'] as DateTime? ?? DateTime(1970)) ?? 0);
        setState(() { _assessments = processed; _loading = false; });
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) { setState(() => _loading = false); return; }

      final List<Map<String, dynamic>> matched = [];
      try {
        final barangayAssessments = await firestoreService
            .getAssessmentsForBarangayPatient(widget.patient.docId);
        matched.addAll(barangayAssessments
            .map((a) => _extractAssessment(a, a['id'])));
      } catch (e) {
        debugPrint('[ProfileOverview] Error fetching barangay assessments: $e');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).collection('homepageData').get();
      Map<String, dynamic>? fallbackByDocId;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final demographic = data['demographic'] ?? {};
        final firstName = (demographic['firstName'] ?? '').toString();
        final lastName = (demographic['lastName'] ?? '').toString();
        final nameField = (demographic['name'] ?? '').toString();
        if (doc.id == widget.patient.docId) fallbackByDocId = data;
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
        matched.add(_extractAssessment(fallbackByDocId, widget.patient.docId));
      }

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

      setState(() { _assessments = finalList; _loading = false; });
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
      bottomNavigationBar: AppBottomNavBar(controller: _tabController),

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

  void _showAddAssessmentSheet() {
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
                  Color(0xFF2E8B7B),
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

  // ── Save assessment ────────────────────────────────────────────────────────
  Future<void> _saveNewAssessment({
    required String date,
    required String weight,
    required String height,
    required String muac,
    bool? diarrhea, bool? fever, bool? cough, bool? other, bool? medications,
    bool? purelyBreastfed, String? cfAge, String? cfFreq, String? cfFood,
    String? mealFreq, String? dewormDate, bool? dewormNA, String? drugGiven,
    String? adverseReactions, String? nextDewormDate, String? overallRisk,
  }) async {
    final patient = widget.patient;
    final result = AnthropometricCalculator.calculate(
      weightStr: weight,
      heightStr: height,
      ageStr: patient.age.toString(),
      sexStr: patient.sex,
      dobStr: patient.dateOfBirth,
      measurementDateStr: date,
    );

    final data = {
      'demographic': {
        'firstName': patient.firstName, 'lastName': patient.lastName,
        'age': patient.age.toString(), 'sex': patient.sex,
        'address': patient.address, 'dateOfBirth': patient.dateOfBirth,
        'mother': patient.motherName, 'motherContact': patient.motherContact,
        'father': patient.fatherName, 'fatherContact': patient.fatherContact,
      },
      'anthropometric': {
        'dateOfMeasurement': date, 'weight': weight, 'height': height,
        'muac': muac,
        'weightForAge': result?.weightForAge ?? '',
        'weightForHeight': result?.weightForHeight ?? '',
        'heightForAge': result?.heightForAge ?? '',
        'bmi': result?.bmi ?? '',
      },
      'healthStatus': {
        'diarrhea': diarrhea ?? false, 'fever': fever ?? false,
        'cough': cough ?? false, 'other': other ?? false,
        'medications': medications ?? false,
      },
      'dietary': {
        'purelyBreastfed': purelyBreastfed, 'cfAge': cfAge ?? '',
        'cfFrequency': cfFreq ?? '', 'cfFoods': cfFood ?? '',
        'mealFrequency': mealFreq ?? '',
      },
      'deworming': {
        'dateOfLastDeworming': dewormDate ?? '', 'isNA': dewormNA ?? false,
        'drugGiven': drugGiven, 'adverseReactions': adverseReactions ?? '',
        'nextDewormingDate': nextDewormDate ?? '',
      },
      'oral': {'overallRisk': overallRisk},
    };

    try {
      await FirestoreService().saveAssessmentToBarangayPatient(
        patientId: patient.docId, assessmentData: data,
      );
      await LocalDbService.instance.saveLocalRecord(data,
          synced: true, firestoreId: patient.docId);
      if (mounted) _snack('Assessment saved successfully.');
    } catch (e) {
      debugPrint('Error saving assessment: $e');
      await LocalDbService.instance.saveLocalRecord(data, synced: false);
      if (mounted) {
        _snack('Saved locally, will sync later.', color: Colors.orange);
      }
    }

    if (mounted) {
      setState(() => _loading = true);
      await _fetchAssessments();
    }
  }
}