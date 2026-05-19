import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lumasdang/screens/dashboard/dashboard_empty.dart';
import 'package:lumasdang/screens/dashboard/dashboard_skeleton.dart';
import 'package:lumasdang/models/patient_list_filter.dart';
import 'package:lumasdang/screens/dashboard/pending_sync_card.dart';
import 'package:lumasdang/screens/home/widgets/stats_row.dart';
import 'package:lumasdang/screens/home/widgets/upcoming_events.dart';
import 'package:lumasdang/services/age_utils.dart';
import 'package:lumasdang/services/connectivity_service.dart';
import 'package:lumasdang/services/dashboard_analytics_service.dart';
import 'package:lumasdang/services/local_db_service.dart';
import 'package:lumasdang/services/nutrition_status_classifier.dart';

enum AssessedPeriod { today, thisWeek, thisMonth }

enum AnalyticsTimeFilter { thisWeek, thisMonth }

enum SexFilter { all, male, female }

class DashboardScreen extends StatefulWidget {
  final int refreshKey;
  final Future<void> Function()? onSyncPending;
  final void Function(PatientListFilter filter)? onOpenPatientList;

  const DashboardScreen({
    super.key,
    required this.refreshKey,
    this.onSyncPending,
    this.onOpenPatientList,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _loading = true;
  bool _patientsReloading = false;
  String? _error;
  int _assessedToday = 0;
  int _assessedWeek = 0;
  int _assessedMonth = 0;
  AssessedPeriod _assessedPeriod = AssessedPeriod.today;
  AnalyticsTimeFilter _analyticsTime = AnalyticsTimeFilter.thisWeek;
  NutritionCategory _category = NutritionCategory.stunting;
  SexFilter _sex = SexFilter.all;
  List<Map<String, dynamic>> _patientsInWindow = [];
  int _pendingSyncCount = 0;
  bool _syncing = false;
  Map<String, int> _statusCounts = {};

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      _reloadAll();
    }
  }

  Future<void> _reloadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final online =
          kIsWeb ? true : await ConnectivityService.instance.checkOnline();
      final counts = await DashboardAnalyticsService.loadAssessedCounts(
        online: online,
      );
      final now = DateTime.now();
      final end = DashboardAnalyticsService.startOfNextDay(now);
      final start = _analyticsTime == AnalyticsTimeFilter.thisWeek
          ? DashboardAnalyticsService.startOfIsoWeekMonday(now)
          : DashboardAnalyticsService.startOfMonth(now);
      final patients = await DashboardAnalyticsService.loadPatientsInRange(
        online: online,
        startInclusive: start,
        endExclusive: end,
      );
      await LocalDbService.instance.init();
      final pending = await LocalDbService.instance.getUnsyncedRecords();
      final statusCounts =
          await DashboardAnalyticsService.loadStatusCounts(online: online);
      if (!mounted) return;
      setState(() {
        _assessedToday = counts.today;
        _assessedWeek = counts.week;
        _assessedMonth = counts.month;
        _patientsInWindow = patients;
        _pendingSyncCount = pending.length;
        _statusCounts = statusCounts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _reloadPatientsOnly() async {
    setState(() => _patientsReloading = true);
    try {
      final online =
          kIsWeb ? true : await ConnectivityService.instance.checkOnline();
      final now = DateTime.now();
      final end = DashboardAnalyticsService.startOfNextDay(now);
      final start = _analyticsTime == AnalyticsTimeFilter.thisWeek
          ? DashboardAnalyticsService.startOfIsoWeekMonday(now)
          : DashboardAnalyticsService.startOfMonth(now);
      final patients = await DashboardAnalyticsService.loadPatientsInRange(
        online: online,
        startInclusive: start,
        endExclusive: end,
      );
      if (!mounted) return;
      setState(() {
        _patientsInWindow = patients;
        _patientsReloading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _patientsReloading = false;
      });
    }
  }

  int get _assessedDisplay {
    switch (_assessedPeriod) {
      case AssessedPeriod.today:
        return _assessedToday;
      case AssessedPeriod.thisWeek:
        return _assessedWeek;
      case AssessedPeriod.thisMonth:
        return _assessedMonth;
    }
  }

  String get _assessedSubtitle {
    switch (_assessedPeriod) {
      case AssessedPeriod.today:
        return 'New assessments logged today in your barangay';
      case AssessedPeriod.thisWeek:
        return 'New assessments from Monday through today';
      case AssessedPeriod.thisMonth:
        return 'New assessments from the 1st of this month through today';
    }
  }

  Map<String, dynamic>? _demographic(Map<String, dynamic> p) {
    final d = p['demographic'];
    if (d is Map<String, dynamic>) return d;
    if (d is Map) return Map<String, dynamic>.from(d);
    return null;
  }

  List<Map<String, dynamic>> get _filteredPatients {
    return _patientsInWindow.where((p) {
      final flags = NutritionStatusClassifier.classify(p);
      if (!flags.matchesCategory(_category)) return false;
      final sex = NutritionStatusClassifier.normalizeSex(_demographic(p));
      if (_sex == SexFilter.male && sex != 'male') return false;
      if (_sex == SexFilter.female && sex != 'female') return false;
      return true;
    }).toList();
  }

  String _ageBucketLabel(int? months) {
    if (months == null) return 'Unknown';
    if (months <= 5) return '0–5 mo';
    if (months <= 11) return '6–11 mo';
    if (months <= 23) return '12–23 mo';
    if (months <= 35) return '24–35 mo';
    if (months <= 47) return '36–47 mo';
    if (months <= 59) return '48–59 mo';
    return '60+ mo';
  }

  Map<String, int> _ageBucketCounts(List<Map<String, dynamic>> patients) {
    final buckets = <String, int>{};
    for (final p in patients) {
      final demo = _demographic(p);
      final created = NutritionStatusClassifier.patientCreatedAt(p);
      final months = ageInMonthsFromDemographic(
        demo ?? {},
        referenceDate: created ?? DateTime.now(),
      );
      final label = _ageBucketLabel(months);
      buckets[label] = (buckets[label] ?? 0) + 1;
    }
    return buckets;
  }

  ({String label, int count})? _topAgeBucket(
    List<Map<String, dynamic>> patients,
  ) {
    final m = _ageBucketCounts(patients);
    if (m.isEmpty) return null;
    var best = m.entries.first;
    for (final e in m.entries) {
      if (e.value > best.value) best = e;
    }
    return (label: best.key, count: best.value);
  }

  Map<DateTime, int> _dailyCounts(
    List<Map<String, dynamic>> patients,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final map = <DateTime, int>{};
    for (final p in patients) {
      final dt = NutritionStatusClassifier.patientCreatedAt(p);
      if (dt == null) continue;
      final day = DateTime(dt.year, dt.month, dt.day);
      if (day.isBefore(rangeStart) || !day.isBefore(rangeEnd)) continue;
      map[day] = (map[day] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      color: const Color(0xFF2E8B7B),
      onRefresh: _reloadAll,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────────────────
                  _buildHeader(),
                  const SizedBox(height: 20),

                  if (_error != null) _buildErrorBanner(),

                  if (_loading)
                    const DashboardSkeleton()
                  else ...[
                    // 1. Pending sync — actionable, show first
                    if (_pendingSyncCount > 0) ...[
                      PendingSyncCard(
                        pendingCount: _pendingSyncCount,
                        syncing: _syncing,
                        onSyncTap:
                            widget.onSyncPending != null ? _handleSyncTap : null,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 2. Patients assessed — key snapshot metric
                    _numberAssessedCard(),
                    const SizedBox(height: 20),

                    // 3. Status overview (malnutrition type counts)
                    _sectionHeader(
                      icon: Icons.monitor_heart_rounded,
                      title: 'Status overview',
                    ),
                    const SizedBox(height: 10),
                    StatsRow(
                      key: ValueKey('stats_${widget.refreshKey}'),
                      showTodayCard: false,
                      statusCounts: _statusCounts,
                      onStatusTap: widget.onOpenPatientList == null
                          ? null
                          : (label) => _openPatients(
                                PatientListFilter(malnutritionType: label),
                              ),
                    ),
                    const SizedBox(height: 24),

                    // 4. Upcoming events
                    _sectionHeader(
                      icon: Icons.event_rounded,
                      title: 'Upcoming events',
                    ),
                    const SizedBox(height: 10),
                    const UpcomingEvents(),
                    const SizedBox(height: 24),

                    // 5. Malnutrition analytics (filters + charts)
                    _sectionHeader(
                      icon: Icons.bar_chart_rounded,
                      title: 'Malnutrition analytics',
                    ),
                    const SizedBox(height: 10),

                    // Filters card — contained so they feel grouped
                    _filtersCard(),
                    const SizedBox(height: 12),

                    if (_patientsReloading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          color: Color(0xFFF5A962),
                          backgroundColor: Colors.white24,
                        ),
                      ),

                    // Summary mini-stats
                    _malnutritionSummary(),
                    const SizedBox(height: 12),

                    // Charts: trend first, then breakdown
                    _chartsCard(),
                    const SizedBox(height: 24),

                    // 6. Age analysis
                    _sectionHeader(
                      icon: Icons.child_care_rounded,
                      title: 'Age analysis',
                    ),
                    const SizedBox(height: 10),
                    _ageAnalysisCard(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Health analytics',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        // Inline sync badge (subtle, when there's no full pending card)
        if (!_loading && _pendingSyncCount == 0)
          GestureDetector(
            onTap: _reloadAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Refresh',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.red.shade700, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _error!,
                  style:
                      TextStyle(color: Colors.red.shade900, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────

  Widget _sectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ── Patients assessed card ─────────────────────────────────────────────────

  Widget _numberAssessedCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withValues(alpha: 0.96),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8B7B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fact_check_rounded,
                    color: Color(0xFF2E8B7B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Patients Assessed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Segmented period selector
            _segmentedPeriodSelector(),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TweenAnimationBuilder<int>(
                  key: ValueKey('${_assessedPeriod}_$_assessedDisplay'),
                  tween: IntTween(begin: 0, end: _assessedDisplay),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E8B7B),
                        height: 1.0,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'patients',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _assessedSubtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pill-style segmented control instead of individual FilterChips
  Widget _segmentedPeriodSelector() {
    const periods = [
      (AssessedPeriod.today, 'Today'),
      (AssessedPeriod.thisWeek, 'This week'),
      (AssessedPeriod.thisMonth, 'This month'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: periods.map((entry) {
          final (period, label) = entry;
          final selected = _assessedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _assessedPeriod = period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF2E8B7B) : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Filters card ───────────────────────────────────────────────────────────

  /// All analytics filters in one contained card to reduce visual noise
  Widget _filtersCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withValues(alpha: 0.96),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Timeframe (segmented)
            _filterLabel('Timeframe'),
            const SizedBox(height: 6),
            _timeframeSegmented(),
            const SizedBox(height: 14),

            // Row 2: Category
            _filterLabel('Category'),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: NutritionCategory.values.map((c) {
                  final sel = _category == c;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        c.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              sel ? FontWeight.w700 : FontWeight.w500,
                          color: const Color(0xFF1B4332),
                        ),
                      ),
                      selected: sel,
                      onSelected: (_) => setState(() => _category = c),
                      selectedColor:
                          const Color(0xFFF5A962).withValues(alpha: 0.45),
                      checkmarkColor: const Color(0xFF1B4332),
                      backgroundColor: Colors.grey.shade100,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Row 3: Sex
            _filterLabel('Sex'),
            const SizedBox(height: 6),
            Row(
              children: [
                _sexChip('All', SexFilter.all),
                const SizedBox(width: 8),
                _sexChip('Male', SexFilter.male),
                const SizedBox(width: 8),
                _sexChip('Female', SexFilter.female),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _timeframeSegmented() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: _timeframeOption(
              'This week',
              AnalyticsTimeFilter.thisWeek,
            ),
          ),
          Expanded(
            child: _timeframeOption(
              'This month',
              AnalyticsTimeFilter.thisMonth,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeframeOption(String label, AnalyticsTimeFilter value) {
    final selected = _analyticsTime == value;
    return GestureDetector(
      onTap: () async {
        if (_analyticsTime == value) return;
        setState(() => _analyticsTime = value);
        await _reloadPatientsOnly();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2E8B7B) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _sexChip(String label, SexFilter value) {
    final sel = _sex == value;
    return GestureDetector(
      onTap: () => setState(() => _sex = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: sel
              ? const Color(0xFF2E8B7B).withValues(alpha: 0.15)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                sel ? const Color(0xFF2E8B7B) : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            color: sel
                ? const Color(0xFF1B4332)
                : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  // ── Malnutrition summary mini-stats ────────────────────────────────────────

  Widget _malnutritionSummary() {
    final list = _filteredPatients;
    if (list.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF5C9EAD),
        child: const DashboardEmpty(
          title: 'No matching cases in this period',
          subtitle: 'Try another category, sex, or timeframe.',
        ),
      );
    }
    final male = list
        .where((p) =>
            NutritionStatusClassifier.normalizeSex(_demographic(p)) == 'male')
        .length;
    final female = list
        .where((p) =>
            NutritionStatusClassifier.normalizeSex(_demographic(p)) == 'female')
        .length;
    return Row(
      children: [
        Expanded(
            child: _miniStat('Cases', '${list.length}', Icons.pie_chart_outline,
                const Color(0xFF2E8B7B))),
        const SizedBox(width: 10),
        Expanded(
            child: _miniStat(
                'Male', '$male', Icons.male_rounded, const Color(0xFF5C9EAD))),
        const SizedBox(width: 10),
        Expanded(
            child: _miniStat('Female', '$female', Icons.female_rounded,
                const Color(0xFFE07A5F))),
      ],
    );
  }

  Widget _miniStat(
      String title, String value, IconData icon, Color accentColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white.withValues(alpha: 0.96),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B4332),
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ── Charts card ────────────────────────────────────────────────────────────

  Widget _chartsCard() {
    final list = _filteredPatients;
    if (list.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final startLine =
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final lineEnd = DashboardAnalyticsService.startOfNextDay(now);
    final daily = _dailyCounts(list, startLine, lineEnd);
    final spots = <FlSpot>[
      for (var i = 0; i < 7; i++)
        FlSpot(i.toDouble(), (daily[startLine.add(Duration(days: i))] ?? 0).toDouble()),
    ];
    final maxLineY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final lineMaxY = maxLineY < 3 ? 4.0 : maxLineY + 1;

    final buckets = _ageBucketCounts(list);
    final sortedKeys = buckets.keys.toList()
      ..sort((a, b) => (buckets[b] ?? 0).compareTo(buckets[a] ?? 0));
    final maxYBar =
        buckets.values.fold<int>(0, (a, b) => a > b ? a : b);

    final male = list
        .where((p) =>
            NutritionStatusClassifier.normalizeSex(_demographic(p)) == 'male')
        .length;
    final female = list
        .where((p) =>
            NutritionStatusClassifier.normalizeSex(_demographic(p)) == 'female')
        .length;
    final other = list.length - male - female;
    final pieSections = <PieChartSectionData>[
      if (male > 0)
        PieChartSectionData(
          color: const Color(0xFF5C9EAD),
          value: male.toDouble(),
          title: '$male',
          radius: 52,
          titleStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      if (female > 0)
        PieChartSectionData(
          color: const Color(0xFFE07A5F),
          value: female.toDouble(),
          title: '$female',
          radius: 52,
          titleStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      if (other > 0)
        PieChartSectionData(
          color: Colors.grey.shade400,
          value: other.toDouble(),
          title: '$other',
          radius: 52,
          titleStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
        ),
    ];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withValues(alpha: 0.96),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart 1: Trend line — most actionable info first
            _chartSectionTitle(
              'Daily new cases',
              'Last 7 days',
              Icons.trending_up_rounded,
              const Color(0xFFF5A962),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: lineMaxY,
                  lineTouchData: LineTouchData(enabled: true),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (v, m) {
                          final i = v.toInt();
                          if (i < 0 || i > 6) return const SizedBox.shrink();
                          final d = startLine.add(Duration(days: i));
                          return Text(
                            '${d.month}/${d.day}',
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (v, m) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFFF5A962),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFFF5A962).withValues(alpha: 0.18),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            _divider(),
            const SizedBox(height: 20),

            // Chart 2: Age group bar chart
            _chartSectionTitle(
              'Cases by age group',
              null,
              Icons.bar_chart_rounded,
              const Color(0xFF2E8B7B),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxYBar + 1).toDouble().clamp(1, 9999),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, m) {
                          final i = v.toInt();
                          if (i < 0 || i >= sortedKeys.length)
                            return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              sortedKeys[i],
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, m) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < sortedKeys.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: buckets[sortedKeys[i]]!.toDouble(),
                            width: 18,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                            color: const Color(0xFF2E8B7B),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            _divider(),
            const SizedBox(height: 20),

            // Chart 3: Sex distribution pie — last (supplementary)
            _chartSectionTitle(
              'Sex distribution',
              null,
              Icons.donut_small_rounded,
              const Color(0xFF5C9EAD),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  height: 160,
                  width: 160,
                  child: pieSections.isEmpty
                      ? const Center(child: Text('No data'))
                      : PieChart(
                          PieChartData(
                            sections: pieSections,
                            centerSpaceRadius: 28,
                            sectionsSpace: 2,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                _pieLegendVertical(male, female, other, list.length),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartSectionTitle(
      String title, String? subtitle, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1B4332)),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ),
        ],
      ],
    );
  }

  Widget _divider() {
    return Divider(color: Colors.grey.shade200, height: 1);
  }

  Widget _pieLegendVertical(int male, int female, int other, int total) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendRow(
              const Color(0xFF5C9EAD), 'Male', male, total),
          const SizedBox(height: 10),
          _legendRow(
              const Color(0xFFE07A5F), 'Female', female, total),
          if (other > 0) ...[
            const SizedBox(height: 10),
            _legendRow(Colors.grey.shade400, 'Other', other, total),
          ],
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label, int count, int total) {
    final pct = total == 0 ? 0 : (count / total * 100).round();
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                '$count ($pct%)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Age analysis card ──────────────────────────────────────────────────────

  Widget _ageAnalysisCard() {
    final list = _filteredPatients;
    if (list.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF5C9EAD),
        child: const DashboardEmpty(
          title: 'No age data for current filters',
          subtitle: 'Adjust filters or add assessments in this period.',
        ),
      );
    }
    final top = _topAgeBucket(list);
    final buckets = _ageBucketCounts(list);
    final sorted = buckets.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withValues(alpha: 0.96),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Highest burden highlight
            if (top != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2E8B7B).withValues(alpha: 0.12),
                      const Color(0xFF2E8B7B).withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2E8B7B).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFF2E8B7B),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Highest burden age group',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1B4332),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            top.label,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2E8B7B),
                            ),
                          ),
                          Text(
                            '${top.count} case(s) · ${_category.label} · '
                            '${_analyticsTime == AnalyticsTimeFilter.thisWeek ? "This week" : "This month"}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'All age groups',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...sorted.map((e) {
              final maxV = sorted.first.value;
              final p = maxV == 0 ? 0.0 : e.value / maxV;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          e.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5A962).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${e.value}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B4332),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: p,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade100,
                        color: const Color(0xFFF5A962),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _handleSyncTap() async {
    if (_syncing || widget.onSyncPending == null) return;
    setState(() => _syncing = true);
    try {
      await widget.onSyncPending!();
      await _reloadAll();
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _openPatients(PatientListFilter filter) {
    widget.onOpenPatientList?.call(filter);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}