import 'dart:convert';
import 'package:booru_app/extensions/shared_preferences_extension.dart';
import 'package:booru_app/models/yande/post.dart';

class Statistics {
  Statistics();

  List<StatisticsItem> statistics;

  static void append(StatisticsItem item) async {
    var s = await SharedPreferencesExtension.getTyped<String>("Statistics");
    Statistics statistics;
    if (s != null)
      statistics = Statistics.fromJson(json.decode(s));
    else
      statistics = Statistics();

    if (statistics.statistics == null)
      statistics.statistics = List<StatisticsItem>();

    statistics.statistics.add(item);

    SharedPreferencesExtension.setTyped<String>(
        "Statistics", statistics.toJsonString());
  }

  static Future<Statistics> getStatistics() async {
    var s = await SharedPreferencesExtension.getTyped<String>("Statistics");
    if (s != null) {
      return Statistics.fromJson(json.decode(s));
    } else {
      return Statistics();
    }
  }

  Statistics.fromJson(Map<String, dynamic> json) {
    if (json["statistics"] != null) {
      statistics = List<StatisticsItem>();
      json['statistics'].forEach((x) {
        statistics.add(StatisticsItem.fromJson(x));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.statistics != null) {
      data['statistics'] = this.statistics.map((v) => v.toJson()).toList();
    }
    return data;
  }

  String toJsonString() {
    return json.encode(toJson());
  }
}

class StatisticsItem {
  StatisticsItem({this.post, this.postEntry});
  final Post post;
  final String postEntry;

  StatisticsItem.fromJson(Map<String, dynamic> json)
      : post = Post.fromJson(json['post']),
        postEntry = json['postEntry'];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['post'] = this.post.toJson();
    data['postEntry'] = this.postEntry;
    return data;
  }
}

enum PostEntry { App, Link }
