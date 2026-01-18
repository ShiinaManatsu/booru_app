import 'dart:typed_data';

import 'package:booru_app/settings/app_settings.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:super_clipboard/super_clipboard.dart';

class ClipboardImage {
  const ClipboardImage._();

  /// Downloads [url], converts it to PNG, and writes it to the system clipboard.
  static Future<void> copyNetworkImageAsPng(String url) async {
    final uri = Uri.parse(url);
    final response = await http.get(uri, headers: AppSettings.booruHeaders());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode} when downloading image');
    }

    final bytes = response.bodyBytes;
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Unsupported image format');
    }

    final pngBytes = Uint8List.fromList(img.encodePng(decoded));

    final item = DataWriterItem();
    item.add(Formats.png(pngBytes));

    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      throw Exception('Clipboard is not available on this platform');
    }
    await clipboard.write(<DataWriterItem>[item]);
  }
}
