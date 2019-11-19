import 'package:http/http.dart' as http;
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
  int _page = 1;
  int _limit = 30;
  String tags="";
  String baseUrl;
  DateTime _time = DateTime.now();
  HttpClient _httpClient;

  String _posts;
  String _popularRecent;
  String _weeklyUrl;
  String _taggedPosts;

  BooruPosts() {
    baseUrl = AppSettings.currentBaseUrl;
    _httpClient = new HttpClient(url: baseUrl);
    buildUrl();
  }

  buildUrl() {
    _taggedPosts= '$baseUrl/post.json?limit=$_limit&page=$_page&tags=$tags';
    _posts = '$baseUrl/post.json?limit=$_limit&page=$_page';
    _popularRecent = '$baseUrl/post/popular_recent.json';
    _weeklyUrl =
        '$baseUrl/post/popular_by_week.json?day=${_time.day}&month=${_time.month}&year=${_time.year}';
  }

  Future<List<Post>> fetchTaggedPosts() async {
    http.Response response = await http.get(_taggedPosts);
    List responseJson = json.decode(response.body);
    return responseJson.map((m) => Post.fromJson(m)).toList();
  }

  set page(int value) {
    _page = value > 0 ? value : _page;
    buildUrl();
  }

  get page {
    return _page;
  }

  set limit(int value) {
    _limit = value > 0 ? value : _limit;
  }

  // Return a url specified by the type
  HttpClient setType(FetchType type) {
    switch (type) {
      case FetchType.Post:
        _httpClient.url = _posts;
        return _httpClient;
        break;
      case FetchType.PopularDaily:
        _httpClient.url = _popularRecent;
        return _httpClient;
        break;
      case FetchType.PopularWeekly:
        _httpClient.url = _weeklyUrl;
        return _httpClient;
        break;
      default:
        return null;
        break;
    }
  }
}

class HttpClient {
  HttpClient({this.url});
  String url;
  Future<List<Post>> fetchPosts() async {
    http.Response response = await http.get(url);
    List responseJson = json.decode(response.body);
    return responseJson.map((m) => Post.fromJson(m)).toList();
  }
}
