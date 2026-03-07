/*import 'package:flutter/foundation.dart';
import 'package:growth_standards/growth_standards.dart';

/// WHO z-score interpretation (widely used in the Philippines and internationally).
/// Results are formatted as "z-score (interpretation)".
/// Weight-for-length: 0–2 yrs | Weight-for-height: 2–5 yrs
class AnthropometricCalculator {
  static final _gs = GrowthStandard.who.fromBirthTo5Years;

  /// Parse age in months.
  ///
  /// New convention (Feb 2026):
  /// - Plain numbers (e.g. "18") are treated as **months**
  /// - Strings with "year"/"yr" are converted to months
  /// - Strings with "month" are treated as months
  /// - When `dobStr` and `measurementDateStr` are both available, we
  ///   prefer an exact month difference from those dates.
  static int? _parseAgeInMonths(String ageStr, String? dobStr, String? measurementDateStr) {
    // Prefer DOB + measurement date when available (exact calculation)
    if (dobStr != null &&
        dobStr.trim().isNotEmpty &&
        measurementDateStr != null &&
        measurementDateStr.trim().isNotEmpty) {
      final dob = _parseDate(dobStr);
      final meas = _parseDate(measurementDateStr);
      if (dob != null && meas != null) {
        final months = (meas.year - dob.year) * 12 + (meas.month - dob.month);
        if (months >= 0) return months;
      }
    }

    if (ageStr.trim().isEmpty) return null;
    final age = ageStr.trim().toLowerCase();
    if (age.isNotEmpty) {
      final numMatch = RegExp(r'[\d.]+').firstMatch(age);
      if (numMatch != null) {
        final num = double.tryParse(numMatch.group(0)!);
        if (num != null) {
          if (age.contains('month')) {
            return num.round();
          }
          if (age.contains('year') || age.contains('yr')) {
            // explicit years → convert to months
            return (num * 12).round();
          }
          // Plain numeric input is now interpreted as **months**
          // (e.g. "18" → 18 months)
          if (num >= 0) {
            return num.round();
          }
        }
      }
    }
    return null;
  }

  static ({int year, int month, int day})? _parseDate(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return null;

    // Detect explicit YYYY-... pattern and parse as YYYY-MM-DD
    final isoLike = RegExp(r'^\d{4}[-/]').hasMatch(trimmed);

    final parts = trimmed.split(RegExp(r'[/\-.,\s]+'));
    if (parts.length >= 2) {
      final vals = parts.map((e) => int.tryParse(e)).toList();
      if (vals.length >= 3 && vals[0] != null && vals[1] != null && vals[2] != null) {
        int y;
        int m;
        int d;

        if (isoLike) {
          // YYYY-MM-DD
          y = vals[0]!;
          m = vals[1]!.clamp(1, 12);
          d = vals[2]!.clamp(1, 31);
        } else {
          // Default to MM-DD-YYYY for user-entered dates
          m = vals[0]!.clamp(1, 12);
          d = vals[1]!.clamp(1, 31);
          y = vals[2]!;
        }

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
      debugPrint(
        '[Lumasdang] AnthropometricCalculator returned null (inputs invalid or insufficient). '
        'weight=$weightStr→$weight height=$heightStr→$height ageMonths=$ageMonths sex=$sexStr→$sex '
        'dobStr=$dobStr measurementDateStr=$measurementDateStr',
      );
      return null;
    }

    try {
      // Pass observedDate (measurement date) when available for accurate age at measurement
      final Age age;
      final meas = _parseDate(measurementDateStr ?? '');
      if (meas != null) {
        final measDate = Date.fromDateTime(DateTime(meas.year, meas.month, meas.day));
        age = Age.byMonthsAgo(ageMonths, observedDate: measDate);
      } else {
        age = Age.byMonthsAgo(ageMonths);
      }
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
        // Weight-for-length: 0-2 yrs (length 45-110 cm) | Weight-for-height: 2-5 yrs (height 65-120 cm)
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
      } catch (e, st) {
        debugPrint(
          '[Lumasdang] Weight for Length/Height (Lt/Ht) calculation failed. '
          'ageMonths=$ageMonths height=${height}cm (${ageMonths < 24 ? "length" : "height"}). '
          'WHO: 0–2y length 45–110cm, 2–5y height 65–120cm. Error: $e',
        );
        if (kDebugMode) debugPrint('$st');
      }

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
    } catch (e, st) {
      debugPrint('[Lumasdang] AnthropometricCalculator failed (outer catch): $e');
      if (kDebugMode) debugPrint('$st');
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
*/

import 'package:flutter/foundation.dart';
import 'dart:math' as math;

/// WHO z-score calculator using LMS method — no external packages.
/// Works on both mobile AND web.
/// Replaces growth_standards (which uses dart_numerics 0.0.6, incompatible with web).
///
/// LMS method: Z = [(X/M)^L - 1] / (S * L)
/// Source: WHO Child Growth Standards (0–5 years)
class AnthropometricCalculator {

  // ── WHO LMS Tables ──────────────────────────────────────────────────────────
  // Format: ageMonths -> [L, M, S]

  static const _wfaBoys = <int, List<double>>{
    0: [-0.3521, 3.3464, 0.14602], 1: [-0.3521, 4.4709, 0.13395],
    2: [-0.3521, 5.5675, 0.12385], 3: [-0.3521, 6.3762, 0.11727],
    4: [-0.3521, 7.0023, 0.11316], 5: [-0.3521, 7.5105, 0.10998],
    6: [-0.3521, 7.9340, 0.10762], 7: [-0.3521, 8.2970, 0.10576],
    8: [-0.3521, 8.6151, 0.10420], 9: [-0.3521, 8.9014, 0.10280],
    10: [-0.3521, 9.1649, 0.10145], 11: [-0.3521, 9.4122, 0.10011],
    12: [-0.3521, 9.6479, 0.09877], 15: [-0.3521, 10.3108, 0.09466],
    18: [-0.3521, 10.9385, 0.09051], 21: [-0.3521, 11.5428, 0.08659],
    24: [-0.3521, 12.1236, 0.08304], 27: [-0.3521, 12.7087, 0.07991],
    30: [-0.3521, 13.3141, 0.07724], 33: [-0.3521, 13.9419, 0.07500],
    36: [-0.3521, 14.5888, 0.07315], 39: [-0.3521, 15.2466, 0.07165],
    42: [-0.3521, 15.9058, 0.07043], 45: [-0.3521, 16.5564, 0.06945],
    48: [-0.3521, 17.1901, 0.06868], 51: [-0.3521, 17.8030, 0.06813],
    54: [-0.3521, 18.3957, 0.06780], 57: [-0.3521, 18.9712, 0.06770],
    60: [-0.3521, 19.5346, 0.06785],
  };

  static const _wfaGirls = <int, List<double>>{
    0: [-0.3833, 3.2322, 0.14171], 1: [-0.3833, 4.1873, 0.13724],
    2: [-0.3833, 5.1282, 0.13000], 3: [-0.3833, 5.8458, 0.12619],
    4: [-0.3833, 6.4237, 0.12402], 5: [-0.3833, 6.8985, 0.12274],
    6: [-0.3833, 7.2970, 0.12214], 7: [-0.3833, 7.6422, 0.12192],
    8: [-0.3833, 7.9487, 0.12179], 9: [-0.3833, 8.2254, 0.12160],
    10: [-0.3833, 8.4800, 0.12138], 11: [-0.3833, 8.7192, 0.12107],
    12: [-0.3833, 8.9481, 0.12066], 15: [-0.3833, 9.5993, 0.11890],
    18: [-0.3833, 10.2279, 0.11703], 21: [-0.3833, 10.8482, 0.11552],
    24: [-0.3833, 11.4593, 0.11460], 27: [-0.3833, 12.0637, 0.11437],
    30: [-0.3833, 12.6648, 0.11477], 33: [-0.3833, 13.2577, 0.11563],
    36: [-0.3833, 13.8358, 0.11680], 39: [-0.3833, 14.3929, 0.11811],
    42: [-0.3833, 14.9241, 0.11943], 45: [-0.3833, 15.4276, 0.12070],
    48: [-0.3833, 15.9050, 0.12190], 51: [-0.3833, 16.3596, 0.12303],
    54: [-0.3833, 16.7961, 0.12412], 57: [-0.3833, 17.2199, 0.12521],
    60: [-0.3833, 17.6375, 0.12635],
  };

  static const _hfaBoys = <int, List<double>>{
    0: [1.0, 49.8842, 0.03795], 1: [1.0, 54.7244, 0.03557],
    2: [1.0, 58.4249, 0.03424], 3: [1.0, 61.4292, 0.03279],
    4: [1.0, 63.8860, 0.03133], 5: [1.0, 65.9026, 0.03042],
    6: [1.0, 67.6236, 0.02964], 7: [1.0, 69.1645, 0.02902],
    8: [1.0, 70.5994, 0.02846], 9: [1.0, 71.9736, 0.02800],
    10: [1.0, 73.2812, 0.02760], 11: [1.0, 74.5388, 0.02724],
    12: [1.0, 75.7488, 0.02692], 15: [1.0, 79.1458, 0.02613],
    18: [1.0, 82.2577, 0.02548], 21: [1.0, 85.1348, 0.02494],
    24: [1.0, 87.8161, 0.02447], 27: [1.0, 90.3541, 0.02406],
    30: [1.0, 92.7929, 0.02371], 33: [1.0, 95.1553, 0.02341],
    36: [1.0, 97.4553, 0.02314], 39: [1.0, 99.7029, 0.02291],
    42: [1.0, 101.9054, 0.02271], 45: [1.0, 104.0689, 0.02254],
    48: [1.0, 106.1997, 0.02239], 51: [1.0, 108.3035, 0.02227],
    54: [1.0, 110.3840, 0.02217], 57: [1.0, 112.4443, 0.02208],
    60: [1.0, 114.4870, 0.02202],
  };

  static const _hfaGirls = <int, List<double>>{
    0: [1.0, 49.1477, 0.03790], 1: [1.0, 53.6872, 0.03640],
    2: [1.0, 57.0673, 0.03503], 3: [1.0, 59.8029, 0.03374],
    4: [1.0, 62.0899, 0.03249], 5: [1.0, 64.0301, 0.03166],
    6: [1.0, 65.7311, 0.03092], 7: [1.0, 67.2873, 0.03031],
    8: [1.0, 68.7498, 0.02976], 9: [1.0, 70.1435, 0.02927],
    10: [1.0, 71.4818, 0.02882], 11: [1.0, 72.7710, 0.02840],
    12: [1.0, 74.0150, 0.02801], 15: [1.0, 77.5099, 0.02697],
    18: [1.0, 80.7079, 0.02609], 21: [1.0, 83.6654, 0.02533],
    24: [1.0, 86.4214, 0.02468], 27: [1.0, 89.0054, 0.02411],
    30: [1.0, 91.4428, 0.02363], 33: [1.0, 93.7542, 0.02320],
    36: [1.0, 95.9562, 0.02283], 39: [1.0, 98.0613, 0.02250],
    42: [1.0, 100.0794, 0.02221], 45: [1.0, 102.0182, 0.02196],
    48: [1.0, 103.8834, 0.02174], 51: [1.0, 105.6790, 0.02155],
    54: [1.0, 107.4073, 0.02138], 57: [1.0, 109.0703, 0.02124],
    60: [1.0, 110.6700, 0.02111],
  };

  static const _bmiBoys = <int, List<double>>{
    0: [1.0, 13.4069, 0.09838], 3: [1.0, 15.8972, 0.09238],
    6: [1.0, 16.4769, 0.08436], 9: [1.0, 16.0489, 0.08260],
    12: [1.0, 15.6689, 0.08190], 15: [1.0, 15.4009, 0.08270],
    18: [1.0, 15.2294, 0.08420], 21: [1.0, 15.1815, 0.08580],
    24: [1.0, 15.2263, 0.08630], 30: [1.0, 15.4094, 0.08670],
    36: [1.0, 15.6174, 0.08700], 42: [1.0, 15.8160, 0.08730],
    48: [1.0, 15.9725, 0.08750], 54: [1.0, 16.0861, 0.08800],
    60: [1.0, 16.1646, 0.08850],
  };

  static const _bmiGirls = <int, List<double>>{
    0: [1.0, 13.3363, 0.09519], 3: [1.0, 15.5823, 0.09119],
    6: [1.0, 15.9670, 0.08619], 9: [1.0, 15.3157, 0.08719],
    12: [1.0, 14.8561, 0.08819], 15: [1.0, 14.6210, 0.08919],
    18: [1.0, 14.5248, 0.09019], 21: [1.0, 14.5180, 0.09119],
    24: [1.0, 14.5760, 0.09119], 30: [1.0, 14.7757, 0.09219],
    36: [1.0, 15.0296, 0.09319], 42: [1.0, 15.2669, 0.09419],
    48: [1.0, 15.4485, 0.09519], 54: [1.0, 15.5797, 0.09619],
    60: [1.0, 15.6710, 0.09719],
  };

  // Weight-for-Height BOYS (height cm -> [L, M, S]) — 65–120 cm
  static const _wfhBoys = <int, List<double>>{
    65: [-0.3521, 7.4327, 0.10996], 70: [-0.3521, 8.2098, 0.10679],
    75: [-0.3521, 9.0594, 0.10442], 80: [-0.3521, 9.9750, 0.10221],
    85: [-0.3521, 10.9493, 0.10007], 90: [-0.3521, 11.9983, 0.09833],
    95: [-0.3521, 13.1265, 0.09720], 100: [-0.3521, 14.3480, 0.09677],
    105: [-0.3521, 15.6831, 0.09699], 110: [-0.3521, 17.1591, 0.09754],
    115: [-0.3521, 18.8071, 0.09840], 120: [-0.3521, 20.6541, 0.09957],
  };

  // Weight-for-Height GIRLS (height cm -> [L, M, S]) — 65–120 cm
  static const _wfhGirls = <int, List<double>>{
    65: [-0.3833, 7.1538, 0.11503], 70: [-0.3833, 7.9128, 0.11269],
    75: [-0.3833, 8.7416, 0.11020], 80: [-0.3833, 9.6436, 0.10798],
    85: [-0.3833, 10.6123, 0.10615], 90: [-0.3833, 11.6333, 0.10481],
    95: [-0.3833, 12.6987, 0.10397], 100: [-0.3833, 13.7968, 0.10366],
    105: [-0.3833, 14.9213, 0.10387], 110: [-0.3833, 16.0674, 0.10461],
    115: [-0.3833, 17.2363, 0.10590], 120: [-0.3833, 18.4328, 0.10774],
  };

  // ── LMS interpolation ───────────────────────────────────────────────────────
  static List<double>? _getLMS(Map<int, List<double>> table, int key) {
    if (table.containsKey(key)) return table[key];
    final keys = table.keys.toList()..sort();
    int? lower, upper;
    for (final k in keys) {
      if (k <= key) lower = k;
      if (k >= key && upper == null) upper = k;
    }
    if (lower == null || upper == null) return null;
    if (lower == upper) return table[lower];
    final t = (key - lower) / (upper - lower);
    final lo = table[lower]!;
    final hi = table[upper]!;
    return [lo[0], lo[1] + t * (hi[1] - lo[1]), lo[2] + t * (hi[2] - lo[2])];
  }

  static double? _zScore(double x, List<double> lms) {
    final l = lms[0], m = lms[1], s = lms[2];
    if (m <= 0 || s <= 0) return null;
    if (l.abs() < 1e-6) return math.log(x / m) / s;
    return (math.pow(x / m, l) - 1) / (s * l);
  }

  // ── Parsing ─────────────────────────────────────────────────────────────────
  static int? _parseAgeInMonths(String ageStr, String? dobStr, String? measurementDateStr) {
    if (dobStr != null && dobStr.trim().isNotEmpty &&
        measurementDateStr != null && measurementDateStr.trim().isNotEmpty) {
      final dob = _parseDate(dobStr);
      final meas = _parseDate(measurementDateStr);
      if (dob != null && meas != null) {
        final months = (meas.year - dob.year) * 12 + (meas.month - dob.month);
        if (months >= 0) return months;
      }
    }
    if (ageStr.trim().isEmpty) return null;
    final age = ageStr.trim().toLowerCase();
    final numMatch = RegExp(r'[\d.]+').firstMatch(age);
    if (numMatch != null) {
      final n = double.tryParse(numMatch.group(0)!);
      if (n != null) {
        if (age.contains('month')) return n.round();
        if (age.contains('year') || age.contains('yr')) return (n * 12).round();
        if (n >= 0) return n.round();
      }
    }
    return null;
  }

  static ({int year, int month, int day})? _parseDate(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    final iso = RegExp(r'^\d{4}[-/]').hasMatch(t);
    final parts = t.split(RegExp(r'[/\-.,\s]+'));
    if (parts.length >= 3) {
      final vals = parts.map((e) => int.tryParse(e)).toList();
      if (vals[0] != null && vals[1] != null && vals[2] != null) {
        int y, m, d;
        if (iso) { y = vals[0]!; m = vals[1]!.clamp(1, 12); d = vals[2]!.clamp(1, 31); }
        else { m = vals[0]!.clamp(1, 12); d = vals[1]!.clamp(1, 31); y = vals[2]!; }
        if (y < 100) y += 2000;
        return (year: y, month: m, day: d);
      }
    }
    return null;
  }

  static bool _isMale(String s) {
    final v = s.trim().toLowerCase();
    return v.startsWith('m') || v == 'male' || v == 'lalaki';
  }

  static bool _isFemale(String s) {
    final v = s.trim().toLowerCase();
    return v.startsWith('f') || v == 'female' || v == 'babae';
  }

  // ── Interpretation ───────────────────────────────────────────────────────────
  static String _interpret(double z, String type) {
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

  static String _fmt(double z, String type) => '${z.toStringAsFixed(2)} (${_interpret(z, type)})';

  // ── Public API ───────────────────────────────────────────────────────────────
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
    final male = _isMale(sexStr);
    final female = _isFemale(sexStr);

    if (weight == null || weight <= 0 || height == null || height <= 0 ||
        ageMonths == null || ageMonths < 0 || (!male && !female)) {
      debugPrint('[Lumasdang] AnthropometricCalculator: invalid inputs — '
          'weight=$weight height=$height ageMonths=$ageMonths sex=$sexStr');
      return null;
    }

    final bmiValue = weight / math.pow(height / 100, 2);

    if (ageMonths > 60) {
      return AnthropometricResult(bmi: bmiValue.toStringAsFixed(1));
    }

    final wfaTable = male ? _wfaBoys : _wfaGirls;
    final hfaTable = male ? _hfaBoys : _hfaGirls;
    final bmiTable = male ? _bmiBoys : _bmiGirls;
    final wfhTable = male ? _wfhBoys : _wfhGirls;

    String? wfaResult, hfaResult, wfhResult, bmiResult;

    // Weight-for-Age
    final wfaLms = _getLMS(wfaTable, ageMonths);
    if (wfaLms != null) {
      final z = _zScore(weight, wfaLms);
      if (z != null) wfaResult = _fmt(z, 'wfa');
    }

    // Height-for-Age
    final hfaLms = _getLMS(hfaTable, ageMonths);
    if (hfaLms != null) {
      final z = _zScore(height, hfaLms);
      if (z != null) hfaResult = _fmt(z, 'hfa');
    }

    // Weight-for-Height (by height in cm, rounded to nearest 5)
    final heightKey = ((height / 5).round() * 5).clamp(65, 120);
    final wfhLms = _getLMS(wfhTable, heightKey);
    if (wfhLms != null) {
      final z = _zScore(weight, wfhLms);
      if (z != null) wfhResult = _fmt(z, 'wfh');
    }

    // BMI-for-Age
    final bmiLms = _getLMS(bmiTable, ageMonths);
    if (bmiLms != null) {
      final z = _zScore(bmiValue, bmiLms);
      if (z != null) {
        bmiResult = '${bmiValue.toStringAsFixed(1)} | ${_fmt(z, 'bmi')}';
      }
    }
    bmiResult ??= bmiValue.toStringAsFixed(1);

    return AnthropometricResult(
      weightForAge: wfaResult,
      weightForHeight: wfhResult,
      heightForAge: hfaResult,
      bmi: bmiResult,
    );
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