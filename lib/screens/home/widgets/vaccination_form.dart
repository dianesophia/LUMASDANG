import 'package:flutter/material.dart';
import 'vaccine_dose_selector.dart';

class VaccinationForm extends StatefulWidget {
  final Function(Map<String, dynamic>)? onDataChanged;

  const VaccinationForm({super.key, this.onDataChanged});

  @override
  State<VaccinationForm> createState() => _VaccinationFormState();
}

class _VaccinationFormState extends State<VaccinationForm> {
  // ── Theme constants (mirrors AnthropometricDataForm) ──────────────────────
  static const Color _primary = Color(0xFFF5A962);
  static const Color _primaryDark = Color(0xFFF08030);
  static const Color _surface = Colors.white;
  static const Color _surfaceAlt = Color(0xFFFAFAFA);
  static const Color _border = Color(0xFFEEEEEE);
  static const Color _labelColor = Color(0xFFF5A962);
  static const Color _textColor = Color(0xFF1A1A1A);

  static const _vaccineNames = [
    'BCG',
    'HEP B',
    'PENTAVALENT',
    'OPV',
    'IPV',
    'PCV',
    'MMR',
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

  // ── Shared builders (identical to AnthropometricDataForm) ─────────────────
  Widget _buildCard({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _surface,
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

  Widget _buildSectionHeader(
    String title,
    IconData icon, {
    List<Color> gradientColors = const [Color(0xFFF5A962), Color(0xFFF08030)],
  }) {
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
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Header ─────────────────────────────────────────────
          _buildSectionHeader('VACCINATION', Icons.vaccines_outlined),
          const SizedBox(height: 4),
          const Text(
            'Tap a cell to record a dose',
            style: TextStyle(
              fontSize: 10,
              color: Colors.black38,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 14),

          // ── Table ──────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
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
                      const SizedBox(width: 90),
                      for (final header in _columnHeaders)
                        Expanded(
                          child: Text(
                            header,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: _primary,
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
            width: 90,
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