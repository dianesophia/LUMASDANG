import 'package:flutter/material.dart';

/// Placed after DietaryAssessmentForm in home_page.dart
class NutritionEnvironmentForm extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onDataChanged;

  const NutritionEnvironmentForm({super.key, this.onDataChanged});

  @override
  State<NutritionEnvironmentForm> createState() =>
      _NutritionEnvironmentFormState();
}

class _NutritionEnvironmentFormState
    extends State<NutritionEnvironmentForm> {
  // Oil
  String? _oilType;
  final _oilOtherController = TextEditingController();

  // Salt
  String? _saltType;

  // Water
  String? _waterSource;
  final _waterOtherController = TextEditingController();

  // Backyard gardening
  bool? _hasBackyardGarden;
  final _gardenWhatController = TextEditingController();

  static const _oilOptions = [
    'Coconut Oil',
    'Palm Oil',
    'Vegetable Oil',
    'Canola Oil',
    'Other',
  ];

  static const _saltOptions = [
    'Iodized Salt',
    'Rock Salt',
    'Sea Salt',
  ];

  static const _waterOptions = [
    'Tap / Piped',
    'Deep Well',
    'Spring / Stream',
    'Bottled Water',
    'Rain Water',
    'Other',
  ];

  void _notify() {
    widget.onDataChanged?.call({
      'oilType': _oilType == 'Other' ? _oilOtherController.text.trim() : _oilType,
      'saltType': _saltType,
      'waterSource': _waterSource == 'Other'
          ? _waterOtherController.text.trim()
          : _waterSource,
      'hasBackyardGarden': _hasBackyardGarden,
      'gardenWhat': _gardenWhatController.text.trim(),
    });
  }

  Widget _buildTogglePill(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
  }

  Widget _buildOtherField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: controller,
        onChanged: (_) => _notify(),
        style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Colors.black26),
          prefixIcon: const Icon(Icons.edit_outlined,
              size: 16, color: Colors.black38),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFFF5A962), width: 2),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _oilOtherController.dispose();
    _waterOtherController.dispose();
    _gardenWhatController.dispose();
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
                child: const Icon(Icons.eco_outlined,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'NUTRITION ENVIRONMENT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF5A962),
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Oil Type
          _buildSectionLabel('OIL TYPE USED IN COOKING'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _oilOptions
                .map((o) => _buildTogglePill(o, _oilType == o, () {
                      setState(() => _oilType = o);
                      _notify();
                    }))
                .toList(),
          ),
          if (_oilType == 'Other')
            _buildOtherField(_oilOtherController, 'Specify oil type'),

          const SizedBox(height: 16),

          // Salt Type
          _buildSectionLabel('SALT TYPE'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _saltOptions
                .map((s) => _buildTogglePill(s, _saltType == s, () {
                      setState(() => _saltType = s);
                      _notify();
                    }))
                .toList(),
          ),

          const SizedBox(height: 16),

          // Water Source
          _buildSectionLabel('SOURCE OF DRINKING WATER'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _waterOptions
                .map((w) => _buildTogglePill(w, _waterSource == w, () {
                      setState(() => _waterSource = w);
                      _notify();
                    }))
                .toList(),
          ),
          if (_waterSource == 'Other')
            _buildOtherField(_waterOtherController, 'Specify water source'),

          const SizedBox(height: 16),

          // Backyard Gardening
          _buildSectionLabel('BACKYARD GARDENING?'),
          Row(
            children: [
              _buildTogglePill('Yes', _hasBackyardGarden == true, () {
                setState(() => _hasBackyardGarden = true);
                _notify();
              }),
              const SizedBox(width: 8),
              _buildTogglePill('No', _hasBackyardGarden == false, () {
                setState(() {
                  _hasBackyardGarden = false;
                  _gardenWhatController.clear();
                });
                _notify();
              }),
            ],
          ),
          if (_hasBackyardGarden == true) ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: _gardenWhatController,
              onChanged: (_) => _notify(),
              maxLines: 2,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                hintText: 'What do you grow? (e.g. kangkong, camote…)',
                hintStyle:
                    const TextStyle(fontSize: 12, color: Colors.black26),
                prefixIcon: const Icon(Icons.grass_outlined,
                    size: 16, color: Colors.black38),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFFF5A962), width: 2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}