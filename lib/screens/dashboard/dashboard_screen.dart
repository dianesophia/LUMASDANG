import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lumasdang/screens/dashboard/dashboard_empty.dart';
import 'package:lumasdang/screens/dashboard/dashboard_skeleton.dart';
import 'package:lumasdang/services/age_utils.dart';
import 'package:lumasdang/services/connectivity_service.dart';
import 'package:lumasdang/services/dashboard_analytics_service.dart';
import 'package:lumasdang/services/nutrition_status_classifier.dart';

enum AssessedPeriod { today, thisWeek, thisMonth }

enum AnalyticsTimeFilter { thisWeek, thisMonth }

enum SexFilter { all, male, female }

class DashboardScreen extends StatefulWidget {
  final int refreshKey;

  const DashboardScreen({super.key, required this.refreshKey});

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
      if (!mounted) return;
      setState(() {
        _assessedToday = counts.today;
        _assessedWeek = counts.week;
        _assessedMonth = counts.month;
        _patientsInWindow = patients;
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
        return 'New patient records created today';
      case AssessedPeriod.thisWeek:
        return 'Total from Monday through today';
      case AssessedPeriod.thisMonth:
        return 'Total from the 1st of this month through today';
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Health analytics',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  if (_loading)
                    const DashboardSkeleton()
                  else ...[
                    if (_patientsReloading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          color: Color(0xFFF5A962),
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ..._bodyCharts(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _bodyCharts() {
    return [
      _numberAssessedCard(),
      const SizedBox(height: 20),
      _sectionTitle('Malnutrition analytics'),
      const SizedBox(height: 8),
      _analyticsChips(),
      const SizedBox(height: 12),
      _malnutritionSummary(),
      const SizedBox(height: 12),
      _chartsCard(),
      const SizedBox(height: 20),
      _sectionTitle('Age analysis'),
      const SizedBox(height: 8),
      _ageAnalysisCard(),
    ];
  }

  Widget _sectionTitle(String t) {
    return Text(
      t,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }

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
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Number Assessed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _periodChip('Today', AssessedPeriod.today),
                _periodChip('This week', AssessedPeriod.thisWeek),
                _periodChip('This month', AssessedPeriod.thisMonth),
              ],
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<int>(
              key: ValueKey('${_assessedPeriod}_$_assessedDisplay'),
              tween: IntTween(begin: 0, end: _assessedDisplay),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E8B7B),
                    height: 1.05,
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              _assessedSubtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodChip(String label, AssessedPeriod period) {
    final selected = _assessedPeriod == period;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _assessedPeriod = period),
      selectedColor: const Color(0xFF2E8B7B).withValues(alpha: 0.25),
      checkmarkColor: const Color(0xFF1B4332),
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: const Color(0xFF1B4332),
        fontSize: 12,
      ),
    );
  }

  Widget _analyticsChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: NutritionCategory.values.map((c) {
              final sel = _category == c;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(c.label),
                  selected: sel,
                  onSelected: (_) => setState(() => _category = c),
                  selectedColor: const Color(0xFFF5A962).withValues(alpha: 0.45),
                  checkmarkColor: const Color(0xFF1B4332),
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sex',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            _sexChip('All', SexFilter.all),
            _sexChip('Male', SexFilter.male),
            _sexChip('Female', SexFilter.female),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Timeframe',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('This week'),
              selected: _analyticsTime == AnalyticsTimeFilter.thisWeek,
              onSelected: (_) async {
                if (_analyticsTime == AnalyticsTimeFilter.thisWeek) return;
                setState(() => _analyticsTime = AnalyticsTimeFilter.thisWeek);
                await _reloadPatientsOnly();
              },
              selectedColor: Colors.white.withValues(alpha: 0.35),
            ),
            FilterChip(
              label: const Text('This month'),
              selected: _analyticsTime == AnalyticsTimeFilter.thisMonth,
              onSelected: (_) async {
                if (_analyticsTime == AnalyticsTimeFilter.thisMonth) return;
                setState(() => _analyticsTime = AnalyticsTimeFilter.thisMonth);
                await _reloadPatientsOnly();
              },
              selectedColor: Colors.white.withValues(alpha: 0.35),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sexChip(String label, SexFilter value) {
    final sel = _sex == value;
    return FilterChip(
      label: Text(label),
      selected: sel,
      onSelected: (_) => setState(() => _sex = value),
      selectedColor: Colors.white.withValues(alpha: 0.35),
    );
  }

  Widget _malnutritionSummary() {
    final list = _filteredPatients;
    if (list.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Color(0xFF5C9EAD),
        child: const DashboardEmpty(
          title: 'No matching cases in this period',
          subtitle: 'Try another category, sex, or timeframe.',
        ),
      );
    }
    final male = list.where((p) {
      return NutritionStatusClassifier.normalizeSex(_demographic(p)) == 'male';
    }).length;
    final female = list.where((p) {
      return NutritionStatusClassifier.normalizeSex(_demographic(p)) ==
          'female';
    }).length;
    return Row(
      children: [
        Expanded(
          child: _miniStat('Cases', '${list.length}', Icons.pie_chart_outline),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStat('Male', '$male', Icons.male_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStat('Female', '$female', Icons.female_rounded),
        ),
      ],
    );
  }

  Widget _miniStat(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2E8B7B), size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B4332),
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartsCard() {
    final list = _filteredPatients;
    if (list.isEmpty) {
      return const SizedBox.shrink();
    }
    final buckets = _ageBucketCounts(list);
    final sortedKeys = buckets.keys.toList()
      ..sort((a, b) => (buckets[b] ?? 0).compareTo(buckets[a] ?? 0));

    final now = DateTime.now();
    final startLine = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final lineEnd = DashboardAnalyticsService.startOfNextDay(now);
    final daily = _dailyCounts(list, startLine, lineEnd);
    final spots = <FlSpot>[];
    for (var i = 0; i < 7; i++) {
      final d = startLine.add(Duration(days: i));
      spots.add(FlSpot(i.toDouble(), (daily[d] ?? 0).toDouble()));
    }

    final maxYBar = buckets.values.fold<int>(
      0,
      (a, b) => a > b ? a : b,
    );

    final pieSections = <PieChartSectionData>[];
    final male = list.where((p) {
      return NutritionStatusClassifier.normalizeSex(_demographic(p)) == 'male';
    }).length;
    final female = list.where((p) {
      return NutritionStatusClassifier.normalizeSex(_demographic(p)) ==
          'female';
    }).length;
    final other = list.length - male - female;
    if (male > 0) {
      pieSections.add(
        PieChartSectionData(
          color: const Color(0xFF5C9EAD),
          value: male.toDouble(),
          title: '$male',
          radius: 52,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }
    if (female > 0) {
      pieSections.add(
        PieChartSectionData(
          color: const Color(0xFFE07A5F),
          value: female.toDouble(),
          title: '$female',
          radius: 52,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }
    if (other > 0) {
      pieSections.add(
        PieChartSectionData(
          color: Colors.grey.shade500,
          value: other.toDouble(),
          title: '$other',
          radius: 52,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      );
    }
    final maxLineY = spots.isEmpty
        ? 1.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1;
    final lineMaxY = maxLineY < 4 ? 4.0 : maxLineY;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withValues(alpha: 0.96),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visualizations',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B4332),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cases by age group',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600 ),
            ),
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
                          if (i < 0 || i >= sortedKeys.length) {
                            return const SizedBox.shrink();
                          }
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
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
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
                              top: Radius.circular(6),
                            ),
                            color: const Color(0xFF2E8B7B),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sex distribution',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
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
            const SizedBox(height: 6),
            _pieLegend(),
            const SizedBox(height: 12),
            const Text(
              'Daily new cases (last 7 days)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
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
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
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
                        color: const Color(0xFFF5A962).withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pieLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _LegendDot(color: Color(0xFF5C9EAD), label: 'Male'),
        _LegendDot(color: Color(0xFFE07A5F), label: 'Female'),
        _LegendDot(color: Color(0xFF9E9E9E), label: 'Other / unknown'),
      ],
    );
  }

  Widget _ageAnalysisCard() {
    final list = _filteredPatients;
    if (list.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Color(0xFF5C9EAD),
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
            if (top != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8B7B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Highest burden age group',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      top.label,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E8B7B),
                      ),
                    ),
                    Text(
                      '${top.count} case(s) for ${_category.label} · ${_analyticsTime == AnalyticsTimeFilter.thisWeek ? "This week" : "This month"}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            const Text(
              'Ranked age groups',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...sorted.map((e) {
              final maxV = sorted.first.value;
              final p = maxV == 0 ? 0.0 : e.value / maxV;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
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
                        Text('${e.value}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: p,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
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
