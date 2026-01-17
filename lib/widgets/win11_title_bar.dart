import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class Win11TitleBar extends StatelessWidget {
  const Win11TitleBar({super.key, required this.title});

  static const double height = 48;
  static const double _captionWidth = 138;

  final String title;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) {
      return const SizedBox.shrink();
    }

    // Force white caption icons for better contrast.
    final brightness = Brightness.dark;

    return SizedBox(
      height: height,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.32),
                    Colors.black.withValues(alpha: 0.20),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.65, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    right: _captionWidth,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: (_) {
                        // Drag the native window.
                        windowManager.startDragging();
                      },
                      onDoubleTap: () async {
                        // Standard Windows behavior.
                        if (await windowManager.isMaximized()) {
                          await windowManager.unmaximize();
                        } else {
                          await windowManager.maximize();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: DefaultTextStyle(
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: _captionWidth,
                      child: WindowCaption(
                        brightness: brightness,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
