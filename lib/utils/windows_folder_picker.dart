import 'dart:io';

import 'package:filepicker_windows/filepicker_windows.dart';
import 'package:flutter/foundation.dart';

/// Opens the native Windows folder picker.
///
/// Uses `filepicker_windows`'s `DirectoryPicker`, which wraps IFileOpenDialog.
/// Returns the selected folder path, or null if the user cancelled.
Future<String?> pickWindowsFolder({
  String title = 'Select folder',
  String? initialDirectory,
  int hwndOwner = 0,
}) async {
  try {
    final picker = DirectoryPicker()
      ..title = title
      ..hWndOwner = hwndOwner;

    if (initialDirectory != null) {
      final normalized = initialDirectory.trim();
      if (normalized.isNotEmpty && Directory(normalized).existsSync()) {
        picker
          ..initialDirectory = normalized
          ..alwaysShowInitialDirectory = true;
      }
    }

    final dir = picker.getDirectory();
    return dir?.path;
  } catch (e, st) {
    // Avoid hard-crashing the app if COM/native APIs throw.
    if (kDebugMode) {
      debugPrint('pickWindowsFolder failed: $e');
      debugPrintStack(stackTrace: st);
    }
    return null;
  }
}
