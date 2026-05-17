import 'package:flutter/material.dart';

/// Overall Nutritional Status summary card — styled to match ProfileInfoCard.
class OverallNutritionalStatusSection extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;

  const OverallNutritionalStatusSection({
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
  static const Color _greenBg     = Color(0xFFEDF7F1);
  static const Color _greenText   = Color(0xFF1A7A3C);
  static const Color _red         = Color(0xFFDC2626);
  static const Color _redBg       = Color(0xFFFEF2F2);
  static const Color _amber       = Color(0xFFF08030);
  static const Color _amberBg     = Color(0xFFFFF6EE);

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

  Map<String, dynamic>? _getLatestAssessment() {
    for (var i = assessments.length - 1; i >= 0; i--) {
      final a = assessments[i];
      if ((a['weightForAge'] ?? '').toString().isNotEmpty ||
          (a['heightForAge'] ?? '').toString().isNotEmpty ||
          (a['muac'] ?? '').toString().isNotEmpty) {
        return a;
      }
    }
    return null;
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'N/A';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
  }

  String _extractInterp(String? s) {
    if (s == null || s.isEmpty) return '';
    return RegExp(r'\(([^)]+)\)').firstMatch(s)?.group(1) ?? '';
  }

  String _wfaStatus(String? wfa) {
    final i = _extractInterp(wfa);
    return i.isEmpty ? '' : '$i (Weight-for-Age)';
  }

  String _hfaStatus(String? hfa) {
    final i = _extractInterp(hfa);
    if (i.isEmpty) return '';
    switch (i.toLowerCase()) {
      case 'severely stunted': return 'Severely Stunted (Height-for-Age)';
      case 'stunted':          return 'Stunted (Height-for-Age)';
      case 'normal':           return 'Normal Height (Height-for-Age)';
      default:                 return '$i (Height-for-Age)';
    }
  }

  String _muacStatus(String? muacStr) {
    if (muacStr == null || muacStr.isEmpty) return '';
    final muac = double.tryParse(muacStr.trim());
    if (muac == null) return '';
    final cls = muac < 11.5 ? 'SAM' : muac < 12.5 ? 'MAM' : muac < 13.5 ? 'At Risk' : 'Normal';
    return 'MUAC $cls (${muac}cm)';
  }

  _RiskLevel _calcRisk(Map<String, dynamic> a) {
    final interps = [
      _extractInterp(a['weightForAge']?.toString()).toLowerCase(),
      _extractInterp(a['heightForAge']?.toString()).toLowerCase(),
      _extractInterp(a['weightForHeight']?.toString()).toLowerCase(),
    ];
    final muac = double.tryParse(a['muac']?.toString().trim() ?? '');
    final severeTerms  = ['severely', 'obese'];
    final modTerms     = ['underweight','stunted','wasted','overweight','at risk'];
    bool severe = interps.any((s) => severeTerms.any((t) => s.contains(t)));
    bool mod    = interps.any((s) => modTerms.any((t) => s == t));
    if (muac != null) {
      if (muac < 11.5) severe = true;
      else if (muac < 13.5) mod = true;
    }
    return severe ? _RiskLevel.high : mod ? _RiskLevel.moderate : _RiskLevel.low;
  }

  _Severity _interpSeverity(String interp) {
    final l = interp.toLowerCase();
    if (l.contains('severe')) return _Severity.severe;
    if (l == 'normal') return _Severity.normal;
    return _Severity.warning;
  }

  _Severity _muacSeverity(String? muacStr) {
    final muac = double.tryParse(muacStr?.trim() ?? '');
    if (muac == null) return _Severity.normal;
    if (muac < 11.5) return _Severity.severe;
    if (muac < 13.5) return _Severity.warning;
    return _Severity.normal;
  }

  Color _severityFg(_Severity s) {
    switch (s) {
      case _Severity.severe:  return _red;
      case _Severity.warning: return _amber;
      case _Severity.normal:  return _greenText;
    }
  }

  Color _severityBg(_Severity s) {
    switch (s) {
      case _Severity.severe:  return _redBg;
      case _Severity.warning: return _amberBg;
      case _Severity.normal:  return _greenBg;
    }
  }

  Color _riskFg(_RiskLevel r) {
    switch (r) {
      case _RiskLevel.high:     return _red;
      case _RiskLevel.moderate: return _amber;
      case _RiskLevel.low:      return _greenText;
    }
  }

  Color _riskBg(_RiskLevel r) {
    switch (r) {
      case _RiskLevel.high:     return _redBg;
      case _RiskLevel.moderate: return _amberBg;
      case _RiskLevel.low:      return _greenBg;
    }
  }

  String _riskLabel(_RiskLevel r) {
    switch (r) {
      case _RiskLevel.high:     return 'High Nutritional Risk';
      case _RiskLevel.moderate: return 'Moderate Nutritional Risk';
      case _RiskLevel.low:      return 'Low Nutritional Risk';
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final latest = _getLatestAssessment();

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
            _iconBox(Icons.monitor_heart_rounded),
            const SizedBox(width: 12),
            const Text(
              'Overall Nutritional Status',
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
            Icon(Icons.assessment_outlined, size: 40, color: _orange.withOpacity(0.35)),
            const SizedBox(height: 12),
            const Text(
              'No assessment data available yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _inkMid),
            ),
          ],
        ),
      );

  // ─── Content ────────────────────────────────────────────────────────────────

  Widget _buildContent(Map<String, dynamic> latest) {
    final date      = latest['date'] as DateTime?;
    final wfa       = latest['weightForAge']?.toString();
    final hfa       = latest['heightForAge']?.toString();
    final muac      = latest['muac']?.toString();
    final riskLevel = _calcRisk(latest);

    final items = <_StatusItem>[
      if (_wfaStatus(wfa).isNotEmpty)
        _StatusItem(_wfaStatus(wfa), _interpSeverity(_extractInterp(wfa))),
      if (_hfaStatus(hfa).isNotEmpty)
        _StatusItem(_hfaStatus(hfa), _interpSeverity(_extractInterp(hfa))),
      if (_muacStatus(muac).isNotEmpty)
        _StatusItem(_muacStatus(muac), _muacSeverity(muac)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date pill
          _datePill('Last Assessment: ${_formatDate(date)}'),
          const SizedBox(height: 16),

          // Status tiles
          if (items.isNotEmpty) ...[
            const Text(
              'INDICATORS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _inkMid,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _statusTile(item),
                )),
            const SizedBox(height: 8),
          ],

          // Risk classification tile
          _riskTile(riskLevel),
        ],
      ),
    );
  }

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

  Widget _statusTile(_StatusItem item) {
    final fg = _severityFg(item.severity);
    final bg = _severityBg(item.severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _surfaceDim,
        borderRadius: BorderRadius.circular(_ri),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.severity == _Severity.normal
                  ? Icons.check_rounded
                  : item.severity == _Severity.warning
                      ? Icons.warning_amber_rounded
                      : Icons.error_rounded,
              size: 14,
              color: fg,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _riskTile(_RiskLevel risk) {
    final fg = _riskFg(risk);
    final bg = _riskBg(risk);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_ri),
        border: Border.all(color: fg.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: fg.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.shield_rounded, size: 16, color: fg),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Risk Classification',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: _inkMid,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _riskLabel(risk),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Enums & helpers ─────────────────────────────────────────────────────────

enum _RiskLevel { low, moderate, high }
enum _Severity  { normal, warning, severe }

class _StatusItem {
  final String text;
  final _Severity severity;
  const _StatusItem(this.text, this.severity);
}