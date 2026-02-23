import 'package:flutter/material.dart';
import 'trend_line_painter.dart';

/// Z-Score Interpretation Trends card — styled to match ProfileInfoCard.
class TrendsSection extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;

  const TrendsSection({
    super.key,
    required this.assessments,
  });

  // ─── Design Tokens (matches ProfileInfoCard) ────────────────────────────────
  static const Color _orange      = Color(0xFFF08030);
  static const Color _orangeLight = Color(0xFFF5A962);
  static const Color _surface     = Color(0xFFFFFFFF);
  static const Color _surfaceDim  = Color(0xFFFAFAFA);
  static const Color _border      = Color(0xFFE8E8ED);
  static const Color _ink         = Color(0xFF1C1C1E);
  static const Color _inkMid      = Color(0xFF6C6C70);

  // Chart line colors — harmonized with the orange palette
  static const Color _colorHeight = Color(0xFF5DADE2);
  static const Color _colorWeight = Color(0xFF58D68D);
  static const Color _colorMuac   = Color(0xFFF5A962);

  static const double _r  = 18;
  static const double _ri = 12;

  static List<BoxShadow> get _shadow => [
        BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 6)),
      ];

  // ─── Helpers ────────────────────────────────────────────────────────────────

  String _formatDateShort(DateTime? date) {
    if (date == null) return '--';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[date.month - 1];
  }

  double? _extractZScore(String? value) {
    if (value == null || value.isEmpty) return null;
    final match = RegExp(r'^(-?\d+\.?\d*)').firstMatch(value.trim());
    return match != null ? double.tryParse(match.group(1)!) : null;
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (assessments.isEmpty) return const SizedBox.shrink();

    final validAssessments = <Map<String, dynamic>>[];
    final List<double?> heightScores = [];
    final List<double?> weightScores = [];
    final List<double?> wfhScores    = [];

    for (final a in assessments) {
      final hScore   = _extractZScore(a['heightForAge']?.toString());
      final wScore   = _extractZScore(a['weightForAge']?.toString());
      final wfhScore = _extractZScore(a['weightForHeight']?.toString());
      if (hScore != null || wScore != null || wfhScore != null) {
        validAssessments.add(a);
        heightScores.add(hScore);
        weightScores.add(wScore);
        wfhScores.add(wfhScore);
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(_r),
        border: Border.all(color: _border, width: 1),
        boxShadow: _shadow,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent bar
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_orangeLight, _orange]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(_r)),
            ),
          ),
          _buildHeader(),
          const Divider(height: 1, color: _border),
          if (validAssessments.length < 2)
            _buildInsufficient()
          else
            _buildCharts(validAssessments, heightScores, weightScores, wfhScores),
        ],
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.show_chart_rounded, color: _orange, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Z-Score Trends',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _ink,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      );

  Widget _buildInsufficient() => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.show_chart_rounded, size: 40, color: _orange.withOpacity(0.35)),
            const SizedBox(height: 12),
            const Text(
              'At least 2 assessments with z-score data are needed to show trends.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: _inkMid, height: 1.4),
            ),
          ],
        ),
      );

  // ─── Charts ─────────────────────────────────────────────────────────────────

  Widget _buildCharts(
    List<Map<String, dynamic>> valid,
    List<double?> height,
    List<double?> weight,
    List<double?> wfh,
  ) {
    final dates = valid.map((a) => _formatDateShort(a['date'] as DateTime?)).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        children: [
          // Legend row
          _legendRow(),
          const SizedBox(height: 14),

          if (height.any((s) => s != null)) ...[
            _TrendChart(
              label: 'Height',
              data: height.map((s) => s ?? 0.0).toList(),
              dates: dates,
              color: _colorHeight,
              showXAxis: false,
            ),
            const SizedBox(height: 10),
          ],
          if (weight.any((s) => s != null)) ...[
            _TrendChart(
              label: 'Weight',
              data: weight.map((s) => s ?? 0.0).toList(),
              dates: dates,
              color: _colorWeight,
              showXAxis: false,
            ),
            const SizedBox(height: 10),
          ],
          if (wfh.any((s) => s != null))
            _TrendChart(
              label: 'MUAC',
              data: wfh.map((s) => s ?? 0.0).toList(),
              dates: dates,
              color: _colorMuac,
              showXAxis: true,
            ),
        ],
      ),
    );
  }

  Widget _legendRow() => Row(
        children: [
          _legendDot('Height', _colorHeight),
          const SizedBox(width: 14),
          _legendDot('Weight', _colorWeight),
          const SizedBox(width: 14),
          _legendDot('MUAC', _colorMuac),
        ],
      );

  Widget _legendDot(String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _inkMid)),
        ],
      );
}

// ─── Individual chart ─────────────────────────────────────────────────────────

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

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);

    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Y-axis labels + metric name
          SizedBox(
            width: 46,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
                ),
                Text(
                  maxVal.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF6C6C70), fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  minVal.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF6C6C70), fontWeight: FontWeight.w500),
                ),
                if (showXAxis) const SizedBox(height: 14),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: TrendLinePainter(
                      data: data,
                      color: color,
                      minValue: minVal,
                      maxValue: maxVal,
                    ),
                  ),
                ),
                if (showXAxis) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: dates
                        .map((d) => Text(
                              d,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFF6C6C70),
                                fontWeight: FontWeight.w500,
                              ),
                            ))
                        .toList(),
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