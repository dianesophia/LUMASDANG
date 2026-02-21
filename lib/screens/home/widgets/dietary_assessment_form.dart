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
  // ── Theme constants (mirrors other forms) ─────────────────────────────────
  static const Color _primary = Color(0xFFB5651D);
  static const Color _primaryLight = Color(0xFFFFF3E0);
  static const Color _surface = Colors.white;
  static const Color _surfaceAlt = Color(0xFFFDF6EE);
  static const Color _border = Color(0xFFE8C9A0);
  static const Color _labelColor = Color(0xFF795548);
  static const Color _textColor = Color(0xFF3E2723);

  bool? _purelyBreastfed;

  @override
  void initState() {
    super.initState();
    _purelyBreastfed = widget.purelyBreastfed;
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    String? Function(String?)? validator,
    Widget? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _textColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFD4A97A)),
            prefixIcon: prefixIcon,
            prefixIconColor: _primary,
            filled: true,
            fillColor: _surfaceAlt,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE8985A), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  /// YES / NO pill toggle for boolean fields.
  Widget _buildYesNoToggle({
    required String label,
    required bool? value,
    required ValueChanged<bool?> onChanged,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        Row(
          children: [
            _buildTogglePill(
              label: 'Yes',
              selected: value == true,
              onTap: () => onChanged(true),
            ),
            const SizedBox(width: 10),
            _buildTogglePill(
              label: 'No',
              selected: value == false,
              onTap: () => onChanged(false),
            ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              errorText,
              style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
            ),
          ),
      ],
    );
  }

  Widget _buildTogglePill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _primary : _surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _primary : _border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 15,
              color: selected ? Colors.white : _labelColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A sub-section card (same pattern as parent info / WHO results panels).
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
                  child: const Icon(Icons.restaurant_outlined,
                      size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Dietary Assessment',
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
                // ── Purely Breastfed ─────────────────────────────────────
                _buildYesNoToggle(
                  label: 'Purely Breastfed',
                  value: _purelyBreastfed,
                  errorText: widget.purelyBreastfedError,
                  onChanged: (v) {
                    setState(() => _purelyBreastfed = v);
                    widget.onPurelyBreastfedChanged?.call(v);
                  },
                ),

                const SizedBox(height: 20),

                // ── Complementary Feeding sub-section ────────────────────
                _buildSubSection(
                  title: 'Complementary Feeding (CF)',
                  icon: Icons.child_care_outlined,
                  children: [
                    _buildField(
                      label: 'Age When CF Started',
                      controller: widget.ageWhenCfController,
                      keyboardType: TextInputType.number,
                      hint: 'Age in months',
                      prefixIcon: const Icon(Icons.cake_outlined, size: 18),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      label: 'Frequency of CF per Day',
                      controller: widget.freqCfController,
                      keyboardType: TextInputType.number,
                      hint: 'e.g. 3',
                      prefixIcon: const Icon(Icons.repeat_outlined, size: 18),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      label: 'Foods Given on CF',
                      controller: widget.foodCfController,
                      hint: 'e.g. rice porridge, mashed vegetables',
                      prefixIcon:
                          const Icon(Icons.set_meal_outlined, size: 18),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Dietary Diversity sub-section ────────────────────────
                _buildSubSection(
                  title: 'Dietary Diversity',
                  icon: Icons.pie_chart_outline,
                  children: [
                    const Text(
                      'Select all food groups consumed and specify:',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF8D4E15),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const CheckboxFieldRow(
                        label: 'Grains / Roots / Tubers',
                        hint: 'Specify'),
                    const SizedBox(height: 8),
                    const CheckboxFieldRow(
                        label: 'Legumes / Nuts', hint: 'Specify'),
                    const SizedBox(height: 8),
                    const CheckboxFieldRow(
                        label: 'Dairy Products', hint: 'Specify'),
                    const SizedBox(height: 8),
                    const CheckboxFieldRow(
                        label: 'Meat / Fish / Poultry', hint: 'Specify'),
                    const SizedBox(height: 8),
                    const CheckboxFieldRow(label: 'Eggs', hint: 'Specify'),
                    const SizedBox(height: 8),
                    const CheckboxFieldRow(
                        label: 'Vit-A Rich Fruits & Vegetables',
                        hint: 'Specify'),
                    const SizedBox(height: 8),
                    const CheckboxFieldRow(
                        label: 'Other Fruits & Vegetables',
                        hint: 'Specify'),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Meal Frequency ───────────────────────────────────────
                _buildField(
                  label: 'Meal Frequency per Day',
                  controller: widget.mealFrequencyController,
                  keyboardType: TextInputType.number,
                  hint: 'e.g. 3',
                  prefixIcon:
                      const Icon(Icons.dining_outlined, size: 18),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Meal frequency is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}