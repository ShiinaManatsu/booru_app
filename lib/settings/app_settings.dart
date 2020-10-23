import 'dart:io';

import 'package:booru_app/extensions/shared_preferences_extension.dart';
import 'package:booru_app/models/rx/booru_api.dart';
import 'package:booru_app/pages/setting_page.dart';
import 'package:flutter/foundation.dart';

/// Settings fot the whole application.
///
/// This may gonna implement to database.
class AppSettings {
  /// The current client
  static ClientType currentClient = ClientType.Yande;

  /// The height of post in the post list
  static double fixedPostHeight = !kIsWeb && Platform.isAndroid ? 256.0 : 384.0;

  /// The first day that yande has datas
  static DateTime yandeFirstday = DateTime(2006, 9);

  /// The first day that konanchan has datas
  static DateTime konachanFirstday = DateTime(2008, 2);

  /// Preview image quality
  static PreviewQuality previewQuality = PreviewQuality.Medium;

  /// Filter only safe images
  static bool safeMode = false;

  /// Use masonry grid
  static bool masonryGrid = false;

  static double masonryGridBorderRadius = 12;

  static double masonryGridSpacing = 4;

  /// Photo save location
  static Future<String> get savePath async =>
      await SharedPreferencesExtension.getTyped<String>("savePath") ?? "";

  static setSavePath(String path) =>
      SharedPreferencesExtension.setTyped<String>("savePath", path);

  /// Post limit for post and search
  static Future<double> get postLimit async =>
      await SharedPreferencesExtension.getTyped<double>("postLimit") ?? 50;

  /// Post limit for post and search
  static setPostLimit(double value) =>
      SharedPreferencesExtension.setTyped<double>("postLimit", value);

  static String get token =>
      localUsers.where((x) => x.clientType == currentClient).first.token;

  static List<LocalUser> localUsers = List<LocalUser>();

  /// Return the current client `url`
  static String get currentBaseUrl {
    switch (currentClient) {
      case ClientType.Yande:
        return "https://yande.re";
        break;
      case ClientType.Konachan:
        return "https://konachan.com";
        break;
      default:
        return null;
        break;
    }
  }
}

/// Indicate a booru client type
enum ClientType { Yande, Konachan }

/// User object
/// "password_hash=9b86532bf85edf67fbc5c96561c178edaefc6d37&login=yande_loli";
class LocalUser {
  int id;
  ClientType clientType;
  String hashedPassword = "";
  String username = "";
  String get token => "login=$username&password_hash=$hashedPassword";
  List<String> blacklist = [];

  String get avatarUrl =>
      "${AppSettings.currentBaseUrl}/data/avatars/${id.toString()}.jpg";

  LocalUser(this.clientType, String username, String password) {
    this.username = username;
    hashedPassword = BooruAPI.getSha1Password(password);
    BooruAPI.getUsers(name: username).then((x) => id = x.first.id);
  }
}
