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
  // ── Theme constants ────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFFB5651D);       // warm brown
  static const Color _primaryLight = Color(0xFFFFF3E0);  // amber-50
  static const Color _surface = Colors.white;
  static const Color _surfaceAlt = Color(0xFFFDF6EE);    // warm white
  static const Color _border = Color(0xFFE8C9A0);        // warm tan border
  static const Color _labelColor = Color(0xFF795548);    // brown-600
  static const Color _textColor = Color(0xFF3E2723);     // brown-900
  static const Color _accentGreen = Color(0xFFB5651D);   // reuse brown for results
  static const Color _accentGreenLight = Color(0xFFFFF8F0); // warm cream

  // ── Recalculation logic ───────────────────────────────────────────────────
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// A styled input field label above the text field.
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

  /// A styled, self-contained input field (replaces FormFieldRow for the new
  /// layout — individual rows with label on top).
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    bool readOnly = false,
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
          readOnly: readOnly,
          validator: validator,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: readOnly ? _accentGreen : _textColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFD4A97A)),
            prefixIcon: prefixIcon,
            prefixIconColor: readOnly ? _accentGreen : _primary,
            filled: true,
            fillColor: readOnly ? const Color(0xFFFFF3E0) : _surfaceAlt,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: readOnly
                    ? const Color(0xFFE8985A) // original orange
                    : _border,
                width: 1.5,
              ),
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

  /// A two-column grid row for the calculated results.
  Widget _buildResultRow(
    String label1,
    TextEditingController c1,
    Widget icon1,
    String label2,
    TextEditingController c2,
    Widget icon2,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildField(
            label: label1,
            controller: c1,
            readOnly: true,
            prefixIcon: icon1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildField(
            label: label2,
            controller: c2,
            readOnly: true,
            prefixIcon: icon2,
          ),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
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
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8985A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.monitor_weight_outlined,
                      size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Anthropometric Data',
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
                // Date of Measurement (full width)
                _buildField(
                  label: 'Date of Measurement',
                  controller: widget.dateController,
                  keyboardType: TextInputType.datetime,
                  hint: 'MM-DD-YYYY',
                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Date of measurement is required';
                    }
                    if (!RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(v.trim())) {
                      return 'Use format MM-DD-YYYY';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // Weight + Height (side by side)
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'Weight (kg)',
                        controller: widget.weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        hint: '0.0',
                        prefixIcon:
                            const Icon(Icons.fitness_center_outlined, size: 18),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          final w = double.tryParse(v.trim());
                          if (w == null) return 'Invalid number';
                          if (w <= 0 || w > 300) return 'Invalid weight';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        label: 'Height (cm)',
                        controller: widget.heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        hint: '0.0',
                        prefixIcon: const Icon(Icons.height_outlined, size: 18),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          final h = double.tryParse(v.trim());
                          if (h == null) return 'Invalid number';
                          if (h <= 0 || h > 300) return 'Invalid height';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // MUAC (full width)
                _buildField(
                  label: 'MUAC (cm)',
                  controller: widget.muacController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  hint: '0.0',
                  prefixIcon: const Icon(Icons.straighten_outlined, size: 18),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'MUAC is required';
                    final m = double.tryParse(v.trim());
                    if (m == null) return 'Invalid number';
                    if (m <= 0) return 'Invalid MUAC value';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Calculated Results Section ───────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFE8985A), width: 1.5),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sub-header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB5651D),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.auto_graph_outlined,
                                size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'WHO Z-Score Results',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB5651D),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8985A).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Auto-calculated',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB5651D),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),
                      const Text(
                        'Derived from weight, height, age & sex inputs',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF8D4E15), // emerald-700
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Results grid — 2 per row
                      _buildResultRow(
                        'Weight-for-Age',
                        widget.weightForAgeController,
                        const Icon(Icons.monitor_weight_outlined, size: 16),
                        'Weight-for-Height',
                        widget.weightForHeightController,
                        const Icon(Icons.swap_vert_outlined, size: 16),
                      ),

                      const SizedBox(height: 12),

                      _buildResultRow(
                        'Height-for-Age',
                        widget.heightForAgeController,
                        const Icon(Icons.height_outlined, size: 16),
                        'BMI (kg/m²)',
                        widget.bmiController,
                        const Icon(Icons.calculate_outlined, size: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}