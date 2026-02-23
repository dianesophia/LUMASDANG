import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // add intl to pubspec.yaml
import '../../../services/anthropometric_calculator.dart';

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

  // ── Calendar helper ─────────────────────────────────────────────────────
  Future<void> _pickMeasurementDate() async {
    DateTime initialDate = DateTime.now();
    final existing = widget.dateController.text.trim();
    if (existing.isNotEmpty) {
      try {
        initialDate = DateFormat('MM-dd-yyyy').parse(existing);
      } catch (_) {}
    }
    if (initialDate.isAfter(DateTime.now())) initialDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFF5A962),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF1A1A1A),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF5A962),
            ),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      widget.dateController.text = DateFormat('MM-dd-yyyy').format(picked);
      // _recalculate() fires via listener automatically
    }
  }

  // ── Shared builders ─────────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    bool readOnly = false,
    bool hasCalendar = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    final isResult = readOnly && !hasCalendar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isResult ? const Color(0xFF2E8B7B) : const Color(0xFFF5A962),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly || hasCalendar,
          onTap: onTap,
          validator: validator,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isResult ? const Color(0xFF2E8B7B) : const Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.black26),
            prefixIcon: icon != null
                ? Icon(icon,
                    size: 16,
                    color: isResult ? const Color(0xFF2E8B7B) : Colors.black38)
                : null,
            suffixIcon: hasCalendar
                ? const Icon(Icons.calendar_month_outlined,
                    size: 18, color: Color(0xFFF5A962))
                : null,
            filled: true,
            fillColor: isResult
                ? const Color(0xFFEDF7F6)
                : const Color(0xFFFAFAFA),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isResult
                    ? const Color(0xFF2E8B7B).withValues(alpha: 0.3)
                    : const Color(0xFFEEEEEE),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isResult
                    ? const Color(0xFF2E8B7B)
                    : const Color(0xFFF5A962),
                width: 2,
              ),
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

  Widget _buildSectionHeader(String title, IconData icon,
      {List<Color> gradientColors = const [
        Color(0xFFF5A962),
        Color(0xFFF08030),
      ]}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.35),
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
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: gradientColors.first,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                  'ANTHROPOMETRIC DATA', Icons.monitor_weight_outlined),
              const SizedBox(height: 14),

              // ── Date of Measurement — tap to open calendar ────────────
              _buildField(
                label: 'DATE OF MEASUREMENT',
                controller: widget.dateController,
                hint: 'Tap to select date',
                hasCalendar: true,
                icon: Icons.calendar_today_outlined,
                onTap: _pickMeasurementDate,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Date of measurement is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'WEIGHT (KG)',
                      controller: widget.weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      hint: '0.0',
                      icon: Icons.fitness_center_outlined,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final w = double.tryParse(v.trim());
                        if (w == null) return 'Invalid number';
                        if (w <= 0 || w > 300) return 'Invalid weight';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField(
                      label: 'HEIGHT (CM)',
                      controller: widget.heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      hint: '0.0',
                      icon: Icons.height_outlined,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final h = double.tryParse(v.trim());
                        if (h == null) return 'Invalid number';
                        if (h <= 0 || h > 300) return 'Invalid height';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _buildField(
                label: 'MUAC (CM)',
                controller: widget.muacController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                hint: '0.0',
                icon: Icons.straighten_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'MUAC is required';
                  final m = double.tryParse(v.trim());
                  if (m == null) return 'Invalid number';
                  if (m <= 0) return 'Invalid MUAC value';
                  return null;
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'WHO Z-SCORE RESULTS',
                Icons.auto_graph_outlined,
                gradientColors: const [Color(0xFF2E8B7B), Color(0xFF5CAA7F)],
              ),
              const SizedBox(height: 4),
              const Text(
                'Auto-calculated from inputs above',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black38,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'WEIGHT-FOR-AGE',
                      controller: widget.weightForAgeController,
                      readOnly: true,
                      icon: Icons.monitor_weight_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField(
                      label: 'WEIGHT-FOR-HEIGHT',
                      controller: widget.weightForHeightController,
                      readOnly: true,
                      icon: Icons.swap_vert_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'HEIGHT-FOR-AGE',
                      controller: widget.heightForAgeController,
                      readOnly: true,
                      icon: Icons.height_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField(
                      label: 'BMI (KG/M²)',
                      controller: widget.bmiController,
                      readOnly: true,
                      icon: Icons.calculate_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}