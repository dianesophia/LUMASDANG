import 'package:flutter/material.dart';
import 'checkbox_field_row.dart';
import 'form_field_label.dart';

class HealthStatusForm extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Card 1: Illnesses ─────────────────────────────────────────
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                  'HEALTH STATUS', Icons.health_and_safety_outlined),
              const SizedBox(height: 6),
              const FormFieldLabel(
                label: 'ILLNESSES / CONDITIONS',
                isOptional: true,
              ),
              const SizedBox(height: 4),
              const Text(
                'Check all that apply and specify date of occurrence / duration:',
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: Colors.black38,
                ),
              ),
              const SizedBox(height: 12),
              CheckboxFieldRow(
                label: 'Diarrhea',
                hint: 'Date of occurrence / duration',
                initialValue: diarrhea,
                onChanged: onDiarrheaChanged,
                isOptional: true,
              ),
              const SizedBox(height: 8),
              CheckboxFieldRow(
                label: 'Fever',
                hint: 'Date of occurrence / duration',
                initialValue: fever,
                onChanged: onFeverChanged,
                isOptional: true,
              ),
              const SizedBox(height: 8),
              CheckboxFieldRow(
                label: 'Cough / Pneumonia',
                hint: 'Date of occurrence / duration',
                initialValue: cough,
                onChanged: onCoughChanged,
                isOptional: true,
              ),
              const SizedBox(height: 8),
              CheckboxFieldRow(
                label: 'Other',
                hint: 'Date of occurrence / duration',
                initialValue: other,
                onChanged: onOtherChanged,
                isOptional: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Card 2: Medications ───────────────────────────────────────
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                  'MEDICATIONS', Icons.medication_outlined),
              const SizedBox(height: 6),
              const Text(
                'Current medications or those taken during illness:',
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: Colors.black38,
                ),
              ),
              const SizedBox(height: 12),
              CheckboxFieldRow(
                label: 'Medication(s)',
                hint: 'Current / taken during illness',
                initialValue: medications,
                onChanged: onMedicationsChanged,
                isOptional: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}