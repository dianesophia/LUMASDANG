import 'package:flutter/material.dart';
import '../../../services/assessment_service.dart';

class AssessmentTable extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;
  final String patientId;
  final bool loading;
  final VoidCallback onAddAssessment;
  final Future<void> Function(Map<String, dynamic>, String patientId)?
      saveNewAssessment;

  const AssessmentTable({
    super.key,
    required this.patientId,
    required this.assessments,
    required this.loading,
    required this.onAddAssessment,
    this.saveNewAssessment,
  });

  // ─── Design Tokens (matches ProfileInfoCard) ────────────────────────────────
  static const Color _orange       = Color(0xFFF08030);
  static const Color _orangeLight  = Color(0xFFF5A962);
  static const Color _surface      = Color(0xFFFFFFFF);
  static const Color _surfaceDim   = Color(0xFFFAFAFA);
  static const Color _border       = Color(0xFFE8E8ED);
  static const Color _ink          = Color(0xFF1C1C1E);
  static const Color _inkMid       = Color(0xFF6C6C70);
  static const Color _green        = Color(0xFF34C759);
  static const Color _greenBg      = Color(0xFFEDF7F1);
  static const Color _greenText    = Color(0xFF1A7A3C);
  static const Color _red          = Color(0xFFDC2626);
  static const Color _redBg        = Color(0xFFFEF2F2);
  static const Color _warning      = Color(0xFFF08030);
  static const Color _warningBg    = Color(0xFFFFF6EE);

  static const double _r  = 18;
  static const double _ri = 12;

  static List<BoxShadow> get _shadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  // ─── Classification logic ───────────────────────────────────────────────────

  // Extract leading numeric z-score from strings like "-2.5 (Stunted)" or "-2.5".
  double? _extractZScore(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final match = RegExp(r'^-?\d+(\.\d+)?').firstMatch(raw.trim());
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  // Extract BMI z-score from strings like "18.2 | 0.10 (Normal)".
  double? _extractBmiZScore(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final trimmed = raw.trim();
    if (!trimmed.contains('|')) return null;
    final parts = trimmed.split('|');
    if (parts.length < 2) return null;
    final afterPipe = parts[1].trim();
    final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(afterPipe);
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  String _getClassification(Map<String, dynamic> a) {
    final double? weightForAge =
        _extractZScore(a['weightForAge']?.toString());
    final double? heightForAge =
        _extractZScore(a['heightForAge']?.toString());
    final double? weightForHeight =
        _extractZScore(a['weightForHeight']?.toString());
    final double? bmi = _extractBmiZScore(a['bmi']?.toString());

    // Match patient list remarks: if no usable z-scores, treat as assessment done.
    if (weightForAge == null &&
        heightForAge == null &&
        weightForHeight == null &&
        bmi == null) {
      return 'Assessment done';
    }

    // Priority 1: Underweight (Weight-for-Age < -2 SD)
    if (weightForAge != null && weightForAge < -2) {
      return 'Underweight';
    }

    // Priority 2: Stunted (Height-for-Age < -2 SD)
    if (heightForAge != null && heightForAge < -2) {
      return 'Stunted';
    }

    // Priority 3: Overweight/Obese (Weight-for-Height > +1 SD or BMI > +2 SD)
    if ((weightForHeight != null && weightForHeight > 1) ||
        (bmi != null && bmi > 2)) {
      return 'Overweight/Obese';
    }

    // Priority 4: At Risk (any indicator -2 to -1 SD)
    final atRisk = (weightForAge != null &&
            weightForAge >= -2 &&
            weightForAge < -1) ||
        (heightForAge != null &&
            heightForAge >= -2 &&
            heightForAge < -1) ||
        (weightForHeight != null &&
            weightForHeight >= -2 &&
            weightForHeight < -1) ||
        (bmi != null && bmi >= -2 && bmi < -1);
    if (atRisk) {
      return 'At Risk';
    }

    // Priority 5: Normal
    return 'Normal';
  }

  Color _badgeFg(String c) {
    switch (c) {
      case 'Underweight':
      case 'Stunted':
        return _red;
      case 'Overweight/Obese':
      case 'At Risk':
        return _warning;
      case 'Normal':
      case 'Assessment done':
      default:
        return _greenText;
    }
  }

  Color _badgeBg(String c) {
    switch (c) {
      case 'Underweight':
      case 'Stunted':
        return _redBg;
      case 'Overweight/Obese':
      case 'At Risk':
        return _warningBg;
      case 'Normal':
      case 'Assessment done':
      default:
        return _greenBg;
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '--';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}';
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
        children: [
          // Accent bar
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_orangeLight, _orange],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(_r)),
            ),
          ),
          if (loading)
            _buildLoading()
          else ...[
            _buildHeader(),
            const Divider(height: 1, color: _border),
            if (assessments.isEmpty)
              _buildEmptyState()
            else ...[
              _buildColumnHeaders(),
              const SizedBox(height: 4),
              ...assessments.map(_buildTableRow),
              const SizedBox(height: 8),
            ],
            const Divider(height: 1, color: _border),
            _buildAddButton(),
          ],
        ],
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            _iconBox(Icons.bar_chart_rounded),
            const SizedBox(width: 12),
            const Text(
              'Assessment Records',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1E),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      );

  Widget _iconBox(IconData icon) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _orange.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _orange, size: 20),
      );

  Widget _buildLoading() => const Padding(
        padding: EdgeInsets.all(36),
        child: Center(child: CircularProgressIndicator(color: _orange)),
      );

  Widget _buildEmptyState() => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.assessment_outlined, size: 40, color: _orange.withOpacity(0.35)),
            const SizedBox(height: 12),
            const Text(
              'No assessments recorded yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6C6C70)),
            ),
          ],
        ),
      );

  // ─── Column headers ─────────────────────────────────────────────────────────

  Widget _buildColumnHeaders() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Row(
          children: [
            _colHeader('Date',   flex: 2),
            _colHeader('Height', flex: 2),
            _colHeader('Weight', flex: 2),
            _colHeader('MUAC',   flex: 2),
            _colHeader('Status', flex: 3),
          ],
        ),
      );

  Widget _colHeader(String text, {required int flex}) => Expanded(
        flex: flex,
        child: Text(
          text.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _inkMid,
            letterSpacing: 1.2,
          ),
        ),
      );

  // ─── Data row ───────────────────────────────────────────────────────────────

  Widget _buildTableRow(Map<String, dynamic> a) {
    final cls   = _getClassification(a);
    final date  = a['date'] as DateTime?;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: _surfaceDim,
        borderRadius: BorderRadius.circular(_ri),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(date),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _orange,
              ),
            ),
          ),
          _cell(a['height']?.toString() ?? '--', flex: 2),
          _cell(a['weight']?.toString() ?? '--', flex: 2),
          _cell(a['muac']?.toString()   ?? '--', flex: 2),
          Expanded(
            flex: 3,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _badgeBg(cls),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _badgeFg(cls).withOpacity(0.30),
                    width: 1,
                  ),
                ),
                child: Text(
                  cls,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: _badgeFg(cls),
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, {required int flex}) => Expanded(
        flex: flex,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _ink,
          ),
        ),
      );

  // ─── Add button ─────────────────────────────────────────────────────────────

  Widget _buildAddButton() => Padding(
        padding: const EdgeInsets.all(14),
        child: Center(
          child: GestureDetector(
            onTap: onAddAssessment,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_orangeLight, _orange],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _orange.withOpacity(0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Add New Assessment',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}