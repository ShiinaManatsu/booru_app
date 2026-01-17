import 'package:shared_preferences/shared_preferences.dart';

/// An extension for easily get preferences
/// The extension method cannot apply to package class
class SharedPreferencesExtension {
  /// Legacy entry point kept for compatibility.
  ///
  /// Historically this app used a file-based preferences fallback on Windows.
  /// `shared_preferences` supports desktop now, so this is a no-op.
  SharedPreferencesExtension.windows();

  /// Set the type value from SharedPreferences
  /// Where [T] is the type you want ot save
  static Future<bool> setTyped<T>(String key, T value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value is bool) return prefs.setBool(key, value);
    if (value is double) return prefs.setDouble(key, value);
    if (value is int) return prefs.setInt(key, value);
    if (value is String) return prefs.setString(key, value);
    if (value is List<String>) return prefs.setStringList(key, value);

    // Keep behavior predictable; unknown types just fail.
    return false;
  }

  /// Get the type value from SharedPreferences
  /// Where [T] is the type you want ot get
  static Future<T?> getTyped<T>(String key) async {
    final prefs = await SharedPreferences.getInstance();

    if (T == bool) return prefs.getBool(key) as T?;
    if (T == double) return prefs.getDouble(key) as T?;
    if (T == int) return prefs.getInt(key) as T?;
    if (T == String) return prefs.getString(key) as T?;
    if (T == List || T == List<String>) return prefs.getStringList(key) as T?;

    return null;
  }

  /// Get all the keys
  static Future<Set<String>> getAllKeys() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getKeys();
  }
}
