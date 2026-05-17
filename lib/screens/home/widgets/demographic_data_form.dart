import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DemographicDataForm extends StatefulWidget {
  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController lastNameController;
  final TextEditingController ageController;
  final TextEditingController ageDaysController;
  final TextEditingController ageYearsController;
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
  // Blood Type
  final TextEditingController bloodTypeController;
  // PhilHealth — Mother
  final TextEditingController motherPhilHealthNumberController;
  final TextEditingController motherPhilHealthMemberTypeController;
  // PhilHealth — Father
  final TextEditingController fatherPhilHealthNumberController;
  final TextEditingController fatherPhilHealthMemberTypeController;
  final TextEditingController extensionNameController;

  final bool? belongsToIpGroup;
  final String? ipEthnicity;
  final bool? isFourPsMember;
  final bool? hasDisability;
  final ValueChanged<bool?>? onBelongsToIpGroupChanged;
  final ValueChanged<String?>? onIpEthnicityChanged;
  final ValueChanged<bool?>? onIsFourPsMemberChanged;
  final ValueChanged<bool?>? onHasDisabilityChanged;

  final bool isDraft;

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
    required this.bloodTypeController,
    required this.motherPhilHealthNumberController,
    required this.motherPhilHealthMemberTypeController,
    required this.fatherPhilHealthNumberController,
    required this.fatherPhilHealthMemberTypeController,
    required this.extensionNameController,
    this.belongsToIpGroup,
    this.ipEthnicity,
    this.isFourPsMember,
    this.hasDisability,
    this.onBelongsToIpGroupChanged,
    this.onIpEthnicityChanged,
    this.onIsFourPsMemberChanged,
    this.onHasDisabilityChanged,
    this.isDraft = false,
  });

  @override
  State<DemographicDataForm> createState() => _DemographicDataFormState();
}

class _DemographicDataFormState extends State<DemographicDataForm> {
  bool? _belongsToIpGroup;
  String? _ipEthnicity;
  bool _middleNameNA = false;
  bool? _isFourPsMember;
  bool? _hasDisability;
  String? _disabilityType;

  String? _residenceStatus;
  String? _selectedSex;
  String? _selectedBloodType;
  String? _selectedBirthWeight;
  String? _selectedBirthOrder;
  String? _motherPhilHealthMemberType;
  String? _fatherPhilHealthMemberType;
  String? _selectedExtension;
  bool _extensionOptional = false;
  String? _selectedMotherStatus = 'Present';
  String? _selectedFatherStatus = 'Present';
  bool _isMotherAvailable = true;
  bool _isFatherAvailable = true;
  String? _selectedCaregiverPresence = 'No';

  bool sameAsAddress = false;

  String? selectedProvince;
  String? selectedMunicipality;
  String? selectedBarangay;

  String? birthProvince;
  String? birthMunicipality;
  String? birthBarangay;

  static const _birthWeightOptions = [
    '1.0', '1.1', '1.2', '1.3', '1.4', '1.5', '1.6', '1.7', '1.8', '1.9',
    '2.0', '2.1', '2.2', '2.3', '2.4', '2.5', '2.6', '2.7', '2.8', '2.9',
    '3.0', '3.1', '3.2', '3.3', '3.4', '3.5', '3.6', '3.7', '3.8', '3.9',
    '4.0', '4.1', '4.2', '4.3', '4.4', '4.5', '4.6', '4.7', '4.8', '4.9',
    '5.0',
  ];

  static const _birthOrderOptions = [
    '1st',
    '2nd',
    '3rd',
    '4th',
    '5th',
    '6th or later',
  ];

  static const _philHealthMemberTypes = [
    'Member',
    'Dependent',
    'Indigent',
    'Senior Citizen',
    'PWD',
    'Other',
  ];

  static const _bloodTypes = [
    'A+',
    'A−',
    'B+',
    'B−',
    'AB+',
    'AB−',
    'O+',
    'O−',
    'Unknown',
  ];

  static const _parentStatuses = [
    'Present',
    'N/A (Deceased)',
    'N/A (Unknown)',
    'N/A (Absent)',
  ];

  static const _caregiverOptions = [
    'Yes',
    'No',
  ];

   final Map<String, List<String>> carLocations = {
    "Abra": [
      "Bangued",
      "Boliney",
      "Bucay",
      "Bucloc",
      "Daguioman",
      "Danglas",
      "Dolores",
      "La Paz",
      "Lacub",
      "Lagangilang",
      "Lagayan",
      "Langiden",
      "Licuan-Baay",
      "Luba",
      "Malibcong",
      "Manabo",
      "Peñarrubia",
      "Pidigan",
      "Pilar",
      "Sallapadan",
      "San Isidro",
      "San Juan",
      "San Quintin",
      "Tayum",
      "Tineg",
      "Tubo",
      "Villaviciosa",
    ],
    "Apayao": [
      "Calanasan",
      "Conner",
      "Flora",
      "Kabugao",
      "Luna",
      "Pudtol",
      "Santa Marcela",
    ],
    "Benguet": [
      "Atok",
      "Bakun",
      "Bokod",
      "Buguias",
      "Itogon",
      "Kabayan",
      "Kapangan",
      "Kibungan",
      "La Trinidad",
      "Mankayan",
      "Sablan",
      "Tuba",
      "Tublay",
    ],
    "Ifugao": [
      "Aguinaldo",
      "Alfonso Lista",
      "Asipulo",
      "Banaue",
      "Hingyon",
      "Hungduan",
      "Kiangan",
      "Lagawe",
      "Lamut",
      "Mayoyao",
      "Tinoc",
    ],
    "Kalinga": [
      "Balbalan",
      "Lubuagan",
      "Pasil",
      "Pinukpuk",
      "Rizal",
      "Tanudan",
      "Tinglayan",
      "Tabuk City",
    ],
    "Mountain Province": [
      "Barlig",
      "Bauko",
      "Besao",
      "Bontoc",
      "Natonin",
      "Paracelis",
      "Sabangan",
      "Sadanga",
      "Sagada",
      "Tadian",
    ],
  };

  /// Sample barangays
  final List<String> barangays = [
    "Barangay 1",
    "Barangay 2",
    "Barangay 3",
    "Poblacion",
    "San Jose",
  ];

  final Map<String, List<String>> barangayData = {
  "La Trinidad": [
    "Alapang",
    "Alno",
    "Ambiong",
    "Bahong",
    "Balili",
    "Beckel",
    "Betag",
    "Bineng",
    "Cruz",
    "Lubas",
    "Pico",
    "Poblacion",
    "Puguis",
    "Shilan",
    "Tawang",
    "Wangal",
  ],

  "Baguio": [
    "Session Road",
    "Irisan",
    "Burnham",
  ],
};

  @override
  void initState() {
    super.initState();
    _belongsToIpGroup = widget.belongsToIpGroup;
    _ipEthnicity = widget.ipEthnicity;
    _isFourPsMember = widget.isFourPsMember;
    _hasDisability = widget.hasDisability;

    final sexText = widget.sexController.text.trim().toLowerCase();
    if (sexText == 'male' || sexText == 'm') {
      _selectedSex = 'Male';
    } else if (sexText == 'female' || sexText == 'f') {
      _selectedSex = 'Female';
    }

    // Seed blood type from controller if already set
    final btText = widget.bloodTypeController.text.trim();
    if (_bloodTypes.contains(btText)) {
      _selectedBloodType = btText;
    }

    // Seed extension name from controller if already set
    final extText = widget.extensionNameController.text.trim();
    if (['Jr.', 'Sr.', 'II', 'III', 'IV'].contains(extText)) {
      _selectedExtension = extText;
    }

    // Seed birth weight selection if already set
    final birthWeightText = widget.birthWeightController.text.trim();
    if (birthWeightText.isNotEmpty && _birthWeightOptions.contains(birthWeightText)) {
      _selectedBirthWeight = birthWeightText;
    }

    // Seed birth order selection if already set
    final birthOrderValue = widget.birthOrderController.text.trim();
    if (birthOrderValue.isNotEmpty) {
      final order = int.tryParse(birthOrderValue);
      if (order != null && order >= 1 && order <= 5) {
        _selectedBirthOrder = '${order}st';
        if (order == 2) _selectedBirthOrder = '2nd';
        if (order == 3) _selectedBirthOrder = '3rd';
        if (order == 4) _selectedBirthOrder = '4th';
        if (order == 5) _selectedBirthOrder = '5th';
      } else if (order != null && order > 5) {
        _selectedBirthOrder = '6th or later';
      }
    }

    // Seed PhilHealth member type dropdowns
    final mPhType = widget.motherPhilHealthMemberTypeController.text.trim();
    if (_philHealthMemberTypes.contains(mPhType)) {
      _motherPhilHealthMemberType = mPhType;
    }
    final fPhType = widget.fatherPhilHealthMemberTypeController.text.trim();
    if (_philHealthMemberTypes.contains(fPhType)) {
      _fatherPhilHealthMemberType = fPhType;
    }

    final motherText = widget.motherController.text.trim();
    if (_parentStatuses.contains(motherText) && motherText != 'Present') {
      _selectedMotherStatus = motherText;
      _isMotherAvailable = false;
    } else if (motherText.isNotEmpty) {
      _selectedMotherStatus = 'Present';
      _isMotherAvailable = true;
    }

    final fatherText = widget.fatherController.text.trim();
    if (_parentStatuses.contains(fatherText) && fatherText != 'Present') {
      _selectedFatherStatus = fatherText;
      _isFatherAvailable = false;
    } else if (fatherText.isNotEmpty) {
      _selectedFatherStatus = 'Present';
      _isFatherAvailable = true;
    }

    final caregiverName = widget.caregiverNameController.text.trim();
    if (caregiverName.isNotEmpty) {
      _selectedCaregiverPresence = 'Yes';
    }

    final res = widget.residenceStatusController.text.trim();
    if (res == 'Tenant' || res == 'Permanent') {
      _residenceStatus = res;
    }

    _parseAddressIntoDropdowns(
      widget.addressController.text.trim(),
      isBirth: false,
    );
    _parseAddressIntoDropdowns(
      widget.placeOfBirthController.text.trim(),
      isBirth: true,
    );

    _isMotherAvailable = _selectedMotherStatus == 'Present';
    _isFatherAvailable = _selectedFatherStatus == 'Present';
  }

  void _parseAddressIntoDropdowns(String addr, {required bool isBirth}) {
    if (addr.isEmpty) return;
    final parts = addr
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length >= 3) {
      if (isBirth) {
        birthBarangay = parts[0];
        birthMunicipality = parts[1];
        birthProvince = parts[2];
      } else {
        selectedBarangay = parts[0];
        selectedMunicipality = parts[1];
        selectedProvince = parts[2];
      }
    }
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

  // ── Validators ──────────────────────────────────────────────────────────────
  static final _phoneRegex = RegExp(r'^(09\d{9}|\+639\d{9})$');

  String? _alwaysRequired(String? v, String message) {
    if (v == null || v.trim().isEmpty) return message;
    if (v.trim().length < 2) return 'Min. 2 chars';
    return null;
  }

  String? _requiredOnSubmit(String? v, String message) {
    if (widget.isDraft) return null;
    if (v == null || v.trim().isEmpty) return message;
    return null;
  }

  String? _validateMotherPhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Contact number is required';
    if (!_phoneRegex.hasMatch(v.trim())) {
      return 'Enter a valid PH number (09XXXXXXXXX or +639XXXXXXXXX)';
    }
    return null;
  }

  String _formatAddress(String? province, String? municipality, String? barangay) {
    final parts = <String>[];
    if (barangay != null && barangay.isNotEmpty) parts.add(barangay);
    if (municipality != null && municipality.isNotEmpty) parts.add(municipality);
    if (province != null && province.isNotEmpty) parts.add(province);
    return parts.join(', ');
  }

  void _updateAddressController() {
    widget.addressController.text = _formatAddress(
      selectedProvince,
      selectedMunicipality,
      selectedBarangay,
    );
  }

  void _updatePlaceOfBirthController() {
    widget.placeOfBirthController.text = _formatAddress(
      birthProvince,
      birthMunicipality,
      birthBarangay,
    );
  }

  // ── Date picker ────────────────────────────────────────────────────────────
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
              foregroundColor: const Color(0xFFF5A962),
            ),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      widget.dobController.text = DateFormat('MM-dd-yyyy').format(picked);
      final now = DateTime.now();
      final days = now.difference(picked).inDays;
      widget.ageDaysController.text = days.clamp(0, 99999).toString();
      final months = (now.year - picked.year) * 12 + (now.month - picked.month);
      widget.ageController.text = months.clamp(0, 60).toString();
      final years =
          now.year -
          picked.year -
          (now.month < picked.month ||
                  (now.month == picked.month && now.day < picked.day)
              ? 1
              : 0);
      widget.ageYearsController.text = years.clamp(0, 5).toString();
    }
  }

  // ── Reusable widgets ────────────────────────────────────────────────────────

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    ValueChanged<String?>? onChanged,
    IconData? icon,
    String? Function(String?)? validator,
    bool enabled = true,
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
        DropdownButtonFormField<String>(
          initialValue: value,
          validator: validator,
          onChanged: enabled ? onChanged : null,
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFFF5A962),
            size: 20,
          ),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            hintText: 'Select…',
            enabled: enabled,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.black26),
            prefixIcon: icon != null
                ? Icon(icon, size: 16, color: Colors.black38)
                : null,
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFEEEEEE),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFF5A962), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorStyle: const TextStyle(fontSize: 10),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTogglePill(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5A962) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFF5A962) : const Color(0xFFEEEEEE),
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
                color: selected ? Colors.white : const Color(0xFF1A1A1A),
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
          enabled: enabled,
          onTap: onTap,
          maxLines: maxLines,
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
            suffixIcon: onTap != null
                ? const Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: Color(0xFFF5A962),
                  )
                : null,
            filled: true,
            fillColor: (!enabled || readOnly)
                ? const Color(0xFFF0F0F0)
                : const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFEEEEEE),
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFF5A962), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorStyle: const TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String? headerTitle,
    IconData? headerIcon,
    required Widget child,
  }) {
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

  Widget _buildLabelRow(String label, {bool isRequired = false, bool isOptional = false}) {
    String displayLabel = label;
    if (isRequired) {
      displayLabel = '$label *';
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            displayLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF5A962),
              letterSpacing: 0.5,
            ),
          ),
          if (isOptional) ...[const SizedBox(width: 6),
            Text(
              '(Optional)',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Color(0xFFAAAAAA),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Card 1: Patient Basic Info ──────────────────────────────
        _buildCard(
          headerTitle: 'PATIENT INFORMATION',
          headerIcon: Icons.person_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'FIRST NAME *',
                      controller: widget.firstNameController,
                      icon: Icons.badge_outlined,
                      validator: (v) =>
                          _alwaysRequired(v, 'First name is required'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField(
                      label: 'LAST NAME *',
                      controller: widget.lastNameController,
                      icon: Icons.badge_outlined,
                      validator: (v) =>
                          _alwaysRequired(v, 'Last name is required'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildField(
                      label: 'MIDDLE NAME',
                      controller: widget.middleNameController,
                      icon: Icons.badge_outlined,
                      enabled: !_middleNameNA,
                      validator: (v) {
                        if (widget.isDraft || _middleNameNA) return null;
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 2) return 'Min. 2 chars';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDropdown(
                      label: 'EXTENSION NAME',
                      value: _selectedExtension,
                      items: const ['None', 'Jr.', 'Sr.', 'II', 'III', 'IV'],
                      icon: Icons.badge_outlined,
                      enabled: !_extensionOptional,
                      onChanged: (v) {
                        setState(() {
                          _selectedExtension = v;
                          if (v == 'None' || v == null) {
                            widget.extensionNameController.clear();
                            _selectedExtension = null;
                          } else {
                            widget.extensionNameController.text = v;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _middleNameNA,
                            activeColor: const Color(0xFFF5A962),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                        const Flexible(
                          child: Text(
                            'N/A (no middle name)',
                            style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _extensionOptional,
                            activeColor: const Color(0xFFF5A962),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (val) {
                              setState(() {
                                _extensionOptional = val ?? false;
                                if (_extensionOptional) {
                                  _selectedExtension = null;
                                  widget.extensionNameController.clear();
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Flexible(
                          child: Text(
                            'Extension optional',
                            style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

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

              // ── Sex + Blood Type side by side ───────────────────────
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'SEX',
                      value: _selectedSex,
                      items: const ['Male', 'Female'],
                      icon: Icons.wc_outlined,
                      validator: (v) {
                        if (widget.isDraft) return null;
                        if (v == null || v.isEmpty) return 'Required';
                        return null;
                      },
                      onChanged: (v) {
                        setState(() {
                          _selectedSex = v;
                          widget.sexController.text = v ?? '';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ── BLOOD TYPE dropdown ─────────────────────────────
                  Expanded(
                    child: _buildDropdown(
                      label: 'BLOOD TYPE',
                      value: _selectedBloodType,
                      items: _bloodTypes,
                      icon: Icons.bloodtype_outlined,
                      onChanged: (v) {
                        setState(() {
                          _selectedBloodType = v;
                          widget.bloodTypeController.text = v ?? '';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildSubHeader('BIRTH INFORMATION'),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'BIRTH WEIGHT (kg)',
                      value: _selectedBirthWeight,
                      items: _birthWeightOptions,
                      icon: Icons.monitor_weight_outlined,
                      onChanged: (value) {
                        setState(() {
                          _selectedBirthWeight = value;
                          if (value == null) {
                            widget.birthWeightController.clear();
                          } else {
                            widget.birthWeightController.text = value;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDropdown(
                      label: 'BIRTH ORDER',
                      value: _selectedBirthOrder,
                      items: _birthOrderOptions,
                      icon: Icons.sort_outlined,
                      onChanged: (value) {
                        setState(() {
                          _selectedBirthOrder = value;
                          if (value == null) {
                            widget.birthOrderController.clear();
                          } else if (value == '6th or later') {
                            if (int.tryParse(widget.birthOrderController.text.trim()) == null ||
                                int.tryParse(widget.birthOrderController.text.trim())! <= 5) {
                              widget.birthOrderController.clear();
                            }
                          } else {
                            final numeric = value.replaceAll(RegExp(r'[^0-9]'), '');
                            widget.birthOrderController.text = numeric;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (_selectedBirthOrder == '6th or later') ...[
                const SizedBox(height: 12),
                _buildField(
                  label: 'BIRTH ORDER (exact)',
                  controller: widget.birthOrderController,
                  keyboardType: TextInputType.number,
                  icon: Icons.sort_outlined,
                  hint: 'Enter 6 or higher',
                  validator: (v) {
                    if (widget.isDraft || _selectedBirthOrder != '6th or later') {
                      return null;
                    }
                    if (v == null || v.trim().isEmpty) {
                      return 'Required for 6th or later';
                    }
                    final order = int.tryParse(v.trim());
                    if (order == null || order <= 5) {
                      return 'Enter 6 or greater';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],

              _buildField(
                label: 'RELIGION',
                controller: widget.religionController,
                icon: Icons.church_outlined,
                hint: 'e.g. Catholic, Islam…',
              ),
              const SizedBox(height: 12),

              _buildLabelRow('BELONGS TO IP GROUP?'),
              Row(
                children: [
                  _buildTogglePill('Yes', _belongsToIpGroup == true, () {
                    setState(() => _belongsToIpGroup = true);
                    widget.onBelongsToIpGroupChanged?.call(true);
                  }),
                  const SizedBox(width: 8),
                  _buildTogglePill('No', _belongsToIpGroup == false, () {
                    setState(() {
                      _belongsToIpGroup = false;
                      _ipEthnicity = null;
                    });
                    widget.onIpEthnicityChanged?.call(null);
                    widget.onBelongsToIpGroupChanged?.call(false);
                  }),
                ],
              ),

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
                      'Other',
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

              _buildYesNoRow(
                label: 'HAS DISABILITY?',
                value: _hasDisability,
                onChanged: (v) {
                  setState(() {
                    _hasDisability = v;
                    if (v == false) {
                      _disabilityType = null;
                      widget.disabilityController.clear();
                    }
                  });
                  widget.onHasDisabilityChanged?.call(v);
                },
              ),
              if (_hasDisability == true) ...[
                const SizedBox(height: 10),
                _buildLabelRow('TYPE OF DISABILITY'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in [
                      'Physical',
                      'Visual',
                      'Hearing',
                      'Intellectual',
                      'Psychosocial',
                      'Speech',
                      'Multiple',
                      'Other',
                    ])
                      _buildTogglePill(type, _disabilityType == type, () {
                        setState(() {
                          _disabilityType = type;
                          if (type != 'Other') {
                            widget.disabilityController.text = type;
                          } else {
                            widget.disabilityController.clear();
                          }
                        });
                      }),
                  ],
                ),
                if (_disabilityType == 'Other') ...[
                  const SizedBox(height: 10),
                  _buildField(
                    label: 'SPECIFY DISABILITY',
                    controller: widget.disabilityController,
                    icon: Icons.accessibility_new_outlined,
                    hint: 'Describe the disability',
                    validator: (v) =>
                        _requiredOnSubmit(v, 'Please describe the disability'),
                  ),
                ],
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
              /// ADDRESS
        const Text(
          "ADDRESS",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        _buildDropdown(
          label: "Province",
          value: selectedProvince,
          items: carLocations.keys.toList(),
          onChanged: (value) {
            setState(() {
              selectedProvince = value;
              selectedMunicipality = null;
              selectedBarangay = null;
              _updateAddressController();
              if (sameAsAddress) {
                birthProvince = selectedProvince;
                birthMunicipality = selectedMunicipality;
                birthBarangay = selectedBarangay;
                _updatePlaceOfBirthController();
              }
            });
          },
        ),

        const SizedBox(height: 12),

        _buildDropdown(
          label: "Municipality / City",
          value: selectedMunicipality,
          items: selectedProvince == null
              ? []
              : carLocations[selectedProvince]!,
          onChanged: (value) {
            setState(() {
              selectedMunicipality = value;
              selectedBarangay = null;
              _updateAddressController();
              if (sameAsAddress) {
                birthProvince = selectedProvince;
                birthMunicipality = selectedMunicipality;
                birthBarangay = selectedBarangay;
                _updatePlaceOfBirthController();
              }
            });
          },
        ),

        const SizedBox(height: 12),

        _buildDropdown(
          label: "Barangay",
          value: selectedBarangay,
          items: barangays,
          onChanged: (value) {
            setState(() {
              selectedBarangay = value;
              _updateAddressController();
              if (sameAsAddress) {
                birthProvince = selectedProvince;
                birthMunicipality = selectedMunicipality;
                birthBarangay = selectedBarangay;
                _updatePlaceOfBirthController();
              }
            });
          },
        ),

        const SizedBox(height: 20),

        /// CHECKBOX
        CheckboxListTile(
          value: sameAsAddress,
          title: const Text("Place of Birth is same as Address"),
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            setState(() {
              sameAsAddress = value!;

              if (sameAsAddress) {
                birthProvince = selectedProvince;
                birthMunicipality = selectedMunicipality;
                birthBarangay = selectedBarangay;
                _updatePlaceOfBirthController();
              }
            });
          },
        ),

        const SizedBox(height: 20),

        /// PLACE OF BIRTH
        const Text(
          "PLACE OF BIRTH",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        _buildDropdown(
          label: "Province",
          value: birthProvince,
          items: carLocations.keys.toList(),
          onChanged: sameAsAddress
              ? null
              : (value) {
                  setState(() {
                    birthProvince = value;
                    birthMunicipality = null;
                    birthBarangay = null;
                    _updatePlaceOfBirthController();
                  });
                },
        ),

        const SizedBox(height: 12),

        _buildDropdown(
          label: "Municipality / City",
          value: birthMunicipality,
          items: birthProvince == null
              ? []
              : carLocations[birthProvince]!,
          onChanged: sameAsAddress
              ? null
              : (value) {
                  setState(() {
                    birthMunicipality = value;
                    birthBarangay = null;
                    _updatePlaceOfBirthController();
                  });
                },
        ),

        const SizedBox(height: 12),

        _buildDropdown(
          label: "Barangay",
          value: birthBarangay,
          items: barangays,
          onChanged: sameAsAddress
              ? null
              : (value) {
                  setState(() {
                    birthBarangay = value;
                    _updatePlaceOfBirthController();
                  });
                },
        ),
   
  

              _buildLabelRow('STATUS OF RESIDENCE'),
              Row(
                children: [
                  _buildTogglePill('Tenant', _residenceStatus == 'Tenant', () {
                    setState(() {
                      _residenceStatus = 'Tenant';
                      widget.residenceStatusController.text = 'Tenant';
                    });
                  }),
                  const SizedBox(width: 8),
                  _buildTogglePill(
                    'Permanent',
                    _residenceStatus == 'Permanent',
                    () {
                      setState(() {
                        _residenceStatus = 'Permanent';
                        widget.residenceStatusController.text = 'Permanent';
                      });
                    },
                  ),
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
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _isMotherAvailable,
                      activeColor: const Color(0xFFF5A962),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (val) {
                        setState(() {
                          _isMotherAvailable = val ?? false;
                          if (!_isMotherAvailable) {
                            _selectedMotherStatus = 'N/A (Absent)';
                            widget.motherController.text = _selectedMotherStatus!;
                            widget.motherContactController.clear();
                            widget.motherAgeController.clear();
                            widget.motherOccupationController.clear();
                            widget.motherPhilHealthNumberController.clear();
                            widget.motherPhilHealthMemberTypeController.clear();
                            _motherPhilHealthMemberType = null;
                          } else {
                            _selectedMotherStatus = 'Present';
                            widget.motherController.clear();
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Mother available',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1A1A1A)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildLabelRow("MOTHER'S STATUS", isRequired: true),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                initialValue: _selectedMotherStatus,
                onChanged: (v) {
                  setState(() {
                    _selectedMotherStatus = v;
                    _isMotherAvailable = v == 'Present';
                    if (v == 'Present') {
                      widget.motherController.clear();
                    } else {
                      widget.motherController.text = v ?? '';
                    }
                  });
                },
                items: _parentStatuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline, size: 16),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFF5A962), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_selectedMotherStatus == 'Present') ...[    
                _buildField(
                  label: "MOTHER'S FULL NAME *",
                  controller: widget.motherController,
                  icon: Icons.person_outline,
                  validator: (v) =>
                      _alwaysRequired(v, "Mother's name is required"),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'AGE',
                      controller: widget.motherAgeController,
                      keyboardType: TextInputType.number,
                      icon: Icons.cake_outlined,
                      hint: 'Years',
                      enabled: _isMotherAvailable,
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
                      enabled: _isMotherAvailable,
                      validator: _isMotherAvailable ? _validateMotherPhone : null,
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
                enabled: _isMotherAvailable,
              ),
              const SizedBox(height: 12),
              // PhilHealth
              _buildSubHeader('PHILHEALTH'),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 320;
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildField(
                            label: 'PHILHEALTH NUMBER',
                            controller: widget.motherPhilHealthNumberController,
                            keyboardType: TextInputType.number,
                            icon: Icons.credit_card_outlined,
                            hint: '12-digit number',
                            enabled: _isMotherAvailable,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDropdown(
                            label: 'MEMBER TYPE',
                            value: _motherPhilHealthMemberType,
                            items: _philHealthMemberTypes,
                            icon: Icons.badge_outlined,
                            enabled: _isMotherAvailable,
                            onChanged: (v) {
                              setState(() {
                                _motherPhilHealthMemberType = v;
                                widget
                                        .motherPhilHealthMemberTypeController
                                        .text =
                                    v ?? '';
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildField(
                        label: 'PHILHEALTH NUMBER',
                        controller: widget.motherPhilHealthNumberController,
                        keyboardType: TextInputType.number,
                        icon: Icons.credit_card_outlined,
                        hint: '12-digit number',
                        enabled: _isMotherAvailable,
                      ),
                      const SizedBox(height: 10),
                      _buildDropdown(
                        label: 'MEMBER TYPE',
                        value: _motherPhilHealthMemberType,
                        items: _philHealthMemberTypes,
                        icon: Icons.badge_outlined,
                        enabled: _isMotherAvailable,
                        onChanged: (v) {
                          setState(() {
                            _motherPhilHealthMemberType = v;
                            widget.motherPhilHealthMemberTypeController.text =
                                v ?? '';
                          });
                        },
                      ),
                    ],
                  );
                },
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
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _isFatherAvailable,
                      activeColor: const Color(0xFFF5A962),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (val) {
                        setState(() {
                          _isFatherAvailable = val ?? false;
                          if (!_isFatherAvailable) {
                            _selectedFatherStatus = 'N/A (Absent)';
                            widget.fatherController.text = _selectedFatherStatus!;
                            widget.fatherContactController.clear();
                            widget.fatherAgeController.clear();
                            widget.fatherOccupationController.clear();
                            widget.fatherPhilHealthNumberController.clear();
                            widget.fatherPhilHealthMemberTypeController.clear();
                            _fatherPhilHealthMemberType = null;
                          } else {
                            _selectedFatherStatus = 'Present';
                            widget.fatherController.clear();
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Father available',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1A1A1A)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildLabelRow("FATHER'S STATUS", isRequired: true),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                initialValue: _selectedFatherStatus,
                onChanged: (v) {
                  setState(() {
                    _selectedFatherStatus = v;
                    _isFatherAvailable = v == 'Present';
                    if (v == 'Present') {
                      widget.fatherController.clear();
                    } else {
                      widget.fatherController.text = v ?? '';
                    }
                  });
                },
                items: _parentStatuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline, size: 16),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFF5A962), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_selectedFatherStatus == 'Present') ...[         
                _buildField(
                  label: "FATHER'S FULL NAME *",
                  controller: widget.fatherController,
                  icon: Icons.person_outline,
                  validator: (v) =>
                      _alwaysRequired(v, "Father's name is required"),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'AGE',
                      controller: widget.fatherAgeController,
                      keyboardType: TextInputType.number,
                      icon: Icons.cake_outlined,
                      hint: 'Years',
                      enabled: _isFatherAvailable,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField(
                      label: 'CONTACT NUMBER *',
                      controller: widget.fatherContactController,
                      keyboardType: TextInputType.phone,
                      hint: '09XXXXXXXXX',
                      icon: Icons.phone_outlined,
                      enabled: _isFatherAvailable,
                      validator: _isFatherAvailable
                          ? (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Contact number is required';
                              }
                              if (!_phoneRegex.hasMatch(v.trim())) {
                                return 'Invalid PH number';
                              }
                              return null;
                            }
                          : null,
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
                enabled: _isFatherAvailable,
              ),
              const SizedBox(height: 12),
              // PhilHealth
              _buildSubHeader('PHILHEALTH'),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 320;
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildField(
                            label: 'PHILHEALTH NUMBER',
                            controller: widget.fatherPhilHealthNumberController,
                            keyboardType: TextInputType.number,
                            icon: Icons.credit_card_outlined,
                            hint: '12-digit number',
                            enabled: _isFatherAvailable,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDropdown(
                            label: 'MEMBER TYPE',
                            value: _fatherPhilHealthMemberType,
                            items: _philHealthMemberTypes,
                            icon: Icons.badge_outlined,
                            enabled: _isFatherAvailable,
                            onChanged: (v) {
                              setState(() {
                                _fatherPhilHealthMemberType = v;
                                widget
                                        .fatherPhilHealthMemberTypeController
                                        .text =
                                    v ?? '';
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildField(
                        label: 'PHILHEALTH NUMBER',
                        controller: widget.fatherPhilHealthNumberController,
                        keyboardType: TextInputType.number,
                        icon: Icons.credit_card_outlined,
                        hint: '12-digit number',
                        enabled: _isFatherAvailable,
                      ),
                      const SizedBox(height: 10),
                      _buildDropdown(
                        label: 'MEMBER TYPE',
                        value: _fatherPhilHealthMemberType,
                        items: _philHealthMemberTypes,
                        icon: Icons.badge_outlined,
                        enabled: _isFatherAvailable,
                        onChanged: (v) {
                          setState(() {
                            _fatherPhilHealthMemberType = v;
                            widget.fatherPhilHealthMemberTypeController.text =
                                v ?? '';
                          });
                        },
                      ),
                    ],
                  );
                },
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
              _buildLabelRow("IS CAREGIVER DIFFERENT FROM PARENTS?", isOptional: true),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                initialValue: _selectedCaregiverPresence,
                onChanged: (v) {
                  setState(() {
                    _selectedCaregiverPresence = v;
                    if (v == 'No') {
                      widget.caregiverNameController.clear();
                      widget.caregiverAgeController.clear();
                      widget.caregiverRelationshipController.clear();
                    }
                  });
                },
                items: _caregiverOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.supervisor_account_outlined, size: 16),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFF5A962), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_selectedCaregiverPresence == 'Yes') ...[              
                _buildField(
                  label: "CAREGIVER'S FULL NAME",
                  controller: widget.caregiverNameController,
                  icon: Icons.person_outline,
                  hint: 'Enter caregiver name',
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
              ],
              const SizedBox(height: 16),

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

        const SizedBox(height: 8),
      ],
    );
  }
}
