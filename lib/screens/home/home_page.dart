import 'package:flutter/material.dart';
import 'package:lumasdang/screens/patient_list.dart';
import 'package:lumasdang/screens/settingsPages/main_Settings.dart';
import 'package:lumasdang/screens/notifications_tab.dart';

import '../../services/firestore_service.dart';
import '../../services/local_db_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/vaccine_reminder_service.dart';

import 'widgets/stats_row.dart';
import 'widgets/upcoming_events.dart';
import 'widgets/demographic_data_form.dart';
import 'widgets/anthropometric_data_form.dart';
import 'widgets/health_status_form.dart';
import 'widgets/dietary_assessment_form.dart';
import 'widgets/oral_assessment_form.dart';
import 'widgets/vaccination_form.dart';
import 'widgets/deworming_form.dart';
import 'widgets/family_planning_form.dart';
import 'widgets/nutrition_environment_form.dart';
import 'widgets/allergies_form.dart';
import 'package:flutter/foundation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late TabController _sectionTabController;
  final ScrollController _homeScrollController = ScrollController();

  // ── Form controllers ───────────────────────────────────────────────────────
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController extensionNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController ageDaysController = TextEditingController();
  final TextEditingController ageYearsController = TextEditingController();
  final TextEditingController sexController = TextEditingController();
  final TextEditingController bloodTypeController = TextEditingController();
  // PhilHealth — Mother
  final TextEditingController motherPhilHealthNumberController =
      TextEditingController();
  final TextEditingController motherPhilHealthMemberTypeController =
      TextEditingController();
  // PhilHealth — Father
  final TextEditingController fatherPhilHealthNumberController =
      TextEditingController();
  final TextEditingController fatherPhilHealthMemberTypeController =
      TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController placeOfBirthController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController religionController = TextEditingController();
  final TextEditingController birthWeightController = TextEditingController();
  final TextEditingController birthOrderController = TextEditingController();
  final TextEditingController residenceStatusController =
      TextEditingController();
  final TextEditingController lengthOfStayController = TextEditingController();

  // Mother
  final TextEditingController motherController = TextEditingController();
  final TextEditingController motherContactController = TextEditingController();
  final TextEditingController motherAgeController = TextEditingController();
  final TextEditingController motherOccupationController =
      TextEditingController();

  // Father
  final TextEditingController fatherController = TextEditingController();
  final TextEditingController fatherContactController = TextEditingController();
  final TextEditingController fatherAgeController = TextEditingController();
  final TextEditingController fatherOccupationController =
      TextEditingController();

  // Caregiver
  final TextEditingController caregiverNameController = TextEditingController();
  final TextEditingController caregiverAgeController = TextEditingController();
  final TextEditingController caregiverEthnicityController =
      TextEditingController();
  final TextEditingController caregiverRelationshipController =
      TextEditingController();
  final TextEditingController caregiverReligionController =
      TextEditingController();

  // Household
  final TextEditingController fourPsHouseholdIdController =
      TextEditingController();
  final TextEditingController disabilityController = TextEditingController();

  // Visit
  final TextEditingController visitDateController = TextEditingController();
  final TextEditingController visitTimeController = TextEditingController();

  // Anthropometric
  final TextEditingController measurementDateController =
      TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController muacController = TextEditingController();
  final TextEditingController weightForAgeController = TextEditingController();
  final TextEditingController weightForHeightController =
      TextEditingController();
  final TextEditingController heightForAgeController = TextEditingController();
  final TextEditingController bmiController = TextEditingController();

  // Dietary
  final TextEditingController cfAgeController = TextEditingController();
  final TextEditingController cfFreqController = TextEditingController();
  final TextEditingController cfFoodController = TextEditingController();
  final TextEditingController mealFreqController = TextEditingController();

  // ── State variables ────────────────────────────────────────────────────────
  bool? _belongsToIpGroup;
  String? _ipEthnicity;
  bool? _isFourPsMember;
  bool? _hasDisability;
  String? _selectedSex;
  String? _selectedBloodType;
  String? _residenceStatus;
  String? _selectedMotherStatus;
  String? _selectedFatherStatus;
  String? _selectedCaregiverPresence;
  bool _isSyncing = false;

  bool _diarrhea = false;
  bool _fever = false;
  bool _cough = false;
  bool _other = false;
  bool _medications = false;

  bool? _purelyBreastfed;

  Map<String, dynamic>? _dewormingData;
  Map<String, dynamic>? _oralData;
  Map<String, dynamic>? _vaccinationData;
  Map<String, dynamic>? _familyPlanningData;
  Map<String, dynamic>? _nutritionEnvData;
  Map<String, dynamic>? _allergiesData;

  /// When true, only the basic required fields (patient name, parent names &
  /// contacts) are enforced; all other form validators are skipped.
  bool _isDraft = false;

  // ── Refresh / reset keys ───────────────────────────────────────────────────
  int _statsRefreshKey = 0;
  final ValueNotifier<int> _patientListRefreshTrigger = ValueNotifier<int>(0);
  int _demographicFormKey = 0;
  int _anthropometricFormKey = 0;
  int _dietaryFormKey = 0;
  int _dewormingFormKey = 0;
  int _oralFormKey = 0;
  int _vaccinationFormKey = 0;
  int _familyPlanningFormKey = 0;
  int _nutritionEnvFormKey = 0;
  int _allergiesFormKey = 0;

  // ── Validation ─────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  String? _purelyBreastfedError;
  String? _dewormingError;
  String? _oralRiskError;

  // ── Snackbar helpers ───────────────────────────────────────────────────────
  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13)),
        backgroundColor: color ?? const Color(0xFF2E8B7B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _sectionTabController = TabController(length: 4, vsync: this);

    LocalDbService.instance.init().then((_) async {
      final online = kIsWeb
          ? true
          : await ConnectivityService.instance.checkOnline();
      if (online) {
        final synced = await LocalDbService.instance.syncPending(
          FirestoreService(),
        );
        if (synced > 0 && mounted) {
          _showSnackBar('$synced pending assessment(s) synced.');
        }
        // Check for vaccine doses due today or overdue
        final due = await VaccineReminderService().checkAndFireDueReminders();
        if (due > 0 && mounted) {
          _showSnackBar(
            '$due vaccine dose reminder(s) are due — check Notifications.',
            color: const Color(0xFFF08030),
          );
        }
      }
    });

    ConnectivityService.instance.startMonitoring((online) async {
      if (online) {
        final synced = await LocalDbService.instance.syncPending(
          FirestoreService(),
        );
        if (synced > 0 && mounted) {
          _showSnackBar('$synced pending assessment(s) synced.');
        }
      }
    });
  }

  Future<void> _syncPendingAssessments() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    try {
      final online = kIsWeb
          ? true
          : await ConnectivityService.instance.checkOnline();
      if (!online) {
        _showSnackBar(
          'Offline: sync will run when online.',
          color: const Color(0xFFF08030),
        );
        return;
      }

      final synced = await LocalDbService.instance.syncPending(
        FirestoreService(),
      );
      if (synced > 0) {
        _showSnackBar('$synced pending assessment(s) synced.');
      } else {
        _showSnackBar('No pending assessments to sync.');
      }
    } catch (e) {
      _showSnackBar(
        'Sync failed: ${e.toString()}',
        color: const Color(0xFFEF4444),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    _patientListRefreshTrigger.dispose();
    _tabController.dispose();
    _sectionTabController.dispose();

    // Patient
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    ageController.dispose();
    ageDaysController.dispose();
    ageYearsController.dispose();
    sexController.dispose();
    bloodTypeController.dispose();
    motherPhilHealthNumberController.dispose();
    motherPhilHealthMemberTypeController.dispose();
    fatherPhilHealthNumberController.dispose();
    fatherPhilHealthMemberTypeController.dispose();
    addressController.dispose();
    placeOfBirthController.dispose();
    dobController.dispose();
    religionController.dispose();
    birthWeightController.dispose();
    birthOrderController.dispose();
    residenceStatusController.dispose();
    lengthOfStayController.dispose();
    extensionNameController.dispose();

    // Parents
    motherController.dispose();
    motherContactController.dispose();
    motherAgeController.dispose();
    motherOccupationController.dispose();
    fatherController.dispose();
    fatherContactController.dispose();
    fatherAgeController.dispose();
    fatherOccupationController.dispose();

    // Caregiver
    caregiverNameController.dispose();
    caregiverAgeController.dispose();
    caregiverEthnicityController.dispose();
    caregiverRelationshipController.dispose();
    caregiverReligionController.dispose();

    // Household
    fourPsHouseholdIdController.dispose();
    disabilityController.dispose();

    // Visit
    visitDateController.dispose();
    visitTimeController.dispose();

    // Anthropometric
    measurementDateController.dispose();
    weightController.dispose();
    heightController.dispose();
    muacController.dispose();
    weightForAgeController.dispose();
    weightForHeightController.dispose();
    heightForAgeController.dispose();
    bmiController.dispose();

    // Dietary
    cfAgeController.dispose();
    cfFreqController.dispose();
    cfFoodController.dispose();
    mealFreqController.dispose();

    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  // ── Save Draft ─────────────────────────────────────────────────────────────
  /// Sets draft mode then runs _saveAllData. In draft mode only the basic
  /// required fields (patient name, parent names & contacts) are validated.
  /// All other section validators (oral, deworming, purelyBreastfed, etc.)
  /// are skipped so the record can be saved incomplete.
  Future<void> _saveDraft() async {
    setState(() => _isDraft = true);
    await _saveAllData();
  }

  Future<void> _onSaveAssessmentTapped() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) return;

    final confirmed = await _showAssessmentPreview();
    if (confirmed == true) {
      await _saveAllData();
    }
  }

  Future<bool?> _showAssessmentPreview() {
    final summaryItems = _buildAssessmentSummary();
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Review Assessment'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: summaryItems
                  .map(
                    (item) => _buildSummaryRow(item['label']!, item['value']!),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm & Save'),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, String>> _buildAssessmentSummary() {
    final nameParts = <String>[];
    if (firstNameController.text.trim().isNotEmpty) {
      nameParts.add(firstNameController.text.trim());
    }
    if (middleNameController.text.trim().isNotEmpty) {
      nameParts.add(middleNameController.text.trim());
    }
    if (lastNameController.text.trim().isNotEmpty) {
      nameParts.add(lastNameController.text.trim());
    }
    var patientName = nameParts.join(' ');
    final extensionText = extensionNameController.text.trim();
    if (extensionText.isNotEmpty) {
      patientName = '$patientName $extensionText';
    }

    final motherStatus = _selectedMotherStatus ?? 'Present';
    final fatherStatus = _selectedFatherStatus ?? 'Present';
    final caregiverStatus = _selectedCaregiverPresence ?? 'No';

    return [
      {
        'label': 'Patient Name',
        'value': patientName.isEmpty ? 'N/A' : patientName,
      },
      {'label': 'Sex', 'value': _selectedSex ?? 'N/A'},
      {
        'label': 'Date of Birth',
        'value': dobController.text.trim().isEmpty
            ? 'N/A'
            : dobController.text.trim(),
      },
      {'label': 'Blood Type', 'value': _selectedBloodType ?? 'N/A'},
      {
        'label': 'Birth Weight',
        'value': birthWeightController.text.trim().isEmpty
            ? 'N/A'
            : '${birthWeightController.text.trim()} kg',
      },
      {
        'label': 'Birth Order',
        'value': birthOrderController.text.trim().isEmpty
            ? 'N/A'
            : birthOrderController.text.trim(),
      },
      {
        'label': 'Address',
        'value': addressController.text.trim().isEmpty
            ? 'N/A'
            : addressController.text.trim(),
      },
      {
        'label': 'Place of Birth',
        'value': placeOfBirthController.text.trim().isEmpty
            ? 'N/A'
            : placeOfBirthController.text.trim(),
      },
      {'label': 'Mother Status', 'value': motherStatus},
      {
        'label': 'Mother Name',
        'value': motherController.text.trim().isEmpty
            ? 'N/A'
            : motherController.text.trim(),
      },
      {
        'label': 'Mother Contact',
        'value': motherContactController.text.trim().isEmpty
            ? 'N/A'
            : motherContactController.text.trim(),
      },
      {'label': 'Father Status', 'value': fatherStatus},
      {
        'label': 'Father Name',
        'value': fatherController.text.trim().isEmpty
            ? 'N/A'
            : fatherController.text.trim(),
      },
      {
        'label': 'Father Contact',
        'value': fatherContactController.text.trim().isEmpty
            ? 'N/A'
            : fatherContactController.text.trim(),
      },
      {'label': 'Caregiver Present', 'value': caregiverStatus},
      {'label': '4Ps Member', 'value': _isFourPsMember == true ? 'Yes' : 'No'},
      {
        'label': 'Has Disability',
        'value': _hasDisability == true ? 'Yes' : 'No',
      },
      {'label': 'Residence Status', 'value': _residenceStatus ?? 'N/A'},
    ];
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF444444)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Save All Data ──────────────────────────────────────────────────────────
  Future<void> _saveAllData() async {
    // Run form validators — in draft mode, only the always-required fields
    // (first/last name, parent names + contacts) will fire.
    final isFormValid = _formKey.currentState?.validate() ?? false;
    bool hasNonTextErrors = false;

    if (_isDraft) {
      // Draft: clear all non-text section errors, skip those checks
      setState(() {
        _purelyBreastfedError = null;
        _oralRiskError = null;
        _dewormingError = null;
      });
    } else {
      // Full submit: enforce all section validators
      if (_purelyBreastfed == null) {
        setState(() => _purelyBreastfedError = 'Please select Yes or No');
        hasNonTextErrors = true;
      } else {
        setState(() => _purelyBreastfedError = null);
      }

      if (_oralData == null || _oralData!['overallRisk'] == null) {
        setState(() => _oralRiskError = 'Please select an overall risk level');
        hasNonTextErrors = true;
      } else {
        setState(() => _oralRiskError = null);
      }

      if (_dewormingData == null) {
        setState(
          () => _dewormingError = 'Please fill in deworming information',
        );
        hasNonTextErrors = true;
      } else {
        final dw = _dewormingData!['deworming'] as Map<String, dynamic>?;
        final isNA = dw?['isNA'] == true;
        if (!isNA) {
          if ((dw?['dateOfLastDeworming'] ?? '').toString().trim().isEmpty) {
            setState(
              () => _dewormingError = 'Please enter a date or select N/A',
            );
            hasNonTextErrors = true;
          } else if (dw?['drugGiven'] == null) {
            setState(() => _dewormingError = 'Please select a drug given');
            hasNonTextErrors = true;
          } else {
            setState(() => _dewormingError = null);
          }
        } else {
          setState(() => _dewormingError = null);
        }
      }
    }

    if (!isFormValid || hasNonTextErrors) {
      _showSnackBar(
        _isDraft
            ? 'Please fill in patient name and parent contacts.'
            : 'Please fill in all required fields.',
        color: const Color(0xFFEF4444),
      );
      setState(() => _isDraft = false);
      return;
    }

    final data = {
      'isDraft': _isDraft,
      'visitDate': visitDateController.text.trim(),
      'visitTime': visitTimeController.text.trim(),
      'demographic': {
        'firstName': firstNameController.text.trim(),
        'middleName': middleNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'age': ageController.text.trim(),
        'ageDays': ageDaysController.text.trim(),
        'ageYears': ageYearsController.text.trim(),
        'sex': sexController.text.trim(),
        'bloodType': bloodTypeController.text.trim(),
        'address': addressController.text.trim(),
        'placeOfBirth': placeOfBirthController.text.trim(),
        'dateOfBirth': dobController.text.trim(),
        'belongsToIpGroup': _belongsToIpGroup,
        'ipEthnicity': _ipEthnicity,
        'religion': religionController.text.trim(),
        'birthWeight': birthWeightController.text.trim(),
        'birthOrder': birthOrderController.text.trim(),
        'residenceStatus': residenceStatusController.text.trim(),
        'lengthOfStay': lengthOfStayController.text.trim(),
        'hasDisability': _hasDisability,
        'disability': disabilityController.text.trim(),
        'mother': motherController.text.trim(),
        'motherContact': motherContactController.text.trim(),
        'motherAge': motherAgeController.text.trim(),
        'motherOccupation': motherOccupationController.text.trim(),
        'motherPhilHealthNumber': motherPhilHealthNumberController.text.trim(),
        'motherPhilHealthMemberType': motherPhilHealthMemberTypeController.text
            .trim(),
        'father': fatherController.text.trim(),
        'fatherContact': fatherContactController.text.trim(),
        'fatherAge': fatherAgeController.text.trim(),
        'fatherOccupation': fatherOccupationController.text.trim(),
        'fatherPhilHealthNumber': fatherPhilHealthNumberController.text.trim(),
        'fatherPhilHealthMemberType': fatherPhilHealthMemberTypeController.text
            .trim(),
        'caregiverName': caregiverNameController.text.trim(),
        'caregiverAge': caregiverAgeController.text.trim(),
        'caregiverEthnicity': caregiverEthnicityController.text.trim(),
        'caregiverRelationship': caregiverRelationshipController.text.trim(),
        'caregiverReligion': caregiverReligionController.text.trim(),
        'isFourPsMember': _isFourPsMember,
        'fourPsHouseholdId': fourPsHouseholdIdController.text.trim(),
      },
      'anthropometric': {
        'dateOfMeasurement': measurementDateController.text.trim(),
        'weight': weightController.text.trim(),
        'height': heightController.text.trim(),
        'muac': muacController.text.trim(),
        'weightForAge': weightForAgeController.text.trim(),
        'weightForHeight': weightForHeightController.text.trim(),
        'heightForAge': heightForAgeController.text.trim(),
        'bmi': bmiController.text.trim(),
      },
      'healthStatus': {
        'diarrhea': _diarrhea,
        'fever': _fever,
        'cough': _cough,
        'other': _other,
        'medications': _medications,
      },
      'familyPlanning': _familyPlanningData,
      'dietary': {
        'purelyBreastfed': _purelyBreastfed,
        'cfAge': cfAgeController.text.trim(),
        'cfFrequency': cfFreqController.text.trim(),
        'cfFoods': cfFoodController.text.trim(),
        'mealFrequency': mealFreqController.text.trim(),
      },
      'nutritionEnvironment': _nutritionEnvData,
      'allergies': _allergiesData,
      'deworming': _dewormingData?['deworming'],
      'vitaminA': _dewormingData?['vitaminA'],
      'oral': _oralData,
      'vaccination': _vaccinationData,
    };

    final firestore = FirestoreService();
    final online = kIsWeb
        ? true
        : await ConnectivityService.instance.checkOnline();
    String? barangayPatientId;

    if (online) {
      try {
        final docId = await firestore.saveHomePageData(data);
        try {
          barangayPatientId = await firestore.savePatientToBarangay(data);
          // Save next-dose reminders if vaccination data present
          if (_vaccinationData != null && barangayPatientId != null) {
            try {
              await VaccineReminderService().saveReminders(
                patientId: barangayPatientId!,
                vaccinationData: _vaccinationData!,
                patientInfo: {
                  'firstName': firstNameController.text.trim(),
                  'lastName': lastNameController.text.trim(),
                  'motherContact': motherContactController.text.trim(),
                  'fatherContact': fatherContactController.text.trim(),
                },
              );
            } catch (eReminder) {
              debugPrint('Vaccine reminder save error: $eReminder');
            }
          }
        } catch (eBarangay) {
          debugPrint('Barangay patient save: $eBarangay');
          if (mounted) {
            _showSnackBar(
              'Saved to server but could not add to Patient List.',
              color: Colors.orange,
            );
          }
        }
        await LocalDbService.instance.saveLocalRecord(
          data,
          synced: true,
          firestoreId: docId,
        );
        if (!mounted) return;
        _patientListRefreshTrigger.value++;
        _showSnackBar(
          _isDraft ? 'Draft saved.' : 'Assessment saved to server and locally.',
          color: _isDraft ? const Color(0xFFF5A962) : const Color(0xFF2E8B7B),
        );
      } catch (e) {
        await LocalDbService.instance.saveLocalRecord(data, synced: false);
        if (!mounted) return;
        _showSnackBar(
          'Saved locally (will sync later). Error: ${e.toString()}',
          color: Colors.orange,
        );
      }
    } else {
      await LocalDbService.instance.saveLocalRecord(data, synced: false);
      if (!mounted) return;
      _showSnackBar(
        _isDraft
            ? 'Draft saved locally, will sync when online.'
            : 'No internet: saved locally, will sync when online.',
        color: Colors.orange,
      );
    }

    // ── Sync vaccination status (skip for drafts) ──────────────────────────
    if (_vaccinationData != null && online && !_isDraft) {
      try {
        // Count columns recorded as true, ignoring _date and nextDoseDate keys.
        // Works with any column key names — future-proof.
        int doseCount(String vaccine) {
          final doses = _vaccinationData![vaccine] as Map<String, dynamic>?;
          if (doses == null) return 0;
          return doses.entries
              .where(
                (e) =>
                    !e.key.endsWith('_date') &&
                    e.key != 'nextDoseDate' &&
                    e.value == true,
              )
              .length;
        }

        String doseLabelForCount(String vaccineName, int count) {
          final labels = kVaccineDoseLabels[vaccineName] ?? const <String>[];
          if (count <= 0 || labels.isEmpty) return 'Pending';
          final idx = (count - 1).clamp(0, labels.length - 1);
          return labels[idx];
        }

        // Build statuses keyed by the Firestore/profile camelCase keys.
        // IMPORTANT: only include vaccines that have at least 1 dose selected
        // in this form, so we don't overwrite previously-saved vaccines with
        // `Pending`.
        final statuses = <String, String>{};
        for (final entry in kVaccineNameToKey.entries) {
          final vaccineName = entry.key; // e.g. 'Hepatitis B'
          final firestoreKey = entry.value; // e.g. 'hepatitisB'
          final count = doseCount(vaccineName);
          if (count <= 0) continue;
          statuses[firestoreKey] = doseLabelForCount(vaccineName, count);
        }

        final fs = FirestoreService();
        await fs.saveVaccinationStatus(
          firstName: firstNameController.text.trim(),
          middleName: middleNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          statuses: statuses,
        );

        if (barangayPatientId != null) {
          try {
            final barangayId = await firestore.getCurrentUserBarangayId();
            if (barangayId != null && barangayId.isNotEmpty) {
              await firestore.saveVaccinationStatusToBarangayPatient(
                barangayId: barangayId,
                patientId: barangayPatientId,
                firstName: firstNameController.text.trim(),
                lastName: lastNameController.text.trim(),
                middleName: middleNameController.text.trim(),
                statuses: statuses,
              );
              await firestore.createPatientNotification(
                barangayId: barangayId,
                patientId: barangayPatientId,
                patientData: data,
              );
            }
          } catch (eBarangay) {
            debugPrint('Notification error: $eBarangay');
            if (mounted) {
              _showSnackBar(
                'Saved to server but could not update shared vaccination or notification.',
                color: Colors.orange,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Error syncing vaccination status: $e');
      }
    }

    if (mounted) {
      // Clear all controllers
      for (final c in [
        visitDateController,
        visitTimeController,
        firstNameController,
        middleNameController,
        lastNameController,
        ageController,
        ageDaysController,
        ageYearsController,
        sexController,
        bloodTypeController,
        motherPhilHealthNumberController,
        motherPhilHealthMemberTypeController,
        fatherPhilHealthNumberController,
        fatherPhilHealthMemberTypeController,
        addressController,
        placeOfBirthController,
        dobController,
        religionController,
        birthWeightController,
        birthOrderController,
        residenceStatusController,
        lengthOfStayController,
        motherController,
        motherContactController,
        motherAgeController,
        motherOccupationController,
        fatherController,
        fatherContactController,
        fatherAgeController,
        fatherOccupationController,
        caregiverNameController,
        caregiverAgeController,
        caregiverEthnicityController,
        caregiverRelationshipController,
        caregiverReligionController,
        fourPsHouseholdIdController,
        disabilityController,
        measurementDateController,
        weightController,
        heightController,
        muacController,
        weightForAgeController,
        weightForHeightController,
        heightForAgeController,
        bmiController,
        cfAgeController,
        cfFreqController,
        cfFoodController,
        mealFreqController,
      ]) {
        c.clear();
      }

      setState(() {
        _statsRefreshKey++;
        _demographicFormKey++;
        _anthropometricFormKey++;
        _dietaryFormKey++;
        _dewormingFormKey++;
        _oralFormKey++;
        _vaccinationFormKey++;
        _familyPlanningFormKey++;
        _nutritionEnvFormKey++;
        _allergiesFormKey++;
        _diarrhea = false;
        _fever = false;
        _cough = false;
        _other = false;
        _medications = false;
        _purelyBreastfed = null;
        _purelyBreastfedError = null;
        _belongsToIpGroup = null;
        _ipEthnicity = null;
        _isFourPsMember = null;
        _hasDisability = null;
        _selectedMotherStatus = null;
        _selectedFatherStatus = null;
        _selectedCaregiverPresence = null;
        _oralData = null;
        _oralRiskError = null;
        _vaccinationData = null;
        _dewormingData = null;
        _dewormingError = null;
        _familyPlanningData = null;
        _nutritionEnvData = null;
        _allergiesData = null;
        _isDraft = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _formKey.currentState?.reset();
      });

      setState(() => _statsRefreshKey++);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      bottomNavigationBar: _buildBottomTabBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E8B7B), Color(0xFF5CAA7F), Color(0xFF8BC88A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHomeTab(),
                    _buildPatientListTab(),
                    _buildNotificationsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Lµmasdαng',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _syncPendingAssessments,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 1.2,
                      ),
                    ),
                    child: _isSyncing
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.sync_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MainSettings()),
                  ),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            width: double.infinity,
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
        ],
      ),
    );
  }

  // Widget _buildBottomTabBar() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       gradient: const LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [Color(0xFF2E8B7B), Color(0xFF5CAA7F)],
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.15),
  //           blurRadius: 12,
  //           offset: const Offset(0, -3),
  //         ),
  //       ],
  //     ),
  //     child: SafeArea(
  //       top: false,
  //       child: TabBar(
  //         controller: _tabController,
  //         indicator: BoxDecoration(
  //           color: Colors.white.withOpacity(0.2),
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         indicatorSize: TabBarIndicatorSize.tab,
  //         indicatorPadding:
  //             const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //         dividerColor: Colors.transparent,
  //         labelColor: Colors.white,
  //         unselectedLabelColor: Colors.white.withOpacity(0.55),
  //         labelStyle:
  //             const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
  //         unselectedLabelStyle: const TextStyle(fontSize: 12),
  //         tabs: const [
  //           Tab(icon: Icon(Icons.home_outlined, size: 22), text: 'Home'),
  //           Tab(
  //               icon: Icon(Icons.people_outline, size: 22),
  //               text: 'Patients'),
  //           Tab(
  //               icon: Icon(Icons.notifications_outlined, size: 22),
  //               text: 'Alerts'),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildBottomTabBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F6B5F), Color(0xFF2E8B7B)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.45),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          tabs: const [
            Tab(icon: Icon(Icons.home_rounded, size: 22), text: 'Home'),
            Tab(icon: Icon(Icons.people_rounded, size: 22), text: 'Patients'),
            Tab(
              icon: Icon(Icons.notifications_rounded, size: 22),
              text: 'Alerts',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        Expanded(
          child: NestedScrollView(
            controller: _homeScrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatsRow(
                          key: ValueKey(_statsRefreshKey),
                          onTap: () => _tabController.animateTo(1),
                        ),
                        const SizedBox(height: 16),
                        const UpcomingEvents(),
                        const SizedBox(height: 20),
                        _buildVisitCard(),
                      ],
                    ),
                  ),
                ),
                // SliverPersistentHeader(
                //   pinned: true,
                //   delegate: _HomeSectionTabBarDelegate(
                //     TabBar(
                //       controller: _sectionTabController,
                //       isScrollable: true,
                //       labelColor: Colors.white,
                //       unselectedLabelColor: Colors.white70,
                //       labelStyle: const TextStyle(
                //         fontWeight: FontWeight.w700,
                //         fontSize: 13,
                //       ),
                //       indicator: BoxDecoration(
                //         color: const Color(0xFFF5A962),
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //       tabs: const [
                //         Tab(text: 'Basic Info'),
                //         Tab(text: 'Physical'),
                //         Tab(text: 'Nutrition'),
                //         Tab(text: 'Medical'),
                //       ],
                //     ),
                //   ),
                // ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HomeSectionTabBarDelegate(
                    TabBar(
                      controller: _sectionTabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.55),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      indicator: BoxDecoration(
                        color: const Color(0xFFF5A962),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF5A962).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: EdgeInsets.zero,
                      dividerColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      tabs: const [
                        Tab(text: 'Basic Info'),
                        Tab(text: 'Physical'),
                        Tab(text: 'Nutrition'),
                        Tab(text: 'Medical'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: Form(
              key: _formKey,
              child: TabBarView(
                controller: _sectionTabController,
                children: [
                  _buildBasicInfoSection(),
                  _buildPhysicalAssessmentSection(),
                  _buildNutritionSection(),
                  _buildMedicalSection(),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSaveActionRow(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return SingleChildScrollView(
      key: const PageStorageKey('basic_info_tab'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NEW ASSESSMENT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          DemographicDataForm(
            key: ValueKey('demographic_form_$_demographicFormKey'),
            firstNameController: firstNameController,
            middleNameController: middleNameController,
            lastNameController: lastNameController,
            extensionNameController: extensionNameController,
            ageController: ageController,
            ageDaysController: ageDaysController,
            ageYearsController: ageYearsController,
            sexController: sexController,
            bloodTypeController: bloodTypeController,
            motherPhilHealthNumberController: motherPhilHealthNumberController,
            motherPhilHealthMemberTypeController:
                motherPhilHealthMemberTypeController,
            fatherPhilHealthNumberController: fatherPhilHealthNumberController,
            fatherPhilHealthMemberTypeController:
                fatherPhilHealthMemberTypeController,
            addressController: addressController,
            placeOfBirthController: placeOfBirthController,
            dobController: dobController,
            motherController: motherController,
            motherContactController: motherContactController,
            motherAgeController: motherAgeController,
            motherOccupationController: motherOccupationController,
            fatherController: fatherController,
            fatherContactController: fatherContactController,
            fatherAgeController: fatherAgeController,
            fatherOccupationController: fatherOccupationController,
            religionController: religionController,
            residenceStatusController: residenceStatusController,
            lengthOfStayController: lengthOfStayController,
            birthWeightController: birthWeightController,
            birthOrderController: birthOrderController,
            caregiverNameController: caregiverNameController,
            caregiverAgeController: caregiverAgeController,
            caregiverEthnicityController: caregiverEthnicityController,
            caregiverRelationshipController: caregiverRelationshipController,
            caregiverReligionController: caregiverReligionController,
            fourPsHouseholdIdController: fourPsHouseholdIdController,
            disabilityController: disabilityController,
            belongsToIpGroup: _belongsToIpGroup,
            ipEthnicity: _ipEthnicity,
            isFourPsMember: _isFourPsMember,
            hasDisability: _hasDisability,
            onBelongsToIpGroupChanged: (v) =>
                setState(() => _belongsToIpGroup = v),
            onIpEthnicityChanged: (v) => setState(() => _ipEthnicity = v),
            onIsFourPsMemberChanged: (v) => setState(() => _isFourPsMember = v),
            onHasDisabilityChanged: (v) => setState(() => _hasDisability = v),
            isDraft: _isDraft,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPhysicalAssessmentSection() {
    return SingleChildScrollView(
      key: const PageStorageKey('physical_assessment_tab'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnthropometricDataForm(
            key: ValueKey('anthropometric_form_$_anthropometricFormKey'),
            dateController: measurementDateController,
            weightController: weightController,
            heightController: heightController,
            muacController: muacController,
            weightForAgeController: weightForAgeController,
            weightForHeightController: weightForHeightController,
            heightForAgeController: heightForAgeController,
            bmiController: bmiController,
            ageController: ageController,
            sexController: sexController,
            dobController: dobController,
          ),
          const SizedBox(height: 16),
          HealthStatusForm(
            diarrhea: _diarrhea,
            onDiarrheaChanged: (v) => setState(() => _diarrhea = v),
            fever: _fever,
            onFeverChanged: (v) => setState(() => _fever = v),
            cough: _cough,
            onCoughChanged: (v) => setState(() => _cough = v),
            other: _other,
            onOtherChanged: (v) => setState(() => _other = v),
            medications: _medications,
            onMedicationsChanged: (v) => setState(() => _medications = v),
          ),
          const SizedBox(height: 16),
          AllergiesForm(
            key: ValueKey('allergies_form_$_allergiesFormKey'),
            onDataChanged: (data) => setState(() => _allergiesData = data),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNutritionSection() {
    return SingleChildScrollView(
      key: const PageStorageKey('nutrition_tab'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DietaryAssessmentForm(
            key: ValueKey('dietary_form_$_dietaryFormKey'),
            purelyBreastfed: _purelyBreastfed,
            onPurelyBreastfedChanged: (v) {
              setState(() {
                _purelyBreastfed = v;
                _purelyBreastfedError = null;
              });
            },
            ageWhenCfController: cfAgeController,
            freqCfController: cfFreqController,
            foodCfController: cfFoodController,
            mealFrequencyController: mealFreqController,
            purelyBreastfedError: _purelyBreastfedError,
          ),
          const SizedBox(height: 16),
          NutritionEnvironmentForm(
            key: ValueKey('nutrition_env_form_$_nutritionEnvFormKey'),
            onDataChanged: (data) => setState(() => _nutritionEnvData = data),
          ),
          const SizedBox(height: 16),
          FamilyPlanningForm(
            key: ValueKey('fp_form_$_familyPlanningFormKey'),
            onDataChanged: (data) => setState(() => _familyPlanningData = data),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMedicalSection() {
    return SingleChildScrollView(
      key: const PageStorageKey('medical_tab'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OralAssessmentForm(
            key: ValueKey('oral_form_$_oralFormKey'),
            onDataChanged: (data) {
              _oralData = data;
              setState(() => _oralRiskError = null);
            },
            overallRiskError: _oralRiskError,
          ),
          const SizedBox(height: 16),
          VaccinationForm(
            key: ValueKey('vaccination_form_$_vaccinationFormKey'),
            onDataChanged: (data) => _vaccinationData = data,
          ),
          const SizedBox(height: 16),
          DewormingForm(
            key: ValueKey('deworming_form_$_dewormingFormKey'),
            onSave: (map) {
              setState(() {
                _dewormingData = map;
                _dewormingError = null;
              });
            },
            errorText: _dewormingError,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSaveActionRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _saveDraft,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.7),
                  width: 1.5,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Save Draft',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _onSaveAssessmentTapped,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5A962), Color(0xFFF08030)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF5A962).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Save Assessment',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisitCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5A962), Color(0xFFF08030)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF5A962).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'VISIT DATE & TIME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF5A962),
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              // ── Date of Visit ───────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DATE OF VISIT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF5A962),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFFF5A962),
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Color(0xFF1A1A1A),
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFF5A962),
                                ),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            visitDateController.text =
                                '${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}-${picked.year}';
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: visitDateController,
                          readOnly: true,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tap to select',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: Colors.black26,
                            ),
                            prefixIcon: const Icon(
                              Icons.calendar_month_outlined,
                              size: 16,
                              color: Color(0xFFF5A962),
                            ),
                            suffixIcon: visitDateController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () => setState(
                                      () => visitDateController.clear(),
                                    ),
                                    child: const Icon(
                                      Icons.clear,
                                      size: 14,
                                      color: Colors.black38,
                                    ),
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFEEEEEE),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFF5A962),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ── Time of Visit ────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TIME OF VISIT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF5A962),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () async {
                        final now = TimeOfDay.now();
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: now,
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFFF5A962),
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Color(0xFF1A1A1A),
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFF5A962),
                                ),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null && mounted) {
                          final hour = picked.hourOfPeriod == 0
                              ? 12
                              : picked.hourOfPeriod;
                          final minute = picked.minute.toString().padLeft(
                            2,
                            '0',
                          );
                          final period = picked.period == DayPeriod.am
                              ? 'AM'
                              : 'PM';
                          setState(() {
                            visitTimeController.text = '$hour:$minute $period';
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: visitTimeController,
                          readOnly: true,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tap to select',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: Colors.black26,
                            ),
                            prefixIcon: const Icon(
                              Icons.schedule_outlined,
                              size: 16,
                              color: Color(0xFFF5A962),
                            ),
                            suffixIcon: visitTimeController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () => setState(
                                      () => visitTimeController.clear(),
                                    ),
                                    child: const Icon(
                                      Icons.clear,
                                      size: 14,
                                      color: Colors.black38,
                                    ),
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFEEEEEE),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFF5A962),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientListTab() {
    return PatientListTab(refreshTrigger: _patientListRefreshTrigger);
  }

  Widget _buildNotificationsTab() {
    return NotificationsTab(
      onNavigateToPatients: () => _tabController.animateTo(1),
    );
  }
}

class _HomeSectionTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _HomeSectionTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFF2E8B7B),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
