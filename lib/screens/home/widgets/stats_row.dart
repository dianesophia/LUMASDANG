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
  Future<int> _loadTodayCount() async {
    await LocalDbService.instance.init();
    final online = await ConnectivityService.instance.checkOnline();
    if (online) {
      return FirestoreService().getTodayScreenedCountFromBarangay();
    }
    return LocalDbService.instance.getTodayScreenedCount();
  }

  String _formatDate(DateTime d) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A962),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FutureBuilder<int>(
                      future: _loadTodayCount(),
                      builder: (context, snapshot) {
                        final count = snapshot.hasData ? snapshot.data! : null;
                        return Text(
                          count != null ? '$count' : '—',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No. of patient',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const Text(
                          'screened today',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _formatDate(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFFF5A962),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusRow(count: '0', label: 'Underweight'),
                SizedBox(height: 2),
                StatusRow(count: '1', label: 'Overweight/', subtitle: 'Obese'),
                SizedBox(height: 2),
                StatusRow(count: '2', label: 'Stunted'),
                SizedBox(height: 2),
                StatusRow(count: '3', label: 'At Risk'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
