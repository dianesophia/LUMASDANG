import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';

import 'firestore_service.dart';

/// Age bands used in the OPT Plus summary (0–59 months).
enum OptAgeBand {
  months0to5,
  months6to11,
  months12to23,
  months24to35,
  months36to47,
  months48to59,
}

enum OptSexGroup { boy, girl, unknown }

class OptPlusSummary {
  final int totalChildren0to59;
  final int totalBoys;
  final int totalGirls;

  const OptPlusSummary({
    required this.totalChildren0to59,
    required this.totalBoys,
    required this.totalGirls,
  });
}

/// Summary counts for OPT Plus cells H35–H42 (derived from per-child assessment).
class OptPlusIndicatorSummary {
  /// H35, H36: # Children 0–59 mos. who are Wasted and/or Stunted
  final int countWastedOrStunted0to59;
  /// H37: # Children 0–59 mos. who are Overweight/Obesity
  final int countOverweightObese0to59;
  /// H38: Total Number of Children 0–23 mos. old
  final int totalChildren0to23;
  /// H39: # Children 0–23 mos. who are Wasted and/or Stunted
  final int countWastedOrStunted0to23;
  /// H40: Total Number of Children 0–29 mos. old
  final int totalChildren0to29;
  /// H41: Total Number of Children 30–59 mos. old
  final int totalChildren30to59;
  /// H42: Total Number of Children 24–59 mos. old
  final int totalChildren24to59;

  const OptPlusIndicatorSummary({
    required this.countWastedOrStunted0to59,
    required this.countOverweightObese0to59,
    required this.totalChildren0to23,
    required this.countWastedOrStunted0to23,
    required this.totalChildren0to29,
    required this.totalChildren30to59,
    required this.totalChildren24to59,
  });
}

/// Counts for 0-5 month old boys (OPT Plus Form B cell mapping).
class OptPlusBoys0to5Counts {
  final int wfaNormal;      // B16
  final int wfaMuw;         // B19 - Moderately underweight
  final int wfaSuw;         // B20 - Severely underweight
  final int hfaNormal;      // B21
  final int hfaTall;        // B22
  final int hfaMst;         // B23 - Moderately stunted
  final int hfaSst;         // B24 - Severely stunted
  final int wflNormal;      // B25
  final int wflOw;          // B26 - Overweight
  final int wflOb;          // B27 - Obese
  final int wflMwMam;       // B28 - Moderate wasting / MAM
  final int wflSwSam;       // B29 - Severe wasting / SAM
  final int muacNormal;     // B30
  final int muacMwMam;      // B31
  final int muacSwSam;      // B32

  const OptPlusBoys0to5Counts({
    this.wfaNormal = 0,
    this.wfaMuw = 0,
    this.wfaSuw = 0,
    this.hfaNormal = 0,
    this.hfaTall = 0,
    this.hfaMst = 0,
    this.hfaSst = 0,
    this.wflNormal = 0,
    this.wflOw = 0,
    this.wflOb = 0,
    this.wflMwMam = 0,
    this.wflSwSam = 0,
    this.muacNormal = 0,
    this.muacMwMam = 0,
    this.muacSwSam = 0,
  });
}

class OptPlusService {
  /// When true, uses mock patient/assessment data instead of Firestore.
  /// Toggle via the "Use mock data" switch on the OPT Plus screen.
  static bool useMockData = false;

  /// Mock patient-assessment pairs for testing the full classification pipeline.
  /// Each entry: { 'patient': { id, demographic: { age, sex } }, 'assessment': { anthropometric: {...} } }.
  static List<Map<String, dynamic>> _getMockPatientAssessments() {
    return [
      // 0–5 months: 1 boy (normal), 1 girl (MUW, MSt, MAM)
      {'patient': {'id': 'mock-1', 'demographic': {'age': '3', 'sex': 'male'}}, 'assessment': {'anthropometric': {'weightForAge': '0.2 (Normal)', 'heightForAge': '-0.5 (Normal)', 'weightForHeight': '0.1 (Normal)', 'muac': '13.5'}}},
      {'patient': {'id': 'mock-2', 'demographic': {'age': '4', 'sex': 'female'}}, 'assessment': {'anthropometric': {'weightForAge': '-2.1 (Underweight)', 'heightForAge': '-2.3 (Stunted)', 'weightForHeight': '0.0 (Normal)', 'muac': '12.0'}}},
      // 6–11 months: 1 boy (SUW, SSt, MAM, SAM MUAC), 1 girl (Tall, OW, Normal)
      {'patient': {'id': 'mock-3', 'demographic': {'age': '8', 'sex': 'male'}}, 'assessment': {'anthropometric': {'weightForAge': '-3.2 (Severely underweight)', 'heightForAge': '-3.5 (Severely stunted)', 'weightForHeight': '-2.2 (Wasted)', 'muac': '11.0'}}},
      {'patient': {'id': 'mock-4', 'demographic': {'age': '10', 'sex': 'female'}}, 'assessment': {'anthropometric': {'weightForAge': '0.5 (Normal)', 'heightForAge': '2.5 (Tall)', 'weightForHeight': '2.2 (Overweight)', 'muac': '13.5'}}},
      // 12–23 months: 1 boy (MUW, MSt, Obese), 1 girl (Severe wasting, SAM MUAC)
      {'patient': {'id': 'mock-5', 'demographic': {'age': '18', 'sex': 'male'}}, 'assessment': {'anthropometric': {'weightForAge': '-2.0 (Underweight)', 'heightForAge': '-2.1 (Stunted)', 'weightForHeight': '3.1 (Obese)', 'muac': '13.0'}}},
      {'patient': {'id': 'mock-6', 'demographic': {'age': '20', 'sex': 'female'}}, 'assessment': {'anthropometric': {'weightForAge': '0.0 (Normal)', 'heightForAge': '-0.8 (Normal)', 'weightForHeight': '-3.2 (Severe wasting)', 'muac': '11.2'}}},
      // 24–35 months: 1 boy (SUW, SSt, MAM), 1 girl (all Normal)
      {'patient': {'id': 'mock-7', 'demographic': {'age': '30', 'sex': 'male'}}, 'assessment': {'anthropometric': {'weightForAge': '-3.5 (Severely underweight)', 'heightForAge': '-3.8 (Severely stunted)', 'weightForHeight': '-2.0 (Wasted)', 'muac': '12.0'}}},
      {'patient': {'id': 'mock-8', 'demographic': {'age': '32', 'sex': 'female'}}, 'assessment': {'anthropometric': {'weightForAge': '0.1 (Normal)', 'heightForAge': '-0.3 (Normal)', 'weightForHeight': '0.0 (Normal)', 'muac': '13.0'}}},
      // 36–47 months: 1 boy (MUW, Severe wasting, SAM), 1 girl (Tall, OW, Normal)
      {'patient': {'id': 'mock-9', 'demographic': {'age': '42', 'sex': 'male'}}, 'assessment': {'anthropometric': {'weightForAge': '-2.2 (Underweight)', 'heightForAge': '-1.0 (Normal)', 'weightForHeight': '-3.1 (Severe wasting)', 'muac': '11.3'}}},
      {'patient': {'id': 'mock-10', 'demographic': {'age': '45', 'sex': 'female'}}, 'assessment': {'anthropometric': {'weightForAge': '0.8 (Normal)', 'heightForAge': '2.8 (Tall)', 'weightForHeight': '2.5 (Overweight)', 'muac': '14.0'}}},
      // 48–59 months: 1 boy (Normal, MSt), 1 girl (SUW, SSt, Severe wasting, SAM)
      {'patient': {'id': 'mock-11', 'demographic': {'age': '55', 'sex': 'male'}}, 'assessment': {'anthropometric': {'weightForAge': '0.3 (Normal)', 'heightForAge': '-2.4 (Stunted)', 'weightForHeight': '0.2 (Normal)', 'muac': '12.5'}}},
      {'patient': {'id': 'mock-12', 'demographic': {'age': '58', 'sex': 'female'}}, 'assessment': {'anthropometric': {'weightForAge': '-3.0 (Severely underweight)', 'heightForAge': '-3.2 (Severely stunted)', 'weightForHeight': '-3.5 (Severe wasting)', 'muac': '11.0'}}},
    ];
  }

  static OptAgeBand? _ageBandForMonths(int? months) {
    if (months == null || months < 0) return null;
    if (months <= 5) return OptAgeBand.months0to5;
    if (months <= 11) return OptAgeBand.months6to11;
    if (months <= 23) return OptAgeBand.months12to23;
    if (months <= 35) return OptAgeBand.months24to35;
    if (months <= 47) return OptAgeBand.months36to47;
    if (months <= 59) return OptAgeBand.months48to59;
    return null; // outside OPT Plus age range
  }

  static OptSexGroup _sexGroupForRaw(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    if (s.isEmpty) return OptSexGroup.unknown;
    if (s.startsWith('m') || s == 'lalaki') return OptSexGroup.boy;
    if (s.startsWith('f') || s == 'babae') return OptSexGroup.girl;
    return OptSexGroup.unknown;
  }

  static int _parseAgeMonths(String? ageStr) {
    if (ageStr == null) return -1;
    final trimmed = ageStr.trim();
    if (trimmed.isEmpty) return -1;
    final match = RegExp(r'[\d.]+').firstMatch(trimmed);
    if (match == null) return -1;
    final numVal = double.tryParse(match.group(0)!);
    if (numVal == null || numVal < 0) return -1;
    return numVal.round();
  }

  /// Extract interpretation from strings like "-1.50 (Underweight)" or "0.5 (Normal)".
  static String _extractInterpretation(String? s) {
    if (s == null || s.isEmpty) return '';
    final match = RegExp(r'\(([^)]+)\)').firstMatch(s.trim());
    return (match?.group(1) ?? '').trim().toLowerCase();
  }

  /// Parse z-score from strings like "-1.50 (Underweight)".
  static double? _parseZScore(String? s) {
    if (s == null || s.isEmpty) return null;
    final match = RegExp(r'^-?[\d.]+').firstMatch(s.trim());
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  /// Classify WFA interpretation into OPT Plus categories.
  static void _classifyWfa(String? wfaStr, OptPlusBoys0to5CountsBuilder c) {
    final interp = _extractInterpretation(wfaStr);
    if (interp.isEmpty) return;
    if (interp.contains('normal')) {
      c.wfaNormal++;
    } else if (interp.contains('severely') && interp.contains('underweight')) {
      c.wfaSuw++;
    } else if (interp.contains('underweight')) {
      c.wfaMuw++;
    }
  }

  /// Classify HFA interpretation into OPT Plus categories.
  /// Tall = z > 2; Normal = -2 to 2; MSt = -3 to -2; SSt = z < -3.
  static void _classifyHfa(String? hfaStr, OptPlusBoys0to5CountsBuilder c) {
    final interp = _extractInterpretation(hfaStr);
    final z = _parseZScore(hfaStr);
    if (interp.isEmpty && z == null) return;
    if (z != null) {
      if (z > 2) {
        c.hfaTall++;
        return;
      }
      if (z < -3) {
        c.hfaSst++;
        return;
      }
      if (z < -2) {
        c.hfaMst++;
        return;
      }
      if (z >= -2 && z <= 2) {
        c.hfaNormal++;
        return;
      }
    }
    // Fallback by interpretation
    if (interp.contains('severely') && interp.contains('stunted')) {
      c.hfaSst++;
    } else if (interp.contains('stunted')) {
      c.hfaMst++;
    } else if (interp.contains('normal') || interp.contains('tall')) {
      if (interp.contains('tall')) {
        c.hfaTall++;
      } else {
        c.hfaNormal++;
      }
    }
  }

  /// Classify WFL/WH interpretation into OPT Plus categories.
  static void _classifyWfl(String? wflStr, OptPlusBoys0to5CountsBuilder c) {
    final interp = _extractInterpretation(wflStr);
    if (interp.isEmpty) return;
    if (interp.contains('normal')) {
      c.wflNormal++;
    } else if (interp.contains('obese')) {
      c.wflOb++;
    } else if (interp.contains('overweight')) {
      c.wflOw++;
    } else if (interp.contains('severe') && interp.contains('wasting')) {
      c.wflSwSam++;
    } else if (interp.contains('wasted')) {
      c.wflMwMam++;
    }
  }

  /// Classify MUAC (cm) into OPT Plus categories.
  /// Normal: >= 12.5; MAM: 11.5–12.5; SAM: < 11.5.
  static void _classifyMuac(String? muacStr, OptPlusBoys0to5CountsBuilder c) {
    if (muacStr == null || muacStr.trim().isEmpty) return;
    final val = double.tryParse(muacStr.trim());
    if (val == null || val <= 0) return;
    if (val < 11.5) {
      c.muacSwSam++;
    } else if (val < 12.5) {
      c.muacMwMam++;
    } else {
      c.muacNormal++;
    }
  }

  /// True if child is wasted (WFA MUW/SUW, or WFL/H MAM/SAM, or MUAC MAM/SAM).
  static bool _isWastedFromAssessment(String? wfa, String? wfl, String? muac) {
    final wfaInterp = _extractInterpretation(wfa);
    final wflInterp = _extractInterpretation(wfl);
    if (wfaInterp.contains('severely') && wfaInterp.contains('underweight')) return true;
    if (wfaInterp.contains('underweight')) return true;
    if (wflInterp.contains('severe') && wflInterp.contains('wasting')) return true;
    if (wflInterp.contains('wasted')) return true;
    if (muac != null && muac.trim().isNotEmpty) {
      final val = double.tryParse(muac.trim());
      if (val != null && val > 0 && val < 12.5) return true;
    }
    return false;
  }

  /// True if child is stunted (HFA MSt or SSt).
  static bool _isStuntedFromAssessment(String? hfa) {
    final interp = _extractInterpretation(hfa);
    final z = _parseZScore(hfa);
    if (z != null && z < -2) return true;
    if (interp.contains('severely') && interp.contains('stunted')) return true;
    if (interp.contains('stunted')) return true;
    return false;
  }

  /// True if child is overweight or obese (WFL/H OW or Ob).
  static bool _isOverweightOrObeseFromAssessment(String? wfl) {
    final interp = _extractInterpretation(wfl);
    return interp.contains('obese') || interp.contains('overweight');
  }

  /// Build H35–H42 indicator summary by iterating all children 0–59 with latest assessment.
  static Future<OptPlusIndicatorSummary> buildIndicatorSummary() async {
    int countWastedOrStunted0to59 = 0;
    int countOverweightObese0to59 = 0;
    int totalChildren0to23 = 0;
    int countWastedOrStunted0to23 = 0;
    int totalChildren0to29 = 0;
    int totalChildren30to59 = 0;
    int totalChildren24to59 = 0;

    void processChild(int ageMonths, String? wfa, String? hfa, String? wfl, String? muac) {
      if (ageMonths < 0 || ageMonths > 59) return;
      final wasted = _isWastedFromAssessment(wfa, wfl, muac);
      final stunted = _isStuntedFromAssessment(hfa);
      final owOb = _isOverweightOrObeseFromAssessment(wfl);
      if (wasted || stunted) countWastedOrStunted0to59++;
      if (owOb) countOverweightObese0to59++;
      if (ageMonths <= 23) {
        totalChildren0to23++;
        if (wasted || stunted) countWastedOrStunted0to23++;
      }
      if (ageMonths <= 29) totalChildren0to29++;
      if (ageMonths >= 30) totalChildren30to59++;
      if (ageMonths >= 24) totalChildren24to59++;
    }

    if (useMockData) {
      for (final pa in _getMockPatientAssessments()) {
        final doc = pa['patient'] as Map<String, dynamic>;
        final demographic = (doc['demographic'] ?? {}) as Map<String, dynamic>;
        final ageMonths = _parseAgeMonths(demographic['age']?.toString());
        if (ageMonths < 0 || ageMonths > 59) continue;
        final assessment = pa['assessment'] as Map<String, dynamic>;
        final anthropometric = (assessment['anthropometric'] ?? {}) as Map<String, dynamic>;
        processChild(
          ageMonths,
          anthropometric['weightForAge']?.toString(),
          anthropometric['heightForAge']?.toString(),
          anthropometric['weightForHeight']?.toString(),
          anthropometric['muac']?.toString(),
        );
      }
    } else {
      final patients = await FirestoreService().getPatientsFromBarangay();
      final firestore = FirestoreService();
      for (final doc in patients) {
        final demographic = (doc['demographic'] ?? {}) as Map<String, dynamic>;
        final ageMonths = _parseAgeMonths(demographic['age']?.toString());
        if (ageMonths < 0 || ageMonths > 59) continue;
        final assessments = await firestore.getAssessmentsForBarangayPatient(doc['id'] as String);
        if (assessments.isEmpty) continue;
        final latest = assessments.last;
        final anthropometric = (latest['anthropometric'] ?? {}) as Map<String, dynamic>;
        processChild(
          ageMonths,
          anthropometric['weightForAge']?.toString(),
          anthropometric['heightForAge']?.toString(),
          anthropometric['weightForHeight']?.toString(),
          anthropometric['muac']?.toString(),
        );
      }
    }

    return OptPlusIndicatorSummary(
      countWastedOrStunted0to59: countWastedOrStunted0to59,
      countOverweightObese0to59: countOverweightObese0to59,
      totalChildren0to23: totalChildren0to23,
      countWastedOrStunted0to23: countWastedOrStunted0to23,
      totalChildren0to29: totalChildren0to29,
      totalChildren30to59: totalChildren30to59,
      totalChildren24to59: totalChildren24to59,
    );
  }

  /// Build counts for a given age band and sex. Uses the latest assessment per child.
  static Future<OptPlusBoys0to5Counts> buildAgeBandCounts({
    required int minMonths,
    required int maxMonths,
    required OptSexGroup sex,
  }) async {
    final builder = OptPlusBoys0to5CountsBuilder();

    if (useMockData) {
      for (final pa in _getMockPatientAssessments()) {
        final doc = pa['patient'] as Map<String, dynamic>;
        final demographic = (doc['demographic'] ?? {}) as Map<String, dynamic>;
        final ageMonths = _parseAgeMonths(demographic['age']?.toString());
        if (ageMonths < minMonths || ageMonths > maxMonths) continue;

        final sexGroup = _sexGroupForRaw(demographic['sex']?.toString());
        if (sexGroup != sex) continue;

        final assessment = pa['assessment'] as Map<String, dynamic>;
        final anthropometric = (assessment['anthropometric'] ?? {}) as Map<String, dynamic>;
        final wfa = anthropometric['weightForAge']?.toString();
        final hfa = anthropometric['heightForAge']?.toString();
        final wfl = anthropometric['weightForHeight']?.toString();
        final muac = anthropometric['muac']?.toString();

        _classifyWfa(wfa, builder);
        _classifyHfa(hfa, builder);
        _classifyWfl(wfl, builder);
        _classifyMuac(muac, builder);
      }
      return builder.build();
    }

    final patients = await FirestoreService().getPatientsFromBarangay();
    final firestore = FirestoreService();

    for (final doc in patients) {
      final demographic = (doc['demographic'] ?? {}) as Map<String, dynamic>;
      final ageMonths = _parseAgeMonths(demographic['age']?.toString());
      if (ageMonths < minMonths || ageMonths > maxMonths) continue;

      final sexGroup = _sexGroupForRaw(demographic['sex']?.toString());
      if (sexGroup != sex) continue;

      final assessments = await firestore.getAssessmentsForBarangayPatient(doc['id'] as String);
      if (assessments.isEmpty) continue;

      final latest = assessments.last;
      final anthropometric = (latest['anthropometric'] ?? {}) as Map<String, dynamic>;
      final wfa = anthropometric['weightForAge']?.toString();
      final hfa = anthropometric['heightForAge']?.toString();
      final wfl = anthropometric['weightForHeight']?.toString();
      final muac = anthropometric['muac']?.toString();

      _classifyWfa(wfa, builder);
      _classifyHfa(hfa, builder);
      _classifyWfl(wfl, builder);
      _classifyMuac(muac, builder);
    }

    return builder.build();
  }

  static Future<OptPlusBoys0to5Counts> buildBoys0to5Counts() =>
      buildAgeBandCounts(minMonths: 0, maxMonths: 5, sex: OptSexGroup.boy);
  static Future<OptPlusBoys0to5Counts> buildGirls0to5Counts() =>
      buildAgeBandCounts(minMonths: 0, maxMonths: 5, sex: OptSexGroup.girl);
  static Future<OptPlusBoys0to5Counts> buildBoys6to11Counts() =>
      buildAgeBandCounts(minMonths: 6, maxMonths: 11, sex: OptSexGroup.boy);
  static Future<OptPlusBoys0to5Counts> buildGirls6to11Counts() =>
      buildAgeBandCounts(minMonths: 6, maxMonths: 11, sex: OptSexGroup.girl);
  static Future<OptPlusBoys0to5Counts> buildBoys12to23Counts() =>
      buildAgeBandCounts(minMonths: 12, maxMonths: 23, sex: OptSexGroup.boy);
  static Future<OptPlusBoys0to5Counts> buildGirls12to23Counts() =>
      buildAgeBandCounts(minMonths: 12, maxMonths: 23, sex: OptSexGroup.girl);
  static Future<OptPlusBoys0to5Counts> buildBoys24to35Counts() =>
      buildAgeBandCounts(minMonths: 24, maxMonths: 35, sex: OptSexGroup.boy);
  static Future<OptPlusBoys0to5Counts> buildGirls24to35Counts() =>
      buildAgeBandCounts(minMonths: 24, maxMonths: 35, sex: OptSexGroup.girl);
  static Future<OptPlusBoys0to5Counts> buildBoys36to47Counts() =>
      buildAgeBandCounts(minMonths: 36, maxMonths: 47, sex: OptSexGroup.boy);
  static Future<OptPlusBoys0to5Counts> buildGirls36to47Counts() =>
      buildAgeBandCounts(minMonths: 36, maxMonths: 47, sex: OptSexGroup.girl);
  static Future<OptPlusBoys0to5Counts> buildBoys48to59Counts() =>
      buildAgeBandCounts(minMonths: 48, maxMonths: 59, sex: OptSexGroup.boy);
  static Future<OptPlusBoys0to5Counts> buildGirls48to59Counts() =>
      buildAgeBandCounts(minMonths: 48, maxMonths: 59, sex: OptSexGroup.girl);

  /// Build a very compact summary for all 0–59 month children
  /// in the logged-in user's barangay.
  static Future<OptPlusSummary> buildSummary() async {
    List<Map<String, dynamic>> patients;
    if (useMockData) {
      patients = _getMockPatientAssessments()
          .map((pa) => pa['patient'] as Map<String, dynamic>)
          .toList();
    } else {
      patients = await FirestoreService().getPatientsFromBarangay();
    }

    int totalChildren0to59 = 0;
    int totalBoys = 0;
    int totalGirls = 0;

    for (final doc in patients) {
      final demographic = (doc['demographic'] ?? {}) as Map<String, dynamic>;
      final ageMonths = _parseAgeMonths(demographic['age']?.toString());
      final band = _ageBandForMonths(ageMonths);
      if (band == null) continue;

      final sexGroup = _sexGroupForRaw(demographic['sex']?.toString());
      totalChildren0to59++;
      if (sexGroup == OptSexGroup.boy) {
        totalBoys++;
      } else if (sexGroup == OptSexGroup.girl) {
        totalGirls++;
      }
    }

    return OptPlusSummary(
      totalChildren0to59: totalChildren0to59,
      totalBoys: totalBoys,
      totalGirls: totalGirls,
    );
  }

  /// When non-null, _writeCell/_writeCellString record ref->value here for value-only xlsx patch.
  static Map<String, dynamic>? _optPlusCellUpdates;

  /// Shared style with thin black borders for cells that have no style in the template.
  static final CellStyle _borderedDataStyle = CellStyle(
    fontColorHex: ExcelColor.black,
    backgroundColorHex: ExcelColor.white,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    underline: Underline.None,
    leftBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.black),
    rightBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.black),
    topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.black),
    bottomBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.black),
  );

  /// Writes a value into a cell. When [_optPlusCellUpdates] is set, also records
  /// ref->value for value-only xlsx patch (to preserve template borders).
  static void _writeCell(Sheet sheet, String cellRef, int value) {
    _optPlusCellUpdates?[cellRef] = value;
    final cell = sheet.cell(CellIndex.indexByString(cellRef));
    final existingStyle = cell.cellStyle;
    cell.value = IntCellValue(value);
    cell.cellStyle = existingStyle ?? _borderedDataStyle;
  }

  /// Writes a string into a cell; records to [_optPlusCellUpdates] when set.
  static void _writeCellString(Sheet sheet, String cellRef, String value) {
    _optPlusCellUpdates?[cellRef] = value;
    final cell = sheet.cell(CellIndex.indexByString(cellRef));
    final existingStyle = cell.cellStyle;
    cell.value = TextCellValue(value);
    cell.cellStyle = existingStyle ?? _borderedDataStyle;
  }

  /// Patches the template xlsx by updating only cell values in the worksheet XML.
  /// Leaves styles.xml and all formatting (borders, etc.) unchanged.
  static Uint8List _patchXlsxCellValues(Uint8List templateBytes, Map<String, dynamic> updates) {
    if (updates.isEmpty) return templateBytes;

    final archive = ZipDecoder().decodeBytes(templateBytes);
    String? sheetPath;
    for (final file in archive.files) {
      if (file.name.startsWith('xl/worksheets/sheet') && file.name.endsWith('.xml')) {
        sheetPath = file.name;
        break;
      }
    }
    if (sheetPath == null) throw Exception('OPT Plus template: no worksheet found.');

    // Collect new strings and build ref -> shared string index for string updates
    final stringUpdates = <String, int>{};
    final newStrings = <String>[];
    for (final e in updates.entries) {
      if (e.value is String) {
        final s = e.value as String;
        if (!stringUpdates.containsKey(s)) {
          stringUpdates[s] = newStrings.length;
          newStrings.add(s);
        }
      }
    }

    // Update sharedStrings.xml if we have new strings
    int sharedStringIndexOffset = 0;
    if (newStrings.isNotEmpty) {
      final sharedStringsFile = archive.findFile('xl/sharedStrings.xml');
      if (sharedStringsFile != null) {
        final sstDoc = XmlDocument.parse(String.fromCharCodes(sharedStringsFile.content));
        final sst = sstDoc.rootElement;
        sharedStringIndexOffset = sst.findElements('si').length;
        for (final s in newStrings) {
          final escaped = s
              .replaceAll('&', '&amp;')
              .replaceAll('<', '&lt;')
              .replaceAll('>', '&gt;')
              .replaceAll('"', '&quot;')
              .replaceAll("'", '&apos;');
          final si = XmlElement(XmlName('si'), [], [XmlElement(XmlName('t'), [], [XmlText(escaped)])]);
          sst.children.add(si);
        }
        final count = sst.getAttribute('count');
        final newCount = (count != null ? int.tryParse(count) ?? 0 : sharedStringIndexOffset) + newStrings.length;
        sst.setAttribute('count', newCount.toString());
        sst.setAttribute('uniqueCount', newCount.toString());
        final newSstBytes = Uint8List.fromList(sstDoc.toXmlString(pretty: false, indent: '  ').codeUnits);
        archive.removeFile(sharedStringsFile);
        archive.addFile(ArchiveFile('xl/sharedStrings.xml', newSstBytes.length, newSstBytes));
      } else {
        // Template has no sharedStrings.xml; create one with only new strings
        final sb = StringBuffer();
        sb.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="${newStrings.length}" uniqueCount="${newStrings.length}">');
        for (final s in newStrings) {
          final escaped = s
              .replaceAll('&', '&amp;')
              .replaceAll('<', '&lt;')
              .replaceAll('>', '&gt;')
              .replaceAll('"', '&quot;')
              .replaceAll("'", '&apos;');
          sb.write('<si><t>$escaped</t></si>');
        }
        sb.write('</sst>');
        final newSstBytes = Uint8List.fromList(sb.toString().codeUnits);
        archive.addFile(ArchiveFile('xl/sharedStrings.xml', newSstBytes.length, newSstBytes));
      }
    }

    // Build ref -> shared string index (existing + new)
    final refToSharedIndex = <String, int>{};
    for (final e in updates.entries) {
      if (e.value is String) {
        final idx = stringUpdates[e.value as String]!;
        refToSharedIndex[e.key] = sharedStringIndexOffset + idx;
      }
    }

    // Update worksheet XML
    final sheetFile = archive.findFile(sheetPath);
    if (sheetFile == null) throw Exception('OPT Plus template: worksheet file not found.');
    final sheetDoc = XmlDocument.parse(String.fromCharCodes(sheetFile.content));

    for (final c in sheetDoc.findAllElements('c')) {
      final r = c.getAttribute('r');
      if (r == null || !updates.containsKey(r)) continue;
      final value = updates[r]!;
      final vEls = c.findElements('v').toList();
      final vNode = vEls.isNotEmpty ? vEls.first : null;
      if (value is int) {
        c.attributes.removeWhere((a) => a.name.local == 't');
        if (vNode != null) {
          vNode.children.clear();
          vNode.children.add(XmlText(value.toString()));
        } else {
          c.children.add(XmlElement(XmlName('v'), [], [XmlText(value.toString())]));
        }
      } else if (value is String) {
        final idx = refToSharedIndex[r]!;
        c.attributes.removeWhere((a) => a.name.local == 't');
        c.setAttribute('t', 's');
        if (vNode != null) {
          vNode.children.clear();
          vNode.children.add(XmlText(idx.toString()));
        } else {
          c.children.add(XmlElement(XmlName('v'), [], [XmlText(idx.toString())]));
        }
      }
    }

    final newSheetBytes = Uint8List.fromList(sheetDoc.toXmlString(pretty: false, indent: '  ').codeUnits);
    archive.removeFile(sheetFile);
    archive.addFile(ArchiveFile(sheetPath, newSheetBytes.length, newSheetBytes));

    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  /// Sum each indicator across all six age bands for 0–59 Months total (column T).
  static int _sumWfaNormal(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223, OptPlusBoys0to5Counts b2435, OptPlusBoys0to5Counts g2435, OptPlusBoys0to5Counts b3647, OptPlusBoys0to5Counts g3647, OptPlusBoys0to5Counts b4859, OptPlusBoys0to5Counts g4859) =>
      b05.wfaNormal + g05.wfaNormal + b611.wfaNormal + g611.wfaNormal + b1223.wfaNormal + g1223.wfaNormal + b2435.wfaNormal + g2435.wfaNormal + b3647.wfaNormal + g3647.wfaNormal + b4859.wfaNormal + g4859.wfaNormal;
  static int _sumWfaMuw(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223, OptPlusBoys0to5Counts b2435, OptPlusBoys0to5Counts g2435, OptPlusBoys0to5Counts b3647, OptPlusBoys0to5Counts g3647, OptPlusBoys0to5Counts b4859, OptPlusBoys0to5Counts g4859) =>
      b05.wfaMuw + g05.wfaMuw + b611.wfaMuw + g611.wfaMuw + b1223.wfaMuw + g1223.wfaMuw + b2435.wfaMuw + g2435.wfaMuw + b3647.wfaMuw + g3647.wfaMuw + b4859.wfaMuw + g4859.wfaMuw;
  static int _sumWfaSuw(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223, OptPlusBoys0to5Counts b2435, OptPlusBoys0to5Counts g2435, OptPlusBoys0to5Counts b3647, OptPlusBoys0to5Counts g3647, OptPlusBoys0to5Counts b4859, OptPlusBoys0to5Counts g4859) =>
      b05.wfaSuw + g05.wfaSuw + b611.wfaSuw + g611.wfaSuw + b1223.wfaSuw + g1223.wfaSuw + b2435.wfaSuw + g2435.wfaSuw + b3647.wfaSuw + g3647.wfaSuw + b4859.wfaSuw + g4859.wfaSuw;
  static int _sumHfaNormal(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223, OptPlusBoys0to5Counts b2435, OptPlusBoys0to5Counts g2435, OptPlusBoys0to5Counts b3647, OptPlusBoys0to5Counts g3647, OptPlusBoys0to5Counts b4859, OptPlusBoys0to5Counts g4859) =>
      b05.hfaNormal + g05.hfaNormal + b611.hfaNormal + g611.hfaNormal + b1223.hfaNormal + g1223.hfaNormal + b2435.hfaNormal + g2435.hfaNormal + b3647.hfaNormal + g3647.hfaNormal + b4859.hfaNormal + g4859.hfaNormal;
  static int _sumHfaTall(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223, OptPlusBoys0to5Counts b2435, OptPlusBoys0to5Counts g2435, OptPlusBoys0to5Counts b3647, OptPlusBoys0to5Counts g3647, OptPlusBoys0to5Counts b4859, OptPlusBoys0to5Counts g4859) =>
      b05.hfaTall + g05.hfaTall + b611.hfaTall + g611.hfaTall + b1223.hfaTall + g1223.hfaTall + b2435.hfaTall + g2435.hfaTall + b3647.hfaTall + g3647.hfaTall + b4859.hfaTall + g4859.hfaTall;
  static int _sumHfaMst(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223, OptPlusBoys0to5Counts b2435, OptPlusBoys0to5Counts g2435, OptPlusBoys0to5Counts b3647, OptPlusBoys0to5Counts g3647, OptPlusBoys0to5Counts b4859, OptPlusBoys0to5Counts g4859) =>
      b05.hfaMst + g05.hfaMst + b611.hfaMst + g611.hfaMst + b1223.hfaMst + g1223.hfaMst + b2435.hfaMst + g2435.hfaMst + b3647.hfaMst + g3647.hfaMst + b4859.hfaMst + g4859.hfaMst;
  static int _sumHfaSst(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223, OptPlusBoys0to5Counts b2435, OptPlusBoys0to5Counts g2435, OptPlusBoys0to5Counts b3647, OptPlusBoys0to5Counts g3647, OptPlusBoys0to5Counts b4859, OptPlusBoys0to5Counts g4859) =>
      b05.hfaSst + g05.hfaSst + b611.hfaSst + g611.hfaSst + b1223.hfaSst + g1223.hfaSst + b2435.hfaSst + g2435.hfaSst + b3647.hfaSst + g3647.hfaSst + b4859.hfaSst + g4859.hfaSst;
  static int _sumWflNormal(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223, OptPlusBoys0to5Counts b2435, OptPlusBoys0to5Counts g2435, OptPlusBoys0to5Counts b3647, OptPlusBoys0to5Counts g3647, OptPlusBoys0to5Counts b4859, OptPlusBoys0to5Counts g4859) =>
      b05.wflNormal + g05.wflNormal + b611.wflNormal + g611.wflNormal + b1223.wflNormal + g1223.wflNormal + b2435.wflNormal + g2435.wflNormal + b3647.wflNormal + g3647.wflNormal + b4859.wflNormal + g4859.wflNormal;
  static int _sumWflOw(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223, OptPlusBoys0to5Counts b2435, OptPlusBoys0to5Counts g2435, OptPlusBoys0to5Counts b3647, OptPlusBoys0to5Counts g3647, OptPlusBoys0to5Counts b4859, OptPlusBoys0to5Counts g4859) =>
      b05.wflOw + g05.wflOw + b611.wflOw + g611.wflOw + b1223.wflOw + g1223.wflOw + b2435.wflOw + g2435.wflOw + b3647.wflOw + g3647.wflOw + b4859.wflOw + g4859.wflOw;
  static int _sumWflOb(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223, OptPlusBoys0to5Counts b2435, OptPlusBoys0to5Counts g2435, OptPlusBoys0to5Counts b3647, OptPlusBoys0to5Counts g3647, OptPlusBoys0to5Counts b4859, OptPlusBoys0to5Counts g4859) =>
      b05.wflOb + g05.wflOb + b611.wflOb + g611.wflOb + b1223.wflOb + g1223.wflOb + b2435.wflOb + g2435.wflOb + b3647.wflOb + g3647.wflOb + b4859.wflOb + g4859.wflOb;
  static int _sumWflMwMam(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223, OptPlusBoys0to5Counts b2435, OptPlusBoys0to5Counts g2435, OptPlusBoys0to5Counts b3647, OptPlusBoys0to5Counts g3647, OptPlusBoys0to5Counts b4859, OptPlusBoys0to5Counts g4859) =>
      b05.wflMwMam + g05.wflMwMam + b611.wflMwMam + g611.wflMwMam + b1223.wflMwMam + g1223.wflMwMam + b2435.wflMwMam + g2435.wflMwMam + b3647.wflMwMam + g3647.wflMwMam + b4859.wflMwMam + g4859.wflMwMam;
  static int _sumWflSwSam(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223, OptPlusBoys0to5Counts b2435, OptPlusBoys0to5Counts g2435, OptPlusBoys0to5Counts b3647, OptPlusBoys0to5Counts g3647, OptPlusBoys0to5Counts b4859, OptPlusBoys0to5Counts g4859) =>
      b05.wflSwSam + g05.wflSwSam + b611.wflSwSam + g611.wflSwSam + b1223.wflSwSam + g1223.wflSwSam + b2435.wflSwSam + g2435.wflSwSam + b3647.wflSwSam + g3647.wflSwSam + b4859.wflSwSam + g4859.wflSwSam;
  static int _sumMuacNormal(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223, OptPlusBoys0to5Counts b2435, OptPlusBoys0to5Counts g2435, OptPlusBoys0to5Counts b3647, OptPlusBoys0to5Counts g3647, OptPlusBoys0to5Counts b4859, OptPlusBoys0to5Counts g4859) =>
      b05.muacNormal + g05.muacNormal + b611.muacNormal + g611.muacNormal + b1223.muacNormal + g1223.muacNormal + b2435.muacNormal + g2435.muacNormal + b3647.muacNormal + g3647.muacNormal + b4859.muacNormal + g4859.muacNormal;
  static int _sumMuacMwMam(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223, OptPlusBoys0to5Counts b2435, OptPlusBoys0to5Counts g2435, OptPlusBoys0to5Counts b3647, OptPlusBoys0to5Counts g3647, OptPlusBoys0to5Counts b4859, OptPlusBoys0to5Counts g4859) =>
      b05.muacMwMam + g05.muacMwMam + b611.muacMwMam + g611.muacMwMam + b1223.muacMwMam + g1223.muacMwMam + b2435.muacMwMam + g2435.muacMwMam + b3647.muacMwMam + g3647.muacMwMam + b4859.muacMwMam + g4859.muacMwMam;
  static int _sumMuacSwSam(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223, OptPlusBoys0to5Counts b2435, OptPlusBoys0to5Counts g2435, OptPlusBoys0to5Counts b3647, OptPlusBoys0to5Counts g3647, OptPlusBoys0to5Counts b4859, OptPlusBoys0to5Counts g4859) =>
      b05.muacSwSam + g05.muacSwSam + b611.muacSwSam + g611.muacSwSam + b1223.muacSwSam + g1223.muacSwSam + b2435.muacSwSam + g2435.muacSwSam + b3647.muacSwSam + g3647.muacSwSam + b4859.muacSwSam + g4859.muacSwSam;

  /// F1K 0–23 months: sum each indicator across first three age bands only (0–5, 6–11, 12–23).
  static int _sumF1kWfaNormal(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223) =>
      b05.wfaNormal + g05.wfaNormal + b611.wfaNormal + g611.wfaNormal + b1223.wfaNormal + g1223.wfaNormal;
  static int _sumF1kWfaMuw(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223) =>
      b05.wfaMuw + g05.wfaMuw + b611.wfaMuw + g611.wfaMuw + b1223.wfaMuw + g1223.wfaMuw;
  static int _sumF1kWfaSuw(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223) =>
      b05.wfaSuw + g05.wfaSuw + b611.wfaSuw + g611.wfaSuw + b1223.wfaSuw + g1223.wfaSuw;
  static int _sumF1kHfaNormal(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223) =>
      b05.hfaNormal + g05.hfaNormal + b611.hfaNormal + g611.hfaNormal + b1223.hfaNormal + g1223.hfaNormal;
  static int _sumF1kHfaTall(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223) =>
      b05.hfaTall + g05.hfaTall + b611.hfaTall + g611.hfaTall + b1223.hfaTall + g1223.hfaTall;
  static int _sumF1kHfaMst(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223) =>
      b05.hfaMst + g05.hfaMst + b611.hfaMst + g611.hfaMst + b1223.hfaMst + g1223.hfaMst;
  static int _sumF1kHfaSst(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223) =>
      b05.hfaSst + g05.hfaSst + b611.hfaSst + g611.hfaSst + b1223.hfaSst + g1223.hfaSst;
  static int _sumF1kWflNormal(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223) =>
      b05.wflNormal + g05.wflNormal + b611.wflNormal + g611.wflNormal + b1223.wflNormal + g1223.wflNormal;
  static int _sumF1kWflOw(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223) =>
      b05.wflOw + g05.wflOw + b611.wflOw + g611.wflOw + b1223.wflOw + g1223.wflOw;
  static int _sumF1kWflOb(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223) =>
      b05.wflOb + g05.wflOb + b611.wflOb + g611.wflOb + b1223.wflOb + g1223.wflOb;
  static int _sumF1kWflMwMam(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223) =>
      b05.wflMwMam + g05.wflMwMam + b611.wflMwMam + g611.wflMwMam + b1223.wflMwMam + g1223.wflMwMam;
  static int _sumF1kWflSwSam(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223) =>
      b05.wflSwSam + g05.wflSwSam + b611.wflSwSam + g611.wflSwSam + b1223.wflSwSam + g1223.wflSwSam;
  static int _sumF1kMuacNormal(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223) =>
      b05.muacNormal + g05.muacNormal + b611.muacNormal + g611.muacNormal + b1223.muacNormal + g1223.muacNormal;
  static int _sumF1kMuacMwMam(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223) =>
      b05.muacMwMam + g05.muacMwMam + b611.muacMwMam + g611.muacMwMam + b1223.muacMwMam + g1223.muacMwMam;
  static int _sumF1kMuacSwSam(OptPlusBoys0to5Counts b05, OptPlusBoys0to5Counts g05, OptPlusBoys0to5Counts b611, OptPlusBoys0to5Counts g611, OptPlusBoys0to5Counts b1223, OptPlusBoys0to5Counts g1223) =>
      b05.muacSwSam + g05.muacSwSam + b611.muacSwSam + g611.muacSwSam + b1223.muacSwSam + g1223.muacSwSam;

  /// Generate a filled Excel file based on the OPT Plus template.
  static Future<String> generateExcelFile() async {
    final summary = await buildSummary();
    final indicatorSummary = await buildIndicatorSummary();
    final boys0to5 = await buildBoys0to5Counts();
    final girls0to5 = await buildGirls0to5Counts();
    final boys6to11 = await buildBoys6to11Counts();
    final girls6to11 = await buildGirls6to11Counts();
    final boys12to23 = await buildBoys12to23Counts();
    final girls12to23 = await buildGirls12to23Counts();
    final boys24to35 = await buildBoys24to35Counts();
    final girls24to35 = await buildGirls24to35Counts();
    final boys36to47 = await buildBoys36to47Counts();
    final girls36to47 = await buildGirls36to47Counts();
    final boys48to59 = await buildBoys48to59Counts();
    final girls48to59 = await buildGirls48to59Counts();

    final data = await rootBundle.load('assets/opt_plus_template.xlsx');
    final bytes = data.buffer
        .asUint8List(data.offsetInBytes, data.lengthInBytes)
        .toList();

    final excel = Excel.decodeBytes(bytes);
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName]!;

    _optPlusCellUpdates = <String, dynamic>{};
    final barangayName = await FirestoreService().getCurrentUserBarangayName();
    _writeCellString(sheet, 'B9', barangayName.isEmpty ? '—' : barangayName);

    // Row 13: totals across all patients (all age bands)
    _writeCell(sheet, 'D13', summary.totalBoys);
    _writeCell(sheet, 'G13', summary.totalGirls);
    _writeCell(sheet, 'J13', _sumMuacNormal(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59) +
        _sumMuacMwMam(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59) +
        _sumMuacSwSam(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59));
    _writeCell(sheet, 'M13', _sumWfaNormal(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59) +
        _sumWfaMuw(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59) +
        _sumWfaSuw(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59));
    _writeCell(sheet, 'P13', _sumHfaNormal(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59) +
        _sumHfaTall(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59) +
        _sumHfaMst(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59) +
        _sumHfaSst(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59));
    _writeCell(sheet, 'S13', _sumWflNormal(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59) +
        _sumWflOw(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59) +
        _sumWflOb(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59) +
        _sumWflMwMam(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59) +
        _sumWflSwSam(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59));

    // 0–5 month boys (B)
    _writeCell(sheet, 'B16', boys0to5.wfaNormal);
    _writeCell(sheet, 'B19', boys0to5.wfaMuw);
    _writeCell(sheet, 'B20', boys0to5.wfaSuw);
    _writeCell(sheet, 'B21', boys0to5.hfaNormal);
    _writeCell(sheet, 'B22', boys0to5.hfaTall);
    _writeCell(sheet, 'B23', boys0to5.hfaMst);
    _writeCell(sheet, 'B24', boys0to5.hfaSst);
    _writeCell(sheet, 'B25', boys0to5.wflNormal);
    _writeCell(sheet, 'B26', boys0to5.wflOw);
    _writeCell(sheet, 'B27', boys0to5.wflOb);
    _writeCell(sheet, 'B28', boys0to5.wflMwMam);
    _writeCell(sheet, 'B29', boys0to5.wflSwSam);
    _writeCell(sheet, 'B30', boys0to5.muacNormal);
    _writeCell(sheet, 'B31', boys0to5.muacMwMam);
    _writeCell(sheet, 'B32', boys0to5.muacSwSam);

    // 0–5 month girls (C)
    _writeCell(sheet, 'C16', girls0to5.wfaNormal);
    _writeCell(sheet, 'C19', girls0to5.wfaMuw);
    _writeCell(sheet, 'C20', girls0to5.wfaSuw);
    _writeCell(sheet, 'C21', girls0to5.hfaNormal);
    _writeCell(sheet, 'C22', girls0to5.hfaTall);
    _writeCell(sheet, 'C23', girls0to5.hfaMst);
    _writeCell(sheet, 'C24', girls0to5.hfaSst);
    _writeCell(sheet, 'C25', girls0to5.wflNormal);
    _writeCell(sheet, 'C26', girls0to5.wflOw);
    _writeCell(sheet, 'C27', girls0to5.wflOb);
    _writeCell(sheet, 'C28', girls0to5.wflMwMam);
    _writeCell(sheet, 'C29', girls0to5.wflSwSam);
    _writeCell(sheet, 'C30', girls0to5.muacNormal);
    _writeCell(sheet, 'C31', girls0to5.muacMwMam);
    _writeCell(sheet, 'C32', girls0to5.muacSwSam);

    // 0–5 month total (D) = boys + girls
    _writeCell(sheet, 'D16', boys0to5.wfaNormal + girls0to5.wfaNormal);
    _writeCell(sheet, 'D19', boys0to5.wfaMuw + girls0to5.wfaMuw);
    _writeCell(sheet, 'D20', boys0to5.wfaSuw + girls0to5.wfaSuw);
    _writeCell(sheet, 'D21', boys0to5.hfaNormal + girls0to5.hfaNormal);
    _writeCell(sheet, 'D22', boys0to5.hfaTall + girls0to5.hfaTall);
    _writeCell(sheet, 'D23', boys0to5.hfaMst + girls0to5.hfaMst);
    _writeCell(sheet, 'D24', boys0to5.hfaSst + girls0to5.hfaSst);
    _writeCell(sheet, 'D25', boys0to5.wflNormal + girls0to5.wflNormal);
    _writeCell(sheet, 'D26', boys0to5.wflOw + girls0to5.wflOw);
    _writeCell(sheet, 'D27', boys0to5.wflOb + girls0to5.wflOb);
    _writeCell(sheet, 'D28', boys0to5.wflMwMam + girls0to5.wflMwMam);
    _writeCell(sheet, 'D29', boys0to5.wflSwSam + girls0to5.wflSwSam);
    _writeCell(sheet, 'D30', boys0to5.muacNormal + girls0to5.muacNormal);
    _writeCell(sheet, 'D31', boys0to5.muacMwMam + girls0to5.muacMwMam);
    _writeCell(sheet, 'D32', boys0to5.muacSwSam + girls0to5.muacSwSam);
    _writeCell(sheet, 'B33', boys0to5.wfaNormal + boys0to5.wfaMuw + boys0to5.wfaSuw);
    _writeCell(sheet, 'C33', girls0to5.wfaNormal + girls0to5.wfaMuw + girls0to5.wfaSuw);
    _writeCell(sheet, 'D33', boys0to5.wfaNormal + girls0to5.wfaNormal + boys0to5.wfaMuw + girls0to5.wfaMuw + boys0to5.wfaSuw + girls0to5.wfaSuw);

    // 6–11 month boys (E)
    _writeCell(sheet, 'E16', boys6to11.wfaNormal);
    _writeCell(sheet, 'E19', boys6to11.wfaMuw);
    _writeCell(sheet, 'E20', boys6to11.wfaSuw);
    _writeCell(sheet, 'E21', boys6to11.hfaNormal);
    _writeCell(sheet, 'E22', boys6to11.hfaTall);
    _writeCell(sheet, 'E23', boys6to11.hfaMst);
    _writeCell(sheet, 'E24', boys6to11.hfaSst);
    _writeCell(sheet, 'E25', boys6to11.wflNormal);
    _writeCell(sheet, 'E26', boys6to11.wflOw);
    _writeCell(sheet, 'E27', boys6to11.wflOb);
    _writeCell(sheet, 'E28', boys6to11.wflMwMam);
    _writeCell(sheet, 'E29', boys6to11.wflSwSam);
    _writeCell(sheet, 'E30', boys6to11.muacNormal);
    _writeCell(sheet, 'E31', boys6to11.muacMwMam);
    _writeCell(sheet, 'E32', boys6to11.muacSwSam);

    // 6–11 month girls (F)
    _writeCell(sheet, 'F16', girls6to11.wfaNormal);
    _writeCell(sheet, 'F19', girls6to11.wfaMuw);
    _writeCell(sheet, 'F20', girls6to11.wfaSuw);
    _writeCell(sheet, 'F21', girls6to11.hfaNormal);
    _writeCell(sheet, 'F22', girls6to11.hfaTall);
    _writeCell(sheet, 'F23', girls6to11.hfaMst);
    _writeCell(sheet, 'F24', girls6to11.hfaSst);
    _writeCell(sheet, 'F25', girls6to11.wflNormal);
    _writeCell(sheet, 'F26', girls6to11.wflOw);
    _writeCell(sheet, 'F27', girls6to11.wflOb);
    _writeCell(sheet, 'F28', girls6to11.wflMwMam);
    _writeCell(sheet, 'F29', girls6to11.wflSwSam);
    _writeCell(sheet, 'F30', girls6to11.muacNormal);
    _writeCell(sheet, 'F31', girls6to11.muacMwMam);
    _writeCell(sheet, 'F32', girls6to11.muacSwSam);

    // 6–11 month total (G) = boys + girls
    _writeCell(sheet, 'G16', boys6to11.wfaNormal + girls6to11.wfaNormal);
    _writeCell(sheet, 'G19', boys6to11.wfaMuw + girls6to11.wfaMuw);
    _writeCell(sheet, 'G20', boys6to11.wfaSuw + girls6to11.wfaSuw);
    _writeCell(sheet, 'G21', boys6to11.hfaNormal + girls6to11.hfaNormal);
    _writeCell(sheet, 'G22', boys6to11.hfaTall + girls6to11.hfaTall);
    _writeCell(sheet, 'G23', boys6to11.hfaMst + girls6to11.hfaMst);
    _writeCell(sheet, 'G24', boys6to11.hfaSst + girls6to11.hfaSst);
    _writeCell(sheet, 'G25', boys6to11.wflNormal + girls6to11.wflNormal);
    _writeCell(sheet, 'G26', boys6to11.wflOw + girls6to11.wflOw);
    _writeCell(sheet, 'G27', boys6to11.wflOb + girls6to11.wflOb);
    _writeCell(sheet, 'G28', boys6to11.wflMwMam + girls6to11.wflMwMam);
    _writeCell(sheet, 'G29', boys6to11.wflSwSam + girls6to11.wflSwSam);
    _writeCell(sheet, 'G30', boys6to11.muacNormal + girls6to11.muacNormal);
    _writeCell(sheet, 'G31', boys6to11.muacMwMam + girls6to11.muacMwMam);
    _writeCell(sheet, 'G32', boys6to11.muacSwSam + girls6to11.muacSwSam);
    _writeCell(sheet, 'E33', boys6to11.wfaNormal + boys6to11.wfaMuw + boys6to11.wfaSuw);
    _writeCell(sheet, 'F33', girls6to11.wfaNormal + girls6to11.wfaMuw + girls6to11.wfaSuw);
    _writeCell(sheet, 'G33', boys6to11.wfaNormal + girls6to11.wfaNormal + boys6to11.wfaMuw + girls6to11.wfaMuw + boys6to11.wfaSuw + girls6to11.wfaSuw);

    // 12–23 month boys (H)
    _writeCell(sheet, 'H16', boys12to23.wfaNormal);
    _writeCell(sheet, 'H19', boys12to23.wfaMuw);
    _writeCell(sheet, 'H20', boys12to23.wfaSuw);
    _writeCell(sheet, 'H21', boys12to23.hfaNormal);
    _writeCell(sheet, 'H22', boys12to23.hfaTall);
    _writeCell(sheet, 'H23', boys12to23.hfaMst);
    _writeCell(sheet, 'H24', boys12to23.hfaSst);
    _writeCell(sheet, 'H25', boys12to23.wflNormal);
    _writeCell(sheet, 'H26', boys12to23.wflOw);
    _writeCell(sheet, 'H27', boys12to23.wflOb);
    _writeCell(sheet, 'H28', boys12to23.wflMwMam);
    _writeCell(sheet, 'H29', boys12to23.wflSwSam);
    _writeCell(sheet, 'H30', boys12to23.muacNormal);
    _writeCell(sheet, 'H31', boys12to23.muacMwMam);
    _writeCell(sheet, 'H32', boys12to23.muacSwSam);

    // 12–23 month girls (I)
    _writeCell(sheet, 'I16', girls12to23.wfaNormal);
    _writeCell(sheet, 'I19', girls12to23.wfaMuw);
    _writeCell(sheet, 'I20', girls12to23.wfaSuw);
    _writeCell(sheet, 'I21', girls12to23.hfaNormal);
    _writeCell(sheet, 'I22', girls12to23.hfaTall);
    _writeCell(sheet, 'I23', girls12to23.hfaMst);
    _writeCell(sheet, 'I24', girls12to23.hfaSst);
    _writeCell(sheet, 'I25', girls12to23.wflNormal);
    _writeCell(sheet, 'I26', girls12to23.wflOw);
    _writeCell(sheet, 'I27', girls12to23.wflOb);
    _writeCell(sheet, 'I28', girls12to23.wflMwMam);
    _writeCell(sheet, 'I29', girls12to23.wflSwSam);
    _writeCell(sheet, 'I30', girls12to23.muacNormal);
    _writeCell(sheet, 'I31', girls12to23.muacMwMam);
    _writeCell(sheet, 'I32', girls12to23.muacSwSam);

    // 12–23 month total (J) = boys + girls
    _writeCell(sheet, 'J16', boys12to23.wfaNormal + girls12to23.wfaNormal);
    _writeCell(sheet, 'J19', boys12to23.wfaMuw + girls12to23.wfaMuw);
    _writeCell(sheet, 'J20', boys12to23.wfaSuw + girls12to23.wfaSuw);
    _writeCell(sheet, 'J21', boys12to23.hfaNormal + girls12to23.hfaNormal);
    _writeCell(sheet, 'J22', boys12to23.hfaTall + girls12to23.hfaTall);
    _writeCell(sheet, 'J23', boys12to23.hfaMst + girls12to23.hfaMst);
    _writeCell(sheet, 'J24', boys12to23.hfaSst + girls12to23.hfaSst);
    _writeCell(sheet, 'J25', boys12to23.wflNormal + girls12to23.wflNormal);
    _writeCell(sheet, 'J26', boys12to23.wflOw + girls12to23.wflOw);
    _writeCell(sheet, 'J27', boys12to23.wflOb + girls12to23.wflOb);
    _writeCell(sheet, 'J28', boys12to23.wflMwMam + girls12to23.wflMwMam);
    _writeCell(sheet, 'J29', boys12to23.wflSwSam + girls12to23.wflSwSam);
    _writeCell(sheet, 'J30', boys12to23.muacNormal + girls12to23.muacNormal);
    _writeCell(sheet, 'J31', boys12to23.muacMwMam + girls12to23.muacMwMam);
    _writeCell(sheet, 'J32', boys12to23.muacSwSam + girls12to23.muacSwSam);
    _writeCell(sheet, 'H33', boys12to23.wfaNormal + boys12to23.wfaMuw + boys12to23.wfaSuw);
    _writeCell(sheet, 'I33', girls12to23.wfaNormal + girls12to23.wfaMuw + girls12to23.wfaSuw);
    _writeCell(sheet, 'J33', boys12to23.wfaNormal + girls12to23.wfaNormal + boys12to23.wfaMuw + girls12to23.wfaMuw + boys12to23.wfaSuw + girls12to23.wfaSuw);

    // 24–35 month boys (K)
    _writeCell(sheet, 'K16', boys24to35.wfaNormal);
    _writeCell(sheet, 'K19', boys24to35.wfaMuw);
    _writeCell(sheet, 'K20', boys24to35.wfaSuw);
    _writeCell(sheet, 'K21', boys24to35.hfaNormal);
    _writeCell(sheet, 'K22', boys24to35.hfaTall);
    _writeCell(sheet, 'K23', boys24to35.hfaMst);
    _writeCell(sheet, 'K24', boys24to35.hfaSst);
    _writeCell(sheet, 'K25', boys24to35.wflNormal);
    _writeCell(sheet, 'K26', boys24to35.wflOw);
    _writeCell(sheet, 'K27', boys24to35.wflOb);
    _writeCell(sheet, 'K28', boys24to35.wflMwMam);
    _writeCell(sheet, 'K29', boys24to35.wflSwSam);
    _writeCell(sheet, 'K30', boys24to35.muacNormal);
    _writeCell(sheet, 'K31', boys24to35.muacMwMam);
    _writeCell(sheet, 'K32', boys24to35.muacSwSam);

    // 24–35 month girls (L)
    _writeCell(sheet, 'L16', girls24to35.wfaNormal);
    _writeCell(sheet, 'L19', girls24to35.wfaMuw);
    _writeCell(sheet, 'L20', girls24to35.wfaSuw);
    _writeCell(sheet, 'L21', girls24to35.hfaNormal);
    _writeCell(sheet, 'L22', girls24to35.hfaTall);
    _writeCell(sheet, 'L23', girls24to35.hfaMst);
    _writeCell(sheet, 'L24', girls24to35.hfaSst);
    _writeCell(sheet, 'L25', girls24to35.wflNormal);
    _writeCell(sheet, 'L26', girls24to35.wflOw);
    _writeCell(sheet, 'L27', girls24to35.wflOb);
    _writeCell(sheet, 'L28', girls24to35.wflMwMam);
    _writeCell(sheet, 'L29', girls24to35.wflSwSam);
    _writeCell(sheet, 'L30', girls24to35.muacNormal);
    _writeCell(sheet, 'L31', girls24to35.muacMwMam);
    _writeCell(sheet, 'L32', girls24to35.muacSwSam);

    // 24–35 month total (M) = boys + girls
    _writeCell(sheet, 'M16', boys24to35.wfaNormal + girls24to35.wfaNormal);
    _writeCell(sheet, 'M19', boys24to35.wfaMuw + girls24to35.wfaMuw);
    _writeCell(sheet, 'M20', boys24to35.wfaSuw + girls24to35.wfaSuw);
    _writeCell(sheet, 'M21', boys24to35.hfaNormal + girls24to35.hfaNormal);
    _writeCell(sheet, 'M22', boys24to35.hfaTall + girls24to35.hfaTall);
    _writeCell(sheet, 'M23', boys24to35.hfaMst + girls24to35.hfaMst);
    _writeCell(sheet, 'M24', boys24to35.hfaSst + girls24to35.hfaSst);
    _writeCell(sheet, 'M25', boys24to35.wflNormal + girls24to35.wflNormal);
    _writeCell(sheet, 'M26', boys24to35.wflOw + girls24to35.wflOw);
    _writeCell(sheet, 'M27', boys24to35.wflOb + girls24to35.wflOb);
    _writeCell(sheet, 'M28', boys24to35.wflMwMam + girls24to35.wflMwMam);
    _writeCell(sheet, 'M29', boys24to35.wflSwSam + girls24to35.wflSwSam);
    _writeCell(sheet, 'M30', boys24to35.muacNormal + girls24to35.muacNormal);
    _writeCell(sheet, 'M31', boys24to35.muacMwMam + girls24to35.muacMwMam);
    _writeCell(sheet, 'M32', boys24to35.muacSwSam + girls24to35.muacSwSam);
    _writeCell(sheet, 'K33', boys24to35.wfaNormal + boys24to35.wfaMuw + boys24to35.wfaSuw);
    _writeCell(sheet, 'L33', girls24to35.wfaNormal + girls24to35.wfaMuw + girls24to35.wfaSuw);
    _writeCell(sheet, 'M33', boys24to35.wfaNormal + girls24to35.wfaNormal + boys24to35.wfaMuw + girls24to35.wfaMuw + boys24to35.wfaSuw + girls24to35.wfaSuw);

    // 36–47 month boys (N)
    _writeCell(sheet, 'N16', boys36to47.wfaNormal);
    _writeCell(sheet, 'N19', boys36to47.wfaMuw);
    _writeCell(sheet, 'N20', boys36to47.wfaSuw);
    _writeCell(sheet, 'N21', boys36to47.hfaNormal);
    _writeCell(sheet, 'N22', boys36to47.hfaTall);
    _writeCell(sheet, 'N23', boys36to47.hfaMst);
    _writeCell(sheet, 'N24', boys36to47.hfaSst);
    _writeCell(sheet, 'N25', boys36to47.wflNormal);
    _writeCell(sheet, 'N26', boys36to47.wflOw);
    _writeCell(sheet, 'N27', boys36to47.wflOb);
    _writeCell(sheet, 'N28', boys36to47.wflMwMam);
    _writeCell(sheet, 'N29', boys36to47.wflSwSam);
    _writeCell(sheet, 'N30', boys36to47.muacNormal);
    _writeCell(sheet, 'N31', boys36to47.muacMwMam);
    _writeCell(sheet, 'N32', boys36to47.muacSwSam);

    // 36–47 month girls (O)
    _writeCell(sheet, 'O16', girls36to47.wfaNormal);
    _writeCell(sheet, 'O19', girls36to47.wfaMuw);
    _writeCell(sheet, 'O20', girls36to47.wfaSuw);
    _writeCell(sheet, 'O21', girls36to47.hfaNormal);
    _writeCell(sheet, 'O22', girls36to47.hfaTall);
    _writeCell(sheet, 'O23', girls36to47.hfaMst);
    _writeCell(sheet, 'O24', girls36to47.hfaSst);
    _writeCell(sheet, 'O25', girls36to47.wflNormal);
    _writeCell(sheet, 'O26', girls36to47.wflOw);
    _writeCell(sheet, 'O27', girls36to47.wflOb);
    _writeCell(sheet, 'O28', girls36to47.wflMwMam);
    _writeCell(sheet, 'O29', girls36to47.wflSwSam);
    _writeCell(sheet, 'O30', girls36to47.muacNormal);
    _writeCell(sheet, 'O31', girls36to47.muacMwMam);
    _writeCell(sheet, 'O32', girls36to47.muacSwSam);

    // 36–47 month total (P) = boys + girls
    _writeCell(sheet, 'P16', boys36to47.wfaNormal + girls36to47.wfaNormal);
    _writeCell(sheet, 'P19', boys36to47.wfaMuw + girls36to47.wfaMuw);
    _writeCell(sheet, 'P20', boys36to47.wfaSuw + girls36to47.wfaSuw);
    _writeCell(sheet, 'P21', boys36to47.hfaNormal + girls36to47.hfaNormal);
    _writeCell(sheet, 'P22', boys36to47.hfaTall + girls36to47.hfaTall);
    _writeCell(sheet, 'P23', boys36to47.hfaMst + girls36to47.hfaMst);
    _writeCell(sheet, 'P24', boys36to47.hfaSst + girls36to47.hfaSst);
    _writeCell(sheet, 'P25', boys36to47.wflNormal + girls36to47.wflNormal);
    _writeCell(sheet, 'P26', boys36to47.wflOw + girls36to47.wflOw);
    _writeCell(sheet, 'P27', boys36to47.wflOb + girls36to47.wflOb);
    _writeCell(sheet, 'P28', boys36to47.wflMwMam + girls36to47.wflMwMam);
    _writeCell(sheet, 'P29', boys36to47.wflSwSam + girls36to47.wflSwSam);
    _writeCell(sheet, 'P30', boys36to47.muacNormal + girls36to47.muacNormal);
    _writeCell(sheet, 'P31', boys36to47.muacMwMam + girls36to47.muacMwMam);
    _writeCell(sheet, 'P32', boys36to47.muacSwSam + girls36to47.muacSwSam);
    _writeCell(sheet, 'N33', boys36to47.wfaNormal + boys36to47.wfaMuw + boys36to47.wfaSuw);
    _writeCell(sheet, 'O33', girls36to47.wfaNormal + girls36to47.wfaMuw + girls36to47.wfaSuw);
    _writeCell(sheet, 'P33', boys36to47.wfaNormal + girls36to47.wfaNormal + boys36to47.wfaMuw + girls36to47.wfaMuw + boys36to47.wfaSuw + girls36to47.wfaSuw);

    // 48–59 month boys (Q)
    _writeCell(sheet, 'Q16', boys48to59.wfaNormal);
    _writeCell(sheet, 'Q19', boys48to59.wfaMuw);
    _writeCell(sheet, 'Q20', boys48to59.wfaSuw);
    _writeCell(sheet, 'Q21', boys48to59.hfaNormal);
    _writeCell(sheet, 'Q22', boys48to59.hfaTall);
    _writeCell(sheet, 'Q23', boys48to59.hfaMst);
    _writeCell(sheet, 'Q24', boys48to59.hfaSst);
    _writeCell(sheet, 'Q25', boys48to59.wflNormal);
    _writeCell(sheet, 'Q26', boys48to59.wflOw);
    _writeCell(sheet, 'Q27', boys48to59.wflOb);
    _writeCell(sheet, 'Q28', boys48to59.wflMwMam);
    _writeCell(sheet, 'Q29', boys48to59.wflSwSam);
    _writeCell(sheet, 'Q30', boys48to59.muacNormal);
    _writeCell(sheet, 'Q31', boys48to59.muacMwMam);
    _writeCell(sheet, 'Q32', boys48to59.muacSwSam);

    // 48–59 month girls (R)
    _writeCell(sheet, 'R16', girls48to59.wfaNormal);
    _writeCell(sheet, 'R19', girls48to59.wfaMuw);
    _writeCell(sheet, 'R20', girls48to59.wfaSuw);
    _writeCell(sheet, 'R21', girls48to59.hfaNormal);
    _writeCell(sheet, 'R22', girls48to59.hfaTall);
    _writeCell(sheet, 'R23', girls48to59.hfaMst);
    _writeCell(sheet, 'R24', girls48to59.hfaSst);
    _writeCell(sheet, 'R25', girls48to59.wflNormal);
    _writeCell(sheet, 'R26', girls48to59.wflOw);
    _writeCell(sheet, 'R27', girls48to59.wflOb);
    _writeCell(sheet, 'R28', girls48to59.wflMwMam);
    _writeCell(sheet, 'R29', girls48to59.wflSwSam);
    _writeCell(sheet, 'R30', girls48to59.muacNormal);
    _writeCell(sheet, 'R31', girls48to59.muacMwMam);
    _writeCell(sheet, 'R32', girls48to59.muacSwSam);

    // 48–59 month total (S) = boys + girls
    _writeCell(sheet, 'S16', boys48to59.wfaNormal + girls48to59.wfaNormal);
    _writeCell(sheet, 'S19', boys48to59.wfaMuw + girls48to59.wfaMuw);
    _writeCell(sheet, 'S20', boys48to59.wfaSuw + girls48to59.wfaSuw);
    _writeCell(sheet, 'S21', boys48to59.hfaNormal + girls48to59.hfaNormal);
    _writeCell(sheet, 'S22', boys48to59.hfaTall + girls48to59.hfaTall);
    _writeCell(sheet, 'S23', boys48to59.hfaMst + girls48to59.hfaMst);
    _writeCell(sheet, 'S24', boys48to59.hfaSst + girls48to59.hfaSst);
    _writeCell(sheet, 'S25', boys48to59.wflNormal + girls48to59.wflNormal);
    _writeCell(sheet, 'S26', boys48to59.wflOw + girls48to59.wflOw);
    _writeCell(sheet, 'S27', boys48to59.wflOb + girls48to59.wflOb);
    _writeCell(sheet, 'S28', boys48to59.wflMwMam + girls48to59.wflMwMam);
    _writeCell(sheet, 'S29', boys48to59.wflSwSam + girls48to59.wflSwSam);
    _writeCell(sheet, 'S30', boys48to59.muacNormal + girls48to59.muacNormal);
    _writeCell(sheet, 'S31', boys48to59.muacMwMam + girls48to59.muacMwMam);
    _writeCell(sheet, 'S32', boys48to59.muacSwSam + girls48to59.muacSwSam);
    _writeCell(sheet, 'Q33', boys48to59.wfaNormal + boys48to59.wfaMuw + boys48to59.wfaSuw);
    _writeCell(sheet, 'R33', girls48to59.wfaNormal + girls48to59.wfaMuw + girls48to59.wfaSuw);
    _writeCell(sheet, 'S33', boys48to59.wfaNormal + girls48to59.wfaNormal + boys48to59.wfaMuw + girls48to59.wfaMuw + boys48to59.wfaSuw + girls48to59.wfaSuw);

    // 0–59 Months: Total column only, starting at T16
    _writeCell(sheet, 'T16', _sumWfaNormal(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59));
    _writeCell(sheet, 'T19', _sumWfaMuw(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59));
    _writeCell(sheet, 'T20', _sumWfaSuw(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59));
    _writeCell(sheet, 'T21', _sumHfaNormal(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59));
    _writeCell(sheet, 'T22', _sumHfaTall(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59));
    _writeCell(sheet, 'T23', _sumHfaMst(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59));
    _writeCell(sheet, 'T24', _sumHfaSst(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59));
    _writeCell(sheet, 'T25', _sumWflNormal(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59));
    _writeCell(sheet, 'T26', _sumWflOw(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59));
    _writeCell(sheet, 'T27', _sumWflOb(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59));
    _writeCell(sheet, 'T28', _sumWflMwMam(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59));
    _writeCell(sheet, 'T29', _sumWflSwSam(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59));
    _writeCell(sheet, 'T30', _sumMuacNormal(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59));
    _writeCell(sheet, 'T31', _sumMuacMwMam(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59));
    _writeCell(sheet, 'T32', _sumMuacSwSam(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23, boys24to35, girls24to35, boys36to47, girls36to47, boys48to59, girls48to59));
    // F1K 0–23 months total (V16:V32)
    _writeCell(sheet, 'V16', _sumF1kWfaNormal(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23));
    _writeCell(sheet, 'V19', _sumF1kWfaMuw(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23));
    _writeCell(sheet, 'V20', _sumF1kWfaSuw(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23));
    _writeCell(sheet, 'V21', _sumF1kHfaNormal(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23));
    _writeCell(sheet, 'V22', _sumF1kHfaTall(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23));
    _writeCell(sheet, 'V23', _sumF1kHfaMst(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23));
    _writeCell(sheet, 'V24', _sumF1kHfaSst(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23));
    _writeCell(sheet, 'V25', _sumF1kWflNormal(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23));
    _writeCell(sheet, 'V26', _sumF1kWflOw(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23));
    _writeCell(sheet, 'V27', _sumF1kWflOb(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23));
    _writeCell(sheet, 'V28', _sumF1kWflMwMam(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23));
    _writeCell(sheet, 'V29', _sumF1kWflSwSam(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23));
    _writeCell(sheet, 'V30', _sumF1kMuacNormal(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23));
    _writeCell(sheet, 'V31', _sumF1kMuacMwMam(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23));
    _writeCell(sheet, 'V32', _sumF1kMuacSwSam(boys0to5, girls0to5, boys6to11, girls6to11, boys12to23, girls12to23));

    // H35–H42: indicator summary (Wasted/Stunted, OW/Ob, age-band totals)
    _writeCell(sheet, 'H35', indicatorSummary.countWastedOrStunted0to59);
    _writeCell(sheet, 'H36', indicatorSummary.countWastedOrStunted0to59);
    _writeCell(sheet, 'H37', indicatorSummary.countOverweightObese0to59);
    _writeCell(sheet, 'H38', indicatorSummary.totalChildren0to23);
    _writeCell(sheet, 'H39', indicatorSummary.countWastedOrStunted0to23);
    _writeCell(sheet, 'H40', indicatorSummary.totalChildren0to29);
    _writeCell(sheet, 'H41', indicatorSummary.totalChildren30to59);
    _writeCell(sheet, 'H42', indicatorSummary.totalChildren24to59);

    // Patch template with only cell value changes so template borders/formatting are preserved
    final templateBytes = Uint8List.fromList(bytes);
    final patchedBytes = _patchXlsxCellValues(templateBytes, _optPlusCellUpdates!);
    _optPlusCellUpdates = null;

    final dir = await getTemporaryDirectory();
    final filePath = p.join(
      dir.path,
      'opt_plus_summary_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );

    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsBytes(patchedBytes, flush: true);

    return filePath;
  }
}

class OptPlusBoys0to5CountsBuilder {
  int wfaNormal = 0, wfaMuw = 0, wfaSuw = 0;
  int hfaNormal = 0, hfaTall = 0, hfaMst = 0, hfaSst = 0;
  int wflNormal = 0, wflOw = 0, wflOb = 0, wflMwMam = 0, wflSwSam = 0;
  int muacNormal = 0, muacMwMam = 0, muacSwSam = 0;

  OptPlusBoys0to5Counts build() => OptPlusBoys0to5Counts(
    wfaNormal: wfaNormal, wfaMuw: wfaMuw, wfaSuw: wfaSuw,
    hfaNormal: hfaNormal, hfaTall: hfaTall, hfaMst: hfaMst, hfaSst: hfaSst,
    wflNormal: wflNormal, wflOw: wflOw, wflOb: wflOb,
    wflMwMam: wflMwMam, wflSwSam: wflSwSam,
    muacNormal: muacNormal, muacMwMam: muacMwMam, muacSwSam: muacSwSam,
  );
}

