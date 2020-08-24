import 'dart:io';
import 'package:booru_app/extensions/shared_preferences_extension.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:booru_app/settings/language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:booru_app/pages/post_view_page.dart';
import 'package:booru_app/pages/setting_page.dart';
import 'package:booru_app/pages/testGroundPage.dart';
import 'package:rxdart/rxdart.dart';
import 'android/notifier.dart';
import 'pages/home_page.dart';
import 'pages/search_tagged_posts_page.dart';
import 'themes/theme_light.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, kIsWeb;

/// Global variables
/// Global events
/// Do function after check account
PublishSubject<Function> accountOperation = PublishSubject<Function>();
Language language;

Notifier notifier;

void globalInitial() {
  accountOperation
      .where((_) => AppSettings.localUsers.contains(
          (LocalUser user) => user.clientType == AppSettings.currentClient))
      .listen((event) => event());
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

// Routes
const String homePage = '/';
const String searchTaggedPostsPage = '/searchTaggedPostsPage';
const String postViewPage = '/postViewPage';
const String settingsPage = '/settingsPage';
const String testGroundPage = '/testGroundPage';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.white.withOpacity(0.95),
        statusBarIconBrightness: Brightness.dark));

    return OverlaySupport(
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateRoute:(settings)=>MaterialPageRoute(
            settings: settings,
            builder: (context) {
              final Map<String, dynamic> arg = settings.arguments;
                switch (settings.name) {
                  case homePage:
                    return HomePage();
                    break;
                  case searchTaggedPostsPage:
                    return SearchTaggedPostsPage(key: arg["key"]);
                    break;
                  case postViewPage:
                    return PostViewPage(post: arg["post"]);
                    break;
                  case settingsPage:
                    return SettingPage();
                    break;
                  case testGroundPage:
                    return TestGroundPage();
                    break;
                  default:
                    return null;
                }
            },
          ),
          // onGenerateRoute: (settings) => PageRouteBuilder(
          //     settings: settings,
          //     pageBuilder: (context, animation, secondaryAnimation) {
          //       final Map<String, dynamic> arg = settings.arguments;
          //       switch (settings.name) {
          //         case homePage:
          //           return HomePage();
          //           break;
          //         case searchTaggedPostsPage:
          //           return SearchTaggedPostsPage(key: arg["key"]);
          //           break;
          //         case postViewPage:
          //           return PostViewPage(post: arg["post"]);
          //           break;
          //         case settingsPage:
          //           return SettingPage();
          //           break;
          //         case testGroundPage:
          //           return TestGroundPage();
          //           break;
          //         default:
          //           return null;
          //       }
          //     },
          //     transitionDuration: const Duration(milliseconds: 700),
          //     transitionsBuilder:
          //         (context, animation, secondaryAnimation, child) {
          //       return effectMap[PageTransitionType.transferRight](
          //           Curves.ease, animation, secondaryAnimation, child);
          //     }
          //     ),
          title: 'Home',
          theme: lightTheme),
    );
  }
}
