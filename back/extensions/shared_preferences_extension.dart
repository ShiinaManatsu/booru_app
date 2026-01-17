import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An extension for easily get preferences
/// The extension method cannot apply to package class
class SharedPreferencesExtension {
  static PublishSubject<Map<String, dynamic>> _worker;
  static File _file;
  static Map _spJson;

  static PublishSubject _saver;

  bool _finishedWrite = true;

  SharedPreferencesExtension.windows() {
    _file = File("sp.json");
    if (_file != null) if (!_file.existsSync()) _file.createSync();

    var content = _file.readAsStringSync();

    if (content.isNotEmpty)
      _spJson = json.decode(content);
    else
      _spJson = Map();

    _worker = PublishSubject<Map<String, dynamic>>();
    _saver = PublishSubject();

    _saver
        .throttle((x) => TimerStream(x, Duration(milliseconds: 100)),
            trailing: true)
        .takeWhile((element) => _finishedWrite)
        .listen((value) async {
      _finishedWrite = false;
      await _file.writeAsString(json.encode(_spJson));
      _finishedWrite = true;
    });

    _worker.listen((value) async {
      _spJson[value.keys.first] = value.values.first;
      _saver.add(null);
    });
  }

  /// Set the type value from SharedPreferences
  /// Where [T] is the type you want ot save
  static Future<bool> setTyped<T>(String key, T value) async {
    if (!kIsWeb && Platform.isWindows) {
      if (_file != null) if (!_file.existsSync()) _file.createSync();
      _worker.add({key: value});
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
    if (!kIsWeb && Platform.isWindows) {
      var file = File("sp.json");
      if (await file.exists()) {
        var content = await file.readAsString();

        if (content.isEmpty) return null;

        Map<String, dynamic> j = json.decode(content);

        if (j.containsKey(key))
          return j[key] as T;
        else
          return null;
      } else
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
