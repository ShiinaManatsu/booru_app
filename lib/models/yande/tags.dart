import 'dart:convert';
import 'dart:ui';
import 'package:booru_app/settings/app_settings.dart';
import 'package:http/http.dart' as http;

class TagDataBase {
  static int _asInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static TagType _tagTypeFrom(dynamic value) {
    final index = _asInt(value, defaultValue: 0);
    if (index < 0 || index >= TagType.values.length) return TagType.None;
    return TagType.values[index];
  }

  /// Search for tag suggestion
  static Future<List<Tag>> searchTags(String tag) async {
    var url = "${AppSettings.currentBaseUrl}/tag.json?order=count&limit=10&name_pattern=$tag";
    final uri = Uri.parse(url);
    final response = await http.get(uri, headers: AppSettings.booruHeaders());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode} from $uri');
    }
    final ct = response.headers['content-type']?.toLowerCase() ?? '';
    final trimmed = response.body.trimLeft();
    if (ct.contains('text/html') || trimmed.startsWith('<')) {
      final snippet = trimmed.length > 160 ? '${trimmed.substring(0, 160)}…' : trimmed;
      throw Exception('Site returned HTML (likely Cloudflare/anti-bot challenge) instead of JSON. snippet=${snippet.replaceAll("\n", " ")}');
    }
    List decodedjson = json.decode(response.body);
    return decodedjson.map((j) {
      var x = j as Map<dynamic, dynamic>;
      final name = x["name"]?.toString() ?? "";
      return Tag(
        content: name,
        tagType: _tagTypeFrom(x["type"]),
        count: _asInt(x["count"], defaultValue: 0),
      );
    }).toList();
  }
}

class TagEntry {
  const TagEntry({required this.id, required this.name, required this.count, required this.type, required this.ambiguous});

  final int id;
  final String name;
  final int count;
  final TagType type;
  final bool ambiguous;

  factory TagEntry.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final count = json['count'];
    final type = json['type'];
    return TagEntry(
      id: id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      count: count is int ? count : int.tryParse(count?.toString() ?? '') ?? 0,
      type: TagDataBase._tagTypeFrom(type),
      ambiguous: json['ambiguous'] == true,
    );
  }
}

class RelatedTagEntry {
  const RelatedTagEntry({required this.name, required this.count});
  final String name;
  final int count;
}

class Tag {
  final TagType tagType;
  final String content;
  final int count;
  const Tag({required this.content, required this.tagType, required this.count});
}

/// Represent a tag type
enum TagType { None, Artist, NotUsed, Copyright, Character, Circle, Faults }

const Map<TagType, Color> TagToColorMap = {
  TagType.None: Color.fromARGB(255, 118, 118, 118),
  TagType.Artist: Color.fromARGB(255, 202, 80, 16),
  TagType.Character: Color.fromARGB(255, 16, 137, 62),
  TagType.Copyright: Color.fromARGB(255, 194, 57, 179),
  TagType.Circle: Color.fromARGB(255, 45, 125, 154),
  TagType.Faults: Color.fromARGB(255, 232, 17, 35),
  TagType.NotUsed: Color.fromARGB(255, 118, 118, 118),
};
