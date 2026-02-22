import 'package:flutter/material.dart';

/// Widget displaying the Deworming Status card in the patient profile.
/// Shows medication given, dosage, deworming recency, and health outcomes.
class DewormingStatusSection extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;

  const DewormingStatusSection({
    super.key,
    required this.assessments,
  });

  // ─── Design tokens ──────────────────────────────────────────────────────────
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
  static const double _bodyPadH    = 16;
  static const double _bodyPadV    = 20;
  static const double _sectionGap  = 16;

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

  static const TextStyle _pillTextStyle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: _accentTeal,
    letterSpacing: 0.2,
  );

  static const TextStyle _detailLabelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Colors.black45,
    letterSpacing: 0.3,
  );

  static const TextStyle _detailValueStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.black87,
  );

  // ─── Data helpers ───────────────────────────────────────────────────────────

  Map<String, dynamic>? _getLatestDeworming() {
    if (assessments.isEmpty) return null;
    for (var i = assessments.length - 1; i >= 0; i--) {
      final a = assessments[i];
      final deworming = a['deworming'] as Map<String, dynamic>?;
      if (deworming != null) return a;
    }
    return null;
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      final parts = dateStr.split(RegExp(r'[-/]'));
      if (parts.length == 3) {
        final month = int.tryParse(parts[0]);
        final day   = int.tryParse(parts[1]);
        final year  = int.tryParse(parts[2]);
        if (month != null && day != null && year != null) {
          return DateTime(year, month, day);
        }
      }
      return DateTime.tryParse(dateStr);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  bool _isDewormingRecent(DateTime? dewormDate) {
    if (dewormDate == null) return false;
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 183));
    return dewormDate.isAfter(sixMonthsAgo);
  }

  String _getDosageDescription(String? drugGiven) {
    if (drugGiven == null || drugGiven.isEmpty) return '';
    return 'Age-appropriate single dose';
  }

  String _getWeightOutcome() {
    if (assessments.length < 2) return 'Good appetite and weight maintenance';
    final latestWeight = double.tryParse(
        assessments.last['weight']?.toString().trim() ?? '');
    final prevWeight = double.tryParse(
        assessments[assessments.length - 2]['weight']?.toString().trim() ?? '');
    if (latestWeight != null && prevWeight != null) {
      return latestWeight >= prevWeight
          ? 'Good appetite and weight maintenance'
          : 'Slight weight decrease – monitor appetite';
    }
    return 'Good appetite and weight maintenance';
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final latest = _getLatestDeworming();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (latest == null) _buildEmptyState() else _buildContent(latest),
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
            _buildIconBox(Icons.medication_liquid_rounded),
            const SizedBox(width: 12),
            const Text('Deworming Status', style: _headerTitleStyle),
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

  Widget _buildEmptyState() => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.info_outline_rounded,
                size: 40, color: _accentTeal.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text(
              'No deworming data available yet.',
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

  Widget _buildDatePill(String label) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _accentTeal.withOpacity(0.12),
            borderRadius: BorderRadius.circular(_pillRadius),
            border: Border.all(color: _accentTeal.withOpacity(0.25), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 13, color: _accentTeal),
              const SizedBox(width: 6),
              Text(label, style: _pillTextStyle),
            ],
          ),
        ),
      );

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.45),
          borderRadius: BorderRadius.circular(_innerRadius),
          border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _accentTeal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: _accentTeal),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _detailLabelStyle),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: _detailValueStyle.copyWith(
                      color: valueColor ?? Colors.black87),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildOutcomeRow({
    required IconData icon,
    required String text,
    required bool isPositive,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 18,
              color: isPositive ? _positiveGreen : _warningOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: isPositive
                    ? Colors.black.withOpacity(0.75)
                    : _warningOrange,
              ),
            ),
          ),
        ],
      );

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      Center(
        child: GestureDetector(
          onTap: onTap,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
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
      );

  // ─── Content ────────────────────────────────────────────────────────────────

  Widget _buildContent(Map<String, dynamic> latest) {
    final deworming        = latest['deworming'] as Map<String, dynamic>;
    final isNA             = deworming['isNA'] == true;
    final drugGiven        = deworming['drugGiven']?.toString() ?? '';
    final dateStr          = deworming['dateOfLastDeworming']?.toString() ?? '';
    final adverseReactions = deworming['adverseReactions']?.toString() ?? '';
    final dewormDate       = _parseDate(dateStr);
    final isRecent         = _isDewormingRecent(dewormDate);
    final dosage           = _getDosageDescription(drugGiven);

    return Padding(
      padding: const EdgeInsets.fromLTRB(_bodyPadH, 4, _bodyPadH, _bodyPadV),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDatePill('Last Deworming: ${_formatDate(dewormDate)}'),
          const SizedBox(height: _sectionGap),

          if (!isNA) ...[
            if (drugGiven.isNotEmpty) ...[
              _buildDetailCard(
                icon: Icons.vaccines_rounded,
                label: 'Medication Given',
                value: drugGiven,
              ),
              const SizedBox(height: 10),
            ],
            if (dosage.isNotEmpty) ...[
              _buildDetailCard(
                icon: Icons.colorize_rounded,
                label: 'Dosage',
                value: dosage,
              ),
              const SizedBox(height: _sectionGap),
            ],
          ],

          if (isNA) ...[
            _buildDetailCard(
              icon: Icons.block_rounded,
              label: 'Status',
              value: 'Not Applicable',
              valueColor: _accentTeal,
            ),
            const SizedBox(height: _sectionGap),
          ],

          if (!isNA) ...[
            const Divider(color: _dividerColor, thickness: 1.2),
            const SizedBox(height: 12),
            const Text('HEALTH OUTCOMES', style: _sectionLabelStyle),
            const SizedBox(height: 10),
            _buildOutcomeRow(
              icon: Icons.schedule_rounded,
              text: isRecent
                  ? 'Dewormed within last 6 months'
                  : 'Last deworming was more than 6 months ago',
              isPositive: isRecent,
            ),
            const SizedBox(height: 8),
            _buildOutcomeRow(
              icon: adverseReactions.isEmpty
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              text: adverseReactions.isEmpty
                  ? 'No symptoms of intestinal worms'
                  : 'Adverse reactions: $adverseReactions',
              isPositive: adverseReactions.isEmpty,
            ),
            const SizedBox(height: 8),
            _buildOutcomeRow(
              icon: Icons.monitor_weight_rounded,
              text: _getWeightOutcome(),
              isPositive: !_getWeightOutcome().contains('decrease'),
            ),
          ],
        ],
      ),
    );
  }
}