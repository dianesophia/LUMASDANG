import 'package:flutter/material.dart';
import 'form_card.dart';
import 'yes_no_row.dart';

class OralAssessmentForm extends StatefulWidget {
  final Function(Map<String, dynamic>)? onDataChanged;
  final String? overallRiskError;

  const OralAssessmentForm(
      {super.key, this.onDataChanged, this.overallRiskError});

  @override
  State<OralAssessmentForm> createState() => _OralAssessmentFormState();
}

class _OralAssessmentFormState extends State<OralAssessmentForm> {
  // ── Theme constants ───────────────────────────────────────────────────────
  static const Color _primary = Color(0xFFB5651D);
  static const Color _primaryLight = Color(0xFFFFF3E0);
  static const Color _surface = Colors.white;
  static const Color _surfaceAlt = Color(0xFFFDF6EE);
  static const Color _border = Color(0xFFE8C9A0);
  static const Color _labelColor = Color(0xFF795548);
  static const Color _textColor = Color(0xFF3E2723);

  // ── Risk palette ──────────────────────────────────────────────────────────
  static const Color _highRisk = Color(0xFFDC2626);
  static const Color _highRiskLight = Color(0xFFFEF2F2);
  static const Color _modRisk = Color(0xFFD97706);
  static const Color _modRiskLight = Color(0xFFFFFBEB);
  static const Color _lowRisk = Color(0xFF059669);
  static const Color _lowRiskLight = Color(0xFFECFDF5);

  String? _selectedOverallRisk;

  void _notifyDataChanged() {
    if (widget.onDataChanged != null && _selectedOverallRisk != null) {
      widget.onDataChanged!({'overallRisk': _selectedOverallRisk});
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _labelColor,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _buildRiskBadge(String label, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1.2),
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
  }

  Widget _buildYesNoHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Expanded(child: SizedBox()),
          SizedBox(
            width: 36,
            child: Text(
              'YES',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: _labelColor,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 36,
            child: Text(
              'NO',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: _labelColor,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Risk card with coloured left accent bar.
  Widget _buildRiskCard({
    required String title,
    required String badgeLabel,
    required Color riskColor,
    required Color riskBgColor,
    required List<String> items,
    bool showTitle = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1.5),
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
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _textColor,
                              ),
                            ),
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
                    ...items.map((item) =>
                        YesNoRow(text: item, color: riskColor)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRisk() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Overall Risk Assessment'),
        Row(
          children: [
            Expanded(
                child: _buildRiskPill('High', _highRisk, _highRiskLight)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildRiskPill('Moderate', _modRisk, _modRiskLight)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildRiskPill('Low', _lowRisk, _lowRiskLight)),
          ],
        ),
        if (widget.overallRiskError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              widget.overallRiskError!,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFFEF4444)),
            ),
          ),
      ],
    );
  }

  Widget _buildRiskPill(String label, Color color, Color bgColor) {
    final isSelected = _selectedOverallRisk == label;
    return GestureDetector(
      onTap: () {
        setState(
            () => _selectedOverallRisk = isSelected ? null : label);
        _notifyDataChanged();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? color : bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              size: 15,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Header ─────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: _primaryLight,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.medical_services_outlined,
                      size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Oral Assessment',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // ── Form Body ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Risk Factors ───────────────────────────────────────
                _buildLabel('Risk Factors'),

                _buildRiskCard(
                  title: 'Social / Behavioral / Medical',
                  badgeLabel: 'High Risk',
                  riskColor: _highRisk,
                  riskBgColor: _highRiskLight,
                  items: [
                    'Mother/primary caregiver has active dental caries',
                    'Parent/caregiver has life-time of poverty, low health literacy',
                    'Child has frequent exposure (>3×/day) to sugar-containing snacks or beverages between meals',
                    'Child uses bottle or nonspill cup with natural/added sugar frequently between meals or at bedtime',
                  ],
                ),

                const SizedBox(height: 8),

                _buildRiskCard(
                  title: '',
                  badgeLabel: 'Moderate Risk',
                  riskColor: _modRisk,
                  riskBgColor: _modRiskLight,
                  showTitle: false,
                  items: [
                    'Child is a recent immigrant',
                    'Child has special health care needs',
                  ],
                ),

                const SizedBox(height: 12),

                _buildRiskCard(
                  title: 'Clinical',
                  badgeLabel: 'High Risk',
                  riskColor: _highRisk,
                  riskBgColor: _highRiskLight,
                  items: [
                    'Child has visible plaque on teeth',
                    'Child presents with dental enamel defects',
                  ],
                ),

                const SizedBox(height: 12),

                _buildRiskCard(
                  title: 'Protective Factors',
                  badgeLabel: 'Low Risk',
                  riskColor: _lowRisk,
                  riskBgColor: _lowRiskLight,
                  items: [
                    'Child receives optimally-fluoridated drinking water or fluoride supplements',
                    'Child has teeth brushed daily with fluoridated toothpaste',
                    'Child receives topical fluoride from health professional',
                    'Child has dental home / regular dental care',
                  ],
                ),

                const SizedBox(height: 20),

                // ── Disease Indicators ─────────────────────────────────
                _buildLabel('Disease Indicators'),
                _buildRiskCard(
                  title: 'Caries Findings',
                  badgeLabel: 'High Risk',
                  riskColor: _highRisk,
                  riskBgColor: _highRiskLight,
                  items: [
                    'Child has noncavitated (incipient / white spot) caries lesions',
                    'Child has visible caries lesions',
                    'Child has recent restorations or missing teeth due to caries',
                  ],
                ),

                const SizedBox(height: 20),

                // ── Overall Risk ───────────────────────────────────────
                _buildOverallRisk(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}