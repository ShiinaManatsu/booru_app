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
  static Future<List<Post>> _httpGet(String url) async {
    http.Response response = await http.get(url);
    List responseJson = json.decode(response.body);
    return responseJson.map((m) => Post.fromJson(m)).toList();
  }

  /// Fetch tagged posts
  static Future<List<Post>> fetchTagged(
      {@required TaggedArgs args, int limit = 50}) async {
    if (args.tags.length < 1) {
      return null;
    }

    var url =
        '${AppSettings.currentBaseUrl}/post.json?limit=${limit == AppSettings.postLimit.toInt() ? limit : AppSettings.postLimit.toInt()}&page=${args.page}&tags=${args.tags}';
    return await _httpGet(url);
  }

  /// Fetch posts
  static Future<List<Post>> fetchPosts(
      {@required PostsArgs args, int limit = 50}) async {
    var url =
        '${AppSettings.currentBaseUrl}/post.json?limit=${limit == AppSettings.postLimit.toInt() ? limit : AppSettings.postLimit.toInt()}&page=${args.page}';
    return await _httpGet(url);
  }

  /// Fetch specfic post
  static Future<List<Post>> fetchSpecficPost({@required String id}) async {
    var url = '${AppSettings.currentBaseUrl}/post.json?tags=id:$id';
    return await _httpGet(url);
  }

  /// Fetch popular posts by recent
  static Future<List<Post>> fetchPopularRecent(
      {@required PopularRecentArgs args}) async {
    var url =
        "${AppSettings.currentBaseUrl}/post/popular_recent.json?period=${periodMap[args.period]}";
    return await _httpGet(url);
  }

  /// Fetch popular posts by recent
  static Future<List<Post>> fetchPopularByDay(
      {@required PopularByDayArgs args}) async {
    var url =
        "${AppSettings.currentBaseUrl}/post/popular_by_day.json?day=${args.time.day}&month=${args.time.month}&year=${args.time.year}";
    return await _httpGet(url);
  }

  /// Fetch popular posts by week
  static Future<List<Post>> fetchPopularByWeek(
      {@required PopularByWeekArgs args}) async {
    var url =
        "${AppSettings.currentBaseUrl}/post/popular_by_week.json?day=${args.time.day}&month=${args.time.month}&year=${args.time.year}";
    return await _httpGet(url);
  }

  /// Fetch popular posts by month
  static Future<List<Post>> fetchPopularByMonth(
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
    return responseJson.map((m) => Comment.fromJson(m)).toList();
  }

  /// Leave comment
  static Future<bool> leaveComment(
      {@required int postID,
      @required String content,
      bool anonymous = false}) async {
    var url =
        "${AppSettings.currentBaseUrl}/comment/create.json?comment[post_id]=$postID&comment[body]=$content&${AppSettings.token}";
    http.Response response = await http.get(url);
    List decodedJson = json.decode(response.body);
    return decodedJson.map((f) {
      return (f as Map<dynamic, dynamic>)["success"] as bool;
    }).first;
  }

  /* Incoming feature
  https://yande.re/comment/create.json?comment[post_id]=605753&comment[body]="hso"&$token
  */

  // 125*125
  static String get avatarUrl {
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

  static String avatarUrlFromID(int id) =>
      "${AppSettings.currentBaseUrl}/data/avatars/${id.toString()}.jpg";
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
