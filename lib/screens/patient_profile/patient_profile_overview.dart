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

class PatientProfileOverview extends StatefulWidget {
  final Patient patient;
  final int initialTabIndex;
  
  /// If true, this patient is from the barangay shared list
  final bool isSharedPatient;
  
  /// Patient ID for shared patients (from barangays collection)
  final String? sharedPatientId;
  
  /// Barangay ID for shared patients
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

class _PatientProfileOverviewState extends State<PatientProfileOverview> {
  List<Map<String, dynamic>> _assessments = [];
  bool _loading = true;
  late int _currentTabIndex;

  // Preferred contact method state (persisted to Firestore)
  bool _preferPhoneCall = true;
  bool _preferSMS = false;

  // Tab titles shown in the top bar
  static const _tabTitles = [
    'PROFILE',
    'PARENT CONTACT',
  ];

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
    _fetchAssessments();
    _loadContactPreferences();
  }

  /// Load saved preferred contact method from Firestore
  Future<void> _loadContactPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || widget.patient.docId.isEmpty) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('homepageData')
          .doc(widget.patient.docId)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        final prefs = data['contactPreferences'] as Map<String, dynamic>? ?? {};
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

  /// Save preferred contact method to Firestore
  Future<void> _saveContactPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || widget.patient.docId.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('homepageData')
          .doc(widget.patient.docId)
          .set({
        'contactPreferences': {
          'phoneCall': _preferPhoneCall,
          'sms': _preferSMS,
        },
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving contact preferences: $e');
    }
  }

  Map<String, dynamic> _extractAssessment(
      Map<String, dynamic> data, String docId) {
    final anthropometric = data['anthropometric'] ?? {};
    final healthStatus = data['healthStatus'];
    final dietary = data['dietary'];
    final oral = data['oral'];
    final deworming = data['deworming'];
    final createdAt = data['createdAt'] as Timestamp?;

    // Use dateOfMeasurement from the anthropometric form as the primary date,
    // falling back to the Firestore createdAt timestamp
    DateTime? measurementDate;
    final dateOfMeasurement =
        anthropometric['dateOfMeasurement']?.toString() ?? '';
    if (dateOfMeasurement.isNotEmpty) {
      measurementDate = _parseDate(dateOfMeasurement);
    }
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
      'healthStatus': healthStatus,
      'dietary': dietary,
      'oral': oral,
      'deworming': deworming,
      'docId': docId,
    };
  }

  bool _namesMatch(String storedFirst, String storedLast) {
    final patientFirst = widget.patient.firstName.trim().toLowerCase();
    final patientLast = widget.patient.lastName.trim().toLowerCase();
    final first = storedFirst.trim().toLowerCase();
    final last = storedLast.trim().toLowerCase();

    // Exact match
    if (first == patientFirst && last == patientLast) return true;

    // Also try matching full name in case stored differently
    final storedFull = '$first $last';
    final patientFull = '$patientFirst $patientLast';
    if (storedFull == patientFull) return true;

    return false;
  }

  Future<void> _fetchAssessments() async {
    try {
      final firestoreService = FirestoreService();
      
      // If this is a shared patient, fetch from barangay assessments
      if (widget.isSharedPatient && widget.sharedPatientId != null) {
        final assessments = await firestoreService.getAssessmentsForBarangayPatient(
          widget.sharedPatientId!,
        );
        
        final List<Map<String, dynamic>> processed = [];
        for (var assessment in assessments) {
          processed.add(_extractAssessment(assessment, assessment['id']));
        }
        
        // Sort by date ascending
        processed.sort((a, b) {
          final dateA = a['date'] as DateTime?;
          final dateB = b['date'] as DateTime?;
          if (dateA == null || dateB == null) return 0;
          return dateA.compareTo(dateB);
        });
        
        setState(() {
          _assessments = processed;
          _loading = false;
        });
        return;
      }
      
      // Otherwise, use the original personal data logic
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('homepageData')
          .get();

      final List<Map<String, dynamic>> matched = [];
      Map<String, dynamic>? fallbackByDocId;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final demographic = data['demographic'] ?? {};
        final firstName = (demographic['firstName'] ?? '').toString();
        final lastName = (demographic['lastName'] ?? '').toString();

        // Also check 'name' field as fallback
        final nameField = (demographic['name'] ?? '').toString();

        debugPrint(
            '[ProfileOverview] Doc ${doc.id}: firstName="$firstName", lastName="$lastName", name="$nameField"');

        // Save the doc matching by docId as a fallback
        if (doc.id == widget.patient.docId) {
          fallbackByDocId = data;
        }

        if (_namesMatch(firstName, lastName)) {
          matched.add(_extractAssessment(data, doc.id));
        } else if (nameField.isNotEmpty) {
          // Try matching against the 'name' field
          final parts = nameField.trim().split(RegExp(r'\s+'));
          final derivedFirst = parts.isNotEmpty ? parts.first : '';
          final derivedLast =
              parts.length > 1 ? parts.sublist(1).join(' ') : '';
          if (_namesMatch(derivedFirst, derivedLast)) {
            matched.add(_extractAssessment(data, doc.id));
          }
        }
      }

      // If no matches by name, use the original document as fallback
      if (matched.isEmpty && fallbackByDocId != null) {
        debugPrint(
            '[ProfileOverview] Name match failed, using docId fallback: ${widget.patient.docId}');
        matched.add(
            _extractAssessment(fallbackByDocId, widget.patient.docId));
      }

      debugPrint('[ProfileOverview] Total assessments found: ${matched.length}');

      // Sort by date ascending
      matched.sort((a, b) {
        final dateA = a['date'] as DateTime?;
        final dateB = b['date'] as DateTime?;
        if (dateA == null || dateB == null) return 0;
        return dateA.compareTo(dateB);
      });

      setState(() {
        _assessments = matched;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching assessments: $e');
      setState(() => _loading = false);
    }
  }

  /// Try to parse common date string formats (MM/DD/YYYY, YYYY-MM-DD, etc.)
  DateTime? _parseDate(String dateStr) {
    try {
      // Try MM/DD/YYYY
      final slashParts = dateStr.split('/');
      if (slashParts.length == 3) {
        final month = int.tryParse(slashParts[0]);
        final day = int.tryParse(slashParts[1]);
        final year = int.tryParse(slashParts[2]);
        if (month != null && day != null && year != null) {
          return DateTime(year, month, day);
        }
      }
      // Try YYYY-MM-DD
      return DateTime.tryParse(dateStr);
    } catch (_) {
      return null;
    }
  }


  // ===== Build the main profile/overview tab content =====
  Widget _buildProfileTab() {
    final patient = widget.patient;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // ===== AVATAR + INFO CARD =====
          ProfileInfoCard(patient: patient),
          const SizedBox(height: 20),

          // ===== ASSESSMENT TABLE =====
          AssessmentTable(
            patientId: widget.sharedPatientId ?? widget.patient.docId,
            assessments: _assessments,
            loading: _loading,
            onAddAssessment: _showAddAssessmentSheet, 
            saveNewAssessment: null, // We'll handle this in the sheet
          ),
          const SizedBox(height: 20),

          // ===== Z-SCORE INTERPRETATION TRENDS =====
          TrendsSection(assessments: _assessments),
          const SizedBox(height: 20),

          // ===== STATUS SECTIONS =====
          StatusSections(assessments: _assessments),
          const SizedBox(height: 20),

          // ===== OVERALL NUTRITIONAL STATUS =====
          OverallNutritionalStatusSection(
            assessments: _assessments,
            onReturnToDashboard: () => Navigator.pop(context),
          ),
          const SizedBox(height: 24),

          // ===== VACCINATION STATUS =====
          VaccinationStatusSection(
            firstName: patient.firstName,
            lastName: patient.lastName,
            //patientId: widget.isSharedPatient ? widget.sharedPatientId : null,
            //barangayId: widget.isSharedPatient ? widget.barangayId : null,
            //useSharedStorage: widget.isSharedPatient,
            patientId: patient.docId,        // ✅ Always use docId
            barangayId: patient.barangayId,  // ✅ Always use barangayId
            useSharedStorage: true,           // ✅ Always shared!
          ),
          const SizedBox(height: 20),

          // ===== DEWORMING STATUS =====
          DewormingStatusSection(
            assessments: _assessments,
            onReturnToDashboard: () => Navigator.pop(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ===== Tab body selector =====
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
              // ===== TOP BAR =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _tabTitles[_currentTabIndex],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            if (widget.isSharedPatient) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'SHARED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // balance the back button
                  ],
                ),
              ),

              // ===== TAB CONTENT =====
              Expanded(child: _buildTabBody()),
            ],
          ),
        ),
      ),

      // ===== BOTTOM NAVIGATION BAR =====
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ===== Bottom navigation bar matching the mockup =====
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2E8B7B),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              icon: Icons.bar_chart_rounded,
              index: 0,
              label: 'Overview',
            ),
            _buildNavItem(
              icon: Icons.contact_page_outlined,
              index: 1,
              label: 'Contact',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required String label,
  }) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? Colors.white : Colors.white54,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ===== ADD NEW ASSESSMENT BOTTOM SHEET =====
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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'New Assessment',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E8B7B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (widget.isSharedPatient) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF2E8B7B).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.people, size: 12, color: Color(0xFF2E8B7B)),
                                SizedBox(width: 4),
                                Text(
                                  'Shared',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E8B7B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.patient.firstName} ${widget.patient.lastName}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Inline error message
                    if (errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFEF5350),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFFEF5350), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFC62828),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildTextField(
                      controller: dateCtrl,
                      label: 'Date of Measurement',
                      hint: 'MM/DD/YYYY',
                      icon: Icons.calendar_today,
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
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: weightCtrl,
                      label: 'Weight (kg)',
                      hint: 'e.g. 9.5',
                      icon: Icons.monitor_weight_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: heightCtrl,
                      label: 'Height (cm)',
                      hint: 'e.g. 80',
                      icon: Icons.height,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: muacCtrl,
                      label: 'MUAC (cm)',
                      hint: 'e.g. 16',
                      icon: Icons.straighten,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (dateCtrl.text.trim().isEmpty ||
                                    weightCtrl.text.trim().isEmpty ||
                                    heightCtrl.text.trim().isEmpty) {
                                  setSheetState(() {
                                    errorMessage =
                                        'Please fill in date, weight, and height.';
                                  });
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
                          backgroundColor: const Color(0xFF2E8B7B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 3,
                          disabledBackgroundColor: const Color(0xFF2E8B7B).withOpacity(0.6),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: onTap != null,
      onTap: onTap,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2E8B7B),
        ),
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: Colors.grey[400],
        ),
        prefixIcon: Icon(icon, color: const Color(0xFFF5A962), size: 22),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E8B7B), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  /*Future<void> _saveNewAssessment({
    required String date,
    required String weight,
    required String height,
    required String muac,
  }) async {
    final patient = widget.patient;

    // Calculate anthropometric classifications
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
        'firstName': patient.firstName,
        'lastName': patient.lastName,
        'age': patient.age.toString(),
        'sex': patient.sex,
        'address': patient.address,
        'dateOfBirth': patient.dateOfBirth,
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
    };

    final firestore = FirestoreService();
    
    try {
      // If shared patient, save to barangay assessments
      if (widget.isSharedPatient && widget.sharedPatientId != null) {
        await firestore.saveAssessmentToBarangayPatient(
          patientId: widget.sharedPatientId!,
          assessmentData: data,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assessment saved to shared patient record.'),
              backgroundColor: Color(0xFF2E8B7B),
            ),
          );
        }
      } else {
        // Otherwise save to personal homepageData
        final online = await ConnectivityService.instance.checkOnline();
        
        if (online) {
          final docId = await firestore.saveHomePageData(data);
          await LocalDbService.instance
              .saveLocalRecord(data, synced: true, firestoreId: docId);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Assessment saved successfully.'),
                backgroundColor: Color(0xFF2E8B7B),
              ),
            );
          }
        } else {
          await LocalDbService.instance.saveLocalRecord(data, synced: false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No internet: saved locally and will sync when online.'),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error saving assessment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving assessment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Refresh the assessment table
    setState(() => _loading = true);
    await _fetchAssessments();
  }
*/

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

  // Calculate anthropometric classifications
  final result = AnthropometricCalculator.calculate(
    weightStr: weight,
    heightStr: height,
    ageStr: patient.age.toString(),
    sexStr: patient.sex,
    dobStr: patient.dateOfBirth,
    measurementDateStr: date,
  );

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Complete assessment saved to shared patient record!'),
          backgroundColor: Color(0xFF2E8B7B),
        ),
      );
    }
  } catch (e) {
    debugPrint('Error saving assessment: $e');
    
    // Fallback to local storage
    await LocalDbService.instance.saveLocalRecord(data, synced: false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved locally, will sync later: $e'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  // Refresh the assessment table
  setState(() => _loading = true);
  await _fetchAssessments();
}



}