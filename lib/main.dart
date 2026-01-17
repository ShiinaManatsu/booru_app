import 'dart:async';

import 'package:adaptive_aura/adaptive_aura.dart';
import 'package:booru_app/extensions/shared_preferences_extension.dart';
import 'package:booru_app/models/rx/booru_api.dart';
import 'package:booru_app/models/rx/task_bloc.dart';
import 'package:booru_app/pages/home/home_shell.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:booru_app/widgets/win11_title_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:booru_app/utils/aura_controller.dart';
import 'package:booru_app/widgets/download_overlay.dart';
import 'package:window_manager/window_manager.dart';
import 'utils/platform.dart';

final BooruAPI booruApi = BooruAPI();
final TaskBloc taskBloc = TaskBloc();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (isDesktop) {
    SharedPreferencesExtension.windows();
  }
  await AppSettings.ensureInitialized();

  if (_useWin11TitleBar) {
    await _initWindowsTitleBar();
  }

  runApp(const BooruApp());
}

bool get _useWin11TitleBar => !kIsWeb && isDesktop && defaultTargetPlatform == TargetPlatform.windows;

Future<void> _initWindowsTitleBar() async {
  await windowManager.ensureInitialized();
  await windowManager.setTitleBarStyle(
    TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

  const options = WindowOptions();
  windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

class BooruApp extends StatelessWidget {
  const BooruApp({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = _useWin11TitleBar ? Win11TitleBar.height : 0.0;
    return ScaffoldMessenger(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) {
                return Stack(
                  children: [
                    Positioned.fill(
                        child: _AuraShell(
                      child: ShadApp(
                        backgroundColor: Colors.transparent,
                        debugShowCheckedModeBanner: false,
                        theme: ShadThemeData(
                          brightness: Brightness.dark,
                          colorScheme: ShadSlateColorScheme.dark(),
                        ),
                        builder: (context, child) {
                          if (child == null) return const SizedBox.shrink();
                          return Padding(
                            padding: EdgeInsets.only(top: topPadding),
                            child: child,
                          );
                        },
                        home: const HomeShell(),
                      ),
                    )),
                    if (_useWin11TitleBar)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Win11TitleBar(title: 'Booru App'),
                      ),
                    DownloadOverlay(taskBloc: taskBloc),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AuraShell extends StatelessWidget {
  const _AuraShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ImageProvider>(
      valueListenable: AuraController.instance.imageListenable,
      builder: (context, image, _) {
        return AdaptiveAuraContainer(
          image: image,
          child: child,
          auraStyle: AuraStyle.gradient,
          variety: 0.7,
          colorIntensity: 0.8,
          blurStrength: 15.0,
          animationValue: 0.4,
          animationDuration: Duration(milliseconds: 800),
          colorTransitionDuration: Duration(milliseconds: 300),
        );
      },
    );
  }
}
