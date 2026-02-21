import 'package:flutter/material.dart';
import 'form_card.dart';
import 'checkbox_field_row.dart';

class HealthStatusForm extends StatelessWidget {
  // ── Theme constants (mirrors other forms) ─────────────────────────────────
  static const Color _primary = Color(0xFFB5651D);
  static const Color _primaryLight = Color(0xFFFFF3E0);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE8C9A0);
  static const Color _labelColor = Color(0xFF795548);
  static const Color _textColor = Color(0xFF3E2723);

  final bool diarrhea;
  final ValueChanged<bool> onDiarrheaChanged;
  final bool fever;
  final ValueChanged<bool> onFeverChanged;
  final bool cough;
  final ValueChanged<bool> onCoughChanged;
  final bool other;
  final ValueChanged<bool> onOtherChanged;
  final bool medications;
  final ValueChanged<bool> onMedicationsChanged;

  const HealthStatusForm({
    super.key,
    required this.diarrhea,
    required this.onDiarrheaChanged,
    required this.fever,
    required this.onFeverChanged,
    required this.cough,
    required this.onCoughChanged,
    required this.other,
    required this.onOtherChanged,
    required this.medications,
    required this.onMedicationsChanged,
  });

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
          // ── Section Header ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.health_and_safety_outlined,
                      size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Health Status',
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

          // ── Form Body ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sub-section: Illnesses
                _buildSubSection(
                  title: 'Illnesses / Conditions',
                  icon: Icons.sick_outlined,
                  children: [
                    const Text(
                      'Check all that apply and specify date of occurrence / duration:',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF8D4E15),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxFieldRow(
                      label: 'Diarrhea',
                      hint: 'Date of occurrence / duration',
                      initialValue: diarrhea,
                      onChanged: onDiarrheaChanged,
                    ),
                    const SizedBox(height: 8),
                    CheckboxFieldRow(
                      label: 'Fever',
                      hint: 'Date of occurrence / duration',
                      initialValue: fever,
                      onChanged: onFeverChanged,
                    ),
                    const SizedBox(height: 8),
                    CheckboxFieldRow(
                      label: 'Cough / Pneumonia',
                      hint: 'Date of occurrence / duration',
                      initialValue: cough,
                      onChanged: onCoughChanged,
                    ),
                    const SizedBox(height: 8),
                    CheckboxFieldRow(
                      label: 'Other',
                      hint: 'Date of occurrence / duration',
                      initialValue: other,
                      onChanged: onOtherChanged,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Sub-section: Medications
                _buildSubSection(
                  title: 'Medications',
                  icon: Icons.medication_outlined,
                  children: [
                    const Text(
                      'Current medications or those taken during illness:',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF8D4E15),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxFieldRow(
                      label: 'Medication(s)',
                      hint: 'Current / taken during illness',
                      initialValue: medications,
                      onChanged: onMedicationsChanged,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}