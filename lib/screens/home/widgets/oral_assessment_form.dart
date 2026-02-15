import 'package:flutter/material.dart';
import 'form_card.dart';
import 'yes_no_row.dart';

class OralAssessmentForm extends StatefulWidget {
  final Function(Map<String, dynamic>)? onDataChanged;
  final String? overallRiskError;

  const OralAssessmentForm({super.key, this.onDataChanged, this.overallRiskError});

  @override
  State<OralAssessmentForm> createState() => _OralAssessmentFormState();
}

class _OralAssessmentFormState extends State<OralAssessmentForm> {
  String? _selectedOverallRisk;

  void _notifyDataChanged() {
    if (widget.onDataChanged != null && _selectedOverallRisk != null) {
      widget.onDataChanged!({
        'overallRisk': _selectedOverallRisk,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'ORAL ASSESSMENT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRiskSection(
            'Risk factors: Social/behavioral/medical',
            const Color(0xFFE53935),
            [
              'Mother/primary caregiver has active dental caries',
              'Parent/caregiver has life-time of poverty, low health literacy',
              'Child has frequent exposure (>3 times/day) between-meal sugar-containing snacks or beverages per day',
              'Child uses bottle or nonspill cup containing natural or added sugar frequently, between meals and/or at bedtime',
            ],
          ),
          const SizedBox(height: 8),
          _buildModerateRiskItems([
            'Child is a recent immigrant',
            'Child has special health care needs',
          ]),
          const SizedBox(height: 12),
          _buildRiskSection(
            'Risk factors: Clinical',
            const Color(0xFFE53935),
            [
              'Child has visible plaque on teeth',
              'Child presents with dental enamel defects',
            ],
          ),
          const SizedBox(height: 12),
          _buildRiskSection(
            'Protective Factors',
            const Color(0xFFFFEB3B),
            [
              'Child receives optimally-fluoridated drinking water or fluoride supplements',
              'Child has teeth brushed daily with fluoridated toothpaste',
              'Child receives topical fluoride from health professional',
              'Child has dental home/regular dental care',
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Disease Indicators:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 8),
          _buildDiseaseIndicators(),
          const SizedBox(height: 12),
          _buildOverallRisk(),
          if (widget.overallRiskError != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 6),
              child: Text(
                widget.overallRiskError!,
                style: const TextStyle(fontSize: 11, color: Color(0xFFD32F2F)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRiskSection(String title, Color indicatorColor, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                indicatorColor == const Color(0xFFE53935)
                    ? 'High Risk'
                    : indicatorColor == const Color(0xFFFF9800)
                        ? 'Moderate Risk'
                        : 'Low Risk',
                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildYesNoHeader(),
        ...items.map((item) => YesNoRow(text: item, color: indicatorColor)),
      ],
    );
  }

  Widget _buildModerateRiskItems(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Moderate Risk',
                style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        ...items.map((item) => YesNoRow(text: item, color: const Color(0xFFFF9800))),
      ],
    );
  }

  Widget _buildYesNoHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: SizedBox()),
          SizedBox(
            width: 35,
            child: Text('YES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)), textAlign: TextAlign.center),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 35,
            child: Text('NO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseIndicators() {
    return Column(
      children: [
        _buildYesNoHeader(),
        YesNoRow(text: 'Child has noncavitated (incipient/white spot) caries lesions', color: const Color(0xFFE53935)),
        YesNoRow(text: 'Child has visible caries lesions', color: const Color(0xFFE53935)),
        YesNoRow(text: 'Child has recent restorations or missing teeth due to caries', color: const Color(0xFFE53935)),
      ],
    );
  }

  Widget _buildOverallRisk() {
    return Row(
      children: [
        const Text(
          'Overall:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
        ),
        const SizedBox(width: 12),
        _buildSelectableRiskChip('High', const Color(0xFFE53935)),
        const SizedBox(width: 8),
        _buildSelectableRiskChip('Moderate', const Color(0xFFFF9800)),
        const SizedBox(width: 8),
        _buildSelectableRiskChip('Low', const Color(0xFFFFEB3B)),
      ],
    );
  }

  Widget _buildSelectableRiskChip(String label, Color color) {
    final isSelected = _selectedOverallRisk == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOverallRisk = isSelected ? null : label;
        });
        _notifyDataChanged();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: color == const Color(0xFFFFEB3B) ? Colors.black54 : Colors.white,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 12, color: color)
                  : null,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (color == const Color(0xFFFFEB3B) ? Colors.black87 : Colors.white)
                    : (color == const Color(0xFFFFEB3B) ? Colors.black54 : color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
