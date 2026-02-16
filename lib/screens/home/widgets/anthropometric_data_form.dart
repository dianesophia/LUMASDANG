import 'package:flutter/material.dart';
import '../../../services/anthropometric_calculator.dart';
import 'form_card.dart';
import 'form_field_row.dart';

class AnthropometricDataForm extends StatefulWidget {
  final TextEditingController dateController;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final TextEditingController muacController;
  final TextEditingController weightForAgeController;
  final TextEditingController weightForHeightController;
  final TextEditingController heightForAgeController;
  final TextEditingController bmiController;
  final TextEditingController ageController;
  final TextEditingController sexController;
  final TextEditingController dobController;

  const AnthropometricDataForm({
    super.key,
    required this.dateController,
    required this.weightController,
    required this.heightController,
    required this.muacController,
    required this.weightForAgeController,
    required this.weightForHeightController,
    required this.heightForAgeController,
    required this.bmiController,
    required this.ageController,
    required this.sexController,
    required this.dobController,
  });

  @override
  State<AnthropometricDataForm> createState() => _AnthropometricDataFormState();
}

class _AnthropometricDataFormState extends State<AnthropometricDataForm> {
  void _recalculate() {
    final r = AnthropometricCalculator.calculate(
      weightStr: widget.weightController.text,
      heightStr: widget.heightController.text,
      ageStr: widget.ageController.text,
      sexStr: widget.sexController.text,
      dobStr: widget.dobController.text,
      measurementDateStr: widget.dateController.text,
    );
    if (r != null) {
      widget.weightForAgeController.text = r.weightForAge ?? '';
      widget.weightForHeightController.text = r.weightForHeight ?? '';
      widget.heightForAgeController.text = r.heightForAge ?? '';
      widget.bmiController.text = r.bmi ?? '';
    } else {
      widget.weightForAgeController.clear();
      widget.weightForHeightController.clear();
      widget.heightForAgeController.clear();
      widget.bmiController.clear();
    }
  }

  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = _recalculate;
    widget.weightController.addListener(_listener);
    widget.heightController.addListener(_listener);
    widget.ageController.addListener(_listener);
    widget.sexController.addListener(_listener);
    widget.dobController.addListener(_listener);
    widget.dateController.addListener(_listener);
    // Initial recalc in case controllers are pre-filled (e.g. from parent)
    WidgetsBinding.instance.addPostFrameCallback((_) => _recalculate());
  }

  @override
  void dispose() {
    widget.weightController.removeListener(_listener);
    widget.heightController.removeListener(_listener);
    widget.ageController.removeListener(_listener);
    widget.sexController.removeListener(_listener);
    widget.dobController.removeListener(_listener);
    widget.dateController.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'ATHROPOMETRIC DATA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormFieldRow(
            label: 'Date of Measurement:',
            labelWidth: 140,
            controller: widget.dateController,
            keyboardType: TextInputType.datetime,
            hint: 'MM-DD-YYYY (e.g. 02-13-2026)',
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Date of measurement is required';
              final value = v.trim();
              final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
              if (!regex.hasMatch(value)) {
                return 'Use format MM-DD-YYYY';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Weight (kg):',
            controller: widget.weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Weight is required';
              final w = double.tryParse(v.trim());
              if (w == null) return 'Enter a valid number';
              if (w <= 0 || w > 300) return 'Enter a valid weight';
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Height (cm):',
            controller: widget.heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Height is required';
              final h = double.tryParse(v.trim());
              if (h == null) return 'Enter a valid number';
              if (h <= 0 || h > 300) return 'Enter a valid height';
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'MUAC (cm):',
            controller: widget.muacController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'MUAC is required';
              final m = double.tryParse(v.trim());
              if (m == null) return 'Enter a valid number';
              if (m <= 0) return 'Enter a valid MUAC value';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8985A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-calculated from weight, height, age & sex (WHO z-scores)',
                  style: TextStyle(fontSize: 11, color: Colors.brown.shade800, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                FormFieldRow(label: 'Weight-for-Age (kg):', labelWidth: 140, controller: widget.weightForAgeController, readOnly: true),
                const SizedBox(height: 8),
                FormFieldRow(label: 'Weight-for-Height/Length (kg):', labelWidth: 160, controller: widget.weightForHeightController, readOnly: true),
                const SizedBox(height: 8),
                FormFieldRow(label: 'Height-for-Age (cm):', labelWidth: 140, controller: widget.heightForAgeController, readOnly: true),
                const SizedBox(height: 8),
                FormFieldRow(label: 'BMI (kg/m²):', labelWidth: 140, controller: widget.bmiController, readOnly: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
