import 'package:flutter/material.dart';
import 'trend_line_painter.dart';

/// Widget displaying z-score interpretation trends for Height, Weight, and MUAC
class TrendsSection extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;

  const TrendsSection({
    super.key,
    required this.assessments,
  });

  String _formatDateShort(DateTime? date) {
    if (date == null) return '--';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[date.month - 1];
  }

  /// Extracts numeric z-score from string like "-1.50 (Normal)" or "2.30 (Overweight)"
  double? _extractZScore(String? value) {
    if (value == null || value.isEmpty) return null;
    // Try to extract the first number (z-score) before the parenthesis
    final match = RegExp(r'^(-?\d+\.?\d*)').firstMatch(value.trim());
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (assessments.isEmpty) return const SizedBox.shrink();

    // Filter assessments that have valid z-score data
    final validAssessments = <Map<String, dynamic>>[];
    final List<double?> heightScores = [];
    final List<double?> weightScores = [];
    final List<double?> wfhScores = [];
    
    for (var assessment in assessments) {
      final heightForAge = assessment['heightForAge']?.toString() ?? '';
      final weightForAge = assessment['weightForAge']?.toString() ?? '';
      final weightForHeight = assessment['weightForHeight']?.toString() ?? '';
      
      final hScore = _extractZScore(heightForAge);
      final wScore = _extractZScore(weightForAge);
      final wfhScore = _extractZScore(weightForHeight);
      
      // Only include if at least one z-score is available
      if (hScore != null || wScore != null || wfhScore != null) {
        validAssessments.add(assessment);
        heightScores.add(hScore);
        weightScores.add(wScore);
        wfhScores.add(wfhScore);
      }
    }

    // Need at least 2 data points for a trend
    if (validAssessments.length < 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Z-Score Interpretation Trends',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E8B7B),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Need at least 2 assessments with z-score data to show trends',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final dates = validAssessments.map((a) {
      final date = a['date'] as DateTime?;
      return _formatDateShort(date);
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Z-Score Interpretation Trends',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E8B7B),
            ),
          ),
          const SizedBox(height: 20),
          // Only show charts that have valid data
          if (heightScores.any((s) => s != null))
            _TrendChart(
              label: 'Height',
              data: heightScores.map((s) => s ?? 0.0).toList(),
              dates: dates,
              color: const Color(0xFF5DADE2),
              showXAxis: false,
            ),
          if (heightScores.any((s) => s != null)) const SizedBox(height: 12),
          
          if (weightScores.any((s) => s != null))
            _TrendChart(
              label: 'Weight',
              data: weightScores.map((s) => s ?? 0.0).toList(),
              dates: dates,
              color: const Color(0xFF58D68D),
              showXAxis: false,
            ),
          if (weightScores.any((s) => s != null)) const SizedBox(height: 12),
          
          if (wfhScores.any((s) => s != null))
            _TrendChart(
              label: 'MUAC',
              data: wfhScores.map((s) => s ?? 0.0).toList(),
              dates: dates,
              color: const Color(0xFFF5A962),
              showXAxis: true,
            ),
        ],
      ),
    );
  }
}

/// Individual trend chart widget
class _TrendChart extends StatelessWidget {
  final String label;
  final List<double> data;
  final List<String> dates;
  final Color color;
  final bool showXAxis;

  const _TrendChart({
    required this.label,
    required this.data,
    required this.dates,
    required this.color,
    this.showXAxis = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label and Y-axis values
          SizedBox(
            width: 45,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  maxValue.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  minValue.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (showXAxis) const SizedBox(height: 14),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Chart area
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: TrendLinePainter(
                      data: data,
                      color: color,
                      minValue: minValue,
                      maxValue: maxValue,
                    ),
                  ),
                ),
                if (showXAxis) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: dates.asMap().entries.map((entry) {
                      return Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
