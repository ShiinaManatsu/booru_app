import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:yande_web/settings/app_settings.dart';
import 'package:http/http.dart' as http;

class TagDataBase {
  /// Search for tag suggestion
  static Future<List<Tag>> searchTags(String tag) async {
    var url =
        "${AppSettings.currentBaseUrl}/tag.json?order=count&limit=10&name=$tag";
    http.Response response = await http.get(url);
    List decodedjson = json.decode(response.body);
    return decodedjson.map((j) {
      var x = j as Map<dynamic, dynamic>;
      return Tag(
          content: x["name"] as String,
          tagType: TagType.values[x["type"] as int],
          count: x["count"] as int);
    }).toList();
  }
}

class Tag {
  final TagType tagType;
  final String content;
  final int count;
  Tag({@required this.content, @required this.tagType, this.count});
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