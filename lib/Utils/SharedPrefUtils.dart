import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefUtils {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    if (_prefs != null) return;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // Swallow plugin initialization errors to avoid app crash
      // When the platform registers plugins correctly, subsequent init calls will set _prefs.
    }
  }

  // Save data
  static Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  static Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  // Get data
  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  static bool getBool(String key) {
    return _prefs?.getBool(key) ?? false;
  }

  // Remove data
  static Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  // Clear all
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
