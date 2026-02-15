import 'package:flutter/material.dart';
import 'form_card.dart';
import 'form_field_row.dart';

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
    final map = {
      'dateOfLastDeworming': _dateController.text.trim(),
      'isNA': _isNA,
      'drugGiven': _drugGiven,
      'adverseReactions': _adverseController.text.trim(),
      'nextDewormingDate': _nextDateController.text.trim(),
    };
    widget.onSave?.call(map);
  }

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'DEWORMING',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.errorText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD32F2F).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Color(0xFFD32F2F)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.errorText!,
                        style: const TextStyle(fontSize: 11, color: Color(0xFFD32F2F)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          FormFieldRow(
            label: 'Date of last deworming:',
            labelWidth: 160,
            controller: _dateController,
            keyboardType: TextInputType.datetime,
            hint: 'MM-DD-YYYY (e.g. 11-01-2025)',
            readOnly: _isNA,
            validator: (v) {
              if (_isNA) return null;
              if (v == null || v.trim().isEmpty) return 'Enter a date or select N/A';
              final value = v.trim();
              final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
              if (!regex.hasMatch(value)) {
                return 'Use format MM-DD-YYYY';
              }
              return null;
            },
          ),
          Row(
            children: [
              const SizedBox(width: 12),
              Checkbox(
                value: _isNA,
                onChanged: (v) {
                  setState(() {
                    _isNA = v ?? false;
                    if (_isNA) {
                      _dateController.clear();
                      _nextDateController.clear();
                      _adverseController.clear();
                      _drugGiven = null;
                    }
                  });
                  _notifyParent();
                },
                activeColor: const Color(0xFF2E8B7B),
              ),
              const Text('N/A', style: TextStyle(fontSize: 12, color: Color(0xFF5D4037))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Drug Given:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF5D4037)),
              ),
              const SizedBox(width: 8),
              Checkbox(
                value: !_isNA && _drugGiven == 'Albendazole',
                onChanged: _isNA
                    ? null
                    : (v) {
                        setState(() => _drugGiven = v == true ? 'Albendazole' : null);
                        _notifyParent();
                      },
                activeColor: const Color(0xFF2E8B7B),
              ),
              const Text('Albendazole', style: TextStyle(fontSize: 12, color: Color(0xFF5D4037))),
              Checkbox(
                value: !_isNA && _drugGiven == 'Mebendazole',
                onChanged: _isNA
                    ? null
                    : (v) {
                        setState(() => _drugGiven = v == true ? 'Mebendazole' : null);
                        _notifyParent();
                      },
                activeColor: const Color(0xFF2E8B7B),
              ),
              const Text('Mebendazole', style: TextStyle(fontSize: 12, color: Color(0xFF5D4037))),
            ],
          ),
          const SizedBox(height: 12),
          FormFieldRow(label: 'Adverse Reactions:', labelWidth: 130, controller: _adverseController),
          const SizedBox(height: 12),
          FormFieldRow(
            label: 'Next deworming date:',
            labelWidth: 140,
            controller: _nextDateController,
            keyboardType: TextInputType.datetime,
            hint: 'MM-DD-YYYY (e.g. 05-01-2026)',
            readOnly: _isNA,
            validator: (v) {
              if (_isNA) return null;
              if (v == null || v.trim().isEmpty) return 'Next deworming date is required';
              final value = v.trim();
              final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
              if (!regex.hasMatch(value)) {
                return 'Use format MM-DD-YYYY';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
