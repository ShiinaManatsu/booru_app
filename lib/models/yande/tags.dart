import 'dart:convert';

import 'package:yande_web/settings/app_settings.dart';
import 'package:http/http.dart' as http;

/// Represent a tag type
enum TagType { None, Artist, NotUsed, Copyright, Character, Circle, Faults }

class TagDataBase{

  /// Search for tag suggestion
  Future<List<String>> searchTags(String tag)async{
    var url="${AppSettings.currentBaseUrl}/tag.json?order=count&limit=10&name=$tag";
    http.Response response = await http.get(url);
    List decodedjson=json.decode(response.body);
    return decodedjson.map((j){
      var x=j as Map<String,dynamic>;
      return x["name"] as String;
    }).toList();
  }
}