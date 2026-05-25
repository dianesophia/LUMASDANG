import 'package:flutter/material.dart';

/// Standard form field label with optional "(Optional)" suffix.
class FormFieldLabel extends StatelessWidget {
  final String label;
  final bool isOptional;
  final Color color;
  final EdgeInsetsGeometry? padding;

  const FormFieldLabel({
    super.key,
    required this.label,
    this.isOptional = false,
    this.color = const Color(0xFFF5A962),
    this.padding,
  });

  static const TextStyle optionalStyle = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w500,
    color: Color(0xFFAAAAAA),
    fontStyle: FontStyle.italic,
  );

  @override
  Widget build(BuildContext context) {
    final labelWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        if (isOptional) ...[
          const SizedBox(width: 4),
          const Text('(Optional)', style: optionalStyle),
        ],
      ],
    );

    if (padding != null) {
      return Padding(padding: padding!, child: labelWidget);
    }
    return labelWidget;
  }
}
