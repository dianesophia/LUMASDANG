import 'package:flutter/material.dart';
import 'form_card.dart';
import 'form_field_row.dart';

class DewormingForm extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onSave;
  final String? errorText;

  const DewormingForm({super.key, this.onSave, this.errorText});

  @override
  State<DewormingForm> createState() => _DewormingFormState();
}

class _DewormingFormState extends State<DewormingForm> {
  // ── Theme constants (mirrors other forms) ─────────────────────────────────
  static const Color _primary = Color(0xFFB5651D);
  static const Color _primaryLight = Color(0xFFFFF3E0);
  static const Color _surface = Colors.white;
  static const Color _surfaceAlt = Color(0xFFFDF6EE);
  static const Color _border = Color(0xFFE8C9A0);
  static const Color _labelColor = Color(0xFF795548);
  static const Color _textColor = Color(0xFF3E2723);

  bool _isNA = false;
  String? _drugGiven;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _adverseController = TextEditingController();
  final TextEditingController _nextDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateController.addListener(_notifyParent);
    _adverseController.addListener(_notifyParent);
    _nextDateController.addListener(_notifyParent);
  }

  @override
  void dispose() {
    _dateController.removeListener(_notifyParent);
    _adverseController.removeListener(_notifyParent);
    _nextDateController.removeListener(_notifyParent);
    _dateController.dispose();
    _adverseController.dispose();
    _nextDateController.dispose();
    super.dispose();
  }

  void _notifyParent() {
    widget.onSave?.call({
      'dateOfLastDeworming': _dateController.text.trim(),
      'isNA': _isNA,
      'drugGiven': _drugGiven,
      'adverseReactions': _adverseController.text.trim(),
      'nextDewormingDate': _nextDateController.text.trim(),
    });
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
            color: readOnly ? _labelColor : _textColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFD4A97A)),
            prefixIcon: prefixIcon,
            prefixIconColor: readOnly ? _labelColor : _primary,
            filled: true,
            fillColor: readOnly ? const Color(0xFFF0EBE3) : _surfaceAlt,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: readOnly ? const Color(0xFFD4B896) : _border,
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

  /// A styled drug option pill toggle.
  Widget _buildDrugOption(String drug) {
    final selected = !_isNA && _drugGiven == drug;
    return GestureDetector(
      onTap: _isNA
          ? null
          : () {
              setState(() => _drugGiven = selected ? null : drug);
              _notifyParent();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _primary : (_isNA ? const Color(0xFFF0EBE3) : _surfaceAlt),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _primary : (_isNA ? const Color(0xFFD4B896) : _border),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: selected ? Colors.white : (_isNA ? const Color(0xFFD4B896) : _labelColor),
            ),
            const SizedBox(width: 8),
            Text(
              drug,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : (_isNA ? const Color(0xFFD4B896) : _textColor),
              ),
            ),
          ],
        ),
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
                  child: const Icon(Icons.medication_outlined,
                      size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Deworming',
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
                // ── Error banner ─────────────────────────────────────────
                if (widget.errorText != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.3),
                          width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 16, color: Color(0xFFEF4444)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.errorText!,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFFEF4444)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Date of Last Deworming ───────────────────────────────
                _buildField(
                  label: 'Date of Last Deworming',
                  controller: _dateController,
                  keyboardType: TextInputType.datetime,
                  hint: 'MM-DD-YYYY',
                  readOnly: _isNA,
                  prefixIcon:
                      const Icon(Icons.calendar_today_outlined, size: 18),
                  validator: (v) {
                    if (_isNA) return null;
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter a date or select N/A';
                    }
                    if (!RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(v.trim())) {
                      return 'Use format MM-DD-YYYY';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // N/A toggle
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isNA = !_isNA;
                      if (_isNA) {
                        _dateController.clear();
                        _nextDateController.clear();
                        _adverseController.clear();
                        _drugGiven = null;
                      }
                    });
                    _notifyParent();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _isNA ? _primary : _surfaceAlt,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: _isNA ? _primary : _border,
                            width: 1.5,
                          ),
                        ),
                        child: _isNA
                            ? const Icon(Icons.check,
                                size: 13, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'N/A — Not yet dewormed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _labelColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Drug Given ───────────────────────────────────────────
                _buildLabel('Drug Given'),
                Row(
                  children: [
                    _buildDrugOption('Albendazole'),
                    const SizedBox(width: 10),
                    _buildDrugOption('Mebendazole'),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Adverse Reactions ────────────────────────────────────
                _buildField(
                  label: 'Adverse Reactions',
                  controller: _adverseController,
                  hint: 'Describe any reactions (if none, leave blank)',
                  readOnly: _isNA,
                  prefixIcon:
                      const Icon(Icons.warning_amber_outlined, size: 18),
                ),

                const SizedBox(height: 14),

                // ── Next Deworming Date ──────────────────────────────────
                _buildField(
                  label: 'Next Deworming Date',
                  controller: _nextDateController,
                  keyboardType: TextInputType.datetime,
                  hint: 'MM-DD-YYYY',
                  readOnly: _isNA,
                  prefixIcon:
                      const Icon(Icons.event_outlined, size: 18),
                  validator: (v) {
                    if (_isNA) return null;
                    if (v == null || v.trim().isEmpty) {
                      return 'Next deworming date is required';
                    }
                    if (!RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(v.trim())) {
                      return 'Use format MM-DD-YYYY';
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