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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _homeScrollController = ScrollController();

  // ── Form controllers ───────────────────────────────────────────────────────
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController ageDaysController = TextEditingController();
  final TextEditingController ageYearsController = TextEditingController();
  final TextEditingController sexController = TextEditingController();
  final TextEditingController bloodTypeController = TextEditingController();
  // PhilHealth — Mother
  final TextEditingController motherPhilHealthNumberController = TextEditingController();
  final TextEditingController motherPhilHealthMemberTypeController = TextEditingController();
  // PhilHealth — Father
  final TextEditingController fatherPhilHealthNumberController = TextEditingController();
  final TextEditingController fatherPhilHealthMemberTypeController = TextEditingController();
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    LocalDbService.instance.init().then((_) async {
      final online =
          kIsWeb ? true : await ConnectivityService.instance.checkOnline();
      if (online) {
        final synced =
            await LocalDbService.instance.syncPending(FirestoreService());
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
        final synced =
            await LocalDbService.instance.syncPending(FirestoreService());
        if (synced > 0 && mounted) {
          _showSnackBar('$synced pending assessment(s) synced.');
        }
      }
    });
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    _patientListRefreshTrigger.dispose();
    _tabController.dispose();

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

  // ── Save Draft ─────────────────────────────────────────────────────────────
  /// Sets draft mode then runs _saveAllData. In draft mode only the basic
  /// required fields (patient name, parent names & contacts) are validated.
  /// All other section validators (oral, deworming, purelyBreastfed, etc.)
  /// are skipped so the record can be saved incomplete.
  Future<void> _saveDraft() async {
    setState(() => _isDraft = true);
    await _saveAllData();
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
        setState(
            () => _oralRiskError = 'Please select an overall risk level');
        hasNonTextErrors = true;
      } else {
        setState(() => _oralRiskError = null);
      }

      if (_dewormingData == null) {
        setState(() =>
            _dewormingError = 'Please fill in deworming information');
        hasNonTextErrors = true;
      } else {
        final dw = _dewormingData!['deworming'] as Map<String, dynamic>?;
        final isNA = dw?['isNA'] == true;
        if (!isNA) {
          if ((dw?['dateOfLastDeworming'] ?? '')
              .toString()
              .trim()
              .isEmpty) {
            setState(
                () => _dewormingError = 'Please enter a date or select N/A');
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
        'motherPhilHealthMemberType': motherPhilHealthMemberTypeController.text.trim(),
        'father': fatherController.text.trim(),
        'fatherContact': fatherContactController.text.trim(),
        'fatherAge': fatherAgeController.text.trim(),
        'fatherOccupation': fatherOccupationController.text.trim(),
        'fatherPhilHealthNumber': fatherPhilHealthNumberController.text.trim(),
        'fatherPhilHealthMemberType': fatherPhilHealthMemberTypeController.text.trim(),
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
    final online =
        kIsWeb ? true : await ConnectivityService.instance.checkOnline();
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
                  'firstName':     firstNameController.text.trim(),
                  'lastName':      lastNameController.text.trim(),
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
        await LocalDbService.instance
            .saveLocalRecord(data, synced: true, firestoreId: docId);
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
            color: Colors.orange);
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
              .where((e) =>
                  !e.key.endsWith('_date') &&
                  e.key != 'nextDoseDate' &&
                  e.value == true)
              .length;
        }

        String doseLabelForCount(int count) {
          if (count <= 0) return 'Pending';
          switch (count) {
            case 1:  return '1st dose';
            case 2:  return '2nd dose';
            case 3:  return '3rd dose';
            case 4:  return '4th dose';
            case 5:  return '5th dose';
            default: return 'Booster';
          }
        }

        String vaccineStatus(String name) =>
            doseLabelForCount(doseCount(name));

        final opvCount = doseCount('OPV');
        final ipvCount = doseCount('IPV');

        final statuses = <String, String>{
          'bcg':            vaccineStatus('BCG'),
          'hepatitisB':     vaccineStatus('Hepatitis B'),
          'dptPentavalent': vaccineStatus('DTwP/DTaP-Hib-IPV'),
          'opv':            vaccineStatus('OPV'),
          'ipv':            vaccineStatus('IPV'),
          'opvIpv':         doseLabelForCount(
              opvCount > ipvCount ? opvCount : ipvCount),
          'measlesMmr':     vaccineStatus('MMR/MR'),
          'pcv':            vaccineStatus('PCV'),
        };

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
    return Scaffold(
      bottomNavigationBar: _buildBottomTabBar(),
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
                child: const Icon(Icons.eco_rounded,
                    color: Colors.white, size: 18),
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
                    child: const Icon(Icons.settings_outlined,
                        color: Colors.white, size: 18),
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

  Widget _buildBottomTabBar() {
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
          controller: _tabController,
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
          tabs: const [
            Tab(icon: Icon(Icons.home_outlined, size: 22), text: 'Home'),
            Tab(
                icon: Icon(Icons.people_outline, size: 22),
                text: 'Patients'),
            Tab(
                icon: Icon(Icons.notifications_outlined, size: 22),
                text: 'Alerts'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      key: const PageStorageKey<String>('home_scroll'),
      controller: _homeScrollController,
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
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

            // Section label
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'NEW ASSESSMENT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.65),
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── 1. Demographic ─────────────────────────────────────────
            DemographicDataForm(
              key: ValueKey('demographic_form_$_demographicFormKey'),
              firstNameController: firstNameController,
              middleNameController: middleNameController,
              lastNameController: lastNameController,
              ageController: ageController,
              ageDaysController: ageDaysController,
              ageYearsController: ageYearsController,
              sexController: sexController,
              bloodTypeController: bloodTypeController,
              motherPhilHealthNumberController: motherPhilHealthNumberController,
              motherPhilHealthMemberTypeController: motherPhilHealthMemberTypeController,
              fatherPhilHealthNumberController: fatherPhilHealthNumberController,
              fatherPhilHealthMemberTypeController: fatherPhilHealthMemberTypeController,
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
              onIsFourPsMemberChanged: (v) =>
                  setState(() => _isFourPsMember = v),
              onHasDisabilityChanged: (v) =>
                  setState(() => _hasDisability = v),
              isDraft: _isDraft,
            ),
            const SizedBox(height: 16),

            // ── 2. Anthropometric ──────────────────────────────────────
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

            // ── 3. Health Status ───────────────────────────────────────
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

            // ── 4. Allergies ───────────────────────────────────────────
            AllergiesForm(
              key: ValueKey('allergies_form_$_allergiesFormKey'),
              onDataChanged: (data) =>
                  setState(() => _allergiesData = data),
            ),
            const SizedBox(height: 16),

            // ── 5. Family Planning ─────────────────────────────────────
            FamilyPlanningForm(
              key: ValueKey('fp_form_$_familyPlanningFormKey'),
              onDataChanged: (data) =>
                  setState(() => _familyPlanningData = data),
            ),
            const SizedBox(height: 16),

            // ── 6. Dietary Assessment ──────────────────────────────────
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

            // ── 7. Nutrition Environment ───────────────────────────────
            NutritionEnvironmentForm(
              key: ValueKey('nutrition_env_form_$_nutritionEnvFormKey'),
              onDataChanged: (data) =>
                  setState(() => _nutritionEnvData = data),
            ),
            const SizedBox(height: 16),

            // ── 8. Oral Assessment ─────────────────────────────────────
            OralAssessmentForm(
              key: ValueKey('oral_form_$_oralFormKey'),
              onDataChanged: (data) {
                _oralData = data;
                setState(() => _oralRiskError = null);
              },
              overallRiskError: _oralRiskError,
            ),
            const SizedBox(height: 16),

            // ── 9. Vaccination ─────────────────────────────────────────
            VaccinationForm(
              key: ValueKey('vaccination_form_$_vaccinationFormKey'),
              onDataChanged: (data) => _vaccinationData = data,
            ),
            const SizedBox(height: 16),

            // ── 10. Deworming ──────────────────────────────────────────
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

            const SizedBox(height: 24),

            // ── Save Draft + Save Assessment ───────────────────────────
            Row(
              children: [
                // Save Draft — ghost/outline style
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
                          Icon(Icons.save_outlined,
                              color: Colors.white, size: 18),
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
                // Save Assessment — orange gradient
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _saveAllData,
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
                            color: const Color(0xFFF5A962)
                                .withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.white, size: 18),
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
            ),
            const SizedBox(height: 30),
          ],
        ),
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