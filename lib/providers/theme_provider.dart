import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _fontKey = 'app_selected_font';
  static const String _defaultFont = 'Roboto';

  String _selectedFont = _defaultFont;

  String get selectedFont => _selectedFont;

  /// Initialize the ThemeProvider and load saved font preference
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedFont = prefs.getString(_fontKey) ?? _defaultFont;
    notifyListeners();
  }

  /// Set the font and persist to SharedPreferences
  Future<void> setFont(String font) async {
    if (_selectedFont == font) return;

    _selectedFont = font;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontKey, font);
  }

  /// Returns a TextTheme that matches the currently selected font.
  ///
  /// This is used by the app's ThemeData so that changing the font
  /// in the Appearance screen updates typography globally.
  TextTheme get textTheme {
    switch (_selectedFont) {
      case 'Poppins':
        return GoogleFonts.poppinsTextTheme();
      case 'Montserrat':
        return GoogleFonts.montserratTextTheme();
      case 'Open Sans':
        return GoogleFonts.openSansTextTheme();
      case 'Roboto':
      default:
        return GoogleFonts.robotoTextTheme();
    }
  }
}
