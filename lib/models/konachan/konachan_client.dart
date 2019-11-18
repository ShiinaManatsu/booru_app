import 'package:yande_web/models/interfaces/booru_api_interface.dart';

class KonachanClient implements BooruClient{
  static const String baseUrl = 'https://konachan.com';

  @override
  void login() {
    // TODO: implement login
  }

  @override
  void votePost(int postID) {
    // TODO: implement votePost
  }

  @override
  String getBaseUrl() {
    return baseUrl;
  }
  
}