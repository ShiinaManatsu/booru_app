import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:booru_app/models/rx/update_args.dart';
import 'dart:convert';
import 'package:booru_app/models/yande/post.dart';
import 'package:booru_app/models/yande/pool.dart';
import 'package:booru_app/models/yande/tags.dart';
import 'package:booru_app/models/yande/artist.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

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
  static void _throwIfHtmlResponse(http.Response response, Uri uri) {
    final ct = response.headers['content-type']?.toLowerCase() ?? '';
    final body = response.body;
    final trimmed = body.trimLeft();

    final looksHtml = ct.contains('text/html') || trimmed.startsWith('<!doctype') || trimmed.startsWith('<html') || trimmed.startsWith('<');
    if (!looksHtml) return;

    final snippet = trimmed.length > 160 ? '${trimmed.substring(0, 160)}…' : trimmed;
    throw Exception(
      'Site returned HTML (likely Cloudflare/anti-bot challenge) instead of JSON. '
      'url=$uri status=${response.statusCode} snippet=${snippet.replaceAll("\n", " ")}',
    );
  }

  static void _throwIfBadStatus(http.Response response, Uri uri) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final body = response.body.trimLeft();
    final snippet = body.length > 160 ? '${body.substring(0, 160)}…' : body;
    throw Exception('HTTP ${response.statusCode} from $uri: ${snippet.replaceAll("\n", " ")}');
  }

  /// Base http call for fetch any url
  static Future<List<Post>> _httpGet(String url) async {
    if (kDebugMode) {
      debugPrint('[BooruAPI] GET $url');
    }
    final uri = Uri.parse(url);
    final response = await http.get(uri, headers: AppSettings.booruHeaders());
    _throwIfBadStatus(response, uri);
    _throwIfHtmlResponse(response, uri);
    final responseJson = json.decode(response.body) as List;
    return responseJson.map((m) => Post.fromJson(Map<String, dynamic>.from(m as Map))).toList();
  }

  static Future<Map<String, dynamic>> _httpGetObject(String url) async {
    if (kDebugMode) {
      debugPrint('[BooruAPI] GET $url');
    }
    final uri = Uri.parse(url);
    final response = await http.get(uri, headers: AppSettings.booruHeaders());
    _throwIfBadStatus(response, uri);
    _throwIfHtmlResponse(response, uri);
    final decoded = json.decode(response.body);
    return Map<String, dynamic>.from(decoded as Map);
  }

  /// Password
  /// Get the hashed string by the given string
  static String getSha1Password(String password) {
    return sha1.convert(utf8.encode("choujin-steiner--$password--")).toString();
  }

  /// Posts

  /// Fetch tagged posts
  static Future<List<Post>> fetchTagged({required TaggedArgs args, int limit = 50}) async {
    if (args.tags.length < 1) {
      return <Post>[];
    }

    var url =
        '${AppSettings.currentBaseUrl}/post.json?limit=${limit == (await AppSettings.postLimit).toInt() ? limit : (await AppSettings.postLimit).toInt()}&page=${args.page}&tags=${args.tags}';
    return await _httpGet(url);
  }

  /// Fetch posts
  static Future<List<Post>> fetchPosts({required PostsArgs args, int limit = 50}) async {
    var url =
        '${AppSettings.currentBaseUrl}/post.json?limit=${limit == (await AppSettings.postLimit).toInt() ? limit : (await AppSettings.postLimit).toInt()}&page=${args.page}';
    return await _httpGet(url);
  }

  /// Fetch specfic post
  static Future<List<Post>> fetchSpecficPost({required String id}) async {
    var url = '${AppSettings.currentBaseUrl}/post.json?tags=id:$id';
    return await _httpGet(url);
  }

  /// Fetch a single post by id.
  ///
  /// Uses the JSON endpoint which is confirmed to work on yande/konachan:
  /// `/post.json?tags=id:<id>`
  static Future<Post> fetchPostById({required int id}) async {
    final list = await fetchSpecficPost(id: id.toString());
    if (list.isEmpty) {
      throw Exception('Post not found: id=$id');
    }
    return list.first;
  }

  /// Update a post (or fetch post data by id).
  ///
  /// Endpoint: /post/update.xml
  ///
  /// Notes:
  /// - Only [id] is required; passing only [id] can be used to retrieve post info.
  /// - Other parameters are optional; omit them if you don't want to change them.
  /// - Authentication may be required by the server for updates.
  static Future<Post> updatePost({
    required int id,
    String? tags,
    Rating? rating,
    String? source,
    bool? isRatingLocked,
    bool? isNoteLocked,
    int? parentId,
  }) async {
    // If the caller only wants to query post info, prefer the JSON endpoint.
    // Some servers return 404 for /post/update.xml.
    final wantsUpdate = tags != null || rating != null || source != null || isRatingLocked != null || isNoteLocked != null || parentId != null;
    if (!wantsUpdate) {
      return fetchPostById(id: id);
    }

    final url = '${AppSettings.currentBaseUrl}/post/update.xml?${AppSettings.token}&id=$id';

    final body = <String, String>{
      if (tags != null) 'post[tags]': tags,
      if (rating != null) 'post[rating]': rating.name,
      if (source != null) 'post[source]': source,
      if (isRatingLocked != null) 'post[is_rating_locked]': isRatingLocked ? 'true' : 'false',
      if (isNoteLocked != null) 'post[is_note_locked]': isNoteLocked ? 'true' : 'false',
      if (parentId != null) 'post[parent_id]': '$parentId',
    };

    if (kDebugMode) {
      debugPrint('[BooruAPI] POST $url');
    }

    final uri = Uri.parse(url);
    final response = await http.post(uri, headers: AppSettings.booruHeaders(), body: body);
    _throwIfBadStatus(response, uri);
    _throwIfHtmlResponse(response, uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update post (HTTP ${response.statusCode}). This server may not support /post/update.xml.');
    }

    // The API returns XML; parse the first <post .../> element.
    final doc = XmlDocument.parse(response.body);
    final postEl = doc.findAllElements('post').first;
    final attrs = <String, dynamic>{
      for (final a in postEl.attributes) a.name.local: a.value,
    };
    return Post.fromJson(attrs);
  }

  /// Fetch popular posts by recent
  static Future<List<Post>> fetchPopularRecent({required PopularRecentArgs args}) async {
    var url = "${AppSettings.currentBaseUrl}/post/popular_recent.json?period=${periodMap[args.period]}";
    return await _httpGet(url);
  }

  /// Fetch popular posts by recent
  static Future<List<Post>> fetchPopularByDay({required PopularByDayArgs args}) async {
    var url = "${AppSettings.currentBaseUrl}/post/popular_by_day.json?day=${args.time.day}&month=${args.time.month}&year=${args.time.year}";
    return await _httpGet(url);
  }

  /// Fetch popular posts by week
  static Future<List<Post>> fetchPopularByWeek({required PopularByWeekArgs args}) async {
    var url = "${AppSettings.currentBaseUrl}/post/popular_by_week.json?day=${args.time.day}&month=${args.time.month}&year=${args.time.year}";
    return await _httpGet(url);
  }

  /// Fetch popular posts by month
  static Future<List<Post>> fetchPopularByMonth({required PopularByMonthArgs args}) async {
    var url = "${AppSettings.currentBaseUrl}/post/popular_by_month.json?&month=${args.time.month}&year=${args.time.year}";
    return await _httpGet(url);
  }

  /// Vote
  static Future<bool> votePost({required int postID, required VoteType type}) async {
    var url = "${AppSettings.currentBaseUrl}/post/vote.json?${AppSettings.token}&id=$postID&score=${type.index - 1}";
    final uri = Uri.parse(url);
    final response = await http.post(uri, headers: AppSettings.booruHeaders());
    _throwIfBadStatus(response, uri);
    _throwIfHtmlResponse(response, uri);
    Map decodedJson = json.decode(response.body);
    return decodedJson["success"];
  }

  /// Tags

  /// Fetch tags list (search/suggest).
  ///
  /// Docs: /tag.json
  static Future<List<TagEntry>> fetchTags({
    int? limit,
    int? page,
    TagOrder? order,
    int? id,
    int? afterId,
    String? name,
    String? namePattern,
  }) async {
    final uri = Uri.parse(AppSettings.currentBaseUrl).resolve('/tag.json').replace(
      queryParameters: <String, String>{
        if (limit != null) 'limit': '$limit',
        if (page != null) 'page': '$page',
        if (order != null) 'order': order.name,
        if (id != null) 'id': '$id',
        if (afterId != null) 'after_id': '$afterId',
        if (name != null && name.isNotEmpty) 'name': name,
        if (namePattern != null && namePattern.isNotEmpty) 'name_pattern': namePattern,
      },
    );

    if (kDebugMode) {
      debugPrint('[BooruAPI] GET $uri');
    }
    final response = await http.get(uri, headers: AppSettings.booruHeaders());
    _throwIfBadStatus(response, uri);
    _throwIfHtmlResponse(response, uri);
    final decoded = json.decode(response.body) as List;
    return decoded.map((m) => TagEntry.fromJson(Map<String, dynamic>.from(m as Map))).toList();
  }

  /// Fetch related tags.
  ///
  /// Docs: /tag/related.json (returns map: inputTag -> [[name, count], ...]).
  static Future<Map<String, List<RelatedTagEntry>>> fetchRelatedTags({required String tags, TagRelatedType? type}) async {
    final uri = Uri.parse(AppSettings.currentBaseUrl).resolve('/tag/related.json').replace(
      queryParameters: <String, String>{
        'tags': tags,
        if (type != null) 'type': type.name,
      },
    );

    if (kDebugMode) {
      debugPrint('[BooruAPI] GET $uri');
    }
    final response = await http.get(uri, headers: AppSettings.booruHeaders());
    _throwIfBadStatus(response, uri);
    _throwIfHtmlResponse(response, uri);
    final decoded = json.decode(response.body);
    final obj = Map<String, dynamic>.from(decoded as Map);
    return obj.map((key, value) {
      final list = (value as List).cast<List>();
      final entries = list.map((pair) {
        final name = pair.isNotEmpty ? pair[0].toString() : '';
        final count = pair.length > 1 ? int.tryParse(pair[1].toString()) ?? 0 : 0;
        return RelatedTagEntry(name: name, count: count);
      }).toList();
      return MapEntry(key, entries);
    });
  }

  /// Artists (read-only)

  /// Docs: /artist.json
  static Future<List<Artist>> fetchArtists({String? name, ArtistOrder? order, int? page}) async {
    final uri = Uri.parse(AppSettings.currentBaseUrl).resolve('/artist.json').replace(
      queryParameters: <String, String>{
        if (name != null && name.isNotEmpty) 'name': name,
        if (order != null) 'order': order.name,
        if (page != null) 'page': '$page',
      },
    );

    if (kDebugMode) {
      debugPrint('[BooruAPI] GET $uri');
    }
    final response = await http.get(uri, headers: AppSettings.booruHeaders());
    _throwIfBadStatus(response, uri);
    _throwIfHtmlResponse(response, uri);
    final decoded = json.decode(response.body) as List;
    return decoded.map((m) => Artist.fromJson(Map<String, dynamic>.from(m as Map))).toList();
  }

  /// Pools (read-only)

  /// Docs: /pool.json
  static Future<List<Pool>> fetchPools({String? query, int? page}) async {
    final uri = Uri.parse(AppSettings.currentBaseUrl).resolve('/pool.json').replace(
      queryParameters: <String, String>{
        if (query != null && query.isNotEmpty) 'query': query,
        if (page != null) 'page': '$page',
      },
    );
    if (kDebugMode) {
      debugPrint('[BooruAPI] GET $uri');
    }
    final response = await http.get(uri, headers: AppSettings.booruHeaders());
    _throwIfBadStatus(response, uri);
    _throwIfHtmlResponse(response, uri);
    final decoded = json.decode(response.body) as List;
    return decoded.map((m) => Pool.fromJson(Map<String, dynamic>.from(m as Map))).toList();
  }

  /// Docs: /pool/show.json
  static Future<Pool> fetchPoolShow({required int id, int? page}) async {
    final uri = Uri.parse(AppSettings.currentBaseUrl).resolve('/pool/show.json').replace(
      queryParameters: <String, String>{
        'id': '$id',
        if (page != null) 'page': '$page',
      },
    );
    final obj = await _httpGetObject(uri.toString());
    return Pool.fromJson(obj);
  }

  /// Convenience: fetch just the posts in a pool page.
  static Future<List<Post>> fetchPoolPosts({required int id, required int page}) async {
    final pool = await fetchPoolShow(id: id, page: page);
    return pool.posts ?? <Post>[];
  }

  // 125*125
  static String get avatarUrl {
    switch (AppSettings.currentClient) {
      case ClientType.Yande:
        return "${AppSettings.currentBaseUrl}/data/avatars/{UserID}.jpg";
      case ClientType.Konachan:
        return "${AppSettings.currentBaseUrl}/data/avatars/{UserID}.jpg";
    }
  }

  static String avatarUrlFromID(int id) => "${AppSettings.currentBaseUrl}/data/avatars/${id.toString()}.jpg";

  /// Search user
  /// Get user info by id or name
  static Future<VersionInfo> getLastestVersion() async {
    var url = "https://api.github.com/repos/ShiinaManatsu/booru_app/releases?per_page=1&page=1";
    Map<String, String> header = {"Accept": "application/vnd.github.v3+json"};
    http.Response response = await http.get(Uri.parse(url), headers: header);
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

enum TagOrder { date, count, name }

enum TagRelatedType { general, artist, copyright, character }

enum ArtistOrder { date, name }

Map<Period, String> periodMap = {
  Period.None: "1d",
  Period.Week: "1w",
  Period.Month: "1m",
  Period.Year: "1y",
};

// Enum of the type we want fetch
enum FetchType { Posts, PopularRecent, PopularByDay, PopularByWeek, PopularByMonth, Search, Pool }

class VersionInfo {
  const VersionInfo({required this.tagName, required this.url, required this.publishDate});

  final String tagName;
  final String url;
  final String publishDate;

  int get versionCode => int.parse(tagName.split("-").first.replaceAll(".", ""));

  DateTime get publishDateTime => DateTime.parse(publishDate);
}
