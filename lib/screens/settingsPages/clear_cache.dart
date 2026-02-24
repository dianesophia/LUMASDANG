import 'package:flutter/material.dart';
import '../../services/local_db_service.dart';

class ClearCache extends StatelessWidget {
  const ClearCache({super.key});

  Future<void> _handleClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear synced cache?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'This will delete all locally stored assessments that are already '
          'synced to the server. Unsynced offline data will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final deletedCount = await LocalDbService.instance.clearSyncedRecords();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deletedCount == 0
                  ? 'No synced cached records to clear.'
                  : 'Cleared $deletedCount synced cached record(s).',
            ),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clear Cache')),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.delete_sweep_outlined),
          label: const Text('Clear synced cached assessments'),
          onPressed: () => _handleClear(context),
        ),
      ),
    );
  }
}