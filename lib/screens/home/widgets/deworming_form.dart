import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'form_field_label.dart';

class DewormingForm extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onSave;
  final String? errorText;

  const DewormingForm({super.key, this.onSave, this.errorText});

  @override
  State<DewormingForm> createState() => _DewormingFormState();
}

class _DewormingFormState extends State<DewormingForm> {
  // ── Deworming ──────────────────────────────────────────────────────────────
  bool _isNA = false;
  String? _drugGiven;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _adverseController = TextEditingController();
  final TextEditingController _nextDateController = TextEditingController();

  // ── Vitamin A ──────────────────────────────────────────────────────────────
  bool _vitANA = false;
  String? _vitADose; // '100,000 IU' | '200,000 IU'
  final TextEditingController _vitADateController = TextEditingController();
  final TextEditingController _vitANextDateController =
      TextEditingController();
  final TextEditingController _vitARemarksController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final c in _allControllers) {
      c.addListener(_notifyParent);
    }
  }

  @override
  void dispose() {
    for (final c in _allControllers) {
      c.removeListener(_notifyParent);
      c.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get _allControllers => [
        _dateController,
        _adverseController,
        _nextDateController,
        _vitADateController,
        _vitANextDateController,
        _vitARemarksController,
      ];

  void _notifyParent() {
    widget.onSave?.call({
      // Deworming
      'deworming': {
        'dateOfLastDeworming': _dateController.text.trim(),
        'isNA': _isNA,
        'drugGiven': _drugGiven,
        'adverseReactions': _adverseController.text.trim(),
        'nextDewormingDate': _nextDateController.text.trim(),
      },
      // Vitamin A
      'vitaminA': {
        'isNA': _vitANA,
        'dose': _vitADose,
        'date': _vitADateController.text.trim(),
        'nextDate': _vitANextDateController.text.trim(),
        'remarks': _vitARemarksController.text.trim(),
      },
      // Legacy flat keys kept for backward-compat with home_page validator
      'dateOfLastDeworming': _dateController.text.trim(),
      'isNA': _isNA,
      'drugGiven': _drugGiven,
    });
  }

  // ── Date picker ────────────────────────────────────────────────────────────
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

  // ── Reusable widgets ───────────────────────────────────────────────────────

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
    int maxLines = 1,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(label: label, isOptional: isOptional),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly || hasCalendar,
          onTap: onTap,
          validator: validator,
          maxLines: maxLines,
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
            fillColor:
                readOnly ? const Color(0xFFF5F5F5) : const Color(0xFFFAFAFA),
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

  /// Styled card wrapper with header
  Widget _buildSubCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  /// N/A toggle checkbox row
  Widget _buildNAToggle({
    required bool value,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value
                  ? const Color(0xFFF5A962)
                  : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: value
                    ? const Color(0xFFF5A962)
                    : const Color(0xFFEEEEEE),
                width: 1.5,
              ),
            ),
            child: value
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// Generic pill chip selector
  Widget _buildChip(
    String label,
    bool selected,
    bool disabled,
    VoidCallback onTap, {
    Color activeColor = const Color(0xFFF5A962),
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? activeColor
              : (disabled
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFFFAFAFA)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? activeColor : const Color(0xFFEEEEEE),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 13,
              color: selected
                  ? Colors.white
                  : (disabled ? Colors.black26 : Colors.black38),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : (disabled ? Colors.black26 : const Color(0xFF1A1A1A)),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  // ── Section builders ───────────────────────────────────────────────────────

  Widget _buildDewormingSection() {
    return _buildSubCard(
      title: 'DEWORMING',
      icon: Icons.medication_outlined,
      iconColor: const Color(0xFFF08030),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date of Last Deworming
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
          ),
          const SizedBox(height: 10),

          // N/A toggle
          _buildNAToggle(
            value: _isNA,
            label: 'N/A — Not yet dewormed',
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
          ),
          const SizedBox(height: 14),

          // Drug Given
          const FormFieldLabel(label: 'DRUG GIVEN'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildChip(
                'Albendazole',
                !_isNA && _drugGiven == 'Albendazole',
                _isNA,
                () {
                  setState(() =>
                      _drugGiven = _drugGiven == 'Albendazole'
                          ? null
                          : 'Albendazole');
                  _notifyParent();
                },
              ),
              _buildChip(
                'Mebendazole',
                !_isNA && _drugGiven == 'Mebendazole',
                _isNA,
                () {
                  setState(() =>
                      _drugGiven = _drugGiven == 'Mebendazole'
                          ? null
                          : 'Mebendazole');
                  _notifyParent();
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Adverse Reactions
          _buildField(
            label: 'ADVERSE REACTIONS',
            controller: _adverseController,
            hint: 'Describe any reactions (if none, leave blank)',
            readOnly: _isNA,
            icon: Icons.warning_amber_outlined,
            isOptional: true,
          ),
          const SizedBox(height: 12),

          // Next Deworming Date
          _buildField(
            label: 'NEXT DEWORMING DATE',
            controller: _nextDateController,
            hint: 'Tap to select date',
            readOnly: _isNA,
            hasCalendar: true,
            icon: Icons.event_outlined,
            isOptional: true,
            onTap: _isNA
                ? null
                : () => _pickDate(
                      controller: _nextDateController,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 5)),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitaminASection() {
    return _buildSubCard(
      title: 'VITAMIN A SUPPLEMENTATION',
      icon: Icons.local_pharmacy_outlined,
      iconColor: const Color(0xFFE67E22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dose info banner
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE67E22).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFE67E22).withValues(alpha: 0.25),
                  width: 1.2),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 15, color: Color(0xFFE67E22)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '100,000 IU — Children 6–11 months\n'
                    '200,000 IU — Children 12–59 months',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFE67E22),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Date of Vit A
          _buildField(
            label: 'DATE OF VITAMIN A SUPPLEMENTATION',
            controller: _vitADateController,
            hint: 'Tap to select date',
            readOnly: _vitANA,
            hasCalendar: true,
            icon: Icons.calendar_today_outlined,
            onTap: _vitANA
                ? null
                : () => _pickDate(
                      controller: _vitADateController,
                      lastDate: DateTime.now(),
                    ),
          ),
          const SizedBox(height: 10),

          // N/A toggle
          _buildNAToggle(
            value: _vitANA,
            label: 'N/A — Not yet given',
            onTap: () {
              setState(() {
                _vitANA = !_vitANA;
                if (_vitANA) {
                  _vitADateController.clear();
                  _vitANextDateController.clear();
                  _vitARemarksController.clear();
                  _vitADose = null;
                }
              });
              _notifyParent();
            },
          ),
          const SizedBox(height: 14),

          // Dose chips
          const FormFieldLabel(label: 'DOSE', isOptional: true),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildChip(
                '100,000 IU  (6–11 mos)',
                !_vitANA && _vitADose == '100,000 IU',
                _vitANA,
                () {
                  setState(() => _vitADose =
                      _vitADose == '100,000 IU' ? null : '100,000 IU');
                  _notifyParent();
                },
                activeColor: const Color(0xFFE67E22),
              ),
              _buildChip(
                '200,000 IU  (12–59 mos)',
                !_vitANA && _vitADose == '200,000 IU',
                _vitANA,
                () {
                  setState(() => _vitADose =
                      _vitADose == '200,000 IU' ? null : '200,000 IU');
                  _notifyParent();
                },
                activeColor: const Color(0xFFE67E22),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Remarks
          _buildField(
            label: 'REMARKS',
            controller: _vitARemarksController,
            hint: 'e.g. Child tolerated well…',
            readOnly: _vitANA,
            icon: Icons.notes_outlined,
            maxLines: 2,
            isOptional: true,
          ),
          const SizedBox(height: 12),

          // Next Vit A Date
          _buildField(
            label: 'NEXT VITAMIN A DATE',
            controller: _vitANextDateController,
            hint: 'Tap to select date',
            readOnly: _vitANA,
            hasCalendar: true,
            icon: Icons.event_outlined,
            isOptional: true,
            onTap: _vitANA
                ? null
                : () => _pickDate(
                      controller: _vitANextDateController,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 5)),
                    ),
          ),
        ],
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              'DEWORMING & VITAMIN A',
              Icons.medical_services_outlined),
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
                    child: Text(
                      widget.errorText!,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── 1. Deworming ─────────────────────────────────────────────
          _buildDewormingSection(),
          const SizedBox(height: 12),

          // ── 2. Vitamin A ─────────────────────────────────────────────
          _buildVitaminASection(),
        ],
      ),
    );
  }
}