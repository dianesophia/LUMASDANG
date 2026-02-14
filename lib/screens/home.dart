import 'package:flutter/material.dart';
import 'package:lumasdang/screens/patient_list.dart';
import 'package:lumasdang/screens/settingsPages/main_Settings.dart';

import '../services/anthropometric_calculator.dart';
import '../services/firestore_service.dart';
import '../services/local_db_service.dart';
import '../services/connectivity_service.dart';




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

    if (online) {
      // Try to save to Firestore and local DB
      try {
        final docId = await firestore.saveHomePageData(data);
        // Save locally marked as synced
        await LocalDbService.instance.saveLocalRecord(data, synced: true, firestoreId: docId);

        if (!mounted) return;
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
        // Count how many scheduled doses have been marked for this vaccine
        int _trueDoseCount(String name) {
          final doses = _vaccinationData![name] as Map<String, dynamic>?;
          if (doses == null) return 0;
          return doses.values.where((v) => v == true).length;
        }

        // Convert dose count into a human‑readable label
        String _doseLabelForCount(int count) {
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
              // For anything beyond 5, treat as Booster
              return 'Booster';
          }
        }

        String _vaccineStatus(String name) {
          final count = _trueDoseCount(name);
          return _doseLabelForCount(count);
        }

        // OPV / IPV are combined in the profile card, so we sum their doses
        final opvCount = _trueDoseCount('OPV');
        final ipvCount = _trueDoseCount('IPV');

        final statuses = <String, String>{
          'bcg': _vaccineStatus('BCG'),
          'hepatitisB': _vaccineStatus('HEP B'),
          'dptPentavalent': _vaccineStatus('PENTAVALENT'),
          'opvIpv': _doseLabelForCount(opvCount + ipvCount),
          'measlesMmr': _vaccineStatus('MMR'),
          'pcv': _vaccineStatus('PCV'),
        };

        await FirestoreService().saveVaccinationStatus(
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          statuses: statuses,
        );
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
        // Increment stats key to refresh header
        _statsRefreshKey++;

        // Increment form keys to force rebuild of all forms
        // This ensures forms rebuild with cleared controllers
        _demographicFormKey++;
        _anthropometricFormKey++;
        _dietaryFormKey++;
        _dewormingFormKey++;
        _oralFormKey++;
        _vaccinationFormKey++;

        // Reset toggle/checkbox/radio state
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

      // Reset form validation state AFTER rebuild to ensure it doesn't restore old values
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
    return const PatientListTab();
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
        // 👉 Navigate to Settings Page
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



// ==================== STATS ROW ====================
class StatsRow extends StatefulWidget {
  final VoidCallback? onTap;

  const StatsRow({super.key, this.onTap});

  @override
  State<StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<StatsRow> {
  Future<int> _loadTodayCount() async {
    await LocalDbService.instance.init();
    final online = await ConnectivityService.instance.checkOnline();
    if (online) {
      //return FirestoreService().getTodayScreenedCount();
      return FirestoreService().getTodayScreenedCountFromBarangay();
    }
    return LocalDbService.instance.getTodayScreenedCount();
  }

  String _formatDate(DateTime d) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A962),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FutureBuilder<int>(
                      future: _loadTodayCount(),
                      builder: (context, snapshot) {
                        final count = snapshot.hasData ? snapshot.data! : null;
                        return Text(
                          count != null ? '$count' : '—',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No. of patient',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const Text(
                          'screened today',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _formatDate(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFFF5A962),
                          ),
                        ),
                      ],
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusRow(count: '0', label: 'Underweight'),
                SizedBox(height: 2),
                StatusRow(count: '1', label: 'Overweight/', subtitle: 'Obese'),
                SizedBox(height: 2),
                StatusRow(count: '2', label: 'Stunted'),
                SizedBox(height: 2),
                StatusRow(count: '3', label: 'At Risk'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class StatusRow extends StatelessWidget {
  final String count;
  final String label;
  final String? subtitle;

  const StatusRow({
    super.key,
    required this.count,
    required this.label,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF5A962),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            count,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== UPCOMING EVENTS ====================
class UpcomingEvents extends StatelessWidget {
  const UpcomingEvents({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5A962),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UPCOMING EVENTS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF5A962),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• Operation Timbang',
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                ),
                Text(
                  '• Deworming',
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                ),
                Text(
                  '• Operation Bunot',
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== FORM CARD WIDGET ====================
class FormCard extends StatelessWidget {
  final String title;
  final Widget child;

  const FormCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5A962),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ==================== FORM FIELD WIDGETS ====================
class FormFieldRow extends StatelessWidget {
  final String label;
  final String? hint;
  final double labelWidth;
  final TextEditingController? controller;
  final bool readOnly;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const FormFieldRow({
    super.key,
    required this.label,
    this.hint,
    this.labelWidth = 100,
    this.controller,
    this.readOnly = false,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: controller,
                readOnly: readOnly,
                validator: validator,
                keyboardType: keyboardType,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B6914),
                    fontStyle: FontStyle.italic,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  isDense: true,
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF8B6914), width: 1.5),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF5D4037), width: 2),
                  ),
                  errorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFD32F2F), width: 1.5),
                  ),
                  focusedErrorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFD32F2F), width: 2),
                  ),
                  errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFD32F2F)),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CheckboxFieldRow extends StatefulWidget {
  final String label;
  final String? hint;
  final bool initialValue;
  final ValueChanged<bool>? onChanged;

  const CheckboxFieldRow({
    super.key,
    required this.label,
    this.hint,
    this.initialValue = false,
    this.onChanged,
  });

  @override
  State<CheckboxFieldRow> createState() => _CheckboxFieldRowState();
}

class _CheckboxFieldRowState extends State<CheckboxFieldRow> {
  late bool _isChecked;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _isChecked,
            onChanged: (value) {
              setState(() {
                _isChecked = value ?? false;
              });
              widget.onChanged?.call(_isChecked);
            },
            activeColor: const Color(0xFF2E8B7B),
            side: const BorderSide(color: Color(0xFF5D4037)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5D4037),
          ),
        ),
        if (widget.hint != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 28,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF8B6914), width: 1),
                ),
              ),
              child: TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.hint,
                  hintStyle: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8B6914),
                    fontStyle: FontStyle.italic,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ==================== DEMOGRAPHIC DATA FORM ====================
class DemographicDataForm extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController ageController;
  final TextEditingController sexController;
  final TextEditingController addressController;
  final TextEditingController placeOfBirthController;
  final TextEditingController dobController;
  final TextEditingController motherController;
  final TextEditingController motherContactController;
  final TextEditingController fatherController;
  final TextEditingController fatherContactController;

  const DemographicDataForm({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.ageController,
    required this.sexController,
    required this.addressController,
    required this.placeOfBirthController,
    required this.dobController,
    required this.motherController,
    required this.motherContactController,
    required this.fatherController,
    required this.fatherContactController,
  });

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'DEMOGRAPHIC DATA',
      child: Column(
        children: [
          FormFieldRow(
            label: 'First Name:',
            controller: firstNameController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'First name is required';
              if (v.trim().length < 2) return 'Must be at least 2 characters';
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Last Name:',
            controller: lastNameController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Last name is required';
              if (v.trim().length < 2) return 'Must be at least 2 characters';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FormFieldRow(
                  label: 'Age:',
                  labelWidth: 40,
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  hint: 'Enter age in months (0–60)',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final age = int.tryParse(v.trim());
                    if (age == null) return 'Enter a number';
                    if (age < 0 || age > 60) return 'Enter age in months (0–60)';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FormFieldRow(
                  label: 'Sex:',
                  labelWidth: 40,
                  controller: sexController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final sex = v.trim().toUpperCase();
                    if (sex != 'M' && sex != 'F' && sex != 'MALE' && sex != 'FEMALE') {
                      return 'Enter M or F';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Address:',
            controller: addressController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Address is required';
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Place of Birth:',
            controller: placeOfBirthController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Place of birth is required';
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Date of Birth:',
            controller: dobController,
            keyboardType: TextInputType.datetime,
            hint: 'MM-DD-YYYY (e.g. 05-01-2023)',
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Date of birth is required';
              final value = v.trim();
              final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
              if (!regex.hasMatch(value)) {
                return 'Use format MM-DD-YYYY';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Mother Name:',
            controller: motherController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Mother\'s name is required';
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Contact #:',
            controller: motherContactController,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Contact number is required';
              if (v.trim().length != 11) return 'Enter a valid contact number';
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Fathers Name:',
            controller: fatherController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Father\'s name is required';
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Contact #:',
            controller: fatherContactController,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Contact number is required';
              if (v.trim().length != 11) return 'Enter a valid contact number';
              return null;
            },
          ),
        ],
      ),
    );
  }
}

// ==================== ANTHROPOMETRIC DATA FORM ====================
class AnthropometricDataForm extends StatefulWidget {
  final TextEditingController dateController;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final TextEditingController muacController;
  final TextEditingController weightForAgeController;
  final TextEditingController weightForHeightController;
  final TextEditingController heightForAgeController;
  final TextEditingController bmiController;
  final TextEditingController ageController;
  final TextEditingController sexController;
  final TextEditingController dobController;

  const AnthropometricDataForm({
    super.key,
    required this.dateController,
    required this.weightController,
    required this.heightController,
    required this.muacController,
    required this.weightForAgeController,
    required this.weightForHeightController,
    required this.heightForAgeController,
    required this.bmiController,
    required this.ageController,
    required this.sexController,
    required this.dobController,
  });

  @override
  State<AnthropometricDataForm> createState() => _AnthropometricDataFormState();
}

class _AnthropometricDataFormState extends State<AnthropometricDataForm> {
  void _recalculate() {
    final r = AnthropometricCalculator.calculate(
      weightStr: widget.weightController.text,
      heightStr: widget.heightController.text,
      ageStr: widget.ageController.text,
      sexStr: widget.sexController.text,
      dobStr: widget.dobController.text,
      measurementDateStr: widget.dateController.text,
    );
    if (r != null) {
      widget.weightForAgeController.text = r.weightForAge ?? '';
      widget.weightForHeightController.text = r.weightForHeight ?? '';
      widget.heightForAgeController.text = r.heightForAge ?? '';
      widget.bmiController.text = r.bmi ?? '';
    } else {
      widget.weightForAgeController.clear();
      widget.weightForHeightController.clear();
      widget.heightForAgeController.clear();
      widget.bmiController.clear();
    }
  }

  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = _recalculate;
    widget.weightController.addListener(_listener);
    widget.heightController.addListener(_listener);
    widget.ageController.addListener(_listener);
    widget.sexController.addListener(_listener);
    widget.dobController.addListener(_listener);
    widget.dateController.addListener(_listener);
  }

  @override
  void dispose() {
    widget.weightController.removeListener(_listener);
    widget.heightController.removeListener(_listener);
    widget.ageController.removeListener(_listener);
    widget.sexController.removeListener(_listener);
    widget.dobController.removeListener(_listener);
    widget.dateController.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'ATHROPOMETRIC DATA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormFieldRow(
            label: 'Date of Measurement:',
            labelWidth: 140,
            controller: widget.dateController,
            keyboardType: TextInputType.datetime,
            hint: 'MM-DD-YYYY (e.g. 02-13-2026)',
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Date of measurement is required';
              final value = v.trim();
              final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
              if (!regex.hasMatch(value)) {
                return 'Use format MM-DD-YYYY';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Weight (kg):',
            controller: widget.weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Weight is required';
              final w = double.tryParse(v.trim());
              if (w == null) return 'Enter a valid number';
              if (w <= 0 || w > 300) return 'Enter a valid weight';
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Height (cm):',
            controller: widget.heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Height is required';
              final h = double.tryParse(v.trim());
              if (h == null) return 'Enter a valid number';
              if (h <= 0 || h > 300) return 'Enter a valid height';
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'MUAC (cm):',
            controller: widget.muacController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'MUAC is required';
              final m = double.tryParse(v.trim());
              if (m == null) return 'Enter a valid number';
              if (m <= 0) return 'Enter a valid MUAC value';
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Auto-calculated fields (z-score interpretation per WHO standards)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8985A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-calculated from weight, height, age & sex (WHO z-scores)',
                  style: TextStyle(fontSize: 11, color: Colors.brown.shade800, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                FormFieldRow(label: 'Weight-for-Age (kg):', labelWidth: 140, controller: widget.weightForAgeController, readOnly: true),
                const SizedBox(height: 8),
                FormFieldRow(label: 'Weight-for-Height/Length (kg):', labelWidth: 160, controller: widget.weightForHeightController, readOnly: true),
                const SizedBox(height: 8),
                FormFieldRow(label: 'Height-for-Age (cm):', labelWidth: 140, controller: widget.heightForAgeController, readOnly: true),
                const SizedBox(height: 8),
                FormFieldRow(label: 'BMI (kg/m²):', labelWidth: 140, controller: widget.bmiController, readOnly: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== HEALTH STATUS FORM ====================
class HealthStatusForm extends StatelessWidget {
  final bool diarrhea;
  final ValueChanged<bool> onDiarrheaChanged;
  final bool fever;
  final ValueChanged<bool> onFeverChanged;
  final bool cough;
  final ValueChanged<bool> onCoughChanged;
  final bool other;
  final ValueChanged<bool> onOtherChanged;
  final bool medications;
  final ValueChanged<bool> onMedicationsChanged;

  const HealthStatusForm({
    super.key,
    required this.diarrhea,
    required this.onDiarrheaChanged,
    required this.fever,
    required this.onFeverChanged,
    required this.cough,
    required this.onCoughChanged,
    required this.other,
    required this.onOtherChanged,
    required this.medications,
    required this.onMedicationsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'HEALTH STATUS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxFieldRow(
            label: 'Diarrhea:',
            hint: '(Date of Occurrence/ Duration)',
            initialValue: diarrhea,
            onChanged: onDiarrheaChanged,
          ),
          const SizedBox(height: 10),
          CheckboxFieldRow(
            label: 'Fever:',
            hint: '(Date of Occurrence/ Duration)',
            initialValue: fever,
            onChanged: onFeverChanged,
          ),
          const SizedBox(height: 10),
          CheckboxFieldRow(
            label: 'Cough/Pneumonia:',
            hint: '(Date of Occurrence/ Duration)',
            initialValue: cough,
            onChanged: onCoughChanged,
          ),
          const SizedBox(height: 10),
          CheckboxFieldRow(
            label: 'Other:',
            hint: '(Date of Occurrence/ Duration)',
            initialValue: other,
            onChanged: onOtherChanged,
          ),
          const SizedBox(height: 10),
          CheckboxFieldRow(
            label: 'Medication/s:',
            hint: '(Current/ Taken during illness)',
            initialValue: medications,
            onChanged: onMedicationsChanged,
          ),
        ],
      ),
    );
  }
}

// ==================== DIETARY ASSESSMENT FORM ====================
class DietaryAssessmentForm extends StatefulWidget {
  final bool? purelyBreastfed;
  final ValueChanged<bool?>? onPurelyBreastfedChanged;
  final TextEditingController ageWhenCfController;
  final TextEditingController freqCfController;
  final TextEditingController foodCfController;
  final TextEditingController mealFrequencyController;
  final String? purelyBreastfedError;

  const DietaryAssessmentForm({
    super.key,
    this.purelyBreastfed,
    this.onPurelyBreastfedChanged,
    required this.ageWhenCfController,
    required this.freqCfController,
    required this.foodCfController,
    required this.mealFrequencyController,
    this.purelyBreastfedError,
  });

  @override
  State<DietaryAssessmentForm> createState() => _DietaryAssessmentFormState();
}

class _DietaryAssessmentFormState extends State<DietaryAssessmentForm> {
  bool? _purelyBreastfed;

  @override
  void initState() {
    super.initState();
    _purelyBreastfed = widget.purelyBreastfed;
  }

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'DIETARY ASSESSMENT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Purely Breastfed
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Purely Breastfed:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const Text('YES', style: TextStyle(fontSize: 12, color: Color(0xFF5D4037))),
                      Radio<bool>(
                        value: true,
                        groupValue: _purelyBreastfed,
                        onChanged: (v) {
                          setState(() => _purelyBreastfed = v);
                          widget.onPurelyBreastfedChanged?.call(v);
                        },
                        activeColor: const Color(0xFF2E8B7B),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('NO', style: TextStyle(fontSize: 12, color: Color(0xFF5D4037))),
                      Radio<bool>(
                        value: false,
                        groupValue: _purelyBreastfed,
                        onChanged: (v) {
                          setState(() => _purelyBreastfed = v);
                          widget.onPurelyBreastfedChanged?.call(v);
                        },
                        activeColor: const Color(0xFF2E8B7B),
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.purelyBreastfedError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Text(
                    widget.purelyBreastfedError!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFD32F2F)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Complimentary Feeding
          const Text(
            'Complimentary Feeding (CF):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              children: [
                FormFieldRow(
                  label: 'Age when CF started:',
                  hint: '(Age in months)',
                  labelWidth: 140,
                  controller: widget.ageWhenCfController,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                FormFieldRow(
                  label: 'Frequency of CF a day:',
                  labelWidth: 140,
                  controller: widget.freqCfController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                FormFieldRow(
                  label: 'Food/s given on CF:',
                  labelWidth: 140,
                  controller: widget.foodCfController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Dietary Diversity
          const Text(
            'Dietary Diversity:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Column(
              children: [
                CheckboxFieldRow(label: 'Grains/Roots/Tubers:', hint: '(Specify)'),
                SizedBox(height: 6),
                CheckboxFieldRow(label: 'Legumes/Nuts:', hint: '(Specify)'),
                SizedBox(height: 6),
                CheckboxFieldRow(label: 'Dairy Products:', hint: '(Specify)'),
                SizedBox(height: 6),
                CheckboxFieldRow(label: 'Meat/Fish/Poultry:', hint: '(Specify)'),
                SizedBox(height: 6),
                CheckboxFieldRow(label: 'Eggs:', hint: '(Specify)'),
                SizedBox(height: 6),
                CheckboxFieldRow(label: 'Vit-A rich foods & Vegetables:', hint: '(Specify)'),
                SizedBox(height: 6),
                CheckboxFieldRow(label: 'Other Fruits & Vegetables:', hint: '(Specify)'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Meal frequency in a day:',
            labelWidth: 160,
            controller: widget.mealFrequencyController,
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Meal frequency is required';
              return null;
            },
          ),
        ],
      ),
    );
  }
}

// ==================== ORAL ASSESSMENT FORM ====================
class OralAssessmentForm extends StatefulWidget {
  final Function(Map<String, dynamic>)? onDataChanged;
  final String? overallRiskError;

  const OralAssessmentForm({super.key, this.onDataChanged, this.overallRiskError});

  @override
  State<OralAssessmentForm> createState() => _OralAssessmentFormState();
}

class _OralAssessmentFormState extends State<OralAssessmentForm> {
  String? _selectedOverallRisk;

  void _notifyDataChanged() {
    if (widget.onDataChanged != null && _selectedOverallRisk != null) {
      widget.onDataChanged!({
        'overallRisk': _selectedOverallRisk,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'ORAL ASSESSMENT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk factors: Social/behavioral/medical
          _buildRiskSection(
            'Risk factors: Social/behavioral/medical',
            const Color(0xFFE53935), // High Risk - Red
            [
              'Mother/primary caregiver has active dental caries',
              'Parent/caregiver has life-time of poverty, low health literacy',
              'Child has frequent exposure (>3 times/day) between-meal sugar-containing snacks or beverages per day',
              'Child uses bottle or nonspill cup containing natural or added sugar frequently, between meals and/or at bedtime',
            ],
          ),
          const SizedBox(height: 8),
          _buildModerateRiskItems([
            'Child is a recent immigrant',
            'Child has special health care needs',
          ]),
          const SizedBox(height: 12),
          // Risk factors: Clinical
          _buildRiskSection(
            'Risk factors: Clinical',
            const Color(0xFFE53935),
            [
              'Child has visible plaque on teeth',
              'Child presents with dental enamel defects',
            ],
          ),
          const SizedBox(height: 12),
          // Protective Factors
          _buildRiskSection(
            'Protective Factors',
            const Color(0xFFFFEB3B), // Low Risk - Yellow
            [
              'Child receives optimally-fluoridated drinking water or fluoride supplements',
              'Child has teeth brushed daily with fluoridated toothpaste',
              'Child receives topical fluoride from health professional',
              'Child has dental home/regular dental care',
            ],
          ),
          const SizedBox(height: 16),
          // Disease Indicators
          const Text(
            'Disease Indicators:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 8),
          _buildDiseaseIndicators(),
          const SizedBox(height: 12),
          // Overall Risk
          _buildOverallRisk(),
          if (widget.overallRiskError != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 6),
              child: Text(
                widget.overallRiskError!,
                style: const TextStyle(fontSize: 11, color: Color(0xFFD32F2F)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRiskSection(String title, Color indicatorColor, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                indicatorColor == const Color(0xFFE53935)
                    ? 'High Risk'
                    : indicatorColor == const Color(0xFFFF9800)
                        ? 'Moderate Risk'
                        : 'Low Risk',
                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildYesNoHeader(),
        ...items.map((item) => YesNoRow(text: item, color: indicatorColor)),
      ],
    );
  }

  Widget _buildModerateRiskItems(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Moderate Risk',
                style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        ...items.map((item) => YesNoRow(text: item, color: const Color(0xFFFF9800))),
      ],
    );
  }

  Widget _buildYesNoHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: SizedBox()),
          SizedBox(
            width: 35,
            child: Text('YES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)), textAlign: TextAlign.center),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 35,
            child: Text('NO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseIndicators() {
    return Column(
      children: [
        _buildYesNoHeader(),
        YesNoRow(text: 'Child has noncavitated (incipient/white spot) caries lesions', color: const Color(0xFFE53935)),
        YesNoRow(text: 'Child has visible caries lesions', color: const Color(0xFFE53935)),
        YesNoRow(text: 'Child has recent restorations or missing teeth due to caries', color: const Color(0xFFE53935)),
      ],
    );
  }

  Widget _buildOverallRisk() {
    return Row(
      children: [
        const Text(
          'Overall:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
        ),
        const SizedBox(width: 12),
        _buildSelectableRiskChip('High', const Color(0xFFE53935)),
        const SizedBox(width: 8),
        _buildSelectableRiskChip('Moderate', const Color(0xFFFF9800)),
        const SizedBox(width: 8),
        _buildSelectableRiskChip('Low', const Color(0xFFFFEB3B)),
      ],
    );
  }

  Widget _buildSelectableRiskChip(String label, Color color) {
    final isSelected = _selectedOverallRisk == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOverallRisk = isSelected ? null : label;
        });
        _notifyDataChanged();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: color == const Color(0xFFFFEB3B) ? Colors.black54 : Colors.white,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 12, color: color)
                  : null,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (color == const Color(0xFFFFEB3B) ? Colors.black87 : Colors.white)
                    : (color == const Color(0xFFFFEB3B) ? Colors.black54 : color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Yes/No row widget with mutually exclusive selection
class YesNoRow extends StatefulWidget {
  final String text;
  final Color color;

  const YesNoRow({super.key, required this.text, required this.color});

  @override
  State<YesNoRow> createState() => _YesNoRowState();
}

class _YesNoRowState extends State<YesNoRow> {
  bool? _selectedValue; // null = none, true = Yes, false = No

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              widget.text,
              style: const TextStyle(fontSize: 11, color: Color(0xFF5D4037)),
            ),
          ),
          // YES checkbox
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedValue = _selectedValue == true ? null : true;
              });
            },
            child: Container(
              width: 35,
              height: 20,
              decoration: BoxDecoration(
                color: _selectedValue == true ? widget.color : widget.color.withValues(alpha: 0.25),
                border: Border.all(color: widget.color, width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: _selectedValue == true
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          // NO checkbox
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedValue = _selectedValue == false ? null : false;
              });
            },
            child: Container(
              width: 35,
              height: 20,
              decoration: BoxDecoration(
                color: _selectedValue == false ? widget.color : widget.color.withValues(alpha: 0.25),
                border: Border.all(color: widget.color, width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: _selectedValue == false
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== VACCINATION FORM ====================
class VaccinationForm extends StatefulWidget {
  final Function(Map<String, dynamic>)? onDataChanged;

  const VaccinationForm({super.key, this.onDataChanged});

  @override
  State<VaccinationForm> createState() => _VaccinationFormState();
}

class _VaccinationFormState extends State<VaccinationForm> {
  static const _vaccineNames = ['BCG', 'HEP B', 'PENTAVALENT', 'OPV', 'IPV', 'PCV', 'MMR'];
  static const _columnHeaders = ['BIRTH', '1½', '2½', '3½', '9', '1 YR'];

  // Track dose selection: vaccineName -> [dose string or null × 6]
  final Map<String, List<String?>> _doses = {};

  // Define possible doses for each vaccine at each age column
  List<String> _getPossibleDoses(String vaccine, int colIndex) {
    final ageHeader = _columnHeaders[colIndex];
    
    switch (vaccine) {
      case 'BCG':
        return ageHeader == 'BIRTH' ? ['1st dose'] : [];
      case 'HEP B':
        if (ageHeader == 'BIRTH') return ['1st dose'];
        if (ageHeader == '1½') return ['2nd dose'];
        if (ageHeader == '2½') return ['3rd dose'];
        return [];
      case 'PENTAVALENT':
        if (ageHeader == '1½') return ['1st dose'];
        if (ageHeader == '2½') return ['2nd dose'];
        if (ageHeader == '3½') return ['3rd dose'];
        if (ageHeader == '1 YR') return ['4th dose'];
        return [];
      case 'OPV':
        if (ageHeader == 'BIRTH') return ['1st dose'];
        if (ageHeader == '2½') return ['2nd dose'];
        if (ageHeader == '9') return ['3rd dose'];
        return [];
      case 'IPV':
        if (ageHeader == '1½') return ['1st dose'];
        if (ageHeader == '2½') return ['2nd dose'];
        if (ageHeader == '3½') return ['3rd dose'];
        if (ageHeader == '1 YR') return ['4th dose'];
        return [];
      case 'PCV':
        if (ageHeader == '1½') return ['1st dose'];
        if (ageHeader == '2½') return ['2nd dose'];
        if (ageHeader == '3½') return ['3rd dose'];
        if (ageHeader == '1 YR') return ['4th dose'];
        return [];
      case 'MMR':
        if (ageHeader == '9') return ['1st dose'];
        if (ageHeader == '1 YR') return ['2nd dose'];
        return [];
      default:
        return [];
    }
  }

  @override
  void initState() {
    super.initState();
    for (final name in _vaccineNames) {
      _doses[name] = List.filled(6, null);
    }
    // Notify parent of initial (all-null) state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyParent());
  }

  void _onDoseChanged(String vaccine, int colIndex, String? dose) {
    setState(() {
      _doses[vaccine]![colIndex] = dose;
    });
    _notifyParent();
  }

  void _notifyParent() {
    if (widget.onDataChanged == null) return;
    final data = <String, dynamic>{};
    for (final name in _vaccineNames) {
      final doses = <String, bool>{};
      for (int i = 0; i < _columnHeaders.length; i++) {
        // Convert dose string to boolean for backward compatibility
        doses[_columnHeaders[i]] = _doses[name]![i] != null;
      }
      data[name] = doses;
    }
    widget.onDataChanged!(data);
  }

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'VACCINATION',
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF5D4037), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                // Header Row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFF5D4037))),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 80),
                      for (final header in _columnHeaders)
                        Expanded(
                          child: Text(
                            header,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
                // Vaccine Rows
                for (final name in _vaccineNames) _buildVaccineRow(name),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccineRow(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF5D4037), width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                name,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF5D4037)),
              ),
            ),
          ),
          for (int i = 0; i < 6; i++)
            Expanded(
              child: Center(
                child: VaccineDoseSelector(
                  selectedDose: _doses[name]![i],
                  possibleDoses: _getPossibleDoses(name, i),
                  onDoseSelected: (dose) => _onDoseChanged(name, i, dose),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class VaccineDoseSelector extends StatelessWidget {
  final String? selectedDose;
  final List<String> possibleDoses;
  final ValueChanged<String?> onDoseSelected;

  // All possible doses that can be selected
  static const List<String> allPossibleDoses = [
    '1st dose',
    '2nd dose',
    '3rd dose',
    '4th dose',
    '5th dose',
    'Booster',
  ];

  const VaccineDoseSelector({
    super.key,
    required this.selectedDose,
    required this.possibleDoses,
    required this.onDoseSelected,
  });

  @override
  Widget build(BuildContext context) {
    // If no doses are possible for this vaccine at this age, show empty box
    if (possibleDoses.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        height: 24,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.06),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.25),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          debugPrint('Box tapped! Possible doses: ${possibleDoses.length}');
          _showDoseMenu(context);
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          constraints: const BoxConstraints(minHeight: 24, minWidth: 30),
          decoration: BoxDecoration(
            color: selectedDose != null
                ? const Color(0xFF2E8B7B).withValues(alpha: 0.18)
                : const Color(0xFFD4F1E3), // soft green used elsewhere
            border: Border.all(
              color: selectedDose != null
                  ? const Color(0xFF2E8B7B)
                  : const Color(0xFF2E8B7B).withValues(alpha: 0.6),
              width: selectedDose != null ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: selectedDose != null
                ? Text(
                    selectedDose!,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E8B7B),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : const Icon(
                    Icons.add,
                    size: 12,
                    color: Color(0xFF5D4037),
                  ),
          ),
        ),
      ),
    );
  }

  void _showDoseMenu(BuildContext context) {
    debugPrint('_showDoseMenu called. Valid doses for this age: $possibleDoses');
    
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFD4F1E3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          title: const Text(
            'Select Dose',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E8B7B),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show warning if there are valid doses for this age
                if (possibleDoses.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8E6D5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF2E8B7B).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Color(0xFF2E8B7B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Valid doses for this age: ${possibleDoses.join(", ")}',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF2E8B7B).withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Clear selection option
                if (selectedDose != null)
                  ListTile(
                    leading: const Icon(Icons.clear, color: Colors.red),
                    title: const Text(
                      'Clear selection',
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      onDoseSelected(null);
                    },
                  ),
                // Show all possible doses
                ...allPossibleDoses.map((dose) {
                  final isSelected = selectedDose == dose;
                  final isValid = possibleDoses.contains(dose);
                  return ListTile(
                    leading: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isValid
                          ? (isSelected ? const Color(0xFF2E8B7B) : Colors.grey)
                          : Colors.grey.withValues(alpha: 0.4),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            dose,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isValid
                                  ? (isSelected
                                      ? const Color(0xFF2E8B7B)
                                      : Colors.black87)
                                  : Colors.grey.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        if (!isValid)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: Colors.orange,
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      if (isValid) {
                        onDoseSelected(dose);
                      } else {
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error: "$dose" is not appropriate for this vaccine at this age. Valid doses: ${possibleDoses.join(", ")}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                            action: SnackBarAction(
                              label: 'OK',
                              textColor: Colors.white,
                              onPressed: () {},
                            ),
                          ),
                        );
                      }
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    ).then((_) {
      debugPrint('Dialog closed');
    }).catchError((error) {
      debugPrint('Error showing dialog: $error');
    });
  }
}

// ==================== DEWORMING FORM ====================
class DewormingForm extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onSave;
  final String? errorText;

  const DewormingForm({super.key, this.onSave, this.errorText});

  @override
  State<DewormingForm> createState() => _DewormingFormState();
}

class _DewormingFormState extends State<DewormingForm> {
  bool _isNA = false;
  String? _drugGiven;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _adverseController = TextEditingController();
  final TextEditingController _nextDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateController.addListener(_notifyParent);
    _adverseController.addListener(_notifyParent);
    _nextDateController.addListener(_notifyParent);
  }

  @override
  void dispose() {
    _dateController.removeListener(_notifyParent);
    _adverseController.removeListener(_notifyParent);
    _nextDateController.removeListener(_notifyParent);
    _dateController.dispose();
    _adverseController.dispose();
    _nextDateController.dispose();
    super.dispose();
  }

  void _notifyParent() {
    final map = {
      'dateOfLastDeworming': _dateController.text.trim(),
      'isNA': _isNA,
      'drugGiven': _drugGiven,
      'adverseReactions': _adverseController.text.trim(),
      'nextDewormingDate': _nextDateController.text.trim(),
    };
    widget.onSave?.call(map);
  }

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'DEWORMING',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.errorText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD32F2F).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Color(0xFFD32F2F)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.errorText!,
                        style: const TextStyle(fontSize: 11, color: Color(0xFFD32F2F)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          FormFieldRow(
            label: 'Date of last deworming:',
            labelWidth: 160,
            controller: _dateController,
            keyboardType: TextInputType.datetime,
            hint: 'MM-DD-YYYY (e.g. 11-01-2025)',
            readOnly: _isNA,
            validator: (v) {
              if (_isNA) return null;
              if (v == null || v.trim().isEmpty) return 'Enter a date or select N/A';
              final value = v.trim();
              final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
              if (!regex.hasMatch(value)) {
                return 'Use format MM-DD-YYYY';
              }
              return null;
            },
          ),
          Row(
            children: [
              const SizedBox(width: 12),
              Checkbox(
                value: _isNA,
                onChanged: (v) {
                  setState(() {
                    _isNA = v ?? false;
                    if (_isNA) {
                      // When N/A is selected, clear all related inputs
                      _dateController.clear();
                      _nextDateController.clear();
                      _adverseController.clear();
                      _drugGiven = null;
                    }
                  });
                  _notifyParent();
                },
                activeColor: const Color(0xFF2E8B7B),
              ),
              const Text('N/A', style: TextStyle(fontSize: 12, color: Color(0xFF5D4037))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Drug Given:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF5D4037)),
              ),
              const SizedBox(width: 8),
              Checkbox(
                value: !_isNA && _drugGiven == 'Albendazole',
                onChanged: _isNA
                    ? null
                    : (v) {
                        setState(() => _drugGiven = v == true ? 'Albendazole' : null);
                        _notifyParent();
                      },
                activeColor: const Color(0xFF2E8B7B),
              ),
              const Text('Albendazole', style: TextStyle(fontSize: 12, color: Color(0xFF5D4037))),
              Checkbox(
                value: !_isNA && _drugGiven == 'Mebendazole',
                onChanged: _isNA
                    ? null
                    : (v) {
                        setState(() => _drugGiven = v == true ? 'Mebendazole' : null);
                        _notifyParent();
                      },
                activeColor: const Color(0xFF2E8B7B),
              ),
              const Text('Mebendazole', style: TextStyle(fontSize: 12, color: Color(0xFF5D4037))),
            ],
          ),
          const SizedBox(height: 12),
          FormFieldRow(label: 'Adverse Reactions:', labelWidth: 130, controller: _adverseController),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Next deworming date:',
            labelWidth: 140,
            controller: _nextDateController,
            keyboardType: TextInputType.datetime,
            hint: 'MM-DD-YYYY (e.g. 05-01-2026)',
            readOnly: _isNA,
            validator: (v) {
              if (_isNA) return null;
              if (v == null || v.trim().isEmpty) return 'Next deworming date is required';
              final value = v.trim();
              final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
              if (!regex.hasMatch(value)) {
                return 'Use format MM-DD-YYYY';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

