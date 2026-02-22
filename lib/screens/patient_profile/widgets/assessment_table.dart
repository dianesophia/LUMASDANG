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

  // ─── Design tokens (identical to other health cards) ───────────────────────
  static const Color _cardBg        = Color(0xFFB8E6D5);
  static const Color _headerBg      = Color(0xFFD4F1E3);
  static const Color _accentTeal    = Color(0xFF2E8B7B);
  static const Color _positiveGreen = Color(0xFF27AE60);
  static const Color _warningOrange = Color(0xFFE65100);
  static const Color _dividerColor  = Color(0xFFA0D8C5);

  static const double _cardRadius  = 20;
  static const double _innerRadius = 12;
  static const double _pillRadius  = 30;
  static const double _iconRadius  = 10;

  static List<BoxShadow> get _cardShadow => [
    BoxShadow(
      color: _accentTeal.withOpacity(0.18),
      blurRadius: 16,
      spreadRadius: 1,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.6),
      blurRadius: 1,
      offset: const Offset(0, -1),
    ),
  ];

  static const TextStyle _headerTitleStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: Colors.black87,
    letterSpacing: 0.3,
  );

  static const TextStyle _sectionLabelStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: _accentTeal,
    letterSpacing: 1.4,
  );

  // ─── Classification logic (unchanged) ──────────────────────────────────────

  String _getClassification(Map<String, dynamic> assessment) {
    final wfa = assessment['weightForAge']?.toString().toLowerCase() ?? '';
    final hfa = assessment['heightForAge']?.toString().toLowerCase() ?? '';
    final wfh = assessment['weightForHeight']?.toString().toLowerCase() ?? '';
    if (wfa.contains('severely') ||
        hfa.contains('severely') ||
        wfh.contains('severely')) return 'Severely Underweight';
    if (wfa.contains('underweight') ||
        hfa.contains('stunted') ||
        wfh.contains('wasted')) return 'At Risk';
    if (wfa.contains('overweight') || wfh.contains('overweight')) {
      return 'Overweight';
    }
    if (wfa.contains('normal') || wfa.isEmpty) return 'Normal';
    return 'Normal';
  }

  Color _badgeColor(String classification) {
    switch (classification.toLowerCase()) {
      case 'severely underweight':
        return const Color(0xFFDC2626);
      case 'at risk':
        return _warningOrange;
      case 'overweight':
        return _warningOrange;
      case 'normal':
        return _positiveGreen;
      default:
        return Colors.black38;
    }
  }

  String _formatDateShort(DateTime? date) {
    if (date == null) return '--';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: _cardShadow,
      ),
      clipBehavior: Clip.hardEdge,
      child: loading
          ? _buildLoading()
          : Column(
              children: [
                _buildHeader(),
                Container(
                  height: 1,
                  color: _accentTeal.withOpacity(0.25),
                ),
                if (assessments.isEmpty)
                  _buildEmptyState()
                else ...[
                  const SizedBox(height: 6),
                  ...assessments.map(_buildTableRow),
                  const SizedBox(height: 6),
                ],
                Container(height: 1, color: _dividerColor.withOpacity(0.6)),
                _buildAddButton(),
              ],
            ),
    );
  }

  // ─── Structural widgets ─────────────────────────────────────────────────────

  Widget _buildHeader() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: _headerBg,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(_cardRadius)),
        ),
        child: Row(
          children: [
            _buildIconBox(Icons.bar_chart_rounded),
            const SizedBox(width: 12),
            const Text('Assessment Records', style: _headerTitleStyle),
          ],
        ),
      );

  Widget _buildIconBox(IconData icon) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _accentTeal.withOpacity(0.15),
          borderRadius: BorderRadius.circular(_iconRadius),
        ),
        child: Icon(icon, color: _accentTeal, size: 22),
      );

  Widget _buildLoading() => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: _accentTeal),
        ),
      );

  Widget _buildEmptyState() => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.assessment_outlined,
                size: 40, color: _accentTeal.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text(
              'No assessments recorded yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );

  // ─── Column header row ──────────────────────────────────────────────────────

  Widget _buildColumnHeaders() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _colHeader('Date', flex: 2),
              _colHeader('Height', flex: 2),
              _colHeader('Weight', flex: 2),
              _colHeader('MUAC', flex: 2),
              _colHeader('Status', flex: 3),
            ],
          ),
        ),
      );

  Widget _colHeader(String text, {required int flex}) => Expanded(
        flex: flex,
        child: Text(
          text.toUpperCase(),
          textAlign: TextAlign.center,
          style: _sectionLabelStyle,
        ),
      );

  // ─── Data row ───────────────────────────────────────────────────────────────

  Widget _buildTableRow(Map<String, dynamic> assessment) {
    final classification = _getClassification(assessment);
    final badgeColor     = _badgeColor(classification);
    final date           = assessment['date'] as DateTime?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.45),
        borderRadius: BorderRadius.circular(_innerRadius),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
      ),
      child: Row(
        children: [
          // Date
          Expanded(
            flex: 2,
            child: Text(
              _formatDateShort(date),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _accentTeal,
              ),
            ),
          ),
          _dataCell(assessment['height']?.toString() ?? '--', flex: 2),
          _dataCell(assessment['weight']?.toString() ?? '--', flex: 2),
          _dataCell(assessment['muac']?.toString() ?? '--', flex: 2),
          // Badge
          Expanded(
            flex: 3,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: badgeColor.withOpacity(0.45),
                    width: 1,
                  ),
                ),
                child: Text(
                  classification,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataCell(String text, {required int flex}) => Expanded(
        flex: flex,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2A4F47),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
              decoration: BoxDecoration(
                color: _accentTeal,
                borderRadius: BorderRadius.circular(_pillRadius),
                boxShadow: [
                  BoxShadow(
                    color: _accentTeal.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      size: 16, color: Colors.white),
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