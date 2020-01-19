import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:yande_web/pages/post_view_page.dart';
import 'package:yande_web/pages/setting_page.dart';
import 'android/notifier.dart';
import 'android/post_downloader.dart';
import 'pages/home_page.dart';
import 'pages/search_tagged_posts_page.dart';
import 'themes/theme_light.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, kIsWeb;

Notifier notifier;
PostDownloader postDownloader;

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

  postDownloader = PostDownloader();
}

// Routes
const String homePage = '/';
const String searchTaggedPostsPage = '/searchTaggedPostsPage';
const String postViewPage = '/postViewPage';
const String settingsPage = '/settingsPage';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.transparent));

    return OverlaySupport(
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          // onGenerateRoute: (settings) {
          //   final Map<String, dynamic> arg = settings.arguments;
          //   Widget screen;
          //   switch (settings.name) {
          //     case homePage:
          //       screen = HomePage();
          //       break;
          //     case searchTaggedPostsPage:
          //       screen = SearchTaggedPostsPage(key: arg["key"]);
          //       break;
          //     case postViewPage:
          //       screen = PostViewPage(post: arg["post"]);
          //       break;
          //     case settingsPage:
          //       screen = SettingPage();
          //       break;
          //     default:
          //       return null;
          //   }
          //   return MaterialPageRoute(builder: (BuildContext contex) => screen);
          // },
          onGenerateRoute: (settings) => PageRouteBuilder(
              settings: settings,
              pageBuilder: (context, animation, secondaryAnimation) {
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
                  default:
                    return null;
                }
              },
              transitionDuration: const Duration(milliseconds: 700),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return effectMap[PageTransitionType.transferRight](
                    Curves.ease, animation, secondaryAnimation, child);
              }),
          title: 'Home',
          theme: lightTheme),
    );
  }
}
