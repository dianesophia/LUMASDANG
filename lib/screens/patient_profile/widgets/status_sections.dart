import 'package:flutter/material.dart';

/// Widget displaying Health Status, Dietary Status, and Oral Status sections.
class StatusSections extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;

  const StatusSections({
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
  static const Color _green       = Color(0xFF34C759);
  static const Color _greenBg     = Color(0xFFEDF7F1);
  static const Color _greenText   = Color(0xFF1A7A3C);
  static const Color _red         = Color(0xFFDC2626);
  static const Color _redBg       = Color(0xFFFEF2F2);
  static const Color _amberBg     = Color(0xFFFFF6EE);

  static const double _r  = 18;
  static const double _ri = 12;
  static const double _sectionGap = 16;

  static List<BoxShadow> get _shadow => [
        BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 6)),
      ];

  // ─── Data helpers (all logic unchanged) ────────────────────────────────────

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
    return false;
  }

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
        return 'Feeding data incomplete';
      }
    }
    return 'No dietary data available';
  }

  bool _isDietaryPositive() {
    for (var i = assessments.length - 1; i >= 0; i--) {
      final dietary = assessments[i]['dietary'] as Map<String, dynamic>?;
      if (dietary != null) return dietary['purelyBreastfed'] != null;
    }
    return false;
  }

  String _getOralStatusSummary() {
    if (assessments.isEmpty) return 'No oral assessment data';
    for (var i = assessments.length - 1; i >= 0; i--) {
      final oral = assessments[i]['oral'] as Map<String, dynamic>?;
      if (oral != null) {
        final raw = oral['overallRisk']?.toString().trim() ?? '';
        if (raw.isNotEmpty) {
          final label = raw[0].toUpperCase() + raw.substring(1).toLowerCase();
          return '$label risk for caries';
        }
      }
    }
    return 'No oral assessment data';
  }

  bool _isOralPositive() {
    for (var i = assessments.length - 1; i >= 0; i--) {
      final oral = assessments[i]['oral'] as Map<String, dynamic>?;
      if (oral != null) {
        return oral['overallRisk']?.toString().trim().toLowerCase() == 'low';
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _orange, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: _border),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status summary tile
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _surfaceDim,
                    borderRadius: BorderRadius.circular(_ri),
                    border: Border.all(color: _border, width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isPositive ? _greenBg : _amberBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isPositive ? Icons.check_rounded : Icons.info_rounded,
                          size: 14,
                          color: isPositive ? _greenText : _orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: _ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Action button + count badge
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: dataCount > 0 ? onPressed : null,
                        child: AnimatedOpacity(
                          opacity: dataCount > 0 ? 1.0 : 0.40,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 11),
                            decoration: BoxDecoration(
                              gradient: dataCount > 0
                                  ? const LinearGradient(colors: [_orangeLight, _orange])
                                  : null,
                              color: dataCount > 0 ? null : _border,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: dataCount > 0
                                  ? [BoxShadow(color: _orange.withOpacity(0.28), blurRadius: 12, offset: const Offset(0, 4))]
                                  : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(buttonIcon, size: 15, color: Colors.white),
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
                            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                            decoration: BoxDecoration(
                              color: _orangeLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                '$dataCount',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
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
    return Column(
      children: [
        _buildCard(
          context: context,
          icon: Icons.favorite_rounded,
          title: 'Health Status',
          statusText: _getHealthStatusSummary(),
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
          statusText: _getDietaryStatusSummary(),
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
          statusText: _getOralStatusSummary(),
          buttonLabel: 'View Details',
          buttonIcon: Icons.info_outline_rounded,
          dataCount: _getOralDataCount(),
          isPositive: _isOralPositive(),
          onPressed: () => _showOralDetails(context),
        ),
      ],
    );
  }

  // ─── Bottom sheet launchers (unchanged) ─────────────────────────────────────

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

// ─── Shared bottom sheet shell ───────────────────────────────────────────────

class _SheetShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget body;

  const _SheetShell({
    required this.title,
    required this.icon,
    required this.body,
  });

  static const Color _orange      = Color(0xFFF08030);
  static const Color _orangeLight = Color(0xFFF5A962);
  static const Color _border      = Color(0xFFE8E8ED);
  static const Color _ink         = Color(0xFF1C1C1E);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.78),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 14, bottom: 20),
            decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _orange, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _border),
          Flexible(child: body),
        ],
      ),
    );
  }
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

String _formatDate(DateTime? date) {
  if (date == null) return 'Unknown date';
  return '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.year}';
}

Widget _buildDateLabel(DateTime? date) => Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF08030).withOpacity(0.10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.calendar_today_rounded, size: 11, color: Color(0xFFF08030)),
        ),
        const SizedBox(width: 7),
        Text(
          _formatDate(date),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF08030),
          ),
        ),
      ],
    );

Widget _buildBullet(String text, {bool bold = false, Color? color}) => Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5, height: 5,
            margin: const EdgeInsets.only(top: 5, right: 8),
            decoration: BoxDecoration(
              color: color ?? const Color(0xFF6C6C70),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color ?? const Color(0xFF1C1C1E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );

Widget _buildSubItem(String text) => Padding(
      padding: const EdgeInsets.only(top: 4, left: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('– ', style: TextStyle(fontSize: 12, color: Color(0xFF6C6C70))),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6C6C70),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );

// ─── Health History Sheet ─────────────────────────────────────────────────────

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
              separatorBuilder: (_, __) => const Divider(height: 28, color: Color(0xFFE8E8ED)),
              itemBuilder: (_, i) {
                final a           = filtered[i];
                final hs          = a['healthStatus'] as Map<String, dynamic>;
                final diarrhea    = hs['diarrhea'] == true;
                final fever       = hs['fever'] == true;
                final cough       = hs['cough'] == true;
                final other       = hs['other'] == true;
                final medications = hs['medications'] == true;
                final noIllness   = !diarrhea && !fever && !cough && !other;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateLabel(a['date'] as DateTime?),
                    const SizedBox(height: 8),
                    if (noIllness)
                      _buildBullet('No current illness', color: const Color(0xFF1A7A3C))
                    else ...[
                      if (diarrhea) _buildBullet('Diarrhea'),
                      if (fever)    _buildBullet('Fever'),
                      if (cough)    _buildBullet('Cough'),
                      if (other)    _buildBullet('Other illness'),
                    ],
                    if (medications)
                      _buildBullet('Currently on medications', bold: true, color: const Color(0xFFF08030)),
                  ],
                );
              },
            ),
    );
  }
}

// ─── Dietary Details Sheet ────────────────────────────────────────────────────

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
              separatorBuilder: (_, __) => const Divider(height: 28, color: Color(0xFFE8E8ED)),
              itemBuilder: (_, i) {
                final a        = filtered[i];
                final dietary  = a['dietary'] as Map<String, dynamic>;
                final purelyBF = dietary['purelyBreastfed'];
                final cfAge    = dietary['cfAge']?.toString() ?? '';
                final cfFreq   = dietary['cfFrequency']?.toString() ?? '';
                final cfFoods  = dietary['cfFoods']?.toString() ?? '';
                final mealFreq = dietary['mealFrequency']?.toString() ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateLabel(a['date'] as DateTime?),
                    const SizedBox(height: 8),
                    if (purelyBF == true)
                      _buildBullet('Purely breastfed', color: const Color(0xFF1A7A3C))
                    else if (purelyBF == false) ...[
                      _buildBullet('Complementary feeding', bold: true),
                      if (cfAge.isNotEmpty)    _buildSubItem('Started at: $cfAge months'),
                      if (cfFreq.isNotEmpty)   _buildSubItem('Frequency: $cfFreq times/day'),
                      if (cfFoods.isNotEmpty)  _buildSubItem('Foods: $cfFoods'),
                      if (mealFreq.isNotEmpty) _buildSubItem('Meal frequency: $mealFreq times/day'),
                    ] else
                      _buildBullet('No breastfeeding information', color: const Color(0xFF6C6C70)),
                  ],
                );
              },
            ),
    );
  }
}

// ─── Oral Details Sheet ───────────────────────────────────────────────────────

class _OralDetailsSheet extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;
  const _OralDetailsSheet({required this.assessments});

  Color _riskFg(String risk) {
    switch (risk.trim().toLowerCase()) {
      case 'high':     return const Color(0xFFDC2626);
      case 'moderate': return const Color(0xFFF08030);
      case 'low':      return const Color(0xFF1A7A3C);
      default:         return const Color(0xFF6C6C70);
    }
  }

  Color _riskBg(String risk) {
    switch (risk.trim().toLowerCase()) {
      case 'high':     return const Color(0xFFFEF2F2);
      case 'moderate': return const Color(0xFFFFF6EE);
      case 'low':      return const Color(0xFFEDF7F1);
      default:         return const Color(0xFFF5F5F7);
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
              separatorBuilder: (_, __) => const Divider(height: 28, color: Color(0xFFE8E8ED)),
              itemBuilder: (_, i) {
                final a    = filtered[i];
                final oral = a['oral'] as Map<String, dynamic>;
                final risk = oral['overallRisk']?.toString() ?? '';
                final fg   = _riskFg(risk);
                final bg   = _riskBg(risk);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateLabel(a['date'] as DateTime?),
                    const SizedBox(height: 8),
                    if (risk.isNotEmpty)
                      Row(
                        children: [
                          const Text(
                            '• Overall Risk: ',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1C1C1E)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: fg.withOpacity(0.35), width: 1),
                            ),
                            child: Text(
                              risk,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg),
                            ),
                          ),
                        ],
                      )
                    else
                      _buildBullet('No risk assessment available', color: const Color(0xFF6C6C70)),
                  ],
                );
              },
            ),
    );
  }
}

// ─── Shared empty state ───────────────────────────────────────────────────────

Widget _buildEmpty(String message) => Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.info_outline_rounded, size: 40, color: const Color(0xFFF08030).withOpacity(0.35)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6C6C70)),
          ),
        ],
      ),
    );