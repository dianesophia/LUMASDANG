import 'package:shared_preferences/shared_preferences.dart';

const String _keyAutoArchiveEnabled = 'auto_archive_at_five_years_enabled';

/// Preferences for auto-archiving patients when they reach 5 years (60 months).
/// Default is true (enabled).
class AutoArchivePreferences {
  static Future<bool> isAutoArchiveEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoArchiveEnabled) ?? true;
  }

  static Future<void> setAutoArchiveEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoArchiveEnabled, enabled);
  }
}
