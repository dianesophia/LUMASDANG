import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // add intl to pubspec.yaml

class DemographicDataForm extends StatefulWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController ageController;
  final TextEditingController sexController;
  final TextEditingController addressController;
  final TextEditingController placeOfBirthController;
  final TextEditingController dobController;
  final TextEditingController motherController;
  final TextEditingController motherContactController;
  final TextEditingController fatherController;
  final TextEditingController fatherContactController;
  final bool? belongsToIpGroup;
  final ValueChanged<bool?>? onBelongsToIpGroupChanged;

  const DemographicDataForm({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.ageController,
    required this.sexController,
    required this.addressController,
    required this.placeOfBirthController,
    required this.dobController,
    required this.motherController,
    required this.motherContactController,
    required this.fatherController,
    required this.fatherContactController,
    this.belongsToIpGroup,
    this.onBelongsToIpGroupChanged,
  });

  @override
  State<DemographicDataForm> createState() => _DemographicDataFormState();
}

class _DemographicDataFormState extends State<DemographicDataForm> {
  bool? _belongsToIpGroup;

  @override
  void initState() {
    super.initState();
    _belongsToIpGroup = widget.belongsToIpGroup;
  }

  @override
  void didUpdateWidget(DemographicDataForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.belongsToIpGroup != widget.belongsToIpGroup) {
      _belongsToIpGroup = widget.belongsToIpGroup;
    }
  }

  // ── Phone number validation ─────────────────────────────────────────────
  // Accepts: 09XXXXXXXXX  (11 digits) OR +639XXXXXXXXX (13 chars)
  static final _phoneRegex = RegExp(r'^(09\d{9}|\+639\d{9})$');

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Contact number is required';
    if (!_phoneRegex.hasMatch(v.trim())) {
      return 'Enter a valid PH number (09XXXXXXXXX or +639XXXXXXXXX)';
    }
    return null;
  }

  // ── Calendar date picker ────────────────────────────────────────────────
  Future<void> _pickDate(BuildContext context) async {
    // Parse existing value so the picker opens on the already-set date
    DateTime initialDate = DateTime.now();
    final existing = widget.dobController.text.trim();
    if (existing.isNotEmpty) {
      try {
        initialDate = DateFormat('MM-dd-yyyy').parse(existing);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      // Children can be at most 5 years old (60 months) — allow up to today
      firstDate: DateTime(DateTime.now().year - 6),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
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
        );
      },
    );

    if (picked != null) {
      widget.dobController.text = DateFormat('MM-dd-yyyy').format(picked);

      // Auto-calculate age in months
      final now = DateTime.now();
      final months = (now.year - picked.year) * 12 + (now.month - picked.month);
      widget.ageController.text = months.clamp(0, 60).toString();
    }
  }

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

  // ── Shared field builder ────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    String? Function(String?)? validator,
    IconData? icon,
    bool readOnly = false,
    VoidCallback? onTap,
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
          readOnly: readOnly,
          onTap: onTap,
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
            // Show calendar icon suffix for the DOB field
            suffixIcon: onTap != null
                ? const Icon(Icons.calendar_month_outlined,
                    size: 18, color: Color(0xFFF5A962))
                : null,
            filled: true,
            fillColor: readOnly
                ? const Color(0xFFF5F5F5) // slightly different for read-only
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

  // ── Card wrapper ────────────────────────────────────────────────────────
  Widget _buildCard({required Widget child}) {
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
      child: child,
    );
  }

  // ── Section header ──────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
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
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Card 1: Basic Info ─────────────────────────────────────────
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('BASIC INFORMATION', Icons.person_outline),
              const SizedBox(height: 14),

              // First + Last Name
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'FIRST NAME',
                      controller: widget.firstNameController,
                      icon: Icons.badge_outlined,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 2) return 'Min. 2 characters';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField(
                      label: 'LAST NAME',
                      controller: widget.lastNameController,
                      icon: Icons.badge_outlined,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 2) return 'Min. 2 characters';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Age + Sex
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'AGE (MONTHS)',
                      controller: widget.ageController,
                      keyboardType: TextInputType.number,
                      hint: '0 – 60',
                      icon: Icons.cake_outlined,
                      // Age is auto-filled from DOB; still allow manual entry
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final age = int.tryParse(v.trim());
                        if (age == null) return 'Enter a number';
                        if (age < 0 || age > 60) return 'Must be 0–60';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField(
                      label: 'SEX',
                      controller: widget.sexController,
                      hint: 'M or F',
                      icon: Icons.wc_outlined,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final s = v.trim().toUpperCase();
                        if (s != 'M' && s != 'F' && s != 'MALE' && s != 'FEMALE') {
                          return 'Enter M or F';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Date of Birth — tap to open calendar ─────────────────
              _buildField(
                label: 'DATE OF BIRTH',
                controller: widget.dobController,
                hint: 'Tap to select date',
                icon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: () => _pickDate(context),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Date of birth is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Belongs to IP group (Yes/No)
              const Text(
                'BELONGS TO IP GROUP?',
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
                  _buildTogglePill('Yes', _belongsToIpGroup == true, () {
                    setState(() => _belongsToIpGroup = true);
                    widget.onBelongsToIpGroupChanged?.call(true);
                  }),
                  const SizedBox(width: 10),
                  _buildTogglePill('No', _belongsToIpGroup == false, () {
                    setState(() => _belongsToIpGroup = false);
                    widget.onBelongsToIpGroupChanged?.call(false);
                  }),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Card 2: Address ────────────────────────────────────────────
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('ADDRESS', Icons.home_outlined),
              const SizedBox(height: 14),

              _buildField(
                label: 'ADDRESS',
                controller: widget.addressController,
                icon: Icons.home_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Address is required';
                  return null;
                },
              ),

              const SizedBox(height: 12),

              _buildField(
                label: 'PLACE OF BIRTH',
                controller: widget.placeOfBirthController,
                icon: Icons.location_on_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Place of birth is required';
                  return null;
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Card 3: Mother's Info ──────────────────────────────────────
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("MOTHER'S INFORMATION", Icons.woman_outlined),
              const SizedBox(height: 14),

              _buildField(
                label: "MOTHER'S FULL NAME",
                controller: widget.motherController,
                icon: Icons.person_outline,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Mother's name is required";
                  return null;
                },
              ),

              const SizedBox(height: 12),

              _buildField(
                label: 'CONTACT NUMBER',
                controller: widget.motherContactController,
                keyboardType: TextInputType.phone,
                hint: '09XXXXXXXXX',
                icon: Icons.phone_outlined,
                validator: _validatePhone,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Card 4: Father's Info ──────────────────────────────────────
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("FATHER'S INFORMATION", Icons.man_outlined),
              const SizedBox(height: 14),

              _buildField(
                label: "FATHER'S FULL NAME",
                controller: widget.fatherController,
                icon: Icons.person_outline,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Father's name is required";
                  return null;
                },
              ),

              const SizedBox(height: 12),

              _buildField(
                label: 'CONTACT NUMBER',
                controller: widget.fatherContactController,
                keyboardType: TextInputType.phone,
                hint: '09XXXXXXXXX',
                icon: Icons.phone_outlined,
                validator: _validatePhone,
              ),
            ],
          ),
        ),
      ],
    );
  }
}