import 'package:flutter/material.dart';
import 'checkbox_field_row.dart';

class DietaryAssessmentForm extends StatefulWidget {
  final int? ageInMonths;
  final bool? purelyBreastfed;
  final ValueChanged<bool?>? onPurelyBreastfedChanged;
  final TextEditingController ageWhenCfController;
  final TextEditingController freqCfController;
  final TextEditingController foodCfController;
  final TextEditingController mealFrequencyController;
  final String? purelyBreastfedError;

  const DietaryAssessmentForm({
    super.key,
    this.ageInMonths,
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

  /// True when age is unknown (null) or <= 6 months → show breastfeeding section
  /// False when age > 6 months → show complementary feeding section
  bool get _isBreastfeedingAge => (widget.ageInMonths ?? 0) <= 6;

  @override
  void initState() {
    super.initState();
    _purelyBreastfed = widget.purelyBreastfed;
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF5A962),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.black26),
            prefixIcon: icon != null
                ? Icon(icon, size: 16, color: Colors.black38)
                : null,
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFF5A962), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorStyle: const TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

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

  Widget _buildTogglePill(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFF5A962)
              : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? const Color(0xFFF5A962)
                : const Color(0xFFEEEEEE),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 15,
              color: selected ? Colors.white : Colors.black38,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Card 1: Breastfeeding — shown only when age <= 6 months ─────────
        if (_isBreastfeedingAge) ...[
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                    'DIETARY ASSESSMENT', Icons.restaurant_outlined),
                const SizedBox(height: 14),

                const Text(
                  'PURELY BREASTFED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF5A962),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildTogglePill('Yes', _purelyBreastfed == true, () {
                      setState(() => _purelyBreastfed = true);
                      widget.onPurelyBreastfedChanged?.call(true);
                    }),
                    const SizedBox(width: 10),
                    _buildTogglePill('No', _purelyBreastfed == false, () {
                      setState(() => _purelyBreastfed = false);
                      widget.onPurelyBreastfedChanged?.call(false);
                    }),
                  ],
                ),
                if (widget.purelyBreastfedError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      widget.purelyBreastfedError!,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFFEF4444)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // ── Card 2: Complementary Feeding — shown only when age > 6 months ──
        if (!_isBreastfeedingAge) ...[
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                    'COMPLEMENTARY FEEDING', Icons.child_care_outlined),
                const SizedBox(height: 14),

                _buildField(
                  label: 'AGE WHEN CF STARTED',
                  controller: widget.ageWhenCfController,
                  keyboardType: TextInputType.number,
                  hint: 'Age in months',
                  icon: Icons.cake_outlined,
                  validator: (v) {
                    if (!_isBreastfeedingAge &&
                        (v == null || v.trim().isEmpty)) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildField(
                  label: 'FREQUENCY OF CF PER DAY',
                  controller: widget.freqCfController,
                  keyboardType: TextInputType.number,
                  hint: 'e.g. 3',
                  icon: Icons.repeat_outlined,
                  validator: (v) {
                    if (!_isBreastfeedingAge &&
                        (v == null || v.trim().isEmpty)) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildField(
                  label: 'FOODS GIVEN ON CF',
                  controller: widget.foodCfController,
                  hint: 'e.g. rice porridge, mashed vegetables',
                  icon: Icons.set_meal_outlined,
                  validator: (v) {
                    if (!_isBreastfeedingAge &&
                        (v == null || v.trim().isEmpty)) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // ── Card 3: Dietary Diversity — always shown ─────────────────────────
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                  'DIETARY DIVERSITY', Icons.pie_chart_outline),
              const SizedBox(height: 6),
              const Text(
                'Select all food groups consumed and specify:',
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: Colors.black38,
                ),
              ),
              const SizedBox(height: 12),
              const CheckboxFieldRow(
                  label: 'Grains / Roots / Tubers', hint: 'Specify'),
              const SizedBox(height: 8),
              const CheckboxFieldRow(label: 'Legumes / Nuts', hint: 'Specify'),
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
                  label: 'Vit-A Rich Fruits & Vegetables', hint: 'Specify'),
              const SizedBox(height: 8),
              const CheckboxFieldRow(
                  label: 'Other Fruits & Vegetables', hint: 'Specify'),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Card 4: Meal Frequency — always shown ────────────────────────────
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('MEAL FREQUENCY', Icons.dining_outlined),
              const SizedBox(height: 14),
              _buildField(
                label: 'MEALS PER DAY',
                controller: widget.mealFrequencyController,
                keyboardType: TextInputType.number,
                hint: 'e.g. 3',
                icon: Icons.dining_outlined,
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
    );
  }
}