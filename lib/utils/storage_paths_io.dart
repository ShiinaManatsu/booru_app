import 'dart:io';

import 'package:path/path.dart' as p;
import '../settings/client_types.dart';

Future<String> defaultSavePath(ClientType client) async {
  final base = Directory.current.absolute.path;
  return p.join(base, 'BooruPhotos', client == ClientType.Konachan ? 'konachan' : 'yande');
}
