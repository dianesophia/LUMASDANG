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
  static const _vaccineNames = ['BCG', 'HEP B', 'PENTAVALENT', 'OPV', 'IPV', 'PCV', 'MMR'];
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
    setState(() {
      _doses[vaccine]![colIndex] = dose;
    });
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
    return FormCard(
      title: 'VACCINATION',
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF5D4037), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFF5D4037))),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 80),
                      for (final header in _columnHeaders)
                        Expanded(
                          child: Text(
                            header,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
                for (final name in _vaccineNames) _buildVaccineRow(name),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccineRow(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF5D4037), width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                name,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF5D4037)),
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
