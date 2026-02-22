import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // add intl to pubspec.yaml

class DewormingForm extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onSave;
  final String? errorText;

  const DewormingForm({super.key, this.onSave, this.errorText});

  @override
  State<DewormingForm> createState() => _DewormingFormState();
}

class _DewormingFormState extends State<DewormingForm> {
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

  // ── Calendar helper ─────────────────────────────────────────────────────
  Future<void> _pickDate({
    required TextEditingController controller,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final effectiveFirst = firstDate ?? DateTime(2000);
    final effectiveLast =
        lastDate ?? DateTime.now().add(const Duration(days: 365 * 5));

    DateTime initialDate = DateTime.now();
    final existing = controller.text.trim();
    if (existing.isNotEmpty) {
      try {
        final parsed = DateFormat('MM-dd-yyyy').parse(existing);
        if (!parsed.isBefore(effectiveFirst) &&
            !parsed.isAfter(effectiveLast)) {
          initialDate = parsed;
        }
      } catch (_) {}
    }
    // Clamp initialDate within bounds
    if (initialDate.isBefore(effectiveFirst)) initialDate = effectiveFirst;
    if (initialDate.isAfter(effectiveLast)) initialDate = effectiveLast;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: effectiveFirst,
      lastDate: effectiveLast,
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
      controller.text = DateFormat('MM-dd-yyyy').format(picked);
      _notifyParent();
    }
  }

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
          readOnly: readOnly || hasCalendar,
          onTap: onTap,
          validator: validator,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: readOnly ? Colors.black38 : const Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.black26),
            prefixIcon: icon != null
                ? Icon(icon, size: 16, color: Colors.black38)
                : null,
            suffixIcon: hasCalendar && !readOnly
                ? const Icon(Icons.calendar_month_outlined,
                    size: 18, color: Color(0xFFF5A962))
                : null,
            filled: true,
            fillColor: readOnly
                ? const Color(0xFFF5F5F5)
                : const Color(0xFFFAFAFA),
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
          color: selected
              ? const Color(0xFFF5A962)
              : (_isNA ? const Color(0xFFF5F5F5) : const Color(0xFFFAFAFA)),
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
              color: selected
                  ? Colors.white
                  : (_isNA ? Colors.black26 : Colors.black38),
            ),
            const SizedBox(width: 8),
            Text(
              drug,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : (_isNA ? Colors.black26 : const Color(0xFF1A1A1A)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('DEWORMING', Icons.medication_outlined),
          const SizedBox(height: 14),

          // Error banner
          if (widget.errorText != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 16, color: Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.errorText!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFEF4444))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Date of Last Deworming ────────────────────────────────────
          _buildField(
            label: 'DATE OF LAST DEWORMING',
            controller: _dateController,
            hint: 'Tap to select date',
            readOnly: _isNA,
            hasCalendar: true,
            icon: Icons.calendar_today_outlined,
            onTap: _isNA
                ? null
                : () => _pickDate(
                      controller: _dateController,
                      lastDate: DateTime.now(),
                    ),
            validator: (v) {
              if (_isNA) return null;
              if (v == null || v.trim().isEmpty) {
                return 'Select a date or tick N/A';
              }
              return null;
            },
          ),

          const SizedBox(height: 10),

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
                    color: _isNA
                        ? const Color(0xFFF5A962)
                        : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _isNA
                          ? const Color(0xFFF5A962)
                          : const Color(0xFFEEEEEE),
                      width: 1.5,
                    ),
                  ),
                  child: _isNA
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 8),
                const Text(
                  'N/A — Not yet dewormed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'DRUG GIVEN',
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
              _buildDrugOption('Albendazole'),
              const SizedBox(width: 10),
              _buildDrugOption('Mebendazole'),
            ],
          ),

          const SizedBox(height: 14),

          _buildField(
            label: 'ADVERSE REACTIONS',
            controller: _adverseController,
            hint: 'Describe any reactions (if none, leave blank)',
            readOnly: _isNA,
            icon: Icons.warning_amber_outlined,
          ),

          const SizedBox(height: 12),

          // ── Next Deworming Date ───────────────────────────────────────
          _buildField(
            label: 'NEXT DEWORMING DATE',
            controller: _nextDateController,
            hint: 'Tap to select date',
            readOnly: _isNA,
            hasCalendar: true,
            icon: Icons.event_outlined,
            onTap: _isNA
                ? null
                : () => _pickDate(
                      controller: _nextDateController,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 5)),
                    ),
            validator: (v) {
              if (_isNA) return null;
              if (v == null || v.trim().isEmpty) {
                return 'Next deworming date is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}