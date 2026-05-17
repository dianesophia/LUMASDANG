import 'package:flutter/material.dart';
import '../../patient_list.dart';
import '../../../services/age_utils.dart';

/// Holds controllers and pill-state for [DemographicDataForm].
class DemographicFormControllers {
  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final extensionNameController = TextEditingController();
  final ageController = TextEditingController();
  final ageDaysController = TextEditingController();
  final ageYearsController = TextEditingController();
  final sexController = TextEditingController();
  final bloodTypeController = TextEditingController();
  final addressController = TextEditingController();
  final placeOfBirthController = TextEditingController();
  final dobController = TextEditingController();
  final motherController = TextEditingController();
  final motherContactController = TextEditingController();
  final motherAgeController = TextEditingController();
  final motherOccupationController = TextEditingController();
  final fatherController = TextEditingController();
  final fatherContactController = TextEditingController();
  final fatherAgeController = TextEditingController();
  final fatherOccupationController = TextEditingController();
  final religionController = TextEditingController();
  final residenceStatusController = TextEditingController();
  final lengthOfStayController = TextEditingController();
  final birthWeightController = TextEditingController();
  final birthOrderController = TextEditingController();
  final caregiverNameController = TextEditingController();
  final caregiverAgeController = TextEditingController();
  final caregiverEthnicityController = TextEditingController();
  final caregiverRelationshipController = TextEditingController();
  final caregiverReligionController = TextEditingController();
  final fourPsHouseholdIdController = TextEditingController();
  final disabilityController = TextEditingController();
  final motherPhilHealthNumberController = TextEditingController();
  final motherPhilHealthMemberTypeController = TextEditingController();
  final fatherPhilHealthNumberController = TextEditingController();
  final fatherPhilHealthMemberTypeController = TextEditingController();

  bool? belongsToIpGroup;
  String? ipEthnicity;
  bool? isFourPsMember;
  bool? hasDisability;

  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    extensionNameController.dispose();
    ageController.dispose();
    ageDaysController.dispose();
    ageYearsController.dispose();
    sexController.dispose();
    bloodTypeController.dispose();
    addressController.dispose();
    placeOfBirthController.dispose();
    dobController.dispose();
    motherController.dispose();
    motherContactController.dispose();
    motherAgeController.dispose();
    motherOccupationController.dispose();
    fatherController.dispose();
    fatherContactController.dispose();
    fatherAgeController.dispose();
    fatherOccupationController.dispose();
    religionController.dispose();
    residenceStatusController.dispose();
    lengthOfStayController.dispose();
    birthWeightController.dispose();
    birthOrderController.dispose();
    caregiverNameController.dispose();
    caregiverAgeController.dispose();
    caregiverEthnicityController.dispose();
    caregiverRelationshipController.dispose();
    caregiverReligionController.dispose();
    fourPsHouseholdIdController.dispose();
    disabilityController.dispose();
    motherPhilHealthNumberController.dispose();
    motherPhilHealthMemberTypeController.dispose();
    fatherPhilHealthNumberController.dispose();
    fatherPhilHealthMemberTypeController.dispose();
  }
}

/// Shared demographic map builder (registration + edit).
class DemographicFormBinder {
  DemographicFormBinder._();

  static const _parentStatuses = [
    'Present',
    'N/A (Deceased)',
    'N/A (Unknown)',
    'N/A (Absent)',
  ];

  static String _str(dynamic v) => (v ?? '').toString().trim();

  static void populateFromMap(
    Map<String, dynamic> demo,
    DemographicFormControllers c,
  ) {
    c.firstNameController.text = _str(demo['firstName']);
    c.middleNameController.text = _str(demo['middleName']);
    c.lastNameController.text = _str(demo['lastName']);
    c.extensionNameController.text = _str(demo['extensionName']);
    c.ageController.text = _str(demo['age']);
    c.ageDaysController.text = _str(demo['ageDays']);
    c.ageYearsController.text = _str(demo['ageYears']);
    c.sexController.text = _str(demo['sex']);
    c.bloodTypeController.text = _str(demo['bloodType']);
    c.addressController.text = _str(demo['address']);
    c.placeOfBirthController.text = _str(demo['placeOfBirth']);
    c.dobController.text = _str(demo['dateOfBirth']);
    c.religionController.text = _str(demo['religion']);
    c.birthWeightController.text = _str(demo['birthWeight']);
    c.birthOrderController.text = _str(demo['birthOrder']);
    c.residenceStatusController.text = _str(demo['residenceStatus']);
    c.lengthOfStayController.text = _str(demo['lengthOfStay']);
    c.disabilityController.text = _str(demo['disability']);

    final motherVal = _str(demo['mother']);
    if (_parentStatuses.contains(motherVal) && motherVal != 'Present') {
      c.motherController.text = motherVal;
    } else {
      c.motherController.text = motherVal;
    }

    c.motherContactController.text = _str(demo['motherContact']);
    c.motherAgeController.text = _str(demo['motherAge']);
    c.motherOccupationController.text = _str(demo['motherOccupation']);
    c.motherPhilHealthNumberController.text =
        _str(demo['motherPhilHealthNumber']);
    c.motherPhilHealthMemberTypeController.text =
        _str(demo['motherPhilHealthMemberType']);

    final fatherVal = _str(demo['father']);
    if (_parentStatuses.contains(fatherVal) && fatherVal != 'Present') {
      c.fatherController.text = fatherVal;
    } else {
      c.fatherController.text = fatherVal;
    }

    c.fatherContactController.text = _str(demo['fatherContact']);
    c.fatherAgeController.text = _str(demo['fatherAge']);
    c.fatherOccupationController.text = _str(demo['fatherOccupation']);
    c.fatherPhilHealthNumberController.text =
        _str(demo['fatherPhilHealthNumber']);
    c.fatherPhilHealthMemberTypeController.text =
        _str(demo['fatherPhilHealthMemberType']);

    c.caregiverNameController.text = _str(demo['caregiverName']);
    c.caregiverAgeController.text = _str(demo['caregiverAge']);
    c.caregiverEthnicityController.text = _str(demo['caregiverEthnicity']);
    c.caregiverRelationshipController.text =
        _str(demo['caregiverRelationship']);
    c.caregiverReligionController.text = _str(demo['caregiverReligion']);
    c.fourPsHouseholdIdController.text = _str(demo['fourPsHouseholdId']);

    final ip = demo['belongsToIpGroup'];
    if (ip is bool) {
      c.belongsToIpGroup = ip;
    } else if (ip is String && ip.isNotEmpty) {
      c.belongsToIpGroup = ip.toLowerCase() == 'yes' || ip.toLowerCase() == 'true';
    }

    final ipEth = demo['ipEthnicity'];
    if (ipEth != null && ipEth.toString().trim().isNotEmpty) {
      c.ipEthnicity = ipEth.toString().trim();
    }

    final fourPs = demo['isFourPsMember'];
    if (fourPs is bool) {
      c.isFourPsMember = fourPs;
    } else if (fourPs is String && fourPs.isNotEmpty) {
      c.isFourPsMember =
          fourPs.toLowerCase() == 'yes' || fourPs.toLowerCase() == 'true';
    }

    final disability = demo['hasDisability'];
    if (disability is bool) {
      c.hasDisability = disability;
    } else if (disability is String && disability.isNotEmpty) {
      c.hasDisability =
          disability.toLowerCase() == 'yes' || disability.toLowerCase() == 'true';
    }
  }

  static Map<String, dynamic> buildDemographicMap(DemographicFormControllers c) {
    return {
      'firstName': c.firstNameController.text.trim(),
      'middleName': c.middleNameController.text.trim(),
      'lastName': c.lastNameController.text.trim(),
      'extensionName': c.extensionNameController.text.trim(),
      'age': c.ageController.text.trim(),
      'ageDays': c.ageDaysController.text.trim(),
      'ageYears': c.ageYearsController.text.trim(),
      'sex': c.sexController.text.trim(),
      'bloodType': c.bloodTypeController.text.trim(),
      'address': c.addressController.text.trim(),
      'placeOfBirth': c.placeOfBirthController.text.trim(),
      'dateOfBirth': c.dobController.text.trim(),
      'belongsToIpGroup': c.belongsToIpGroup,
      'ipEthnicity': c.ipEthnicity,
      'religion': c.religionController.text.trim(),
      'birthWeight': c.birthWeightController.text.trim(),
      'birthOrder': c.birthOrderController.text.trim(),
      'residenceStatus': c.residenceStatusController.text.trim(),
      'lengthOfStay': c.lengthOfStayController.text.trim(),
      'hasDisability': c.hasDisability,
      'disability': c.disabilityController.text.trim(),
      'mother': c.motherController.text.trim(),
      'motherContact': c.motherContactController.text.trim(),
      'motherAge': c.motherAgeController.text.trim(),
      'motherOccupation': c.motherOccupationController.text.trim(),
      'motherPhilHealthNumber': c.motherPhilHealthNumberController.text.trim(),
      'motherPhilHealthMemberType':
          c.motherPhilHealthMemberTypeController.text.trim(),
      'father': c.fatherController.text.trim(),
      'fatherContact': c.fatherContactController.text.trim(),
      'fatherAge': c.fatherAgeController.text.trim(),
      'fatherOccupation': c.fatherOccupationController.text.trim(),
      'fatherPhilHealthNumber': c.fatherPhilHealthNumberController.text.trim(),
      'fatherPhilHealthMemberType':
          c.fatherPhilHealthMemberTypeController.text.trim(),
      'caregiverName': c.caregiverNameController.text.trim(),
      'caregiverAge': c.caregiverAgeController.text.trim(),
      'caregiverEthnicity': c.caregiverEthnicityController.text.trim(),
      'caregiverRelationship': c.caregiverRelationshipController.text.trim(),
      'caregiverReligion': c.caregiverReligionController.text.trim(),
      'isFourPsMember': c.isFourPsMember,
      'fourPsHouseholdId': c.fourPsHouseholdIdController.text.trim(),
    };
  }

  /// Rebuild [Patient] from demographic map, preserving list metadata from [existing].
  static Patient patientFromDemographic({
    required Map<String, dynamic> demographic,
    required Patient existing,
    Map<String, dynamic>? patientDocData,
  }) {
    final ageMonths = ageInMonthsFromDemographic(demographic) ??
        int.tryParse(demographic['age']?.toString() ?? '') ??
        existing.age;

    final data = patientDocData ?? <String, dynamic>{};

    return Patient(
      firstName: _str(demographic['firstName']),
      lastName: _str(demographic['lastName']),
      age: ageMonths,
      assessmentRemarks: existing.assessmentRemarks,
      lastVisit: existing.lastVisit,
      guardianContact: _str(demographic['fatherContact']).isNotEmpty
          ? _str(demographic['fatherContact'])
          : _str(demographic['motherContact']),
      avatarColor: existing.avatarColor,
      address: _str(demographic['address']),
      dateOfBirth: _str(demographic['dateOfBirth']),
      sex: _str(demographic['sex']),
      docId: existing.docId,
      motherName: _str(demographic['mother']),
      motherContact: _str(demographic['motherContact']),
      fatherName: _str(demographic['father']),
      fatherContact: _str(demographic['fatherContact']),
      createdBy: data['createdByName']?.toString() ?? existing.createdBy,
      barangayId: data['barangayId']?.toString() ?? existing.barangayId,
      isArchived: existing.isArchived,
      visitDate: data['visitDate']?.toString() ?? existing.visitDate,
      visitTime: data['visitTime']?.toString() ?? existing.visitTime,
      nextFollowUpDate: existing.nextFollowUpDate,
      followUpNotes: existing.followUpNotes,
    );
  }

  static bool namesChanged(
    Map<String, dynamic> before,
    Map<String, dynamic> after,
  ) {
    return _str(before['firstName']) != _str(after['firstName']) ||
        _str(before['middleName']) != _str(after['middleName']) ||
        _str(before['lastName']) != _str(after['lastName']);
  }
}
