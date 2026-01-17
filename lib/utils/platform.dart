import 'package:flutter/foundation.dart' show kIsWeb;

import 'platform_stub.dart' if (dart.library.io) 'platform_io.dart';

bool get isWeb => kIsWeb;
bool get isWindows => !kIsWeb && ioIsWindows;
bool get isMacOS => !kIsWeb && ioIsMacOS;
bool get isLinux => !kIsWeb && ioIsLinux;
bool get isAndroid => !kIsWeb && ioIsAndroid;
bool get isIOS => !kIsWeb && ioIsIOS;
bool get isDesktop => isWindows || isMacOS || isLinux;
