import 'package:flutter/material.dart';

/// Widget displaying Health Status, Dietary Status, and Oral Status sections.
class StatusSections extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;

  const StatusSections({
    super.key,
    required this.assessments,
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

  // ─── Data helpers ───────────────────────────────────────────────────────────

  /// Returns a summary of the most recent health status entry.
  /// Illnesses and medication status are reported separately so "on medications"
  /// is never conflated with active illness labels.
  String _getHealthStatusSummary() {
    if (assessments.isEmpty) return 'No health data available';
    for (var i = assessments.length - 1; i >= 0; i--) {
      final hs = assessments[i]['healthStatus'] as Map<String, dynamic>?;
      if (hs != null) {
        final illnesses = <String>[
          if (hs['diarrhea'] == true) 'Diarrhea',
          if (hs['fever'] == true) 'Fever',
          if (hs['cough'] == true) 'Cough',
          if (hs['other'] == true) 'Other illness',
        ];
        final onMeds = hs['medications'] == true;

        if (illnesses.isEmpty && !onMeds) return 'No current illness';
        if (illnesses.isEmpty && onMeds)  return 'No illness · On medications';

        final base = illnesses.join(', ');
        return onMeds ? '$base · On medications' : base;
      }
    }
    return 'No health data available';
  }

  /// Returns true only when the most recent health record shows no illness
  /// AND the patient is not on medications.
  bool _isHealthPositive() {
    for (var i = assessments.length - 1; i >= 0; i--) {
      final hs = assessments[i]['healthStatus'] as Map<String, dynamic>?;
      if (hs != null) {
        return hs['diarrhea'] != true &&
            hs['fever'] != true &&
            hs['cough'] != true &&
            hs['other'] != true &&
            hs['medications'] != true;
      }
    }
    return false; // no data → not definitively positive
  }

  /// Returns a summary of the most recent dietary entry.
  String _getDietaryStatusSummary() {
    if (assessments.isEmpty) return 'No dietary data available';
    for (var i = assessments.length - 1; i >= 0; i--) {
      final dietary = assessments[i]['dietary'] as Map<String, dynamic>?;
      if (dietary != null) {
        if (dietary['purelyBreastfed'] == true) return 'Purely breastfed';
        if (dietary['purelyBreastfed'] == false) {
          final cfAge    = dietary['cfAge']?.toString().trim() ?? '';
          final mealFreq = dietary['mealFrequency']?.toString().trim() ?? '';
          final parts = <String>[
            if (cfAge.isNotEmpty)    'CF started at $cfAge months',
            if (mealFreq.isNotEmpty) '$mealFreq meals/day',
          ];
          return parts.isEmpty ? 'Complementary feeding' : parts.join(', ');
        }
        // purelyBreastfed is null / not set
        return 'Feeding data incomplete';
      }
    }
    return 'No dietary data available';
  }

  /// Returns true when dietary data exists and is not a "no data" placeholder.
  bool _isDietaryPositive() {
    for (var i = assessments.length - 1; i >= 0; i--) {
      final dietary = assessments[i]['dietary'] as Map<String, dynamic>?;
      if (dietary != null) {
        // Any recorded dietary entry is considered informative / positive
        return dietary['purelyBreastfed'] != null;
      }
    }
    return false;
  }

  /// Returns a summary of the most recent oral risk entry.
  /// Capitalises the risk level for consistent display.
  String _getOralStatusSummary() {
    if (assessments.isEmpty) return 'No oral assessment data';
    for (var i = assessments.length - 1; i >= 0; i--) {
      final oral = assessments[i]['oral'] as Map<String, dynamic>?;
      if (oral != null) {
        final raw = oral['overallRisk']?.toString().trim() ?? '';
        if (raw.isNotEmpty) {
          // Capitalise first letter for display consistency
          final label =
              raw[0].toUpperCase() + raw.substring(1).toLowerCase();
          return '$label risk for caries';
        }
      }
    }
    return 'No oral assessment data';
  }

  /// Low risk = good (shown as positive / green icon).
  /// Moderate or High risk = warning icon.
  /// No data = neutral (warning icon, no false reassurance).
  bool _isOralPositive() {
    for (var i = assessments.length - 1; i >= 0; i--) {
      final oral = assessments[i]['oral'] as Map<String, dynamic>?;
      if (oral != null) {
        final risk = oral['overallRisk']?.toString().trim().toLowerCase() ?? '';
        return risk == 'low';
      }
    }
    return false;
  }

  int _getHealthHistoryCount() =>
      assessments.where((a) => a['healthStatus'] != null).length;

  int _getDietaryDataCount() =>
      assessments.where((a) => a['dietary'] != null).length;

  int _getOralDataCount() =>
      assessments.where((a) => a['oral'] != null).length;

  // ─── Shared card builder ────────────────────────────────────────────────────

  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String statusText,
    required String buttonLabel,
    required IconData buttonIcon,
    required int dataCount,
    required bool isPositive,
    required VoidCallback onPressed,
  }) {
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
          // ── Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: _headerBg,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(_cardRadius)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accentTeal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(_iconRadius),
                  ),
                  child: Icon(icon, color: _accentTeal, size: 22),
                ),
                const SizedBox(width: 12),
                Text(title, style: _headerTitleStyle),
              ],
            ),
          ),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
                _bodyPadH, 4, _bodyPadH, _bodyPadV),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Status summary inside frosted surface card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(_innerRadius),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.7), width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.check_circle_rounded
                            : Icons.info_rounded,
                        size: 18,
                        color: isPositive ? _positiveGreen : _warningOrange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: Colors.black.withOpacity(0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: _sectionGap),

                // Action button + count badge
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: dataCount > 0 ? onPressed : null,
                        child: AnimatedOpacity(
                          opacity: dataCount > 0 ? 1.0 : 0.45,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 11),
                            decoration: BoxDecoration(
                              color: _accentTeal,
                              borderRadius:
                                  BorderRadius.circular(_pillRadius),
                              boxShadow: dataCount > 0
                                  ? [
                                      BoxShadow(
                                        color:
                                            _accentTeal.withOpacity(0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(buttonIcon,
                                    size: 16, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  buttonLabel,
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
                      ),
                      if (dataCount > 0)
                        Positioned(
                          right: -8,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                                minWidth: 20, minHeight: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5A962),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                '$dataCount',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final healthSummary  = _getHealthStatusSummary();
    final dietarySummary = _getDietaryStatusSummary();
    final oralSummary    = _getOralStatusSummary();

    return Column(
      children: [
        _buildCard(
          context: context,
          icon: Icons.favorite_rounded,
          title: 'Health Status',
          statusText: healthSummary,
          buttonLabel: 'View History',
          buttonIcon: Icons.history_rounded,
          dataCount: _getHealthHistoryCount(),
          isPositive: _isHealthPositive(),
          onPressed: () => _showHealthHistory(context),
        ),
        const SizedBox(height: _sectionGap),
        _buildCard(
          context: context,
          icon: Icons.restaurant_rounded,
          title: 'Dietary Status',
          statusText: dietarySummary,
          buttonLabel: 'View Details',
          buttonIcon: Icons.info_outline_rounded,
          dataCount: _getDietaryDataCount(),
          isPositive: _isDietaryPositive(),
          onPressed: () => _showDietaryDetails(context),
        ),
        const SizedBox(height: _sectionGap),
        _buildCard(
          context: context,
          icon: Icons.sentiment_satisfied_rounded,
          title: 'Oral Status',
          statusText: oralSummary,
          buttonLabel: 'View Details',
          buttonIcon: Icons.info_outline_rounded,
          dataCount: _getOralDataCount(),
          isPositive: _isOralPositive(),
          onPressed: () => _showOralDetails(context),
        ),
      ],
    );
  }

  // ─── Bottom sheet launchers ─────────────────────────────────────────────────

  void _showHealthHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HealthHistorySheet(assessments: assessments),
    );
  }

  void _showDietaryDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DietaryDetailsSheet(assessments: assessments),
    );
  }

  void _showOralDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OralDetailsSheet(assessments: assessments),
    );
  }
}

// ─── Shared bottom sheet shell ──────────────────────────────────────────────

class _SheetShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget body;

  const _SheetShell({
    required this.title,
    required this.icon,
    required this.body,
  });

  static const Color _accentTeal = Color(0xFF2E8B7B);
  static const double _iconRadius = 10.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.78),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 14, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _accentTeal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(_iconRadius),
                  ),
                  child: Icon(icon, color: _accentTeal, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _accentTeal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Flexible(child: body),
        ],
      ),
    );
  }
}

// ─── Shared date label ──────────────────────────────────────────────────────

String _formatDate(DateTime? date) {
  if (date == null) return 'Unknown date';
  return '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.year}';
}

Widget _buildDateLabel(DateTime? date) => Text(
      _formatDate(date),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF2E8B7B),
      ),
    );

Widget _buildBullet(String text, {bool bold = false, Color? color}) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color ?? Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );

/// Indented sub-item used for complementary feeding details.
Widget _buildSubItem(String text) => Padding(
      padding: const EdgeInsets.only(top: 3, left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('– ',
              style: TextStyle(fontSize: 12, color: Colors.black38)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );

// ─── Health History Sheet ───────────────────────────────────────────────────

class _HealthHistorySheet extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;

  const _HealthHistorySheet({required this.assessments});

  @override
  Widget build(BuildContext context) {
    final filtered = assessments
        .where((a) => a['healthStatus'] != null)
        .toList()
        .reversed
        .toList();

    return _SheetShell(
      icon: Icons.favorite_rounded,
      title: 'Health Status History',
      body: filtered.isEmpty
          ? _buildEmpty('No health status data available')
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 28, color: Color(0xFFEEEEEE)),
              itemBuilder: (_, i) {
                final a            = filtered[i];
                final hs           = a['healthStatus'] as Map<String, dynamic>;
                final diarrhea     = hs['diarrhea'] == true;
                final fever        = hs['fever'] == true;
                final cough        = hs['cough'] == true;
                final other        = hs['other'] == true;
                final medications  = hs['medications'] == true;
                final noIllness    = !diarrhea && !fever && !cough && !other;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateLabel(a['date'] as DateTime?),
                    const SizedBox(height: 6),
                    if (noIllness)
                      _buildBullet('No current illness',
                          color: const Color(0xFF27AE60))
                    else ...[
                      if (diarrhea) _buildBullet('Diarrhea'),
                      if (fever) _buildBullet('Fever'),
                      if (cough) _buildBullet('Cough'),
                      if (other) _buildBullet('Other illness'),
                    ],
                    if (medications)
                      _buildBullet('Currently on medications',
                          bold: true,
                          color: const Color(0xFFE65100)),
                  ],
                );
              },
            ),
    );
  }
}

// ─── Dietary Details Sheet ──────────────────────────────────────────────────

class _DietaryDetailsSheet extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;

  const _DietaryDetailsSheet({required this.assessments});

  @override
  Widget build(BuildContext context) {
    final filtered = assessments
        .where((a) => a['dietary'] != null)
        .toList()
        .reversed
        .toList();

    return _SheetShell(
      icon: Icons.restaurant_rounded,
      title: 'Dietary Status Details',
      body: filtered.isEmpty
          ? _buildEmpty('No dietary data available')
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 28, color: Color(0xFFEEEEEE)),
              itemBuilder: (_, i) {
                final a             = filtered[i];
                final dietary       = a['dietary'] as Map<String, dynamic>;
                final purelyBF      = dietary['purelyBreastfed'];
                final cfAge         = dietary['cfAge']?.toString() ?? '';
                final cfFreq        = dietary['cfFrequency']?.toString() ?? '';
                final cfFoods       = dietary['cfFoods']?.toString() ?? '';
                final mealFreq      = dietary['mealFrequency']?.toString() ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateLabel(a['date'] as DateTime?),
                    const SizedBox(height: 6),
                    if (purelyBF == true)
                      _buildBullet('Purely breastfed',
                          color: const Color(0xFF27AE60))
                    else if (purelyBF == false) ...[
                      _buildBullet('Complementary feeding', bold: true),
                      if (cfAge.isNotEmpty)
                        _buildSubItem('Started at: $cfAge months'),
                      if (cfFreq.isNotEmpty)
                        _buildSubItem('Frequency: $cfFreq times/day'),
                      if (cfFoods.isNotEmpty)
                        _buildSubItem('Foods: $cfFoods'),
                      if (mealFreq.isNotEmpty)
                        _buildSubItem('Meal frequency: $mealFreq times/day'),
                    ] else
                      _buildBullet('No breastfeeding information',
                          color: Colors.grey),
                  ],
                );
              },
            ),
    );
  }
}

// ─── Oral Details Sheet ─────────────────────────────────────────────────────

class _OralDetailsSheet extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;

  const _OralDetailsSheet({required this.assessments});

  Color _riskColor(String risk) {
    switch (risk.trim().toLowerCase()) {
      case 'high':     return const Color(0xFFDC2626); // red
      case 'moderate': return const Color(0xFFE65100); // deep orange
      case 'low':      return const Color(0xFFF59E0B); // amber — low risk but still monitor
      default:         return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = assessments
        .where((a) => a['oral'] != null)
        .toList()
        .reversed
        .toList();

    return _SheetShell(
      icon: Icons.sentiment_satisfied_rounded,
      title: 'Oral Status Details',
      body: filtered.isEmpty
          ? _buildEmpty('No oral assessment data available')
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 28, color: Color(0xFFEEEEEE)),
              itemBuilder: (_, i) {
                final a    = filtered[i];
                final oral = a['oral'] as Map<String, dynamic>;
                final risk = oral['overallRisk']?.toString() ?? '';
                final color = _riskColor(risk);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateLabel(a['date'] as DateTime?),
                    const SizedBox(height: 6),
                    if (risk.isNotEmpty)
                      Row(
                        children: [
                          const Text(
                            '• Overall Risk: ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: color.withOpacity(0.4), width: 1),
                            ),
                            child: Text(
                              risk,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      _buildBullet('No risk assessment available',
                          color: Colors.grey),
                  ],
                );
              },
            ),
    );
  }
}

// ─── Shared empty state ─────────────────────────────────────────────────────

Widget _buildEmpty(String message) => Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 40, color: const Color(0xFF2E8B7B).withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );