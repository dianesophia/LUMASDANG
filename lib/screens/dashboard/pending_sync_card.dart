import 'package:flutter/material.dart';

/// Shows how many local assessments are waiting to sync, with a sync action.
class PendingSyncCard extends StatelessWidget {
  final int pendingCount;
  final bool syncing;
  final VoidCallback? onSyncTap;

  const PendingSyncCard({
    super.key,
    required this.pendingCount,
    this.syncing = false,
    this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingCount <= 0) return const SizedBox.shrink();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFFFF6EE),
      child: InkWell(
        onTap: syncing ? null : onSyncTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF08030).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: syncing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFFF08030),
                        ),
                      )
                    : const Icon(
                        Icons.cloud_upload_outlined,
                        color: Color(0xFFF08030),
                        size: 24,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$pendingCount assessment${pendingCount == 1 ? '' : 's'} pending sync',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      syncing
                          ? 'Syncing to server…'
                          : 'Tap to upload when online',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (!syncing)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFF08030),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
