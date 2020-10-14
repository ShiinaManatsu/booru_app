import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:booru_app/extensions/shared_preferences_extension.dart';
import 'package:booru_app/pages/home_page.dart';
import 'package:booru_app/pages/setting_page.dart';
import 'package:booru_app/router.gr.dart' as routes;
import 'package:booru_app/settings/app_settings.dart';
import 'package:booru_app/settings/language.dart';
import 'package:path/path.dart' as p;
import 'package:booru_app/themes/theme_dark.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'android/notifier.dart';
import 'themes/theme_light.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, kIsWeb;
import 'package:uni_links/uni_links.dart';

/// Global variables
/// Global events
/// Do function after check account
PublishSubject<Function> accountOperation = PublishSubject<Function>();
Language language;
PublishSubject<String> uniLink = PublishSubject<String>();

Notifier notifier;

void globalInitial() {
  accountOperation
      .where((_) => AppSettings.localUsers.contains(
          (LocalUser user) => user.clientType == AppSettings.currentClient))
      .listen((event) => event());

  if (!Platform.isWindows)
    getUriLinksStream().listen((link) {
      if (AppSettings.currentClient == ClientType.Konachan &&
          link.host.contains("yande")) {
        AppSettings.currentClient = ClientType.Yande;
        booruBloc.onReset.add(null);
      } else if (AppSettings.currentClient == ClientType.Yande &&
          link.host.contains("konachan")) {
        AppSettings.currentClient = ClientType.Konachan;
        booruBloc.onReset.add(null);
      }
      ExtendedNavigator.root.push(routes.Routes.postViewPageByPostID,
          arguments: routes.PostViewPageByPostIDArguments(
              postID:
                  link.pathSegments[link.pathSegments.indexOf("show") + 1]));
    });

  AppSettings.savePath.then((value) async {
    if (Platform.isAndroid) {
      if (value == null || value.isEmpty) {
        AppSettings.setSavePath(
            (await getExternalStorageDirectory()).absolute.path);
      }
    } else {
      AppSettings.setSavePath(
          p.join(Directory.current.absolute.path, "/BooruPhotos"));
    }
  });

  SharedPreferencesExtension.getTyped<String>("PreviewQuality").then((q) {
    if (q != null) {
      AppSettings.previewQuality =
          EnumToString.fromString(PreviewQuality.values, q);
    } else {
      AppSettings.previewQuality = PreviewQuality.Low;
      SharedPreferencesExtension.setTyped(
          "PreviewQuality", EnumToString.convertToString(PreviewQuality.Low));
    }
  });

  SharedPreferencesExtension.getTyped<bool>("safemode").then((value) {
    if (value != null) {
      AppSettings.safeMode = value;
    } else {
      AppSettings.safeMode = false;
      SharedPreferencesExtension.setTyped<bool>("safemode", false);
    }
  });

  SharedPreferencesExtension.getTyped<bool>("masonryGrid").then((value) {
    if (value != null) {
      AppSettings.masonryGrid = value;
    } else {
      AppSettings.masonryGrid = false;
      SharedPreferencesExtension.setTyped<bool>("masonryGrid", false);
    }
  });
}

void _desktopInitHack() {
  if (kIsWeb) return;

  if (Platform.isMacOS) {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  } else if (Platform.isLinux || Platform.isWindows) {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  } else if (Platform.isFuchsia) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
}

void main() {
  _desktopInitHack();
  runApp(MyApp());
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    notifier = Notifier();
  }
  globalInitial();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // uniLink.delay(Duration(seconds: 2)).listen((event) {
    //   toast(event);
    // });
    // getInitialLink().then((value) => uniLink.add(value));

    return OverlaySupport(
        child: MaterialApp(
            builder: (context, child) {
              final MediaQueryData data = MediaQuery.of(context);
              return MediaQuery(
                  data: data.copyWith(textScaleFactor: data.textScaleFactor),
                  child: ExtendedNavigator<routes.Router>(
                      router: routes.Router()));
            },
            title: 'Home',
            darkTheme: darkTheme,
            theme: lightTheme));
  }
}
