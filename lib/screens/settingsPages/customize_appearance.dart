import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class CustomizeAppearance extends StatefulWidget {
  const CustomizeAppearance({super.key});

  @override
  State<CustomizeAppearance> createState() => _CustomizeAppearanceState();
}

class _CustomizeAppearanceState extends State<CustomizeAppearance> {
  Color selectedColor = Colors.black;
  String selectedFont = 'Roboto';

  final List<Color> colors = [
    Colors.white,
    Colors.black,
    const Color(0xFFFFF9C4),
    const Color(0xFF737373),
    Colors.redAccent,
    Colors.blueGrey,
    const Color(0xFFD9D9D9),
    Colors.purpleAccent,
  ];

  final List<String> fonts = ['Roboto', 'Poppins', 'Montserrat', 'Open Sans'];

  /// Detect dark color
  bool _isDarkColor(Color color) {
    return color.computeLuminance() < 0.5;
  }

  Color _getContrastColor(Color color) {
    return _isDarkColor(color) ? Colors.white : Colors.black;
  }

  /// ⭐ Color Picker Dialog
  void openColorPicker() {
    Color tempColor = selectedColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pick a color"),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor,
            onColorChanged: (color) {
              tempColor = color;
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Select"),
            onPressed: () {
              setState(() => selectedColor = tempColor);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E8B7B),
              Color(0xFF5CAA7F),
              Color(0xFF8BC88A),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Customize Appearance",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              Container(
                height: 1.5,
                width: double.infinity,
                color: Colors.white.withOpacity(0.3),
              ),

              const SizedBox(height: 20),

              /// 🔹 Colors Grid
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double colorSize =
                        ((constraints.maxWidth - 12 * 3) / 4) * 0.80;

                    return Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: colors.map((color) {
                        bool isSelected = color == selectedColor;
                        Color contrastColor = _getContrastColor(color);

                        return GestureDetector(
                          onTap: () =>
                              setState(() => selectedColor = color),
                          child: Container(
                            width: colorSize,
                            height: colorSize,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: contrastColor,
                                      width: 3,
                                    )
                                  : null,
                            ),
                            child: isSelected
                                ? Icon(Icons.check, color: contrastColor)
                                : null,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),

                 /// 🔹 Font Selector Card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Aa",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Font Family",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    DropdownButton<String>(
                      value: selectedFont,
                      underline: const SizedBox(),
                      items: fonts.map((font) {
                        return DropdownMenuItem(
                          value: font,
                          child: Text(
                            font,
                            style: TextStyle(fontFamily: font),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedFont = value);
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              /// ⭐ Open Full Color Picker
              GestureDetector(
                onTap: openColorPicker,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.palette),
                      const SizedBox(width: 12),
                      const Text(
                        "Colors",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

          
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
