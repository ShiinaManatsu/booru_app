import 'package:booru_app/models/yande/User.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:booru_app/models/rx/update_args.dart';
import 'package:booru_app/models/yande/comment.dart';
import 'dart:convert';
import 'package:booru_app/models/yande/post.dart';
import 'package:booru_app/settings/app_settings.dart';

/*  Provide base link
    Create post
    Update post
    Destroy post
    Revert tags
    *Vote post
    Artists - artists page
    *Comments
    Wiki
    Notes
    Search users
    Favorites
    black list
*/

class BooruAPI {
  /// Base http call for fetch any url
  static Future<List<Post>> _httpGet(String url) async {
    http.Response response = await http.get(url);
    List responseJson = json.decode(response.body);
    return responseJson.map((m) => Post.fromJson(m)).toList();
  }

  /// Password
  /// Get the hashed string by the given string
  static String getSha1Password(String password) {
    return sha1.convert(utf8.encode("choujin-steiner--$password--")).toString();
  }

  /// Search user
  /// Get user info by id or name
  static Future<List<User>> getUsers({int id, String name}) async {
    var url =
        "${AppSettings.currentBaseUrl}/user.json?${id == null ? "" : "id=$id"}${name == null ? "" : "name=$name"}";
    http.Response response = await http.post(url);
    List decodedJson = json.decode(response.body);
    return decodedJson.map((m) => User.fromJson(m)).toList();
  }

  /// Posts

  /// Fetch tagged posts
  static Future<List<Post>> fetchTagged(
      {@required TaggedArgs args, int limit = 50}) async {
    if (args.tags.length < 1) {
      return null;
    }

    var url =
        '${AppSettings.currentBaseUrl}/post.json?limit=${limit == (await AppSettings.postLimit).toInt() ? limit : (await AppSettings.postLimit).toInt()}&page=${args.page}&tags=${args.tags}';
    return await _httpGet(url);
  }

  /// Fetch posts
  static Future<List<Post>> fetchPosts(
      {@required PostsArgs args, int limit = 50}) async {
    var url =
        '${AppSettings.currentBaseUrl}/post.json?limit=${limit == (await AppSettings.postLimit).toInt() ? limit : (await AppSettings.postLimit).toInt()}&page=${args.page}';
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

  /// Vote
  /// Fetch post comment
  static Future<bool> votePost(
      {@required int postID, @required VoteType type}) async {
    var url =
        "${AppSettings.currentBaseUrl}/post/vote.json?${AppSettings.token}&id=$postID&score=${type.index - 1}";
    http.Response response = await http.post(url);
    Map decodedJson = json.decode(response.body);
    return decodedJson["success"];
  }

  /// Posts

  /// Comnents
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

  /// Search user
  /// Get user info by id or name
  static Future<VersionInfo> getLastestVersion() async {
    var url =
        "https://api.github.com/repos/ShiinaManatsu/booru_app/releases?per_page=1&page=1";
    Map<String, String> header = {"Accept": "application/vnd.github.v3+json"};
    http.Response response = await http.get(url, headers: header);
    List decodedJson = json.decode(response.body);
    return VersionInfo(
      publishDate: decodedJson.first["published_at"],
      tagName: decodedJson.first["tag_name"],
      url: decodedJson.first["assets"].first["browser_download_url"],
    );
  }
}

enum Period {
  None,
  Week,
  Month,
  Year,
}

///  Bad = -1,
///      None = 0,
///      Good = 1,
///     Great = 2,
///     Favorite = 3
enum VoteType { Bad, None, Good, Great, Favorite }

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

class VersionInfo {
  VersionInfo(
      {@required this.tagName, @required this.url, @required this.publishDate});

  final String tagName;
  final String url;
  final String publishDate;

  int get versionCode =>
      int.parse(tagName.split("-").first.replaceAll(".", ""));

  DateTime get publishDateTime => DateTime.parse(publishDate);
}
