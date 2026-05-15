import 'package:cloud_firestore/cloud_firestore.dart';

/// Malnutrition-related flags derived from anthropometric z-scores and text.
class NutritionFlags {
  final bool stunting;
  final bool wasting;
  final bool underweight;
  final bool overweight;
  final bool obese;
  final bool severe;
  final bool atRisk;
  final bool hasAnthroData;

  const NutritionFlags({
    required this.stunting,
    required this.wasting,
    required this.underweight,
    required this.overweight,
    required this.obese,
    required this.severe,
    required this.atRisk,
    required this.hasAnthroData,
  });

  bool get normal =>
      hasAnthroData &&
      !stunting &&
      !wasting &&
      !underweight &&
      !overweight &&
      !obese &&
      !severe &&
      !atRisk;

  bool matchesCategory(NutritionCategory category) {
    switch (category) {
      case NutritionCategory.stunting:
        return stunting;
      case NutritionCategory.wasting:
        return wasting;
      case NutritionCategory.underweight:
        return underweight;
      case NutritionCategory.overweight:
        return overweight && !obese;
      case NutritionCategory.obese:
        return obese;
      case NutritionCategory.severeCases:
        return severe;
      case NutritionCategory.atRisk:
        return atRisk;
      case NutritionCategory.normal:
        return normal;
    }
  }
}

enum NutritionCategory {
  stunting,
  wasting,
  underweight,
  overweight,
  obese,
  severeCases,
  atRisk,
  normal,
}

extension NutritionCategoryLabel on NutritionCategory {
  String get label {
    switch (this) {
      case NutritionCategory.stunting:
        return 'Stunting';
      case NutritionCategory.wasting:
        return 'Wasting';
      case NutritionCategory.underweight:
        return 'Underweight';
      case NutritionCategory.overweight:
        return 'Overweight';
      case NutritionCategory.obese:
        return 'Obese';
      case NutritionCategory.severeCases:
        return 'Severe cases';
      case NutritionCategory.atRisk:
        return 'At risk';
      case NutritionCategory.normal:
        return 'Normal';
    }
  }
}

/// WHO-style z-score parsing and classification aligned with [FirestoreService.getStatusCounts].
class NutritionStatusClassifier {
  NutritionStatusClassifier._();

  static double? extractZScore(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final match = RegExp(r'^-?\d+(\.\d+)?').firstMatch(raw.trim());
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  static double? extractBmiZScore(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final trimmed = raw.trim();
    if (!trimmed.contains('|')) return null;
    final parts = trimmed.split('|');
    if (parts.length < 2) return null;
    final afterPipe = parts[1].trim();
    final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(afterPipe);
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  /// Lowercased interpretation substrings from stored anthropometric strings.
  static void _stringSignals(
    Map<String, dynamic>? anthropometric,
    void Function(String combined) emit,
  ) {
    if (anthropometric == null) return;
    final wfa = (anthropometric['weightForAge'] as String? ?? '').toLowerCase();
    final hfa = (anthropometric['heightForAge'] as String? ?? '').toLowerCase();
    final wfh =
        (anthropometric['weightForHeight'] as String? ?? '').toLowerCase();
    final bmi = (anthropometric['bmi'] as String? ?? '').toLowerCase();
    emit('$wfa $hfa $wfh $bmi');
  }

  static NutritionFlags classify(Map<String, dynamic> patientOrRecordData) {
    final rawAnthro = patientOrRecordData['anthropometric'];
    final anthropometric = _asStringKeyedMap(rawAnthro);

    if (anthropometric == null) {
      return const NutritionFlags(
        stunting: false,
        wasting: false,
        underweight: false,
        overweight: false,
        obese: false,
        severe: false,
        atRisk: false,
        hasAnthroData: false,
      );
    }

    final wfa = extractZScore(anthropometric['weightForAge']?.toString());
    final hfa = extractZScore(anthropometric['heightForAge']?.toString());
    final wfh = extractZScore(anthropometric['weightForHeight']?.toString());
    final bmi = extractBmiZScore(anthropometric['bmi']?.toString());

    var stunting = hfa != null && hfa < -2;
    var wasting = wfh != null && wfh < -2;
    var underweight = wfa != null && wfa < -2;
    var obese = (wfh != null && wfh > 2) || (bmi != null && bmi > 2);
    var overweight = ((wfh != null && wfh > 1 && wfh <= 2) ||
            (bmi != null && bmi > 1 && bmi <= 2)) &&
        !obese;
    var severe = (wfa != null && wfa <= -3) ||
        (hfa != null && hfa <= -3) ||
        (wfh != null && wfh <= -3) ||
        (bmi != null && bmi <= -3);
    var atRisk = (wfa != null && wfa >= -2 && wfa < -1) ||
        (hfa != null && hfa >= -2 && hfa < -1) ||
        (wfh != null && wfh >= -2 && wfh < -1) ||
        (bmi != null && bmi >= -2 && bmi < -1);

    final hasZ = wfa != null || hfa != null || wfh != null || bmi != null;

    _stringSignals(anthropometric, (s) {
      if (s.contains('severe')) severe = true;
      if (s.contains('stunt')) stunting = stunting || s.contains('stunt');
      if (s.contains('wast')) wasting = wasting || s.contains('wast');
      if (s.contains('underweight') || s.contains('under weight')) {
        underweight = true;
      }
      if (s.contains('obese')) {
        obese = true;
      } else if (s.contains('overweight')) {
        overweight = true;
      }
      if (s.contains('at risk') || s.contains('at-risk')) atRisk = true;
    });

    final hasAnthroData = hasZ ||
        anthropometric.values.any((v) => v != null && '$v'.trim().isNotEmpty);

    if (obese) overweight = false;

    return NutritionFlags(
      stunting: stunting,
      wasting: wasting,
      underweight: underweight,
      overweight: overweight,
      obese: obese,
      severe: severe,
      atRisk: atRisk,
      hasAnthroData: hasAnthroData,
    );
  }

  /// Normalizes sex for filtering: `male`, `female`, or null if unknown.
  static String? normalizeSex(Map<String, dynamic>? demographic) {
    if (demographic == null) return null;
    final s = (demographic['sex'] ?? '').toString().trim().toLowerCase();
    if (s.isEmpty) return null;
    if (s.startsWith('m') || s == 'male' || s == 'lalaki') return 'male';
    if (s.startsWith('f') || s == 'female' || s == 'babae') return 'female';
    return null;
  }

  static DateTime? patientCreatedAt(Map<String, dynamic> data) {
    final ts = data['createdAt'];
    if (ts is Timestamp) return ts.toDate();
    if (ts is DateTime) return ts;
    if (ts is String) return DateTime.tryParse(ts);
    return null;
  }
}
