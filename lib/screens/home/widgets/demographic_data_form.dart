import 'package:flutter/material.dart';

class DemographicDataForm extends StatelessWidget {
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
  });

  // ── Shared field builder ────────────────────────────────────────────────
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

  // ── Card wrapper (same shadow/radius as stats_row & upcoming_events) ────
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

  // ── Section header row (icon + title) — same as stats/events labels ────
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
                      controller: firstNameController,
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
                      controller: lastNameController,
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
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      hint: '0 – 60',
                      icon: Icons.cake_outlined,
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
                      controller: sexController,
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

              // Date of Birth
              _buildField(
                label: 'DATE OF BIRTH',
                controller: dobController,
                keyboardType: TextInputType.datetime,
                hint: 'MM-DD-YYYY',
                icon: Icons.calendar_today_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Date of birth is required';
                  if (!RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(v.trim())) {
                    return 'Use format MM-DD-YYYY';
                  }
                  return null;
                },
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
                controller: addressController,
                icon: Icons.home_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Address is required';
                  return null;
                },
              ),

              const SizedBox(height: 12),

              _buildField(
                label: 'PLACE OF BIRTH',
                controller: placeOfBirthController,
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
                controller: motherController,
                icon: Icons.person_outline,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Mother's name is required";
                  return null;
                },
              ),

              const SizedBox(height: 12),

              _buildField(
                label: 'CONTACT NUMBER',
                controller: motherContactController,
                keyboardType: TextInputType.phone,
                hint: '09XXXXXXXXX',
                icon: Icons.phone_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Contact number is required';
                  if (v.trim().length != 11) return 'Enter a valid 11-digit number';
                  return null;
                },
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
                controller: fatherController,
                icon: Icons.person_outline,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Father's name is required";
                  return null;
                },
              ),

              const SizedBox(height: 12),

              _buildField(
                label: 'CONTACT NUMBER',
                controller: fatherContactController,
                keyboardType: TextInputType.phone,
                hint: '09XXXXXXXXX',
                icon: Icons.phone_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Contact number is required';
                  if (v.trim().length != 11) return 'Enter a valid 11-digit number';
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