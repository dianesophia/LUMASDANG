import 'package:lumasdang/services/firestore_service.dart';
import 'package:lumasdang/services/local_db_service.dart';

/// Date windows and online/offline loading for the dashboard.
class DashboardAnalyticsService {
  DashboardAnalyticsService._();

  static DateTime startOfLocalDay(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  static DateTime startOfNextDay(DateTime d) =>
      startOfLocalDay(d).add(const Duration(days: 1));

  /// Monday 00:00 of the week containing [d] (Dart weekday: Mon = 1).
  static DateTime startOfIsoWeekMonday(DateTime d) {
    final day = startOfLocalDay(d);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  static Future<({int today, int week, int month})> loadAssessedCounts({
    required bool online,
    FirestoreService? firestore,
  }) async {
    final fs = firestore ?? FirestoreService();
    final now = DateTime.now();
    final dayStart = startOfLocalDay(now);
    final dayEnd = startOfNextDay(now);
    final weekStart = startOfIsoWeekMonday(now);
    final monthStart = startOfMonth(now);

    if (online) {
      final t = await fs.getAssessedCountBetween(dayStart, dayEnd);
      final w = await fs.getAssessedCountBetween(weekStart, dayEnd);
      final m = await fs.getAssessedCountBetween(monthStart, dayEnd);
      return (today: t, week: w, month: m);
    }

    await LocalDbService.instance.init();
    final records =
        await LocalDbService.instance.getAllRecords(includeDeleted: false);

    int countInRange(DateTime start, DateTime end) {
      var c = 0;
      for (final r in records) {
        final ts = r['timestamp'];
        DateTime? dt;
        if (ts is String) dt = DateTime.tryParse(ts);
        if (dt == null) continue;
        if (!dt.isBefore(start) && dt.isBefore(end)) c++;
      }
      return c;
    }

    return (
      today: countInRange(dayStart, dayEnd),
      week: countInRange(weekStart, dayEnd),
      month: countInRange(monthStart, dayEnd),
    );
  }

  static Future<List<Map<String, dynamic>>> loadPatientsInRange({
    required bool online,
    required DateTime startInclusive,
    required DateTime endExclusive,
    FirestoreService? firestore,
  }) async {
    final fs = firestore ?? FirestoreService();
    if (online) {
      return fs.getPatientsCreatedBetween(startInclusive, endExclusive);
    }

    await LocalDbService.instance.init();
    final records =
        await LocalDbService.instance.getAllRecords(includeDeleted: false);
    final out = <Map<String, dynamic>>[];
    for (final r in records) {
      final ts = r['timestamp'];
      DateTime? dt;
      if (ts is String) dt = DateTime.tryParse(ts);
      if (dt == null) continue;
      if (dt.isBefore(startInclusive) || !dt.isBefore(endExclusive)) continue;
      final data = r['data'] as Map<String, dynamic>? ?? {};
      out.add({
        'id': r['id'],
        'demographic': data['demographic'],
        'anthropometric': data['anthropometric'],
        'createdAt': dt,
      });
    }
    return out;
  }

  static Future<Map<String, int>> loadStatusCounts({
    required bool online,
    FirestoreService? firestore,
  }) async {
    const keys = [
      'Underweight',
      'Overweight/Obese',
      'Stunted',
      'At Risk',
      'Normal',
    ];
    final counts = {for (final k in keys) k: 0};

    if (online) {
      final remote = await (firestore ?? FirestoreService()).getStatusCounts();
      for (final k in keys) {
        counts[k] = remote[k] ?? 0;
      }
      return counts;
    }

    await LocalDbService.instance.init();
    final records =
        await LocalDbService.instance.getAllRecords(includeDeleted: false);

    for (final record in records) {
      final data = record['data'] as Map<String, dynamic>?;
      if (data == null) continue;
      final anthropometric =
          data['anthropometric'] as Map<String, dynamic>? ?? {};

      final wfa =
          (anthropometric['weightForAge'] as String? ?? '').toLowerCase();
      final hfa =
          (anthropometric['heightForAge'] as String? ?? '').toLowerCase();
      final wfh =
          (anthropometric['weightForHeight'] as String? ?? '').toLowerCase();
      final bmi = (anthropometric['bmi'] as String? ?? '').toLowerCase();

      if (wfa.contains('underweight') || bmi.contains('underweight')) {
        counts['Underweight'] = counts['Underweight']! + 1;
      }
      if (wfa.contains('overweight') ||
          wfa.contains('obese') ||
          wfh.contains('overweight') ||
          wfh.contains('obese') ||
          bmi.contains('overweight') ||
          bmi.contains('obese')) {
        counts['Overweight/Obese'] = counts['Overweight/Obese']! + 1;
      }
      if (hfa.contains('stunted')) {
        counts['Stunted'] = counts['Stunted']! + 1;
      }
      if (wfh.contains('wasted') ||
          wfa.contains('at risk') ||
          bmi.contains('at risk') ||
          wfh.contains('at risk')) {
        counts['At Risk'] = counts['At Risk']! + 1;
      }

      final hasAny =
          wfa.isNotEmpty || hfa.isNotEmpty || wfh.isNotEmpty || bmi.isNotEmpty;
      if (hasAny &&
          !wfa.contains('underweight') &&
          !bmi.contains('underweight') &&
          !wfa.contains('overweight') &&
          !wfa.contains('obese') &&
          !wfh.contains('overweight') &&
          !wfh.contains('obese') &&
          !bmi.contains('overweight') &&
          !bmi.contains('obese') &&
          !hfa.contains('stunted') &&
          !wfh.contains('wasted') &&
          !wfa.contains('at risk') &&
          !bmi.contains('at risk') &&
          !wfh.contains('at risk')) {
        counts['Normal'] = counts['Normal']! + 1;
      }
    }

    return counts;
  }
}
