import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../home/widgets/demographic_data_form.dart';
import '../patient_list.dart';
import '../../services/connectivity_service.dart';
import '../../services/firestore_service.dart';
import 'utils/demographic_form_binder.dart';

/// Online-only editor for the full demographic block on an existing barangay patient.
class EditPatientDemographicsScreen extends StatefulWidget {
  final Patient patient;

  const EditPatientDemographicsScreen({super.key, required this.patient});

  @override
  State<EditPatientDemographicsScreen> createState() =>
      _EditPatientDemographicsScreenState();
}

class _EditPatientDemographicsScreenState
    extends State<EditPatientDemographicsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = DemographicFormControllers();
  final _firestore = FirestoreService();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  Map<String, dynamic>? _originalDemographic;
  Map<String, dynamic>? _patientDocData;
  int _demographicFormKey = 0;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  Future<void> _loadPatient() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    if (widget.patient.docId.isEmpty) {
      setState(() {
        _loading = false;
        _loadError = 'This patient record cannot be edited.';
      });
      return;
    }

    try {
      final online = kIsWeb
          ? true
          : await ConnectivityService.instance.checkOnline();
      if (!online) {
        setState(() {
          _loading = false;
          _loadError = 'Connect to the internet to edit patient profile.';
        });
        return;
      }

      final data =
          await _firestore.getBarangayPatientById(widget.patient.docId);
      if (data == null) {
        setState(() {
          _loading = false;
          _loadError = 'Patient record not found.';
        });
        return;
      }

      final rawDemo = data['demographic'];
      Map<String, dynamic> demo;
      if (rawDemo is Map<String, dynamic>) {
        demo = rawDemo;
      } else if (rawDemo is Map) {
        demo = Map<String, dynamic>.from(rawDemo);
      } else {
        demo = <String, dynamic>{};
      }

      DemographicFormBinder.populateFromMap(demo, _controllers);
      _originalDemographic = Map<String, dynamic>.from(demo);
      _patientDocData = data;

      setState(() {
        _loading = false;
        _demographicFormKey++;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = 'Failed to load patient: $e';
      });
    }
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final online = kIsWeb
        ? true
        : await ConnectivityService.instance.checkOnline();
    if (!online) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connect to the internet to save changes.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    setState(() => _saving = true);

    try {
      final demographic =
          DemographicFormBinder.buildDemographicMap(_controllers);

      await _firestore.updatePatientInBarangay(
        patientId: widget.patient.docId,
        demographic: demographic,
      );

      final barangayId = _patientDocData?['barangayId']?.toString() ??
          widget.patient.barangayId;
      if (_originalDemographic != null &&
          DemographicFormBinder.namesChanged(
              _originalDemographic!, demographic) &&
          barangayId.isNotEmpty) {
        await _firestore.saveVaccinationStatusToBarangayPatient(
          barangayId: barangayId,
          patientId: widget.patient.docId,
          firstName: demographic['firstName']?.toString() ?? '',
          middleName: demographic['middleName']?.toString() ?? '',
          lastName: demographic['lastName']?.toString() ?? '',
          statuses: const {},
        );
      }

      final updated = DemographicFormBinder.patientFromDemographic(
        demographic: demographic,
        existing: widget.patient,
        patientDocData: _patientDocData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient profile updated.'),
            backgroundColor: Color(0xFF2E8B7B),
          ),
        );
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E8B7B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Edit ${widget.patient.firstName} ${widget.patient.lastName}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _loading || _loadError != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8B7B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E8B7B)),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _loadPatient,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: DemographicDataForm(
          key: ValueKey('edit_demographic_$_demographicFormKey'),
          firstNameController: _controllers.firstNameController,
          middleNameController: _controllers.middleNameController,
          lastNameController: _controllers.lastNameController,
          extensionNameController: _controllers.extensionNameController,
          ageController: _controllers.ageController,
          ageDaysController: _controllers.ageDaysController,
          ageYearsController: _controllers.ageYearsController,
          sexController: _controllers.sexController,
          bloodTypeController: _controllers.bloodTypeController,
          addressController: _controllers.addressController,
          motherPhilHealthNumberController:
              _controllers.motherPhilHealthNumberController,
          motherPhilHealthMemberTypeController:
              _controllers.motherPhilHealthMemberTypeController,
          fatherPhilHealthNumberController:
              _controllers.fatherPhilHealthNumberController,
          fatherPhilHealthMemberTypeController:
              _controllers.fatherPhilHealthMemberTypeController,
          placeOfBirthController: _controllers.placeOfBirthController,
          dobController: _controllers.dobController,
          motherController: _controllers.motherController,
          motherContactController: _controllers.motherContactController,
          motherAgeController: _controllers.motherAgeController,
          motherOccupationController: _controllers.motherOccupationController,
          fatherController: _controllers.fatherController,
          fatherContactController: _controllers.fatherContactController,
          fatherAgeController: _controllers.fatherAgeController,
          fatherOccupationController: _controllers.fatherOccupationController,
          religionController: _controllers.religionController,
          residenceStatusController: _controllers.residenceStatusController,
          lengthOfStayController: _controllers.lengthOfStayController,
          birthWeightController: _controllers.birthWeightController,
          birthOrderController: _controllers.birthOrderController,
          caregiverNameController: _controllers.caregiverNameController,
          caregiverAgeController: _controllers.caregiverAgeController,
          caregiverEthnicityController:
              _controllers.caregiverEthnicityController,
          caregiverRelationshipController:
              _controllers.caregiverRelationshipController,
          caregiverReligionController: _controllers.caregiverReligionController,
          fourPsHouseholdIdController: _controllers.fourPsHouseholdIdController,
          disabilityController: _controllers.disabilityController,
          belongsToIpGroup: _controllers.belongsToIpGroup,
          ipEthnicity: _controllers.ipEthnicity,
          isFourPsMember: _controllers.isFourPsMember,
          hasDisability: _controllers.hasDisability,
          onBelongsToIpGroupChanged: (v) =>
              setState(() => _controllers.belongsToIpGroup = v),
          onIpEthnicityChanged: (v) =>
              setState(() => _controllers.ipEthnicity = v),
          onIsFourPsMemberChanged: (v) =>
              setState(() => _controllers.isFourPsMember = v),
          onHasDisabilityChanged: (v) =>
              setState(() => _controllers.hasDisability = v),
          isDraft: false, streetController: _controllers.streetController,
        ),
      ),
    );
  }
}
