import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:booru_app/models/local/statistics.dart';
import 'package:booru_app/router.gr.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:booru_app/settings/language.dart';
import 'package:booru_app/themes/theme_dark.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
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
  _getInitPost();

  // Rx.timer(null, Duration(seconds: 1)).listen((event) async {
  //   var s = await Statistics.getStatistics();
  //   toast(s.toJson().toString());
  // });
}

_getInitPost() async {
  var link = await getInitialLink();
  if (link == null) return;

  if (link.isNotEmpty) {
    ExtendedNavigator.root.pushAndRemoveUntil(
        Routes.postViewPageByPostID, (route) => false,
        arguments: PostViewPageByPostIDArguments(postID: link.split("/").last));
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).backgroundColor.withOpacity(0.95),
        statusBarIconBrightness: Theme.of(context).primaryColorBrightness));
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
                  child: ExtendedNavigator<Router>(router: Router()));
            },
            title: 'Home',
            darkTheme: darkTheme,
            theme: lightTheme));
  }
}
