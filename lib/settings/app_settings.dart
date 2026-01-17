import 'package:booru_app/extensions/shared_preferences_extension.dart';
import 'package:booru_app/models/rx/booru_api.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/platform.dart';
import '../utils/storage_paths.dart';
import 'client_types.dart';

export 'client_types.dart';

enum PreviewQuality { Low, Medium }

/// Settings fot the whole application.
///
/// This may gonna implement to database.
class AppSettings {
  /// The current client
  static ClientType currentClient = ClientType.Yande;

  /// The height of post in the post list
  static double fixedPostHeight = !kIsWeb && isAndroid ? 256.0 : 384.0;

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

  /// Photo save location per source
  static Future<String> savePath({ClientType? client}) async => await SharedPreferencesExtension.getTyped<String>(_saveKey(client)) ?? "";

  static Future<void> setSavePath(String path, {ClientType? client}) async => SharedPreferencesExtension.setTyped<String>(_saveKey(client), path);

  /// Post limit for post and search
  static Future<double> get postLimit async => await SharedPreferencesExtension.getTyped<double>("postLimit") ?? 50;

  /// Post limit for post and search
  static setPostLimit(double value) => SharedPreferencesExtension.setTyped<double>("postLimit", value);

  static String get token {
    if (localUsers.any((x) => x.clientType == currentClient)) {
      return localUsers.firstWhere((x) => x.clientType == currentClient).token;
    }
    return "";
  }

  static List<LocalUser> localUsers = <LocalUser>[];

  /// Return the current client `url`
  static String get currentBaseUrl {
    switch (currentClient) {
      case ClientType.Yande:
        return "https://yande.re";
      case ClientType.Konachan:
        return "https://konachan.com";
    }
  }

  static Future<void> ensureInitialized() async {
    await _initPreviewQuality();
    await _initSafeMode();
    await _initMasonryGrid();
    await _initSavePaths();
  }

  static String _saveKey(ClientType? client) {
    final target = client ?? currentClient;
    switch (target) {
      case ClientType.Konachan:
        return "savePath_konachan";
      case ClientType.Yande:
        return "savePath_yande";
    }
  }

  static Future<void> _initPreviewQuality() async {
    final cached = await SharedPreferencesExtension.getTyped<String>("PreviewQuality");
    if (cached != null) {
      previewQuality = EnumToString.fromString(PreviewQuality.values, cached) ?? PreviewQuality.Medium;
    } else {
      previewQuality = PreviewQuality.Medium;
      await SharedPreferencesExtension.setTyped("PreviewQuality", EnumToString.convertToString(PreviewQuality.Medium));
    }
  }

  static Future<void> _initSafeMode() async {
    final value = await SharedPreferencesExtension.getTyped<bool>("safemode");
    if (value != null) {
      safeMode = value;
    } else {
      safeMode = false;
      await SharedPreferencesExtension.setTyped<bool>("safemode", false);
    }
  }

  static Future<void> _initMasonryGrid() async {
    final value = await SharedPreferencesExtension.getTyped<bool>("masonryGrid");
    if (value != null) {
      masonryGrid = value;
    } else {
      masonryGrid = false;
      await SharedPreferencesExtension.setTyped<bool>("masonryGrid", false);
    }

    final radius = await SharedPreferencesExtension.getTyped<double>("masonryGridBorderRadius");
    masonryGridBorderRadius = radius ?? 12;
    if (radius == null) {
      await SharedPreferencesExtension.setTyped<double>("masonryGridBorderRadius", 12);
    }

    final spacing = await SharedPreferencesExtension.getTyped<double>("masonryGridSpacing");
    masonryGridSpacing = spacing ?? 4;
    if (spacing == null) {
      await SharedPreferencesExtension.setTyped<double>("masonryGridSpacing", 4);
    }
  }

  static Future<void> _initSavePaths() async {
    for (final client in ClientType.values) {
      final existing = await savePath(client: client);
      if (existing.isNotEmpty) continue;

      String defaultPath = "";
      if (!kIsWeb && (isAndroid || isIOS)) {
        final dir = await getExternalStorageDirectory();
        if (dir != null) {
          defaultPath = dir.path;
        }
      } else {
        defaultPath = await defaultSavePath(client);
      }

      if (defaultPath.isNotEmpty) {
        await setSavePath(defaultPath, client: client);
      }
    }
  }
}

/// User object
/// "password_hash=9b86532bf85edf67fbc5c96561c178edaefc6d37&login=yande_loli";
class LocalUser {
  int? id;
  ClientType clientType;
  String hashedPassword = "";
  String username = "";
  String get token => "login=$username&password_hash=$hashedPassword";
  List<String> blacklist = [];

  String get avatarUrl => id == null ? "" : "${AppSettings.currentBaseUrl}/data/avatars/${id.toString()}.jpg";

  LocalUser(this.clientType, String username, String password) {
    this.username = username;
    hashedPassword = BooruAPI.getSha1Password(password);
    BooruAPI.getUsers(name: username).then((x) {
      if (x.isNotEmpty) id = x.first.id;
    });
  }
}
