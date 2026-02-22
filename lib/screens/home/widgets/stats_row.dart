import 'package:flutter/material.dart';
import '../../../services/firestore_service.dart';
import '../../../services/local_db_service.dart';
import '../../../services/connectivity_service.dart';
import 'status_row.dart';

class StatsRow extends StatefulWidget {
  final VoidCallback? onTap;

  const StatsRow({super.key, this.onTap});

  @override
  State<StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<StatsRow> {
  late Future<int> _todayCountFuture;
  late Future<Map<String, int>> _statusCountsFuture;

  @override
  void initState() {
    super.initState();
    _todayCountFuture = _loadTodayCount();
    _statusCountsFuture = _loadStatusCounts();
  }

  Future<int> _loadTodayCount() async {
    await LocalDbService.instance.init();
    final online = await ConnectivityService.instance.checkOnline();
    if (online) {
      return FirestoreService().getTodayScreenedCountFromBarangay();
    }
    return LocalDbService.instance.getTodayScreenedCount();
  }

  Future<Map<String, int>> _loadStatusCounts() async {
    await LocalDbService.instance.init();
    final online = await ConnectivityService.instance.checkOnline();
    if (online) {
      return FirestoreService().getTodayStatusCounts();
    }
    return {'Underweight': 0, 'Overweight': 0, 'Stunted': 0, 'At Risk': 0};
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left card: today's screened count ────────────────────────
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
                    // Icon + label row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.people_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
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

                    // Count
                    FutureBuilder<int>(
                      future: _todayCountFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          );
                        }
                        final count = snapshot.data ?? 0;
                        return Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 2),

                    // Label
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

          // ── Right card: status counts ─────────────────────────────────
          Expanded(
            flex: 6,
            child: Container(
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
              child: FutureBuilder<Map<String, int>>(
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

                  final counts = snapshot.data ?? {};
                  final uw = counts['Underweight'] ?? 0;
                  final ow = counts['Overweight'] ?? 0;
                  final st = counts['Stunted'] ?? 0;
                  final ar = counts['At Risk'] ?? 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header
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
                            "Today's Status",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF444444),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Status items
                      _StatusItem(
                        count: uw,
                        label: 'Underweight',
                        color: const Color(0xFF5B8DEF),
                        icon: Icons.arrow_downward_rounded,
                      ),
                      const SizedBox(height: 6),
                      _StatusItem(
                        count: ow,
                        label: 'Overweight/Obese',
                        color: const Color(0xFFF5A962),
                        icon: Icons.arrow_upward_rounded,
                      ),
                      const SizedBox(height: 6),
                      _StatusItem(
                        count: st,
                        label: 'Stunted',
                        color: const Color(0xFFE57373),
                        icon: Icons.height_rounded,
                      ),
                      const SizedBox(height: 6),
                      _StatusItem(
                        count: ar,
                        label: 'At Risk',
                        color: const Color(0xFFFFB74D),
                        icon: Icons.warning_amber_rounded,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inline status item widget (replaces StatusRow for this card) ─────────────
class _StatusItem extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;

  const _StatusItem({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Color dot
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),

        // Label
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

        // Count badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 0.8,
            ),
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
      ],
    );
  }
}