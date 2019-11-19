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
  String baseUrl;
  DateTime _time = DateTime.now();
  HttpClient _httpClient;

  String _homeUrl;
  String _dailyUrl;
  String _weeklyUrl;

  BooruPosts() {
    baseUrl = AppSettings.currentBaseUrl;
    _httpClient = new HttpClient(url: baseUrl);
    buildUrl();
  }

  buildUrl() {
    _homeUrl = '$baseUrl/post.json?limit=$_limit&page=$_page';
    _dailyUrl = '$baseUrl/post/popular_recent.json';
    _weeklyUrl =
        '$baseUrl/post/popular_by_week.json?day=${_time.day}&month=${_time.month}&year=${_time.year}';
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
      case FetchType.Home:
        _httpClient.url = _homeUrl;
        return _httpClient;
        break;
      case FetchType.Daily:
        _httpClient.url = _dailyUrl;
        return _httpClient;
        break;
      case FetchType.Weekly:
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

  Future<List<Post>> urlFetchPosts(String url) async {
    http.Response response = await http.get(url);
    List responseJson = json.decode(response.body);
    return responseJson.map((m) => Post.fromJson(m)).toList();
  }
}
