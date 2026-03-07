import 'package:flutter/material.dart';

/// Placed between HealthStatusForm and DietaryAssessmentForm in home_page.dart
class FamilyPlanningForm extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onDataChanged;

  const FamilyPlanningForm({super.key, this.onDataChanged});

  @override
  State<FamilyPlanningForm> createState() => _FamilyPlanningFormState();
}

class _FamilyPlanningFormState extends State<FamilyPlanningForm> {
  bool? _usingFamilyPlanning;
  String? _methodUsed;
  final _otherMethodController = TextEditingController();

  static const _methods = [
    'Pills',
    'Condom',
    'IUD',
    'Injectable',
    'Natural / NFP',
    'Ligation',
    'Vasectomy',
    'Other',
  ];

  void _notify() {
    widget.onDataChanged?.call({
      'usingFamilyPlanning': _usingFamilyPlanning,
      'methodUsed': _methodUsed,
      'otherMethod': _otherMethodController.text.trim(),
    });
  }

  Widget _buildTogglePill(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5A962) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFF5A962) : const Color(0xFFEEEEEE),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 14,
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

  @override
  void dispose() {
    _otherMethodController.dispose();
    super.dispose();
  }

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
          // Header
          Row(
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
                child: const Icon(Icons.favorite_border_outlined,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'FAMILY PLANNING',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF5A962),
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Currently using FP?
          const Text(
            'CURRENTLY USING FAMILY PLANNING?',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF5A962),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildTogglePill('Yes', _usingFamilyPlanning == true, () {
                setState(() => _usingFamilyPlanning = true);
                _notify();
              }),
              const SizedBox(width: 8),
              _buildTogglePill('No', _usingFamilyPlanning == false, () {
                setState(() {
                  _usingFamilyPlanning = false;
                  _methodUsed = null;
                });
                _notify();
              }),
            ],
          ),

          // Method (shown only when Yes)
          if (_usingFamilyPlanning == true) ...[
            const SizedBox(height: 14),
            const Text(
              'METHOD USED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF5A962),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _methods
                  .map((m) => _buildTogglePill(m, _methodUsed == m, () {
                        setState(() => _methodUsed = m);
                        _notify();
                      }))
                  .toList(),
            ),
            if (_methodUsed == 'Other') ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _otherMethodController,
                onChanged: (_) => _notify(),
                style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
                decoration: InputDecoration(
                  hintText: 'Specify method',
                  hintStyle:
                      const TextStyle(fontSize: 12, color: Colors.black26),
                  prefixIcon: const Icon(Icons.edit_outlined,
                      size: 16, color: Colors.black38),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 11),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFFEEEEEE), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFFF5A962), width: 2),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}