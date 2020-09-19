import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// An extension for easily get preferences
/// The extension method cannot apply to package class
class SharedPreferencesExtension {
  /// Set the type value from SharedPreferences
  /// Where [T] is the type you want ot save
  static Future<bool> setTyped<T>(String key, T value) async {
    if (Platform.isWindows) {
      var file = File("sp.json");
      var j = json.decode(await file.readAsString());
      j[key] = value;
      await file.writeAsString(json.encode(j));
      return true;
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      switch (T) {
        case bool:
          return prefs.setBool(key, value as bool);
          break;
        case double:
          return prefs.setDouble(key, value as double);
          break;
        case int:
          return prefs.setInt(key, value as int);
          break;
        case String:
          return prefs.setString(key, value as String);
          break;
        case List:
          return prefs.setStringList(key, value as List<String>);
          break;
        default:
          return false;
          break;
      }
    }
  }

  /// Get the type value from SharedPreferences
  /// Where [T] is the type you want ot get
  static Future<T> getTyped<T>(String key) async {
    if (Platform.isWindows) {
      var file = File("sp.json");
      var content = await file.readAsString();
      
      if (content.isEmpty) return null;

      Map<String, dynamic> j = json.decode(content);

      if (j.containsKey(key))
        return j[key] as T;
      else
        return null;
    } else {
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
  }

  /// Get all the keys
  static Future<Set<String>> getAllKeys() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getKeys();
  }
}
