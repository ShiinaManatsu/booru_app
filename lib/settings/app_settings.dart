import 'package:yande_web/models/konachan/konachan_client.dart';
import 'package:yande_web/models/yande/yande_client.dart';

class AppSettings {
  static ClientType currentClient = ClientType.Yande; // Current client
  static const double fixedPostHeight = 256.0;  // The height of post in the post list

  static String get currentBaseUrl {
    switch (currentClient) {
      case ClientType.Yande:
        return YandeClient.baseUrl;
        break;
      case ClientType.Konachan:
        return KonachanClient.baseUrl;
        break;
      default:
        return null;
        break;
    }
  }
}

enum ClientType { Yande, Konachan }
