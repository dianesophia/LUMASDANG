import 'package:flutter/material.dart';
import 'form_card.dart';
import 'form_field_row.dart';
import 'checkbox_field_row.dart';

class DietaryAssessmentForm extends StatefulWidget {
  final bool? purelyBreastfed;
  final ValueChanged<bool?>? onPurelyBreastfedChanged;
  final TextEditingController ageWhenCfController;
  final TextEditingController freqCfController;
  final TextEditingController foodCfController;
  final TextEditingController mealFrequencyController;
  final String? purelyBreastfedError;

  const DietaryAssessmentForm({
    super.key,
    this.purelyBreastfed,
    this.onPurelyBreastfedChanged,
    required this.ageWhenCfController,
    required this.freqCfController,
    required this.foodCfController,
    required this.mealFrequencyController,
    this.purelyBreastfedError,
  });

  @override
  State<DietaryAssessmentForm> createState() => _DietaryAssessmentFormState();
}

class _DietaryAssessmentFormState extends State<DietaryAssessmentForm> {
  bool? _purelyBreastfed;

  @override
  void initState() {
    super.initState();
    _purelyBreastfed = widget.purelyBreastfed;
  }

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'DIETARY ASSESSMENT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Purely Breastfed:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const Text('YES', style: TextStyle(fontSize: 12, color: Color(0xFF5D4037))),
                      Radio<bool>(
                        value: true,
                        groupValue: _purelyBreastfed,
                        onChanged: (v) {
                          setState(() => _purelyBreastfed = v);
                          widget.onPurelyBreastfedChanged?.call(v);
                        },
                        activeColor: const Color(0xFF2E8B7B),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('NO', style: TextStyle(fontSize: 12, color: Color(0xFF5D4037))),
                      Radio<bool>(
                        value: false,
                        groupValue: _purelyBreastfed,
                        onChanged: (v) {
                          setState(() => _purelyBreastfed = v);
                          widget.onPurelyBreastfedChanged?.call(v);
                        },
                        activeColor: const Color(0xFF2E8B7B),
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.purelyBreastfedError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Text(
                    widget.purelyBreastfedError!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFD32F2F)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Complimentary Feeding (CF):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              children: [
                FormFieldRow(
                  label: 'Age when CF started:',
                  hint: '(Age in months)',
                  labelWidth: 140,
                  controller: widget.ageWhenCfController,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                FormFieldRow(
                  label: 'Frequency of CF a day:',
                  labelWidth: 140,
                  controller: widget.freqCfController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                FormFieldRow(
                  label: 'Food/s given on CF:',
                  labelWidth: 140,
                  controller: widget.foodCfController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Dietary Diversity:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Column(
              children: [
                CheckboxFieldRow(label: 'Grains/Roots/Tubers:', hint: '(Specify)'),
                SizedBox(height: 6),
                CheckboxFieldRow(label: 'Legumes/Nuts:', hint: '(Specify)'),
                SizedBox(height: 6),
                CheckboxFieldRow(label: 'Dairy Products:', hint: '(Specify)'),
                SizedBox(height: 6),
                CheckboxFieldRow(label: 'Meat/Fish/Poultry:', hint: '(Specify)'),
                SizedBox(height: 6),
                CheckboxFieldRow(label: 'Eggs:', hint: '(Specify)'),
                SizedBox(height: 6),
                CheckboxFieldRow(label: 'Vit-A rich foods & Vegetables:', hint: '(Specify)'),
                SizedBox(height: 6),
                CheckboxFieldRow(label: 'Other Fruits & Vegetables:', hint: '(Specify)'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Meal frequency in a day:',
            labelWidth: 160,
            controller: widget.mealFrequencyController,
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Meal frequency is required';
              return null;
            },
          ),
        ],
      ),
    );
  }
}
