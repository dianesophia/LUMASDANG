import 'package:flutter/material.dart';
import '../../../services/firestore_service.dart';
import '../../../services/local_db_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/dashboard_analytics_service.dart';
import '../../shared/status_color.dart';
import 'package:flutter/foundation.dart';

class StatsRow extends StatefulWidget {
  final VoidCallback? onTap;
  final bool showTodayCard;
  final Map<String, int>? statusCounts;
  final void Function(String statusLabel)? onStatusTap;

  const StatsRow({
    super.key,
    this.onTap,
    this.showTodayCard = true,
    this.statusCounts,
    this.onStatusTap,
  });

  @override
  State<StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<StatsRow> {
  late Future<int> _todayCountFuture;
  late Future<Map<String, int>> _statusCountsFuture;

  @override
  void initState() {
    super.initState();
    if (widget.showTodayCard) {
      _todayCountFuture = _loadTodayCount();
    }
    if (widget.statusCounts == null) {
      _statusCountsFuture = _loadStatusCounts();
    }
  }

  @override
  void didUpdateWidget(covariant StatsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showTodayCard && !oldWidget.showTodayCard) {
      _todayCountFuture = _loadTodayCount();
    }
    if (widget.statusCounts != null && oldWidget.statusCounts == null) {
      _statusCountsFuture = Future.value(widget.statusCounts!);
    } else if (widget.statusCounts == null && oldWidget.statusCounts != null) {
      _statusCountsFuture = _loadStatusCounts();
    } else if (widget.statusCounts != null &&
        widget.statusCounts != oldWidget.statusCounts) {
      _statusCountsFuture = Future.value(widget.statusCounts!);
    }
  }

  Future<int> _loadTodayCount() async {
    await LocalDbService.instance.init();
    final online = kIsWeb
        ? true
        : await ConnectivityService.instance.checkOnline();
    if (online) return FirestoreService().getTodayScreenedCountFromBarangay();
    return LocalDbService.instance.getTodayScreenedCount();
  }

  Future<Map<String, int>> _loadStatusCounts() async {
    await LocalDbService.instance.init();
    final online = kIsWeb
        ? true
        : await ConnectivityService.instance.checkOnline();
    return DashboardAnalyticsService.loadStatusCounts(online: online);
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Widget _buildStatusColumn(Map<String, int> counts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFF5A962),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Overall Status',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF444444),
                letterSpacing: 0.3,
              ),
            ),
            if (widget.onStatusTap != null) ...[
              const Spacer(),
              Text(
                'Tap to view',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        _StatusItem(
          count: counts['Underweight'] ?? 0,
          label: 'Underweight',
          color: kStatusColors['Underweight']!,
          icon: Icons.arrow_downward_rounded,
          onTap: widget.onStatusTap != null
              ? () => widget.onStatusTap!('Underweight')
              : null,
        ),
        const SizedBox(height: 5),
        _StatusItem(
          count: counts['Overweight/Obese'] ?? 0,
          label: 'Overweight/Obese',
          color: kStatusColors['Overweight/Obese']!,
          icon: Icons.arrow_upward_rounded,
          onTap: widget.onStatusTap != null
              ? () => widget.onStatusTap!('Overweight/Obese')
              : null,
        ),
        const SizedBox(height: 5),
        _StatusItem(
          count: counts['Stunted'] ?? 0,
          label: 'Stunted',
          color: kStatusColors['Stunted']!,
          icon: Icons.height_rounded,
          onTap: widget.onStatusTap != null
              ? () => widget.onStatusTap!('Stunted')
              : null,
        ),
        const SizedBox(height: 5),
        _StatusItem(
          count: counts['At Risk'] ?? 0,
          label: 'At Risk',
          color: kStatusColors['At Risk']!,
          icon: Icons.warning_amber_rounded,
          onTap: widget.onStatusTap != null
              ? () => widget.onStatusTap!('At Risk')
              : null,
        ),
        const SizedBox(height: 5),
        _StatusItem(
          count: counts['Normal'] ?? 0,
          label: 'Normal',
          color: kStatusColors['Normal']!,
          icon: Icons.check_circle_outline_rounded,
          onTap: widget.onStatusTap != null
              ? () => widget.onStatusTap!('Normal')
              : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showTodayCard) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: widget.statusCounts != null
            ? _buildStatusColumn(widget.statusCounts!)
            : FutureBuilder<Map<String, int>>(
                future: _statusCountsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFF5A962),
                        ),
                      ),
                    );
                  }
                  return _buildStatusColumn(snapshot.data ?? {});
                },
              ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5A962), Color(0xFFF07B3A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF5A962).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.people_alt_rounded,
                              color: Colors.white, size: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.today_rounded,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 10),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(DateTime.now()),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<int>(
                      future: _todayCountFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          );
                        }
                        return Text(
                          '${snapshot.data ?? 0}',
                          style: const TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Patients screened\ntoday',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: widget.statusCounts != null
                  ? _buildStatusColumn(widget.statusCounts!)
                  : FutureBuilder<Map<String, int>>(
                      future: _statusCountsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFF5A962),
                              ),
                            ),
                          );
                        }
                        return _buildStatusColumn(snapshot.data ?? {});
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatusItem({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF555555),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: color.withValues(alpha: 0.25), width: 0.8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded,
              size: 16, color: Colors.grey.shade500),
        ],
      ],
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: content,
        ),
      ),
    );
  }
}
