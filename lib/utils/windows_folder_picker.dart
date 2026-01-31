import 'package:flutter/foundation.dart';
import 'package:file_selector/file_selector.dart';

/// Opens the native Windows folder picker.
///
/// Uses `file_selector`'s `getDirectoryPath`.
///
/// Note: despite the name, this implementation is cross-platform, but the app
/// only calls it on Windows today.
/// Returns the selected folder path, or null if the user cancelled.
Future<String?> pickWindowsFolder({
  String title = 'Select folder',
  String? initialDirectory,
  int hwndOwner = 0,
}) async {
  try {
    return await getDirectoryPath(
      initialDirectory: initialDirectory,
      confirmButtonText: 'Select',
    );
  } catch (e, st) {
    // Avoid hard-crashing the app if COM/native APIs throw.
    if (kDebugMode) {
      debugPrint('pickWindowsFolder failed: $e');
      debugPrintStack(stackTrace: st);
    }
    return null;
  }
}
