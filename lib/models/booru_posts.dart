import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:yande_web/models/yande/comment.dart';
import 'dart:convert';
import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/settings/app_settings.dart';

/*  Provide base link
    List posts
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

class BooruPosts {
  /// Base http call for fetch any url
  Future<List<Post>> _httpGet(String url) async {
    http.Response response = await http.get(url);
    List responseJson = json.decode(response.body);
    return responseJson.map((m) => Post.fromJson(m)).toList();
  }

  /// Fetch tagged posts
  Future<List<Post>> fetchTagsSearch(
      {@required String tags, int limit = 50, int page = 1}) async {
    if (tags.length < 1) {
      return null;
    }

    var url =
        '${AppSettings.currentBaseUrl}/post.json?limit=$limit&page=$page&tags=$tags';
    return await _httpGet(url);
  }

  /// Fetch posts
  Future<List<Post>> fetchPosts({int limit = 50, int page = 1}) async {
    var url = '${AppSettings.currentBaseUrl}/post.json?limit=$limit&page=$page';
    return await _httpGet(url);
  }

  /// Fetch popular posts by recent
  Future<List<Post>> fetchPopularRecent({Period period = Period.None}) async {
    var url =
        "${AppSettings.currentBaseUrl}/post/popular_recent.json?period=$period";
    return await _httpGet(url);
  }

  /// Fetch popular posts by week
  Future<List<Post>> fetchPopularByWeek({int day, int month, int year}) async {
    var url =
        "${AppSettings.currentBaseUrl}/post/popular_by_week.json?day=$day&month=$month&year=$year";
    return await _httpGet(url);
  }

  /// Fetch popular posts by month
  Future<List<Post>> fetchPopularByMonth({int month, int year}) async {
    var url =
        "${AppSettings.currentBaseUrl}/post/popular_by_month.json?&month=$month&year=$year";
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
}

enum Period {
  None,
  Week,
  Month,
  Year,
}

// Enum of the type we want fetch
enum FetchType { Posts, PopularRecent, PopularByWeek, PopularByMonth, Search }
