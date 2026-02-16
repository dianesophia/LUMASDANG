import 'package:flutter/material.dart';
import 'package:lumasdang/screens/patient_list.dart';
import 'package:lumasdang/screens/settingsPages/main_Settings.dart';

import '../../services/firestore_service.dart';
import '../../services/local_db_service.dart';
import '../../services/connectivity_service.dart';

import 'widgets/stats_row.dart';
import 'widgets/upcoming_events.dart';
import 'widgets/demographic_data_form.dart';
import 'widgets/anthropometric_data_form.dart';
import 'widgets/health_status_form.dart';
import 'widgets/dietary_assessment_form.dart';
import 'widgets/oral_assessment_form.dart';
import 'widgets/vaccination_form.dart';
import 'widgets/deworming_form.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedNavIndex = 0;

  // Controllers for forms
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController sexController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController placeOfBirthController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController motherController = TextEditingController();
  final TextEditingController motherContactController = TextEditingController();
  final TextEditingController fatherController = TextEditingController();
  final TextEditingController fatherContactController = TextEditingController();

  final TextEditingController measurementDateController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController muacController = TextEditingController();
  final TextEditingController weightForAgeController = TextEditingController();
  final TextEditingController weightForHeightController = TextEditingController();
  final TextEditingController heightForAgeController = TextEditingController();
  final TextEditingController bmiController = TextEditingController();

  // Health status booleans
  bool _diarrhea = false;
  bool _fever = false;
  bool _cough = false;
  bool _other = false;
  bool _medications = false;

  // Dietary
  bool? _purelyBreastfed;
  final TextEditingController cfAgeController = TextEditingController();
  final TextEditingController cfFreqController = TextEditingController();
  final TextEditingController cfFoodController = TextEditingController();
  final TextEditingController mealFreqController = TextEditingController();

  // Deworming data captured from DewormingForm's onSave
  Map<String, dynamic>? _dewormingData;

  // Oral assessment data
  Map<String, dynamic>? _oralData;

  // Vaccination data captured from VaccinationForm
  Map<String, dynamic>? _vaccinationData;

  // Refresh key for StatsRow (incremented after save to refresh screened count)
  int _statsRefreshKey = 0;

  /// Increment to tell Patient List tab to refresh (e.g. after form save).
  final ValueNotifier<int> _patientListRefreshTrigger = ValueNotifier<int>(0);

  // Reset keys for forms with internal state (incremented to force rebuild)
  int _demographicFormKey = 0;
  int _anthropometricFormKey = 0;
  int _dietaryFormKey = 0;
  int _dewormingFormKey = 0;
  int _oralFormKey = 0;
  int _vaccinationFormKey = 0;

  // Form validation key
  final _formKey = GlobalKey<FormState>();

  // Validation error states for non-text fields
  String? _purelyBreastfedError;
  String? _dewormingError;
  String? _oralRiskError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize local DB and monitor connectivity for automatic sync
    LocalDbService.instance.init().then((_) async {
      final online = await ConnectivityService.instance.checkOnline();
      if (online) {
        // Try to sync any pending items when app starts if online
        final synced = await LocalDbService.instance.syncPending(FirestoreService());
        if (synced > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$synced pending assessment(s) synced.')),
          );
        }
      }
    });

    ConnectivityService.instance.startMonitoring((online) async {
      if (online) {
        // When connection restored, try to sync.
        final synced = await LocalDbService.instance.syncPending(FirestoreService());
        if (synced > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$synced pending assessment(s) synced.')),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _patientListRefreshTrigger.dispose();
    _tabController.dispose();

    // dispose controllers
    firstNameController.dispose();
    lastNameController.dispose();
    ageController.dispose();
    sexController.dispose();
    addressController.dispose();
    placeOfBirthController.dispose();
    dobController.dispose();
    motherController.dispose();
    motherContactController.dispose();
    fatherController.dispose();
    fatherContactController.dispose();

    measurementDateController.dispose();
    weightController.dispose();
    heightController.dispose();
    muacController.dispose();
    weightForAgeController.dispose();
    weightForHeightController.dispose();
    heightForAgeController.dispose();
    bmiController.dispose();

    cfAgeController.dispose();
    cfFreqController.dispose();
    cfFoodController.dispose();
    mealFreqController.dispose();

    super.dispose();
  }

  Future<void> _saveAllData() async {
    // Validate all form fields
    final isFormValid = _formKey.currentState?.validate() ?? false;

    // Validate non-text fields
    bool hasNonTextErrors = false;

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

    // Validate deworming: either N/A or must have date and drug
    if (_dewormingData == null) {
      setState(() => _dewormingError = 'Please fill in deworming information');
      hasNonTextErrors = true;
    } else {
      final isNA = _dewormingData!['isNA'] == true;
      if (!isNA) {
        if ((_dewormingData!['dateOfLastDeworming'] ?? '').toString().trim().isEmpty) {
          setState(() => _dewormingError = 'Please enter a date or select N/A');
          hasNonTextErrors = true;
        } else if (_dewormingData!['drugGiven'] == null) {
          setState(() => _dewormingError = 'Please select a drug given');
          hasNonTextErrors = true;
        } else {
          setState(() => _dewormingError = null);
        }
      } else {
        setState(() => _dewormingError = null);
      }
    }

    if (!isFormValid || hasNonTextErrors) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields.'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    final data = {
      'demographic': {
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'age': ageController.text.trim(),
        'sex': sexController.text.trim(),
        'address': addressController.text.trim(),
        'placeOfBirth': placeOfBirthController.text.trim(),
        'dateOfBirth': dobController.text.trim(),
        'mother': motherController.text.trim(),
        'motherContact': motherContactController.text.trim(),
        'father': fatherController.text.trim(),
        'fatherContact': fatherContactController.text.trim(),
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
      'dietary': {
        'purelyBreastfed': _purelyBreastfed,
        'cfAge': cfAgeController.text.trim(),
        'cfFrequency': cfFreqController.text.trim(),
        'cfFoods': cfFoodController.text.trim(),
        'mealFrequency': mealFreqController.text.trim(),
      },
      'deworming': _dewormingData,
      'oral': _oralData,
      'vaccination': _vaccinationData,
    };

    final firestore = FirestoreService();

    // Check current connectivity
    final online = await ConnectivityService.instance.checkOnline();

    String? barangayPatientId;
    if (online) {
      // Try to save to Firestore and local DB
      try {
        final docId = await firestore.saveHomePageData(data);
        // Also save to barangay patient list so the patient appears in Patient List tab
        try {
          barangayPatientId = await firestore.savePatientToBarangay(data);
        } catch (eBarangay) {
          debugPrint('Barangay patient save (for Patient List): $eBarangay');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved to server but could not add to Patient List: ${eBarangay.toString()}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
        // Save locally marked as synced
        await LocalDbService.instance.saveLocalRecord(data, synced: true, firestoreId: docId);

        if (!mounted) return;
        _patientListRefreshTrigger.value++;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assessment saved to server and locally.'),
            backgroundColor: Color(0xFF2E8B7B),
          ),
        );
      } catch (e) {
        // If Firestore write fails, fallback to local only and mark unsynced
        await LocalDbService.instance.saveLocalRecord(data, synced: false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved locally (will sync later). Error: ${e.toString()}'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } else {
      // Offline: save locally for later sync
      await LocalDbService.instance.saveLocalRecord(data, synced: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet: saved locally and will sync when online.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
    // Sync vaccination status to the vaccinations collection for Profile Overview
    if (_vaccinationData != null && online) {
      try {
        /// Returns the highest dose number selected for a vaccine
        /// based on which age-column checkboxes are true.
        int highestDoseNumber(String vaccine) {
          final doses = _vaccinationData![vaccine] as Map<String, dynamic>?;
          if (doses == null) return 0;

          // Column headers in chronological order as used in VaccinationForm
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
              // Fallback: consider all columns in generic order
              relevantHeaders = [birth, m1_5, m2_5, m3_5, m9, y1];
          }

          // Walk from latest to earliest and pick the last true checkbox
          for (int i = relevantHeaders.length - 1; i >= 0; i--) {
            final header = relevantHeaders[i];
            if (doses[header] == true) {
              return i + 1; // dose numbers start at 1
            }
          }
          return 0; // none selected → Pending
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

        String vaccineStatus(String name) {
          final n = highestDoseNumber(name);
          return doseLabelForNumber(n);
        }

        final opvNumber = highestDoseNumber('OPV');
        final ipvNumber = highestDoseNumber('IPV');

        final statuses = <String, String>{
          'bcg': vaccineStatus('BCG'),
          'hepatitisB': vaccineStatus('HEP B'),
          'dptPentavalent': vaccineStatus('PENTAVALENT'),
          'opv': vaccineStatus('OPV'),
          'ipv': vaccineStatus('IPV'),
          // Combined OPV+IPV progress for legacy personal view
          'opvIpv': doseLabelForNumber(
            (opvNumber > ipvNumber) ? opvNumber : ipvNumber,
          ),
          'measlesMmr': vaccineStatus('MMR'),
          'pcv': vaccineStatus('PCV'),
        };

        await FirestoreService().saveVaccinationStatus(
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          statuses: statuses,
        );

        // Also save to barangay patient so Profile Overview (Vaccination Status) shows it
        if (barangayPatientId != null) {
          try {
            final barangayId = await FirestoreService().getCurrentUserBarangayId();
            if (barangayId != null && barangayId.isNotEmpty) {
              await FirestoreService().saveVaccinationStatusToBarangayPatient(
                barangayId: barangayId,
                patientId: barangayPatientId,
                firstName: firstNameController.text.trim(),
                lastName: lastNameController.text.trim(),
                statuses: statuses,
              );
            }
          } catch (eBarangayVax) {
            debugPrint('Error syncing vaccination to barangay patient: $eBarangayVax');
          }
        }
      } catch (e) {
        debugPrint('Error syncing vaccination status: $e');
      }
    }
    if (mounted) {
      // Clear all text controllers FIRST
      firstNameController.clear();
      lastNameController.clear();
      ageController.clear();
      sexController.clear();
      addressController.clear();
      placeOfBirthController.clear();
      dobController.clear();
      motherController.clear();
      motherContactController.clear();
      fatherController.clear();
      fatherContactController.clear();

      measurementDateController.clear();
      weightController.clear();
      heightController.clear();
      muacController.clear();
      weightForAgeController.clear();
      weightForHeightController.clear();
      heightForAgeController.clear();
      bmiController.clear();

      cfAgeController.clear();
      cfFreqController.clear();
      cfFoodController.clear();
      mealFreqController.clear();

      // Then rebuild all forms with new keys and reset state
      setState(() {
        _statsRefreshKey++;
        _demographicFormKey++;
        _anthropometricFormKey++;
        _dietaryFormKey++;
        _dewormingFormKey++;
        _oralFormKey++;
        _vaccinationFormKey++;

        _diarrhea = false;
        _fever = false;
        _cough = false;
        _other = false;
        _medications = false;

        _purelyBreastfed = null;
        _purelyBreastfedError = null;

        _oralData = null;
        _oralRiskError = null;

        _vaccinationData = null;

        _dewormingData = null;
        _dewormingError = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _formKey.currentState?.reset();
        }
      });
    }
    if (mounted) setState(() => _statsRefreshKey++);
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
              _buildTabBar(),
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
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF2E8B7B),
        unselectedLabelColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
        tabs: const [
          Tab(text: 'Home'),
          Tab(text: 'Patient List'),
          Tab(text: 'Notifications'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
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
            const Text(
              'NEW ASSESSMENT',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            DemographicDataForm(
              key: ValueKey('demographic_form_$_demographicFormKey'),
              firstNameController: firstNameController,
              lastNameController: lastNameController,
              ageController: ageController,
              sexController: sexController,
              addressController: addressController,
              placeOfBirthController: placeOfBirthController,
              dobController: dobController,
              motherController: motherController,
              motherContactController: motherContactController,
              fatherController: fatherController,
              fatherContactController: fatherContactController,
            ),
            const SizedBox(height: 16),
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
              onDataChanged: (data) {
                _vaccinationData = data;
              },
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAllData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E8B7B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
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
    return const Center(
      child: Text(
        'Notifications',
        style: TextStyle(
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5CAA7F), Color(0xFF8BC88A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.insights, 0),
              _buildNavItem(Icons.fact_check, 1),
              _buildNavItem(Icons.contact_page, 2),
              _buildNavItem(Icons.settings_outlined, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedNavIndex == index;
    return InkWell(
      onTap: () {
         if (index == 3) {
        // Navigate to Settings Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MainSettings(),
          ),
        );
        return;
      }

        setState(() {
          _selectedNavIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
