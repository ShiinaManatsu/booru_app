import 'dart:io';

import 'package:booru_app/models/yande/post.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../utils/platform.dart';
import '../../utils/storage_paths.dart';

String _sanitizeFileNameForFs(String name) {
  // Windows invalid: < > : " / \ | ? * plus control chars.
  final cleaned = name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_').trim();
  return cleaned.isEmpty ? 'download' : cleaned;
}

Future<String> _ensureBaseDir() async {
  var base = await AppSettings.savePath();
  if (base.trim().isEmpty) {
    base = await defaultSavePath(AppSettings.currentClient);
    if (base.trim().isNotEmpty) {
      await AppSettings.setSavePath(base);
    }
  }
  if (base.trim().isEmpty) {
    final temp = await getTemporaryDirectory();
    base = temp.path;
  }
  await Directory(base).create(recursive: true);
  return base;
}

Future<String> _uniquePath(String dir, String fileName) async {
  final sanitized = _sanitizeFileNameForFs(fileName);
  final ext = p.extension(sanitized);
  final stem = p.basenameWithoutExtension(sanitized);

  var candidate = p.join(dir, sanitized);
  if (!await File(candidate).exists()) return candidate;

  for (var i = 1; i <= 9999; i++) {
    final nextName = ext.isEmpty ? '$stem ($i)' : '$stem ($i)$ext';
    candidate = p.join(dir, nextName);
    if (!await File(candidate).exists()) return candidate;
  }

  // Extremely unlikely fallback.
  return p.join(dir, '${stem}_${DateTime.now().millisecondsSinceEpoch}$ext');
}

Future<String?> prepareTargetPath(Post post, String fileName, {bool skipIfExists = false}) async {
  if (isWeb) return null;

  if (isDesktop) {
    final base = await _ensureBaseDir();
    if (skipIfExists) {
      final candidate = p.join(base, _sanitizeFileNameForFs(fileName));
      if (await File(candidate).exists()) return candidate;
    }
    return _uniquePath(base, fileName);
  } else if (isAndroid) {
    // On Android we save into the system gallery (MediaStore) after download.
    // Download into a temporary file first.
    final temp = await getTemporaryDirectory();
    if (skipIfExists) {
      final candidate = p.join(temp.path, _sanitizeFileNameForFs(fileName));
      if (await File(candidate).exists()) return candidate;
    }
    return _uniquePath(temp.path, fileName);
  } else {
    final temp = await getTemporaryDirectory();
    if (skipIfExists) {
      final candidate = p.join(temp.path, _sanitizeFileNameForFs(fileName));
      if (await File(candidate).exists()) return candidate;
    }
    return _uniquePath(temp.path, fileName);
  }
}

Future<FileInfo?> loadCached(String url) async {
  if (isWindows || isWeb) return null;
  return DefaultCacheManager().getFileFromCache(url);
}

Future<void> saveBytes(String path, List<int> bytes) async {
  final file = File(path);
  await file.writeAsBytes(bytes);
}

Future<bool> fileExists(String path) async {
  return File(path).exists();
}
