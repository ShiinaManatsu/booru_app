import 'package:booru_app/models/yande/post.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

Future<String?> prepareTargetPath(Post post, String fileName, {bool skipIfExists = false}) async => null;
Future<FileInfo?> loadCached(String url) async => null;
Future<void> saveBytes(String path, List<int> bytes) async {}
Future<bool> fileExists(String path) async => false;
