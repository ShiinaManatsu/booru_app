import 'dart:async';

import 'package:adaptive_aura/adaptive_aura.dart';
import 'package:booru_app/extensions/shared_preferences_extension.dart';
import 'package:booru_app/models/rx/booru_api.dart';
import 'package:booru_app/models/rx/task_bloc.dart';
import 'package:booru_app/pages/home/home_shell.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:booru_app/utils/aura_controller.dart';
import 'package:booru_app/widgets/download_overlay.dart';
import 'utils/platform.dart';

final BooruAPI booruApi = BooruAPI();
final TaskBloc taskBloc = TaskBloc();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (isDesktop) {
    SharedPreferencesExtension.windows();
  }
  await AppSettings.ensureInitialized();
  runApp(const BooruApp());
}

class BooruApp extends StatelessWidget {
  const BooruApp({super.key});

  @override
  Widget build(BuildContext context) {
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
                        home: HomeShell(),
                      ),
                    )),
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
