import 'package:flutter/material.dart';

class YesNoRow extends StatefulWidget {
  final String text;
  final Color color;
  final ValueChanged<bool?>? onChanged; // ← ADD THIS LINE

  const YesNoRow({
    super.key,
    required this.text,
    required this.color,
    this.onChanged, // ← ADD THIS LINE
  });

  @override
  State<YesNoRow> createState() => _YesNoRowState();
}

class _YesNoRowState extends State<YesNoRow> {
  bool? _selectedValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              widget.text,
              style: const TextStyle(fontSize: 11, color: Color(0xFF5D4037)),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedValue = _selectedValue == true ? null : true;
              });
              widget.onChanged?.call(_selectedValue); // ← ADD THIS LINE
            },
            child: Container(
              width: 35,
              height: 20,
              decoration: BoxDecoration(
                color: _selectedValue == true ? widget.color : widget.color.withValues(alpha: 0.25),
                border: Border.all(color: widget.color, width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: _selectedValue == true
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedValue = _selectedValue == false ? null : false;
              });
              widget.onChanged?.call(_selectedValue); // ← ADD THIS LINE
            },
            child: Container(
              width: 35,
              height: 20,
              decoration: BoxDecoration(
                color: _selectedValue == false ? widget.color : widget.color.withValues(alpha: 0.25),
                border: Border.all(color: widget.color, width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: _selectedValue == false
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}