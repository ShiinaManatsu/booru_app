import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:booru_app/settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A lightweight, persistent tag index for fast local autocomplete.
///
/// Strategy:
/// - On first use per client, fetch `/tag.json?limit=0&order=name` and store only tag names.
/// - Subsequent runs read from disk (no repeated network).
/// - Suggestions use binary-search prefix lookup on a sorted list.
class TagIndexService {
  TagIndexService._();

  static final TagIndexService instance = TagIndexService._();

  final Map<ClientType, List<String>> _tags = <ClientType, List<String>>{};
  final Map<ClientType, Future<void>> _loading = <ClientType, Future<void>>{};

  bool get isSupported => !kIsWeb;

  Future<Directory> _baseDir() async {
    final dir = await getApplicationSupportDirectory();
    final base = Directory(p.join(dir.path, 'booru_cache'));
    if (!await base.exists()) {
      await base.create(recursive: true);
    }
    return base;
  }

  Future<File> _indexFile(ClientType client) async {
    final base = await _baseDir();
    return File(p.join(base.path, 'tag_index_${client.name}.txt'));
  }

  /// Ensure the on-disk index exists and in-memory list is loaded.
  ///
  /// When [forceRefresh] is true, re-downloads and overwrites the index.
  Future<void> ensureLoaded({ClientType? client, bool forceRefresh = false}) {
    final target = client ?? AppSettings.currentClient;
    return _loading[target] ??= _ensureLoadedInternal(target, forceRefresh: forceRefresh).whenComplete(() => _loading.remove(target));
  }

  Future<void> _ensureLoadedInternal(ClientType client, {required bool forceRefresh}) async {
    if (!isSupported) return;

    final file = await _indexFile(client);

    if (!forceRefresh && await file.exists()) {
      final lines = await file.readAsLines();
      _tags[client] = lines.where((e) => e.isNotEmpty).toList(growable: false);
      return;
    }

    if (kDebugMode) {
      debugPrint('[TagIndex] building index for ${client.name}...');
    }

    // NOTE: This may be large; keep only names to reduce memory footprint.
    final uri = Uri.parse(_baseUrlForClient(client)).resolve('/tag.json').replace(
      queryParameters: <String, String>{
        'limit': '0',
        'order': 'name',
      },
    );
    final response = await http.get(uri, headers: AppSettings.booruHeaders(client: client)).timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode} while building tag index for ${client.name}.');
    }
    final ct = response.headers['content-type']?.toLowerCase() ?? '';
    final trimmed = response.body.trimLeft();
    if (ct.contains('text/html') || trimmed.startsWith('<')) {
      final snippet = trimmed.length > 160 ? '${trimmed.substring(0, 160)}…' : trimmed;
      throw Exception(
        'Site returned HTML (likely Cloudflare/anti-bot challenge) when building tag index for ${client.name}. '
        'snippet=${snippet.replaceAll("\n", " ")}',
      );
    }
    final decoded = json.decode(response.body) as List;
    final names = decoded.map((e) => (e as Map)['name']?.toString() ?? '').where((e) => e.isNotEmpty).toSet().toList(growable: false)..sort();

    await file.writeAsString(names.join('\n'), flush: true, encoding: utf8);
    _tags[client] = names;

    if (kDebugMode) {
      debugPrint('[TagIndex] ${client.name}: ${names.length} tags indexed');
    }
  }

  static String _baseUrlForClient(ClientType client) {
    switch (client) {
      case ClientType.Yande:
        return 'https://yande.re';
      case ClientType.Konachan:
        return 'https://konachan.com';
    }
  }

  bool isReady({ClientType? client}) {
    final target = client ?? AppSettings.currentClient;
    return _tags.containsKey(target);
  }

  /// Suggest tags for a prefix. Requires [ensureLoaded] (or will return empty).
  List<String> suggest(String prefix, {ClientType? client, int limit = 20}) {
    final target = client ?? AppSettings.currentClient;
    final list = _tags[target];
    if (list == null || list.isEmpty) return const <String>[];

    final q = prefix.trim();
    if (q.isEmpty) return const <String>[];

    final start = _lowerBound(list, q);
    if (start >= list.length) return const <String>[];

    final out = <String>[];
    for (var i = start; i < list.length && out.length < limit; i++) {
      final v = list[i];
      if (v.startsWith(q)) {
        out.add(v);
      } else {
        break;
      }
    }
    return out;
  }

  /// Whether the exact tag exists in the index.
  ///
  /// Returns false if the index isn't loaded yet.
  bool containsExact(String tag, {ClientType? client}) {
    final target = client ?? AppSettings.currentClient;
    final list = _tags[target];
    if (list == null || list.isEmpty) return false;

    final q = tag.trim();
    if (q.isEmpty) return false;

    final i = _lowerBound(list, q);
    return i >= 0 && i < list.length && list[i] == q;
  }

  static int _lowerBound(List<String> sorted, String value) {
    var low = 0;
    var high = sorted.length;
    while (low < high) {
      final mid = low + ((high - low) >> 1);
      final cmp = sorted[mid].compareTo(value);
      if (cmp < 0) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }
}
