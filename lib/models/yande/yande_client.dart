import 'package:yande_web/models/interfaces/booru_api_interface.dart';
/*
  Posts
  List
  The base URL is /post.xml.

  limit How many posts you want to retrieve. There is a hard limit of 100 posts per request.
  page The page number.
  tags The tags to search for. Any tag combination that works on the web site will work here. This includes all the meta-tags.
*/

// Yande client wraping yande api
class YandeClient implements BooruClient {
  static const String baseUrl = 'https://yande.re';

  @override
  String getBaseUrl() {
    return baseUrl;
  }

  @override
  void login() {
    // TODO: implement login
  }

  @override
  void votePost(int postID) {
    // TODO: implement votePost
  }
}
