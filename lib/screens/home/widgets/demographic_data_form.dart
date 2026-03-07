import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DemographicDataForm extends StatefulWidget {
  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController lastNameController;
  final TextEditingController ageController;         // age in months (auto)
  final TextEditingController ageDaysController;     // age in days (auto)
  final TextEditingController ageYearsController;    // age in years (auto)
  final TextEditingController sexController;
  final TextEditingController addressController;
  final TextEditingController placeOfBirthController;
  final TextEditingController dobController;
  final TextEditingController motherController;
  final TextEditingController motherContactController;
  final TextEditingController motherAgeController;
  final TextEditingController motherOccupationController;
  final TextEditingController fatherController;
  final TextEditingController fatherContactController;
  final TextEditingController fatherAgeController;
  final TextEditingController fatherOccupationController;
  final TextEditingController religionController;
  final TextEditingController residenceStatusController;
  final TextEditingController lengthOfStayController;
  final TextEditingController birthWeightController;
  final TextEditingController birthOrderController;
  // Caregiver
  final TextEditingController caregiverNameController;
  final TextEditingController caregiverAgeController;
  final TextEditingController caregiverEthnicityController;
  final TextEditingController caregiverRelationshipController;
  final TextEditingController caregiverReligionController;
  // 4Ps
  final TextEditingController fourPsHouseholdIdController;
  // Disability
  final TextEditingController disabilityController;

  final bool? belongsToIpGroup;
  final String? ipEthnicity;          // 'Ibaloi' | 'Kankanaey' | 'Other' | null
  final String? ipRemarksOther;       // free text when 'Other'
  final bool? isFourPsMember;
  final bool? hasDisability;
  final ValueChanged<bool?>? onBelongsToIpGroupChanged;
  final ValueChanged<String?>? onIpEthnicityChanged;
  final ValueChanged<bool?>? onIsFourPsMemberChanged;
  final ValueChanged<bool?>? onHasDisabilityChanged;

  final VoidCallback? onSaveDraft;
  final VoidCallback? onSubmit;

  const DemographicDataForm({
    super.key,
    required this.firstNameController,
    required this.middleNameController,
    required this.lastNameController,
    required this.ageController,
    required this.ageDaysController,
    required this.ageYearsController,
    required this.sexController,
    required this.addressController,
    required this.placeOfBirthController,
    required this.dobController,
    required this.motherController,
    required this.motherContactController,
    required this.motherAgeController,
    required this.motherOccupationController,
    required this.fatherController,
    required this.fatherContactController,
    required this.fatherAgeController,
    required this.fatherOccupationController,
    required this.religionController,
    required this.residenceStatusController,
    required this.lengthOfStayController,
    required this.birthWeightController,
    required this.birthOrderController,
    required this.caregiverNameController,
    required this.caregiverAgeController,
    required this.caregiverEthnicityController,
    required this.caregiverRelationshipController,
    required this.caregiverReligionController,
    required this.fourPsHouseholdIdController,
    required this.disabilityController,
    this.belongsToIpGroup,
    this.ipEthnicity,
    this.ipRemarksOther,
    this.isFourPsMember,
    this.hasDisability,
    this.onBelongsToIpGroupChanged,
    this.onIpEthnicityChanged,
    this.onIsFourPsMemberChanged,
    this.onHasDisabilityChanged,
    this.onSaveDraft,
    this.onSubmit,
  });

  @override
  State<DemographicDataForm> createState() => _DemographicDataFormState();
}

class _DemographicDataFormState extends State<DemographicDataForm> {
  final _formKey = GlobalKey<FormState>();

  bool? _belongsToIpGroup;
  String? _ipEthnicity;
  bool _middleNameNA = false;
  bool _isDraft = false;
  bool? _isFourPsMember;
  bool? _hasDisability;

  // Residence status options
  String? _residenceStatus; // 'Tenant' | 'Permanent'

  @override
  void initState() {
    super.initState();
    _belongsToIpGroup = widget.belongsToIpGroup;
    _ipEthnicity = widget.ipEthnicity;
    _isFourPsMember = widget.isFourPsMember;
    _hasDisability = widget.hasDisability;
  }

  @override
  void didUpdateWidget(DemographicDataForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.belongsToIpGroup != widget.belongsToIpGroup) {
      _belongsToIpGroup = widget.belongsToIpGroup;
    }
    if (oldWidget.isFourPsMember != widget.isFourPsMember) {
      _isFourPsMember = widget.isFourPsMember;
    }
    if (oldWidget.hasDisability != widget.hasDisability) {
      _hasDisability = widget.hasDisability;
    }
  }

  // ── Phone validation ────────────────────────────────────────────────────
  static final _phoneRegex = RegExp(r'^(09\d{9}|\+639\d{9})$');

  String? _validatePhone(String? v) {
    if (_isDraft) return null;
    if (v == null || v.trim().isEmpty) return 'Contact number is required';
    if (!_phoneRegex.hasMatch(v.trim())) {
      return 'Enter a valid PH number (09XXXXXXXXX or +639XXXXXXXXX)';
    }
    return null;
  }

  // ── Required only on submit ─────────────────────────────────────────────
  String? _requiredOnSubmit(String? v, String message) {
    if (_isDraft) return null;
    if (v == null || v.trim().isEmpty) return message;
    return null;
  }

  // ── Draft save ──────────────────────────────────────────────────────────
  void _handleSaveDraft() {
    setState(() => _isDraft = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _formKey.currentState?.save();
      widget.onSaveDraft?.call();
      setState(() => _isDraft = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.save_outlined, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Draft saved successfully'),
          ]),
          backgroundColor: const Color(0xFFF5A962),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ),
      );
    });
  }

  void _handleSubmit() {
    setState(() => _isDraft = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_formKey.currentState?.validate() ?? false) {
        _formKey.currentState?.save();
        widget.onSubmit?.call();
      }
    });
  }

  // ── Auto-compute age from DOB ───────────────────────────────────────────
  Future<void> _pickDate(BuildContext context) async {
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
      firstDate: DateTime(DateTime.now().year - 6),
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
                foregroundColor: const Color(0xFFF5A962)),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      widget.dobController.text = DateFormat('MM-dd-yyyy').format(picked);
      final now = DateTime.now();

      // Age in days
      final days = now.difference(picked).inDays;
      widget.ageDaysController.text = days.clamp(0, 99999).toString();

      // Age in months
      final months =
          (now.year - picked.year) * 12 + (now.month - picked.month);
      widget.ageController.text = months.clamp(0, 60).toString();

      // Age in years (floor)
      final years = now.year -
          picked.year -
          (now.month < picked.month ||
                  (now.month == picked.month && now.day < picked.day)
              ? 1
              : 0);
      widget.ageYearsController.text = years.clamp(0, 5).toString();
    }
  }

  // ── Reusable widgets ────────────────────────────────────────────────────
  Widget _buildTogglePill(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color:
              selected ? const Color(0xFFF5A962) : const Color(0xFFFAFAFA),
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
              size: 14,
              color: selected ? Colors.white : Colors.black38,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    selected ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    String? Function(String?)? validator,
    IconData? icon,
    bool readOnly = false,
    bool enabled = true,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF5A962),
              letterSpacing: 0.5,
            )),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          enabled: enabled,
          onTap: onTap,
          maxLines: maxLines,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(fontSize: 12, color: Colors.black26),
            prefixIcon: icon != null
                ? Icon(icon, size: 16, color: Colors.black38)
                : null,
            suffixIcon: onTap != null
                ? const Icon(Icons.calendar_month_outlined,
                    size: 18, color: Color(0xFFF5A962))
                : null,
            filled: true,
            fillColor: (!enabled || readOnly)
                ? const Color(0xFFF0F0F0)
                : const Color(0xFFFAFAFA),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
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

  Widget _buildCard({required String? headerTitle, IconData? headerIcon, required Widget child}) {
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
          if (headerTitle != null && headerIcon != null) ...[
            _buildSectionHeader(headerTitle, headerIcon),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }

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
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFFF5A962),
              letterSpacing: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFFAAAAAA),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLabelRow(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF5A962),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildYesNoRow({
    required String label,
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelRow(label),
        Row(
          children: [
            _buildTogglePill('Yes', value == true, () => onChanged(true)),
            const SizedBox(width: 8),
            _buildTogglePill('No', value == false, () => onChanged(false)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card 1: Patient Basic Info ──────────────────────────────
          _buildCard(
            headerTitle: 'PATIENT INFORMATION',
            headerIcon: Icons.person_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First + Last Name (required)
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'FIRST NAME *',
                        controller: widget.firstNameController,
                        icon: Icons.badge_outlined,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (v.trim().length < 2) return 'Min. 2 chars';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildField(
                        label: 'LAST NAME *',
                        controller: widget.lastNameController,
                        icon: Icons.badge_outlined,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (v.trim().length < 2) return 'Min. 2 chars';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Middle Name + N/A checkbox
                _buildField(
                  label: 'MIDDLE NAME',
                  controller: widget.middleNameController,
                  icon: Icons.badge_outlined,
                  enabled: !_middleNameNA,
                  validator: (v) {
                    if (_isDraft || _middleNameNA) return null;
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.trim().length < 2) return 'Min. 2 chars';
                    return null;
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _middleNameNA,
                        activeColor: const Color(0xFFF5A962),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) {
                          setState(() {
                            _middleNameNA = val ?? false;
                            if (_middleNameNA) {
                              widget.middleNameController.clear();
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('N/A (no middle name)',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF888888))),
                  ],
                ),
                const SizedBox(height: 12),

                // Date of Birth → auto-computes all age fields
                _buildField(
                  label: 'DATE OF BIRTH',
                  controller: widget.dobController,
                  hint: 'Tap to select date',
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: () => _pickDate(context),
                  validator: (v) =>
                      _requiredOnSubmit(v, 'Date of birth is required'),
                ),
                const SizedBox(height: 12),

                // Age: Days / Months / Years (read-only, auto-filled)
                _buildSubHeader('AUTO-COMPUTED AGE'),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'DAYS',
                        controller: widget.ageDaysController,
                        icon: Icons.today_outlined,
                        readOnly: true,
                        hint: 'Auto',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildField(
                        label: 'MONTHS',
                        controller: widget.ageController,
                        icon: Icons.date_range_outlined,
                        readOnly: true,
                        hint: 'Auto',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildField(
                        label: 'YEARS',
                        controller: widget.ageYearsController,
                        icon: Icons.cake_outlined,
                        readOnly: true,
                        hint: 'Auto',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sex
                _buildField(
                  label: 'SEX',
                  controller: widget.sexController,
                  hint: 'M or F',
                  icon: Icons.wc_outlined,
                  validator: (v) {
                    if (_isDraft) return null;
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final s = v.trim().toUpperCase();
                    if (s != 'M' &&
                        s != 'F' &&
                        s != 'MALE' &&
                        s != 'FEMALE') return 'Enter M or F';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Birth Weight + Birth Order
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'BIRTH WEIGHT (kg)',
                        controller: widget.birthWeightController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        icon: Icons.monitor_weight_outlined,
                        hint: 'e.g. 3.2',
                        validator: (v) {
                          if (_isDraft || (v == null || v.trim().isEmpty))
                            return null;
                          final w = double.tryParse(v.trim());
                          if (w == null || w <= 0) return 'Invalid weight';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildField(
                        label: 'BIRTH ORDER',
                        controller: widget.birthOrderController,
                        keyboardType: TextInputType.number,
                        icon: Icons.sort_outlined,
                        hint: 'e.g. 1st, 2nd…',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Religion
                _buildField(
                  label: 'RELIGION',
                  controller: widget.religionController,
                  icon: Icons.church_outlined,
                  hint: 'e.g. Catholic, Islam…',
                ),
                const SizedBox(height: 12),

                // IP Group
                _buildLabelRow('BELONGS TO IP GROUP?'),
                Row(
                  children: [
                    _buildTogglePill(
                        'Yes', _belongsToIpGroup == true, () {
                      setState(() => _belongsToIpGroup = true);
                      widget.onBelongsToIpGroupChanged?.call(true);
                    }),
                    const SizedBox(width: 8),
                    _buildTogglePill(
                        'No', _belongsToIpGroup == false, () {
                      setState(() => _belongsToIpGroup = false);
                      widget.onIpEthnicityChanged?.call(null);
                      widget.onBelongsToIpGroupChanged?.call(false);
                    }),
                  ],
                ),

                // IP Ethnicity options (shown only when IP = Yes)
                if (_belongsToIpGroup == true) ...[
                  const SizedBox(height: 10),
                  _buildLabelRow('ETHNICITY'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final eth in [
                        'Ibaloi',
                        'Kankanaey',
                        'Kalanguya',
                        'Applai',
                        'Other'
                      ])
                        _buildTogglePill(eth, _ipEthnicity == eth, () {
                          setState(() => _ipEthnicity = eth);
                          widget.onIpEthnicityChanged?.call(eth);
                        }),
                    ],
                  ),
                  if (_ipEthnicity == 'Other') ...[
                    const SizedBox(height: 10),
                    _buildField(
                      label: 'SPECIFY ETHNICITY',
                      controller: widget.caregiverEthnicityController,
                      icon: Icons.edit_outlined,
                      hint: 'Enter ethnicity',
                    ),
                  ],
                ],
                const SizedBox(height: 12),

                // Disability
                _buildYesNoRow(
                  label: 'HAS DISABILITY?',
                  value: _hasDisability,
                  onChanged: (v) {
                    setState(() => _hasDisability = v);
                    widget.onHasDisabilityChanged?.call(v);
                  },
                ),
                if (_hasDisability == true) ...[
                  const SizedBox(height: 10),
                  _buildField(
                    label: 'DISABILITY / SPECIFY',
                    controller: widget.disabilityController,
                    icon: Icons.accessibility_new_outlined,
                    hint: 'Describe disability',
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Card 2: Address & Residence ─────────────────────────────
          _buildCard(
            headerTitle: 'ADDRESS & RESIDENCE',
            headerIcon: Icons.home_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(
                  label: 'ADDRESS',
                  controller: widget.addressController,
                  icon: Icons.home_outlined,
                  validator: (v) =>
                      _requiredOnSubmit(v, 'Address is required'),
                ),
                const SizedBox(height: 12),
                _buildField(
                  label: 'PLACE OF BIRTH',
                  controller: widget.placeOfBirthController,
                  icon: Icons.location_on_outlined,
                  validator: (v) =>
                      _requiredOnSubmit(v, 'Place of birth is required'),
                ),
                const SizedBox(height: 12),

                // Status of Residence
                _buildLabelRow('STATUS OF RESIDENCE'),
                Row(
                  children: [
                    _buildTogglePill(
                        'Tenant', _residenceStatus == 'Tenant', () {
                      setState(() {
                        _residenceStatus = 'Tenant';
                        widget.residenceStatusController.text = 'Tenant';
                      });
                    }),
                    const SizedBox(width: 8),
                    _buildTogglePill(
                        'Permanent', _residenceStatus == 'Permanent', () {
                      setState(() {
                        _residenceStatus = 'Permanent';
                        widget.residenceStatusController.text = 'Permanent';
                      });
                    }),
                  ],
                ),
                const SizedBox(height: 12),

                _buildField(
                  label: 'LENGTH OF STAY',
                  controller: widget.lengthOfStayController,
                  icon: Icons.timelapse_outlined,
                  hint: 'e.g. 3 years',
                  keyboardType: TextInputType.text,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Card 3: Mother's Info ───────────────────────────────────
          _buildCard(
            headerTitle: "MOTHER'S INFORMATION",
            headerIcon: Icons.woman_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(
                  label: "MOTHER'S FULL NAME *",
                  controller: widget.motherController,
                  icon: Icons.person_outline,
                  validator: (v) =>
                      _requiredOnSubmit(v, "Mother's name is required"),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'AGE',
                        controller: widget.motherAgeController,
                        keyboardType: TextInputType.number,
                        icon: Icons.cake_outlined,
                        hint: 'Years',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildField(
                        label: 'CONTACT NUMBER *',
                        controller: widget.motherContactController,
                        keyboardType: TextInputType.phone,
                        hint: '09XXXXXXXXX',
                        icon: Icons.phone_outlined,
                        validator: _validatePhone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildField(
                  label: 'OCCUPATION',
                  controller: widget.motherOccupationController,
                  icon: Icons.work_outline,
                  hint: 'e.g. Farmer, Teacher…',
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Card 4: Father's Info ───────────────────────────────────
          _buildCard(
            headerTitle: "FATHER'S INFORMATION",
            headerIcon: Icons.man_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(
                  label: "FATHER'S FULL NAME",
                  controller: widget.fatherController,
                  icon: Icons.person_outline,
                  validator: (v) =>
                      _requiredOnSubmit(v, "Father's name is required"),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'AGE',
                        controller: widget.fatherAgeController,
                        keyboardType: TextInputType.number,
                        icon: Icons.cake_outlined,
                        hint: 'Years',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildField(
                        label: 'CONTACT NUMBER',
                        controller: widget.fatherContactController,
                        keyboardType: TextInputType.phone,
                        hint: '09XXXXXXXXX',
                        icon: Icons.phone_outlined,
                        validator: (v) {
                          if (_isDraft) return null;
                          if (v == null || v.trim().isEmpty) return null; // optional
                          if (!_phoneRegex.hasMatch(v.trim())) {
                            return 'Invalid PH number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildField(
                  label: 'OCCUPATION',
                  controller: widget.fatherOccupationController,
                  icon: Icons.work_outline,
                  hint: 'e.g. Farmer, Driver…',
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Card 5: Caregiver & Household ──────────────────────────
          _buildCard(
            headerTitle: 'CAREGIVER & HOUSEHOLD',
            headerIcon: Icons.supervisor_account_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(
                  label: "CAREGIVER'S FULL NAME",
                  controller: widget.caregiverNameController,
                  icon: Icons.person_outline,
                  hint: 'If different from parents',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'CAREGIVER AGE',
                        controller: widget.caregiverAgeController,
                        keyboardType: TextInputType.number,
                        icon: Icons.cake_outlined,
                        hint: 'Years',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildField(
                        label: 'RELATIONSHIP TO CHILD',
                        controller: widget.caregiverRelationshipController,
                        icon: Icons.family_restroom_outlined,
                        hint: 'e.g. Lolo, Tita…',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'ETHNICITY',
                        controller: widget.caregiverEthnicityController,
                        icon: Icons.groups_outlined,
                        hint: 'e.g. Ibaloi…',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildField(
                        label: 'RELIGION',
                        controller: widget.caregiverReligionController,
                        icon: Icons.church_outlined,
                        hint: 'e.g. Catholic…',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4Ps
                _buildYesNoRow(
                  label: '4Ps MEMBER?',
                  value: _isFourPsMember,
                  onChanged: (v) {
                    setState(() => _isFourPsMember = v);
                    widget.onIsFourPsMemberChanged?.call(v);
                  },
                ),
                if (_isFourPsMember == true) ...[
                  const SizedBox(height: 10),
                  _buildField(
                    label: 'HOUSEHOLD ID NUMBER',
                    controller: widget.fourPsHouseholdIdController,
                    icon: Icons.tag_outlined,
                    hint: 'Enter household ID',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Draft / Submit buttons ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleSaveDraft,
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('SAVE DRAFT',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF5A962),
                    side: const BorderSide(
                        color: Color(0xFFF5A962), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _handleSubmit,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('SUBMIT',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A962),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}