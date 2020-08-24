import 'package:shared_preferences/shared_preferences.dart';

/// An extension for easily get preferences
/// The extension method cannot apply to package class
class SharedPreferencesExtension{
  /// Set the type value from SharedPreferences
  /// Where [T] is the type you want ot save
  static setTyped<T>(String key, T value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    switch (T) {
      case bool:
        prefs.setBool(key, value as bool);
        break;
      case double:
        prefs.setDouble(key, value as double);
        break;
      case int:
        prefs.setInt(key, value as int);
        break;
      case String:
        prefs.setString(key, value as String);
        break;
      case List:
        prefs.setStringList(key, value as List<String>);
        break;
      default:
        break;
    }
  }

  /// Get the type value from SharedPreferences
  /// Where [T] is the type you want ot get
  static Future<T> getTyped<T>(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    switch (T) {
      case bool:
        return prefs.getBool(key) as T;
        break;
      case double:
        return prefs.getDouble(key) as T;
        break;
      case int:
        return prefs.getInt(key) as T;
        break;
      case String:
        return prefs.getString(key) as T;
        break;
      case List:
        return prefs.getStringList(key) as T;
        break;
      default:
        return null;
    }
  }

  /// Get all the keys
  static Future<Set<String>> getAllKeys() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getKeys();
  }
}