import '../settings/client_types.dart';
import 'storage_paths_stub.dart' if (dart.library.io) 'storage_paths_io.dart' as impl;

Future<String> defaultSavePath(ClientType client) => impl.defaultSavePath(client);
