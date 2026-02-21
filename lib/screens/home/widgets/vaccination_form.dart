import 'package:flutter/material.dart';
import 'form_card.dart';
import 'vaccine_dose_selector.dart';

class VaccinationForm extends StatefulWidget {
  final Function(Map<String, dynamic>)? onDataChanged;

  const VaccinationForm({super.key, this.onDataChanged});

  @override
  State<VaccinationForm> createState() => _VaccinationFormState();
}

class _VaccinationFormState extends State<VaccinationForm> {
  // ── Theme constants (mirrors other forms) ─────────────────────────────────
  static const Color _primary = Color(0xFFB5651D);
  static const Color _primaryLight = Color(0xFFFFF3E0);
  static const Color _surface = Colors.white;
  static const Color _surfaceAlt = Color(0xFFFDF6EE);
  static const Color _border = Color(0xFFE8C9A0);
  static const Color _labelColor = Color(0xFF795548);
  static const Color _textColor = Color(0xFF3E2723);

  static const _vaccineNames = [
    'BCG', 'HEP B', 'PENTAVALENT', 'OPV', 'IPV', 'PCV', 'MMR'
  ];
  static const _columnHeaders = ['BIRTH', '1½', '2½', '3½', '9', '1 YR'];

  final Map<String, List<String?>> _doses = {};

  List<String> _getPossibleDoses(String vaccine, int colIndex) {
    final ageHeader = _columnHeaders[colIndex];
    switch (vaccine) {
      case 'BCG':
        return ageHeader == 'BIRTH' ? ['1st dose'] : [];
      case 'HEP B':
        if (ageHeader == 'BIRTH') return ['1st dose'];
        if (ageHeader == '1½') return ['2nd dose'];
        if (ageHeader == '2½') return ['3rd dose'];
        return [];
      case 'PENTAVALENT':
        if (ageHeader == '1½') return ['1st dose'];
        if (ageHeader == '2½') return ['2nd dose'];
        if (ageHeader == '3½') return ['3rd dose'];
        if (ageHeader == '1 YR') return ['4th dose'];
        return [];
      case 'OPV':
        if (ageHeader == 'BIRTH') return ['1st dose'];
        if (ageHeader == '2½') return ['2nd dose'];
        if (ageHeader == '9') return ['3rd dose'];
        return [];
      case 'IPV':
        if (ageHeader == '1½') return ['1st dose'];
        if (ageHeader == '2½') return ['2nd dose'];
        if (ageHeader == '3½') return ['3rd dose'];
        if (ageHeader == '1 YR') return ['4th dose'];
        return [];
      case 'PCV':
        if (ageHeader == '1½') return ['1st dose'];
        if (ageHeader == '2½') return ['2nd dose'];
        if (ageHeader == '3½') return ['3rd dose'];
        if (ageHeader == '1 YR') return ['4th dose'];
        return [];
      case 'MMR':
        if (ageHeader == '9') return ['1st dose'];
        if (ageHeader == '1 YR') return ['2nd dose'];
        return [];
      default:
        return [];
    }
  }

  @override
  void initState() {
    super.initState();
    for (final name in _vaccineNames) {
      _doses[name] = List.filled(6, null);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyParent());
  }

  void _onDoseChanged(String vaccine, int colIndex, String? dose) {
    setState(() => _doses[vaccine]![colIndex] = dose);
    _notifyParent();
  }

  void _notifyParent() {
    if (widget.onDataChanged == null) return;
    final data = <String, dynamic>{};
    for (final name in _vaccineNames) {
      final doses = <String, bool>{};
      for (int i = 0; i < _columnHeaders.length; i++) {
        doses[_columnHeaders[i]] = _doses[name]![i] != null;
      }
      data[name] = doses;
    }
    widget.onDataChanged!(data);
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
                  child: const Icon(Icons.vaccines_outlined,
                      size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Vaccination',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Tap cell to record dose',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Table ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border, width: 1.5),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  // Column headers row
                  Container(
                    color: _surfaceAlt,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        const SizedBox(width: 88),
                        for (final header in _columnHeaders)
                          Expanded(
                            child: Text(
                              header,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _labelColor,
                                letterSpacing: 0.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(height: 1.5, color: _border),
                  // Vaccine rows
                  for (int vi = 0; vi < _vaccineNames.length; vi++) ...[
                    _buildVaccineRow(_vaccineNames[vi], vi),
                    if (vi < _vaccineNames.length - 1)
                      Container(height: 1, color: _border),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccineRow(String name, int rowIndex) {
    return Container(
      color: rowIndex.isEven ? _surface : _surfaceAlt,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _textColor,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          for (int i = 0; i < 6; i++)
            Expanded(
              child: Center(
                child: VaccineDoseSelector(
                  selectedDose: _doses[name]![i],
                  possibleDoses: _getPossibleDoses(name, i),
                  onDoseSelected: (dose) => _onDoseChanged(name, i, dose),
                ),
              ),
            ),
        ],
      ),
    );
  }
}