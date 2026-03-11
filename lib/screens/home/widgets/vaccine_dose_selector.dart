import 'package:flutter/material.dart';

class VaccineDoseSelector extends StatelessWidget {
  final String? selectedDose;
  final List<String> possibleDoses;
  final ValueChanged<String?> onDoseSelected;

  // ── Theme constants (mirrors other forms) ─────────────────────────────────
  static const Color _primary = Color(0xFFB5651D);
  static const Color _primaryLight = Color(0xFFFFF3E0);
  static const Color _border = Color(0xFFE8C9A0);
  static const Color _labelColor = Color(0xFF795548);
  static const Color _textColor = Color(0xFF3E2723);
  static const Color _surfaceAlt = Color(0xFFFDF6EE);

  static const List<String> allPossibleDoses = [
    '1st dose',
    '2nd dose',
    '3rd dose',
    '4th dose',
    '5th dose',
    'Booster',
  ];

  const VaccineDoseSelector({
    super.key,
    required this.selectedDose,
    required this.possibleDoses,
    required this.onDoseSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Empty cell — not applicable for this vaccine/age combo
    if (possibleDoses.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFFF5EFE8),
          border: Border.all(color: const Color(0xFFE8C9A0), width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }

    final isDone = selectedDose != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDoseMenu(context),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          constraints: const BoxConstraints(minHeight: 26, minWidth: 32),
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFFFFF3E0) : _surfaceAlt,
            border: Border.all(
              color: isDone ? _primary : _border,
              width: isDone ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: isDone
                ? Text(
                    selectedDose!,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : const Icon(Icons.add, size: 12, color: _labelColor),
          ),
        ),
      ),
    );
  }

  void _showDoseMenu(BuildContext context) {
    // Move focus to a dummy node so that when the dialog closes,
    // Flutter doesn't restore focus (and scroll) back to a text field
    // higher up in the form.
    FocusScope.of(context).requestFocus(FocusNode());

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _border, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Dialog header ──────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.vaccines_outlined,
                          size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Select Dose',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _surfaceAlt,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _border),
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: _labelColor),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Valid doses hint banner ────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _border, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: _primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Valid for this age: ${possibleDoses.join(", ")}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Clear option ──────────────────────────────────────
                if (selectedDose != null) ...[
                  _buildDialogOption(
                    context: context,
                    dialogContext: dialogContext,
                    dose: null,
                    label: 'Clear selection',
                    icon: Icons.clear,
                    isSelected: false,
                    isValid: true,
                    isClear: true,
                  ),
                  const SizedBox(height: 4),
                ],

                // ── Dose options ──────────────────────────────────────
                ...allPossibleDoses.map((dose) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _buildDialogOption(
                        context: context,
                        dialogContext: dialogContext,
                        dose: dose,
                        label: dose,
                        icon: selectedDose == dose
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        isSelected: selectedDose == dose,
                        isValid: possibleDoses.contains(dose),
                        isClear: false,
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogOption({
    required BuildContext context,
    required BuildContext dialogContext,
    required String? dose,
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isValid,
    required bool isClear,
  }) {
    final Color itemColor = isClear
        ? const Color(0xFFEF4444)
        : isValid
            ? (isSelected ? _primary : _textColor)
            : _border;

    return GestureDetector(
      onTap: () {
        Navigator.of(dialogContext).pop();
        if (isClear) {
          onDoseSelected(null);
        } else if (isValid) {
          onDoseSelected(dose);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '"$dose" is not valid here. Valid: ${possibleDoses.join(", ")}',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: const Color(0xFFB45309),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryLight
              : isClear
                  ? const Color(0xFFFEF2F2)
                  : (!isValid ? const Color(0xFFF5EFE8) : _surfaceAlt),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? _primary
                : isClear
                    ? const Color(0xFFFCA5A5)
                    : (!isValid ? _border : const Color(0xFFE8C9A0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: itemColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: itemColor,
                ),
              ),
            ),
            if (!isValid && !isClear)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: const Text(
                  'N/A',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}