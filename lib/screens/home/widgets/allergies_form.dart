import 'package:flutter/material.dart';

/// Allergy entry model
class AllergyEntry {
  String? type;       // Food | Drug | Environmental | Insect | Other
  String allergen;    // specific allergen (free text)
  String reaction;    // symptoms / reaction (free text)
  String? severity;   // Mild | Moderate | Severe

  AllergyEntry({
    this.type,
    this.allergen = '',
    this.reaction = '',
    this.severity,
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'allergen': allergen,
        'reaction': reaction,
        'severity': severity,
      };
}

class AllergiesForm extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onDataChanged;

  const AllergiesForm({super.key, required this.onDataChanged});

  @override
  State<AllergiesForm> createState() => _AllergiesFormState();
}

class _AllergiesFormState extends State<AllergiesForm> {
  bool? _hasAllergies; // null = not answered, true/false
  final List<AllergyEntry> _entries = [];

  // ── constants ──────────────────────────────────────────────────────────────
  static const _allergyTypes = [
    'Food',
    'Drug',
    'Environmental',
    'Insect',
    'Other',
  ];

  static const _severityLevels = ['Mild', 'Moderate', 'Severe'];

  static const _allergyTypeIcons = <String, IconData>{
    'Food': Icons.fastfood_outlined,
    'Drug': Icons.medication_outlined,
    'Environmental': Icons.eco_outlined,
    'Insect': Icons.pest_control_outlined,
    'Other': Icons.more_horiz,
  };

  static const _severityColors = <String, Color>{
    'Mild': Color(0xFF4CAF50),
    'Moderate': Color(0xFFF5A962),
    'Severe': Color(0xFFEF4444),
  };

  // ── notify parent ──────────────────────────────────────────────────────────
  void _notify() {
    widget.onDataChanged({
      'hasAllergies': _hasAllergies,
      'entries': _entries.map((e) => e.toMap()).toList(),
    });
  }

  // ── add / remove entries ───────────────────────────────────────────────────
  void _addEntry() {
    setState(() => _entries.add(AllergyEntry()));
    _notify();
  }

  void _removeEntry(int index) {
    setState(() => _entries.removeAt(index));
    _notify();
  }

  // ── reusable style helpers (match app palette) ─────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF5A962), Color(0xFFF08030)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF5A962).withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFFF5A962),
              letterSpacing: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF5A962),
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _buildTogglePill(String label, bool selected, VoidCallback onTap,
      {Color? activeColor}) {
    final color = activeColor ?? const Color(0xFFF5A962);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : const Color(0xFFEEEEEE),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 13,
              color: selected ? Colors.white : Colors.black38,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    IconData? icon,
  }) {
    return TextFormField(
      initialValue: value,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A1A1A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Colors.black26),
        prefixIcon:
            icon != null ? Icon(icon, size: 16, color: Colors.black38) : null,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFF5A962), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
      ),
    );
  }

  // ── single allergy entry card ──────────────────────────────────────────────
  Widget _buildAllergyCard(int index) {
    final entry = _entries[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5A962).withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: entry number + remove button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A962).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Allergy #${index + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF08030),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _removeEntry(index),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Allergy Type chips ───────────────────────────────────────
          _buildLabel('ALLERGY TYPE'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allergyTypes.map((type) {
              final icon = _allergyTypeIcons[type] ?? Icons.help_outline;
              final selected = entry.type == type;
              return GestureDetector(
                onTap: () {
                  setState(() => entry.type = type);
                  _notify();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFF5A962)
                        : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFF5A962)
                          : const Color(0xFFEEEEEE),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          size: 13,
                          color: selected ? Colors.white : Colors.black45),
                      const SizedBox(width: 5),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // ── Specific Allergen ────────────────────────────────────────
          _buildLabel('SPECIFIC ALLERGEN'),
          _buildTextField(
            hint: 'e.g. Peanuts, Amoxicillin, Dust mites…',
            value: entry.allergen,
            icon: Icons.search_outlined,
            onChanged: (v) {
              entry.allergen = v;
              _notify();
            },
          ),
          const SizedBox(height: 12),

          // ── Reaction / Symptoms ──────────────────────────────────────
          _buildLabel('REACTION / SYMPTOMS'),
          _buildTextField(
            hint: 'e.g. Hives, difficulty breathing, swelling…',
            value: entry.reaction,
            icon: Icons.warning_amber_outlined,
            maxLines: 2,
            onChanged: (v) {
              entry.reaction = v;
              _notify();
            },
          ),
          const SizedBox(height: 12),

          // ── Severity ─────────────────────────────────────────────────
          _buildLabel('SEVERITY'),
          Row(
            children: _severityLevels.map((level) {
              final color = _severityColors[level]!;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildTogglePill(
                  level,
                  entry.severity == level,
                  () {
                    setState(() => entry.severity = level);
                    _notify();
                  },
                  activeColor: color,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('ALLERGIES & ALLERGY HISTORY', Icons.coronavirus_outlined),
          const SizedBox(height: 14),

          // ── Has Allergies? Yes / No ──────────────────────────────────
          _buildLabel('DOES THE CHILD HAVE KNOWN ALLERGIES?'),
          Row(
            children: [
              _buildTogglePill('Yes', _hasAllergies == true, () {
                setState(() {
                  _hasAllergies = true;
                  if (_entries.isEmpty) _entries.add(AllergyEntry());
                });
                _notify();
              }),
              const SizedBox(width: 8),
              _buildTogglePill('No', _hasAllergies == false, () {
                setState(() {
                  _hasAllergies = false;
                  _entries.clear();
                });
                _notify();
              }),
            ],
          ),

          // ── Allergy entries (shown only when Yes) ────────────────────
          if (_hasAllergies == true) ...[
            const SizedBox(height: 16),
            ..._entries.asMap().entries.map((e) => _buildAllergyCard(e.key)),

            // Add another allergy button
            GestureDetector(
              onTap: _addEntry,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A962).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF5A962).withValues(alpha: 0.4),
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline,
                        size: 16, color: Color(0xFFF5A962)),
                    SizedBox(width: 6),
                    Text(
                      'Add Another Allergy',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF5A962),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}