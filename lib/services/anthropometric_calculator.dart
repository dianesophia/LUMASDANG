import 'package:growth_standards/growth_standards.dart';

/// WHO z-score interpretation (widely used in the Philippines and internationally).
/// Results are formatted as "z-score (interpretation)".
/// Weight-for-length: 0–2 yrs | Weight-for-height: 2–5 yrs
class AnthropometricCalculator {
  static final _gs = GrowthStandard.who.fromBirthTo5Years;

  /// Parse age in months from various input formats.
  /// Supports: "2", "24", "2 years", "24 months", "1.5", "18 months"
  static int? _parseAgeInMonths(String ageStr, String? dobStr, String? measurementDateStr) {
    if (ageStr.trim().isEmpty && (dobStr == null || dobStr.trim().isEmpty)) return null;
    final age = ageStr.trim().toLowerCase();
    if (age.isNotEmpty) {
      final numMatch = RegExp(r'[\d.]+').firstMatch(age);
      if (numMatch != null) {
        final num = double.tryParse(numMatch.group(0)!);
        if (num != null) {
          if (age.contains('month')) return num.round();
          if (age.contains('year') || age.contains('yr')) return (num * 12).round();
          if (num >= 0 && num < 20) return (num * 12).round(); // assume years if small
          if (num >= 24 && num <= 60) return num.round(); // months
          return num.round();
        }
      }
    }
    if (dobStr != null && dobStr.trim().isNotEmpty && measurementDateStr != null && measurementDateStr.trim().isNotEmpty) {
      final dob = _parseDate(dobStr);
      final meas = _parseDate(measurementDateStr);
      if (dob != null && meas != null) {
        final months = (meas.year - dob.year) * 12 + (meas.month - dob.month);
        return months >= 0 ? months : null;
      }
    }
    return null;
  }

  static ({int year, int month, int day})? _parseDate(String s) {
    final parts = s.trim().split(RegExp(r'[/\-.,\s]+'));
    if (parts.length >= 2) {
      final vals = parts.map((e) => int.tryParse(e)).toList();
      if (vals.length >= 2 && vals[0] != null && vals[1] != null) {
        int y = vals[0]!;
        int m = vals[1]!.clamp(1, 12);
        int d = vals.length >= 3 && vals[2] != null ? vals[2]!.clamp(1, 31) : 1;
        if (y < 100) y += 2000;
        return (year: y, month: m, day: d);
      }
    }
    return null;
  }

  static Sex? _parseSex(String sexStr) {
    final s = sexStr.trim().toLowerCase();
    if (s.isEmpty) return null;
    if (s.startsWith('m') || s == 'male' || s == 'lalaki') return Sex.male;
    if (s.startsWith('f') || s == 'female' || s == 'babae') return Sex.female;
    return null;
  }

  /// Returns z-score interpretation string per WHO standards.
  static String _interpretZScore(double? z, {required String type}) {
    if (z == null) return '—';
    if (z < -3) {
      switch (type) {
        case 'wfa': return 'Severely underweight';
        case 'hfa': return 'Severely stunted';
        case 'wfh': return 'Severe wasting';
        case 'bmi': return 'Severely underweight';
        default: return 'Severe';
      }
    }
    if (z < -2) {
      switch (type) {
        case 'wfa': return 'Underweight';
        case 'hfa': return 'Stunted';
        case 'wfh': return 'Wasted';
        case 'bmi': return 'Underweight';
        default: return 'Moderate';
      }
    }
    if (z <= 1) return 'Normal';
    if (z <= 2) return 'At risk of overweight';
    if (z <= 3) return 'Overweight';
    return 'Obese';
  }

  /// Compute anthropometric results. Returns null if inputs are insufficient.
  static AnthropometricResult? calculate({
    required String weightStr,
    required String heightStr,
    required String ageStr,
    required String sexStr,
    String? dobStr,
    String? measurementDateStr,
  }) {
    final weight = double.tryParse(weightStr.trim());
    final height = double.tryParse(heightStr.trim());
    final ageMonths = _parseAgeInMonths(ageStr, dobStr, measurementDateStr);
    final sex = _parseSex(sexStr);

    if (weight == null || weight <= 0 || height == null || height <= 0 ||
        ageMonths == null || ageMonths < 0 || sex == null) {
      return null;
    }

    try {
      final age = Age.byMonthsAgo(ageMonths);
      final kg = Mass$Kilogram(weight);
      final cm = Length$Centimeter(height);
      final measure = ageMonths < 24
          ? LengthHeightMeasurementPosition.recumbent
          : LengthHeightMeasurementPosition.standing;

      double? wfaZ;
      double? hfaZ;
      double? wfhZ;
      double? bmiZ;

      try {
        final wfa = _gs.weightForAge(age: age, weight: kg, sex: sex);
        wfaZ = wfa.zScore(Precision.two).toDouble();
      } catch (_) {}

      try {
        final hfa = _gs.lengthForAge(
          age: age,
          lengthHeight: cm,
          sex: sex,
          measure: measure,
        );
        hfaZ = hfa.zScore(Precision.two).toDouble();
      } catch (_) {}

      try {
        if (ageMonths < 24) {
          final wfh = _gs.weightForLength(
            lengthMeasurementResult: cm,
            massMeasurementResult: kg,
            sex: sex,
            age: age,
            measure: measure,
          );
          wfhZ = wfh.zScore(Precision.two).toDouble();
        } else {
          final wfh = _gs.weightForHeight(
            height: cm,
            mass: kg,
            age: age,
            sex: sex,
            measure: measure,
          );
          wfhZ = wfh.zScore(Precision.two).toDouble();
        }
      } catch (_) {}

      try {
        final bmiCalc = _gs.bodyMassIndexForAge(
          bodyMassIndexMeasurement: WHOGrowthStandardsBodyMassIndexMeasurement.fromMeasurement(
            measure: measure,
            lengthHeight: cm,
            weight: kg,
            age: age,
          ),
          sex: sex,
        );
        bmiZ = bmiCalc.zScore(Precision.two).toDouble();
      } catch (_) {}

      final bmiValue = weight / ((height / 100) * (height / 100));

      return AnthropometricResult(
        weightForAge: wfaZ != null ? '${wfaZ.toStringAsFixed(2)} (${_interpretZScore(wfaZ, type: 'wfa')})' : null,
        weightForHeight: wfhZ != null ? '${wfhZ.toStringAsFixed(2)} (${_interpretZScore(wfhZ, type: 'wfh')})' : null,
        heightForAge: hfaZ != null ? '${hfaZ.toStringAsFixed(2)} (${_interpretZScore(hfaZ, type: 'hfa')})' : null,
        bmi: bmiZ != null ? '${bmiValue.toStringAsFixed(1)} | ${bmiZ.toStringAsFixed(2)} (${_interpretZScore(bmiZ, type: 'bmi')})' : bmiValue.toStringAsFixed(1),
      );
    } catch (_) {
      return null;
    }
  }
}

class AnthropometricResult {
  final String? weightForAge;
  final String? weightForHeight;
  final String? heightForAge;
  final String? bmi;

  AnthropometricResult({
    this.weightForAge,
    this.weightForHeight,
    this.heightForAge,
    this.bmi,
  });
}
