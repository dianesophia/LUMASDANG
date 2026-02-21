import 'package:flutter/material.dart';
import 'form_card.dart';
import 'form_field_row.dart';

class DemographicDataForm extends StatelessWidget {
  // ── Theme constants (mirrors AnthropometricDataForm) ──────────────────────
  static const Color _primary = Color(0xFFB5651D);
  static const Color _primaryLight = Color(0xFFFFF3E0);
  static const Color _surface = Colors.white;
  static const Color _surfaceAlt = Color(0xFFFDF6EE);
  static const Color _border = Color(0xFFE8C9A0);
  static const Color _labelColor = Color(0xFF795548);
  static const Color _textColor = Color(0xFF3E2723);

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
              borderSide:
                  const BorderSide(color: Color(0xFFE8985A), width: 2),
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
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  /// Grouped sub-section with a subtle header divider (used for Parent info).
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
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: _primaryLight,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_outline,
                      size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Demographic Data',
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
                // First + Last Name
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'First Name',
                        controller: firstNameController,
                        prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          if (v.trim().length < 2) {
                            return 'Min. 2 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        label: 'Last Name',
                        controller: lastNameController,
                        prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          if (v.trim().length < 2) {
                            return 'Min. 2 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Age + Sex
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'Age (months)',
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        hint: '0 – 60',
                        prefixIcon:
                            const Icon(Icons.cake_outlined, size: 18),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          final age = int.tryParse(v.trim());
                          if (age == null) return 'Enter a number';
                          if (age < 0 || age > 60) {
                            return 'Must be 0–60';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        label: 'Sex',
                        controller: sexController,
                        hint: 'M or F',
                        prefixIcon: const Icon(
                            Icons.wc_outlined, size: 18),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          final sex = v.trim().toUpperCase();
                          if (sex != 'M' &&
                              sex != 'F' &&
                              sex != 'MALE' &&
                              sex != 'FEMALE') {
                            return 'Enter M or F';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Date of Birth
                _buildField(
                  label: 'Date of Birth',
                  controller: dobController,
                  keyboardType: TextInputType.datetime,
                  hint: 'MM-DD-YYYY',
                  prefixIcon:
                      const Icon(Icons.calendar_today_outlined, size: 18),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Date of birth is required';
                    }
                    if (!RegExp(r'^\d{2}-\d{2}-\d{4}$')
                        .hasMatch(v.trim())) {
                      return 'Use format MM-DD-YYYY';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // Address
                _buildField(
                  label: 'Address',
                  controller: addressController,
                  prefixIcon:
                      const Icon(Icons.home_outlined, size: 18),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Address is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // Place of Birth
                _buildField(
                  label: 'Place of Birth',
                  controller: placeOfBirthController,
                  prefixIcon:
                      const Icon(Icons.location_on_outlined, size: 18),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Place of birth is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Mother sub-section ───────────────────────────────────
                _buildSubSection(
                  title: 'Mother\'s Information',
                  icon: Icons.woman_outlined,
                  children: [
                    _buildField(
                      label: 'Mother\'s Full Name',
                      controller: motherController,
                      prefixIcon:
                          const Icon(Icons.person_outline, size: 18),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Mother\'s name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      label: 'Contact Number',
                      controller: motherContactController,
                      keyboardType: TextInputType.phone,
                      hint: '09XXXXXXXXX',
                      prefixIcon:
                          const Icon(Icons.phone_outlined, size: 18),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Contact number is required';
                        }
                        if (v.trim().length != 11) {
                          return 'Enter a valid 11-digit number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Father sub-section ───────────────────────────────────
                _buildSubSection(
                  title: 'Father\'s Information',
                  icon: Icons.man_outlined,
                  children: [
                    _buildField(
                      label: 'Father\'s Full Name',
                      controller: fatherController,
                      prefixIcon:
                          const Icon(Icons.person_outline, size: 18),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Father\'s name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      label: 'Contact Number',
                      controller: fatherContactController,
                      keyboardType: TextInputType.phone,
                      hint: '09XXXXXXXXX',
                      prefixIcon:
                          const Icon(Icons.phone_outlined, size: 18),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Contact number is required';
                        }
                        if (v.trim().length != 11) {
                          return 'Enter a valid 11-digit number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}