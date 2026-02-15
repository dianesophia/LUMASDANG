import 'package:flutter/material.dart';
import 'form_card.dart';
import 'checkbox_field_row.dart';

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

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'HEALTH STATUS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxFieldRow(
            label: 'Diarrhea:',
            hint: '(Date of Occurrence/ Duration)',
            initialValue: diarrhea,
            onChanged: onDiarrheaChanged,
          ),
          const SizedBox(height: 10),
          CheckboxFieldRow(
            label: 'Fever:',
            hint: '(Date of Occurrence/ Duration)',
            initialValue: fever,
            onChanged: onFeverChanged,
          ),
          const SizedBox(height: 10),
          CheckboxFieldRow(
            label: 'Cough/Pneumonia:',
            hint: '(Date of Occurrence/ Duration)',
            initialValue: cough,
            onChanged: onCoughChanged,
          ),
          const SizedBox(height: 10),
          CheckboxFieldRow(
            label: 'Other:',
            hint: '(Date of Occurrence/ Duration)',
            initialValue: other,
            onChanged: onOtherChanged,
          ),
          const SizedBox(height: 10),
          CheckboxFieldRow(
            label: 'Medication/s:',
            hint: '(Current/ Taken during illness)',
            initialValue: medications,
            onChanged: onMedicationsChanged,
          ),
        ],
      ),
    );
  }
}
