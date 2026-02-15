import 'package:flutter/material.dart';

class VaccineDoseSelector extends StatelessWidget {
  final String? selectedDose;
  final List<String> possibleDoses;
  final ValueChanged<String?> onDoseSelected;

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
    if (possibleDoses.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        height: 24,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.06),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.25),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDoseMenu(context),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          constraints: const BoxConstraints(minHeight: 24, minWidth: 30),
          decoration: BoxDecoration(
            color: selectedDose != null
                ? const Color(0xFF2E8B7B).withValues(alpha: 0.18)
                : const Color(0xFFD4F1E3),
            border: Border.all(
              color: selectedDose != null
                  ? const Color(0xFF2E8B7B)
                  : const Color(0xFF2E8B7B).withValues(alpha: 0.6),
              width: selectedDose != null ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: selectedDose != null
                ? Text(
                    selectedDose!,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E8B7B),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : const Icon(
                    Icons.add,
                    size: 12,
                    color: Color(0xFF5D4037),
                  ),
          ),
        ),
      ),
    );
  }

  void _showDoseMenu(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFD4F1E3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          title: const Text(
            'Select Dose',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E8B7B),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (possibleDoses.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8E6D5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF2E8B7B).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Color(0xFF2E8B7B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Valid doses for this age: ${possibleDoses.join(", ")}',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF2E8B7B).withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (selectedDose != null)
                  ListTile(
                    leading: const Icon(Icons.clear, color: Colors.red),
                    title: const Text(
                      'Clear selection',
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      onDoseSelected(null);
                    },
                  ),
                ...allPossibleDoses.map((dose) {
                  final isSelected = selectedDose == dose;
                  final isValid = possibleDoses.contains(dose);
                  return ListTile(
                    leading: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isValid
                          ? (isSelected ? const Color(0xFF2E8B7B) : Colors.grey)
                          : Colors.grey.withValues(alpha: 0.4),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            dose,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isValid
                                  ? (isSelected
                                      ? const Color(0xFF2E8B7B)
                                      : Colors.black87)
                                  : Colors.grey.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        if (!isValid)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: Colors.orange,
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      if (isValid) {
                        onDoseSelected(dose);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error: "$dose" is not appropriate for this vaccine at this age. Valid doses: ${possibleDoses.join(", ")}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.red,
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
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
