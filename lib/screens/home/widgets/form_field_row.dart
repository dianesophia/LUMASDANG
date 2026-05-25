import 'package:flutter/material.dart';
import 'form_field_label.dart';

class FormFieldRow extends StatelessWidget {
  final String label;
  final String? hint;
  final double labelWidth;
  final TextEditingController? controller;
  final bool readOnly;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool isOptional;

  const FormFieldRow({
    super.key,
    required this.label,
    this.hint,
    this.labelWidth = 100,
    this.controller,
    this.readOnly = false,
    this.validator,
    this.keyboardType,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: FormFieldLabel(
                  label: label,
                  isOptional: isOptional,
                  color: const Color(0xFF5D4037),
                ),
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: controller,
                readOnly: readOnly,
                validator: validator,
                keyboardType: keyboardType,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B6914),
                    fontStyle: FontStyle.italic,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  isDense: true,
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF8B6914), width: 1.5),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF5D4037), width: 2),
                  ),
                  errorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFD32F2F), width: 1.5),
                  ),
                  focusedErrorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFD32F2F), width: 2),
                  ),
                  errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFD32F2F)),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
