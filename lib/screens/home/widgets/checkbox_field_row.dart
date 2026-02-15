import 'package:flutter/material.dart';

class CheckboxFieldRow extends StatefulWidget {
  final String label;
  final String? hint;
  final bool initialValue;
  final ValueChanged<bool>? onChanged;

  const CheckboxFieldRow({
    super.key,
    required this.label,
    this.hint,
    this.initialValue = false,
    this.onChanged,
  });

  @override
  State<CheckboxFieldRow> createState() => _CheckboxFieldRowState();
}

class _CheckboxFieldRowState extends State<CheckboxFieldRow> {
  late bool _isChecked;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _isChecked,
            onChanged: (value) {
              setState(() {
                _isChecked = value ?? false;
              });
              widget.onChanged?.call(_isChecked);
            },
            activeColor: const Color(0xFF2E8B7B),
            side: const BorderSide(color: Color(0xFF5D4037)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5D4037),
          ),
        ),
        if (widget.hint != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 28,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF8B6914), width: 1),
                ),
              ),
              child: TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.hint,
                  hintStyle: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8B6914),
                    fontStyle: FontStyle.italic,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
