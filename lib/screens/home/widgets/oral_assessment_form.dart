import 'package:flutter/material.dart';
import 'form_field_label.dart';
import 'yes_no_row.dart';

// ── Risk level enum ───────────────────────────────────────────────────────────
enum _RiskLevel { high, moderate, low }

// ── Item model — tracks question text, its risk tier, and the user's answer ──
class _RiskItem {
  final String text;
  final _RiskLevel tier;
  bool? answer; // true = Yes, false = No, null = not answered

  _RiskItem(this.text, this.tier);
}

class OralAssessmentForm extends StatefulWidget {
  final Function(Map<String, dynamic>)? onDataChanged;
  final String? overallRiskError;

  const OralAssessmentForm(
      {super.key, this.onDataChanged, this.overallRiskError});

  @override
  State<OralAssessmentForm> createState() => _OralAssessmentFormState();
}

class _OralAssessmentFormState extends State<OralAssessmentForm> {
  // ── Colours ───────────────────────────────────────────────────────────────
  static const Color _highRisk      = Color(0xFFDC2626);
  static const Color _highRiskLight = Color(0xFFFEF2F2);
  static const Color _modRisk       = Color(0xFFD97706);
  static const Color _modRiskLight  = Color(0xFFFFFBEB);
  static const Color _lowRisk       = Color(0xFF059669);
  static const Color _lowRiskLight  = Color(0xFFECFDF5);

  // ── All questions grouped by section ─────────────────────────────────────
  // Social / Behavioral / Medical — High Risk
  final _socialHighItems = <_RiskItem>[
    _RiskItem('Mother/primary caregiver has active dental caries',              _RiskLevel.high),
    _RiskItem('Parent/caregiver has life-time of poverty, low health literacy', _RiskLevel.high),
    _RiskItem('Child has frequent exposure (>3×/day) to sugar-containing snacks or beverages between meals', _RiskLevel.high),
    _RiskItem('Child uses bottle or nonspill cup with natural/added sugar frequently between meals or at bedtime', _RiskLevel.high),
  ];

  // Social / Behavioral / Medical — Moderate Risk
  final _socialModItems = <_RiskItem>[
    _RiskItem('Child is a recent immigrant',              _RiskLevel.moderate),
    _RiskItem('Child has special health care needs',      _RiskLevel.moderate),
  ];

  // Clinical — High Risk
  final _clinicalHighItems = <_RiskItem>[
    _RiskItem('Child has visible plaque on teeth',              _RiskLevel.high),
    _RiskItem('Child presents with dental enamel defects',      _RiskLevel.high),
  ];

  // Protective Factors — Low Risk
  final _protectiveLowItems = <_RiskItem>[
    _RiskItem('Child receives optimally-fluoridated drinking water or fluoride supplements', _RiskLevel.low),
    _RiskItem('Child has teeth brushed daily with fluoridated toothpaste',                  _RiskLevel.low),
    _RiskItem('Child receives topical fluoride from health professional',                   _RiskLevel.low),
    _RiskItem('Child has dental home / regular dental care',                                _RiskLevel.low),
  ];

  // Disease Indicators — High Risk
  final _diseaseHighItems = <_RiskItem>[
    _RiskItem('Child has noncavitated (incipient / white spot) caries lesions',       _RiskLevel.high),
    _RiskItem('Child has visible caries lesions',                                     _RiskLevel.high),
    _RiskItem('Child has recent restorations or missing teeth due to caries',         _RiskLevel.high),
  ];

  // ── Derived overall risk (null = not enough answers yet) ─────────────────
  String? _autoRisk;

  // ── Recalculate overall risk whenever any answer changes ─────────────────
  // Rules (in priority order):
  //   1. Any HIGH-tier item answered YES  → High
  //   2. Any MODERATE-tier item answered YES → Moderate
  //   3. All protective items answered YES and no risk items YES → Low
  //   4. Otherwise → Low (default when something answered but no risk found)
  void _recalcRisk() {
    final allItems = [
      ..._socialHighItems,
      ..._socialModItems,
      ..._clinicalHighItems,
      ..._protectiveLowItems,
      ..._diseaseHighItems,
    ];

    final anyAnswered = allItems.any((i) => i.answer != null);
    if (!anyAnswered) {
      setState(() => _autoRisk = null);
      _notify(null);
      return;
    }

    final hasHighYes = allItems
        .where((i) => i.tier == _RiskLevel.high)
        .any((i) => i.answer == true);

    final hasModYes = allItems
        .where((i) => i.tier == _RiskLevel.moderate)
        .any((i) => i.answer == true);

    String computed;
    if (hasHighYes) {
      computed = 'High';
    } else if (hasModYes) {
      computed = 'Moderate';
    } else {
      computed = 'Low';
    }

    setState(() => _autoRisk = computed);
    _notify(computed);
  }

  void _notify(String? risk) {
    widget.onDataChanged?.call({'overallRisk': risk});
  }

  // ── Colour helpers ────────────────────────────────────────────────────────
  Color _colorFor(String? risk) {
    if (risk == 'High')     return _highRisk;
    if (risk == 'Moderate') return _modRisk;
    return _lowRisk;
  }

  Color _bgColorFor(String? risk) {
    if (risk == 'High')     return _highRiskLight;
    if (risk == 'Moderate') return _modRiskLight;
    return _lowRiskLight;
  }

  // ── Shared card + header builders ─────────────────────────────────────────
  Widget _buildCard({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      );

  Widget _buildSectionHeader(String title, IconData icon) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF5A962), Color(0xFFF08030)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF5A962).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFFF5A962),
              letterSpacing: 1.1,
            ),
          ),
        ],
      );

  Widget _buildRiskBadge(String label, Color color, Color bgColor) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _buildYesNoHeader() => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            const Expanded(child: SizedBox()),
            SizedBox(
              width: 36,
              child: Text('YES',
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.black45,
                      letterSpacing: 0.5),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 36,
              child: Text('NO',
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.black45,
                      letterSpacing: 0.5),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      );

  Widget _buildRiskCard({
    required String title,
    required String badgeLabel,
    required Color riskColor,
    required Color riskBgColor,
    required List<_RiskItem> items,
    bool showTitle = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: riskColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showTitle) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(title,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A))),
                          ),
                          const SizedBox(width: 8),
                          _buildRiskBadge(badgeLabel, riskColor, riskBgColor),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildRiskBadge(badgeLabel, riskColor, riskBgColor),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    _buildYesNoHeader(),
                    // Wire each YesNoRow to update the item and recalc
                    ...items.map((item) => YesNoRow(
                          text: item.text,
                          color: riskColor,
                          onChanged: (val) {
                            item.answer = val;
                            _recalcRisk();
                          },
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Auto-risk result display ───────────────────────────────────────────────
  Widget _buildAutoRiskResult() {
    if (_autoRisk == null) {
      // Nothing answered yet — show a neutral placeholder
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.pending_outlined,
                size: 20, color: Colors.black26),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Awaiting answers',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black45,
                      )),
                  SizedBox(height: 2),
                  Text(
                    'Answer the questions above to auto-determine risk level.',
                    style:
                        TextStyle(fontSize: 10, color: Colors.black38),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final color   = _colorFor(_autoRisk);
    final bgColor = _bgColorFor(_autoRisk);

    final IconData icon;
    final String   subtitle;
    if (_autoRisk == 'High') {
      icon     = Icons.warning_amber_rounded;
      subtitle = 'One or more high-risk indicators were marked YES.';
    } else if (_autoRisk == 'Moderate') {
      icon     = Icons.info_outline;
      subtitle = 'One or more moderate-risk indicators were marked YES.';
    } else {
      icon     = Icons.check_circle_outline;
      subtitle = 'No high or moderate risk indicators were marked YES.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$_autoRisk Risk',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'AUTO',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Card 1: Risk Factors ─────────────────────────────────────
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                  'ORAL ASSESSMENT', Icons.medical_services_outlined),
              const SizedBox(height: 14),

              const FormFieldLabel(label: 'RISK FACTORS', isOptional: true),
              const SizedBox(height: 8),

              _buildRiskCard(
                title: 'Social / Behavioral / Medical',
                badgeLabel: 'High Risk',
                riskColor: _highRisk,
                riskBgColor: _highRiskLight,
                items: _socialHighItems,
              ),
              const SizedBox(height: 8),
              _buildRiskCard(
                title: '',
                badgeLabel: 'Moderate Risk',
                riskColor: _modRisk,
                riskBgColor: _modRiskLight,
                showTitle: false,
                items: _socialModItems,
              ),
              const SizedBox(height: 8),
              _buildRiskCard(
                title: 'Clinical',
                badgeLabel: 'High Risk',
                riskColor: _highRisk,
                riskBgColor: _highRiskLight,
                items: _clinicalHighItems,
              ),
              const SizedBox(height: 8),
              _buildRiskCard(
                title: 'Protective Factors',
                badgeLabel: 'Low Risk',
                riskColor: _lowRisk,
                riskBgColor: _lowRiskLight,
                items: _protectiveLowItems,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Card 2: Disease Indicators ───────────────────────────────
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                  'DISEASE INDICATORS', Icons.biotech_outlined),
              const SizedBox(height: 14),
              _buildRiskCard(
                title: 'Caries Findings',
                badgeLabel: 'High Risk',
                riskColor: _highRisk,
                riskBgColor: _highRiskLight,
                items: _diseaseHighItems,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Card 3: Overall Risk — Auto-calculated ───────────────────
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                  'OVERALL RISK ASSESSMENT', Icons.assessment_outlined),
              const SizedBox(height: 6),

              // How it's calculated info
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A962).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFF5A962).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome_outlined,
                        size: 13, color: Color(0xFFF5A962)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Automatically determined from your answers above. '
                        'Any YES on a High Risk item → High. '
                        'Any YES on Moderate → Moderate. Otherwise → Low.',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF888888)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _buildAutoRiskResult(),

              if (widget.overallRiskError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    widget.overallRiskError!,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFFEF4444)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}