import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yande_web/models/rx/update_args.dart';
import 'package:yande_web/models/yande/comment.dart';
import 'dart:convert';
import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/settings/app_settings.dart';

/*  Provide base link
    Create post
    Update post
    Destroy post
    Revert tags
    *Vote post
    Tags
    Artists - artists page
    *Comments
    Wiki
    Notes
    Search users
    Favorites
*/

class BooruAPI {
  /// Base http call for fetch any url
  Future<List<Post>> _httpGet(String url) async {
    http.Response response = await http.get(url);
    List responseJson = json.decode(response.body);
    return responseJson.map((m) => Post.fromJson(m)).toList();
  }

  /// Fetch tagged posts
  Future<List<Post>> fetchTagged(
      {@required TaggedArgs args, int limit = 50}) async {
    if (args.tags.length < 1) {
      return null;
    }

    var url =
        '${AppSettings.currentBaseUrl}/post.json?limit=$limit&page=${args.page}&tags=${args.tags}';
    return await _httpGet(url);
  }

  /// Fetch posts
  Future<List<Post>> fetchPosts(
      {@required PostsArgs args, int limit = 50}) async {
    var url =
        '${AppSettings.currentBaseUrl}/post.json?limit=$limit&page=${args.page}';
    return await _httpGet(url);
  }

  /// Fetch popular posts by recent
  Future<List<Post>> fetchPopularRecent(
      {@required PopularRecentArgs args}) async {
    var url =
        "${AppSettings.currentBaseUrl}/post/popular_recent.json?period=${periodMap[args.period]}";
    return await _httpGet(url);
  }

  /// Fetch popular posts by recent
  Future<List<Post>> fetchPopularByDay(
      {@required PopularByDayArgs args}) async {
    var url =
        "${AppSettings.currentBaseUrl}/post/popular_by_day.json?day=${args.time.day}&month=${args.time.month}&year=${args.time.year}";
    return await _httpGet(url);
  }

  /// Fetch popular posts by week
  Future<List<Post>> fetchPopularByWeek(
      {@required PopularByWeekArgs args}) async {
    var url =
        "${AppSettings.currentBaseUrl}/post/popular_by_week.json?day=${args.time.day}&month=${args.time.month}&year=${args.time.year}";
    return await _httpGet(url);
  }

  /// Fetch popular posts by month
  Future<List<Post>> fetchPopularByMonth(
      {@required PopularByMonthArgs args}) async {
    var url =
        "${AppSettings.currentBaseUrl}/post/popular_by_month.json?&month=${args.time.month}&year=${args.time.year}";
    return await _httpGet(url);
  }

  /// Fetch post comment
  static Future<List<Comment>> fetchPostsComments({int postID}) async {
    var url = "${AppSettings.currentBaseUrl}/comment.json?post_id=$postID";
    http.Response response = await http.get(url);
    List responseJson = json.decode(response.body);
    if (responseJson.length == 0) {
      List<Comment> l = new List<Comment>();
      l.add(new Comment(isEmpty: true));
      return l;
    }
    return responseJson.map((m) => Comment.fromJson(m)).toList();
  }

  // 125*125
  static String get avatorUrl {
    switch (AppSettings.currentClient) {
      case ClientType.Yande:
        return "${AppSettings.currentBaseUrl}/data/avatars/{UserID}.jpg";
        break;
      case ClientType.Konachan:
        return "${AppSettings.currentBaseUrl}/data/avatars/{UserID}.jpg";
        break;
      default:
        return null;
        break;
    }
  }
}

enum Period {
  None,
  Week,
  Month,
  Year,
}

Map<Period, String> periodMap = {
  Period.None: "1d",
  Period.Week: "1w",
  Period.Month: "1m",
  Period.Year: "1y",
};

// Enum of the type we want fetch
enum FetchType {
  Posts,
  PopularRecent,
  PopularByDay,
  PopularByWeek,
  PopularByMonth,
  Search
}

enum TagType { None, Artist, NotUsed, Copyright, Character, Circle, Faults }

Map<TagType, Color> tagToColorMap = {
  TagType.None: Color.fromARGB(255, 118, 118, 118),
  TagType.Artist: Color.fromARGB(255, 202, 80, 16),
  TagType.Character: Color.fromARGB(255, 16, 137, 62),
  TagType.Copyright: Color.fromARGB(255, 194, 57, 179),
  TagType.Circle: Color.fromARGB(255, 45, 125, 154),
  TagType.Faults: Color.fromARGB(255, 232, 17, 35),
  TagType.NotUsed: Color.fromARGB(255, 118, 118, 118),
};
