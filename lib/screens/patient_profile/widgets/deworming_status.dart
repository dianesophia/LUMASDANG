import 'package:flutter/material.dart';

/// Widget displaying the Deworming Status card in the patient profile.
/// Styled to match ProfileInfoCard — white surface, orange gradient accent.
class DewormingStatusSection extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;
  /// When set, an Edit button is shown in the header; tap opens the edit flow.
  final VoidCallback? onEditTap;

  const DewormingStatusSection({
    super.key,
    required this.assessments,
    this.onEditTap,
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
  static const Color _warning     = Color(0xFFF08030);
  static const Color _warningBg   = Color(0xFFFFF6EE);

  static const double _r  = 18;
  static const double _ri = 12;

  static List<BoxShadow> get _shadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  // ─── Data helpers ───────────────────────────────────────────────────────────

  Map<String, dynamic>? _getLatestDeworming() {
    for (var i = assessments.length - 1; i >= 0; i--) {
      if (assessments[i]['deworming'] != null) return assessments[i];
    }
    return null;
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    try {
      final parts = s.split(RegExp(r'[-/]'));
      if (parts.length == 3) {
        final mo = int.tryParse(parts[0]);
        final d  = int.tryParse(parts[1]);
        final y  = int.tryParse(parts[2]);
        if (mo != null && d != null && y != null) return DateTime(y, mo, d);
      }
      return DateTime.tryParse(s);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'N/A';
    const m = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December',
    ];
    return '${m[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
  }

  bool _isRecent(DateTime? d) {
    if (d == null) return false;
    return d.isAfter(DateTime.now().subtract(const Duration(days: 183)));
  }

  String _weightOutcome() {
    if (assessments.length < 2) return 'Good appetite and weight maintenance';
    final last = double.tryParse(assessments.last['weight']?.toString().trim() ?? '');
    final prev = double.tryParse(
        assessments[assessments.length - 2]['weight']?.toString().trim() ?? '');
    if (last != null && prev != null && last < prev) {
      return 'Slight weight decrease – monitor appetite';
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
              gradient: const LinearGradient(
                colors: [_orangeLight, _orange],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(_r)),
            ),
          ),
          _buildHeader(),
          const Divider(height: 1, color: _border),
          if (latest == null) _buildEmptyState() else _buildContent(latest),
        ],
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            _iconBox(Icons.medication_liquid_rounded),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Deworming Status',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            if (onEditTap != null)
              IconButton(
                onPressed: onEditTap,
                icon: const Icon(Icons.edit_outlined, color: _orange, size: 22),
                tooltip: 'Edit deworming status',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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

  Widget _buildEmptyState() => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.info_outline_rounded,
                size: 40, color: _orange.withOpacity(0.35)),
            const SizedBox(height: 12),
            const Text(
              'No deworming data available yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _inkMid),
            ),
          ],
        ),
      );

  // ─── Content ────────────────────────────────────────────────────────────────

  Widget _buildContent(Map<String, dynamic> latest) {
    final rawDeworming = latest['deworming'];
    final Map<String, dynamic> deworming = rawDeworming is Map<String, dynamic>
        ? rawDeworming
        : Map<String, dynamic>.from(rawDeworming as Map);
    final isNA        = deworming['isNA'] == true;
    final drugGiven   = deworming['drugGiven']?.toString() ?? '';
    final dateStr     = deworming['dateOfLastDeworming']?.toString() ?? '';
    final nextDateStr = deworming['nextDewormingDate']?.toString() ?? '';
    final adverse     = deworming['adverseReactions']?.toString() ?? '';
    final dewormDate  = _parseDate(dateStr);
    final nextDewormDate = _parseDate(nextDateStr);
    final recent      = _isRecent(dewormDate);
    final weightNote  = _weightOutcome();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _datePill('Last Deworming: ${_formatDate(dewormDate)}'),
          if (nextDateStr.isNotEmpty || nextDewormDate != null) ...[
            const SizedBox(height: 8),
            _datePill('Next Deworming: ${_formatDate(nextDewormDate)}'),
          ],
          const SizedBox(height: 14),

          if (!isNA) ...[
            if (drugGiven.isNotEmpty) ...[
              _infoTile(
                icon: Icons.vaccines_rounded,
                label: 'Medication Given',
                value: drugGiven,
              ),
              const SizedBox(height: 10),
              _infoTile(
                icon: Icons.colorize_rounded,
                label: 'Dosage',
                value: 'Age-appropriate single dose',
              ),
              const SizedBox(height: 16),
            ],
          ],

          if (isNA) ...[
            _infoTile(
              icon: Icons.block_rounded,
              label: 'Status',
              value: 'Not Applicable',
            ),
            const SizedBox(height: 16),
          ],

          if (!isNA) ...[
            const Divider(height: 1, color: _border),
            const SizedBox(height: 14),
            const Text(
              'HEALTH OUTCOMES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _inkMid,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            _outcomeRow(
              icon: Icons.schedule_rounded,
              text: recent
                  ? 'Dewormed within the last 6 months'
                  : 'Last deworming was more than 6 months ago',
              positive: recent,
            ),
            const SizedBox(height: 8),
            _outcomeRow(
              icon: adverse.isEmpty
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              text: adverse.isEmpty
                  ? 'No symptoms of intestinal worms'
                  : 'Adverse reactions: $adverse',
              positive: adverse.isEmpty,
            ),
            const SizedBox(height: 8),
            _outcomeRow(
              icon: Icons.monitor_weight_rounded,
              text: weightNote,
              positive: !weightNote.contains('decrease'),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _datePill(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _orange.withOpacity(0.20), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_rounded, size: 13, color: _orange),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _orange,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      );

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) =>
      Container(
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: _orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: _inkMid,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.isNotEmpty ? value : 'N/A',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _outcomeRow({
    required IconData icon,
    required String text,
    required bool positive,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: positive ? _greenBg : _warningBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 14,
              color: positive ? _greenText : _warning,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: positive ? _ink : _warning,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      );
}