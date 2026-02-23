/// Shared utilities for computing age in months from patient demographic data.
/// Used for auto-archiving patients at 60 months (5 years).
library;

/// Parses common date string formats (MM-DD-YYYY, MM/DD/YYYY, YYYY-MM-DD, ISO).
DateTime? parseDate(String? s) {
  if (s == null || s.trim().isEmpty) return null;
  final trimmed = s.trim();
  final dt = DateTime.tryParse(trimmed);
  if (dt != null) return dt;
  final parts = trimmed.split(RegExp(r'[-/]'));
  if (parts.length >= 3) {
    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (month != null && day != null && year != null) {
      return DateTime(year, month, day);
    }
    if (parts[0].length == 4) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) return DateTime(y, m, d);
    }
  }
  return null;
}

/// Age in months between two dates.
int? ageInMonths(DateTime? dob, DateTime? referenceDate) {
  if (dob == null || referenceDate == null) return null;
  if (referenceDate.isBefore(dob)) return null;
  final years = referenceDate.year - dob.year;
  final months = referenceDate.month - dob.month;
  final days = referenceDate.day - dob.day;
  int totalMonths = years * 12 + months;
  if (days < 0) totalMonths -= 1;
  return totalMonths.clamp(0, 999);
}

/// Computes age in months from a patient document's demographic map.
/// Uses dateOfBirth + today when available; otherwise parses demographic['age'].
int? ageInMonthsFromDemographic(Map<String, dynamic> demographic, {DateTime? referenceDate}) {
  final ref = referenceDate ?? DateTime.now();
  final dobStr = (demographic['dateOfBirth'] ?? '').toString().trim();
  if (dobStr.isNotEmpty) {
    final dob = parseDate(dobStr);
    if (dob != null) return ageInMonths(dob, ref);
  }
  final ageStr = (demographic['age'] ?? '').toString().trim();
  if (ageStr.isNotEmpty) {
    final numMatch = RegExp(r'[\d.]+').firstMatch(ageStr);
    if (numMatch != null) {
      final num = double.tryParse(numMatch.group(0)!);
      if (num != null && num >= 0) return num.round();
    }
  }
  return null;
}
