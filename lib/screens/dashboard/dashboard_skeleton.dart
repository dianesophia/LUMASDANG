import 'package:flutter/material.dart';

/// Placeholder blocks while dashboard metrics load.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _box(height: 120),
        const SizedBox(height: 16),
        _box(height: 200),
        const SizedBox(height: 16),
        _box(height: 160),
      ],
    );
  }

  Widget _box({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
