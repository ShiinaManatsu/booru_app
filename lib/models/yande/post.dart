import 'package:flutter/cupertino.dart';
import 'package:yande_web/settings/app_settings.dart';

class Post {
  int id;
  String previewUrl;
  String jpegUrl;
  String fileUrl;
  String sampleUrl;
  int width;
  int height;
  String _rating;

  double _widthInPanel = 0;

  Rating get rating {
    switch (_rating) {
      case 's':
        return Rating.safe;
        break;
      case 'q':
        return Rating.questionable;
        break;
      case 'e':
        return Rating.explicit;
        break;
      default:
        return Rating.safe;
        break;
    }
  }

  // Post ratio
  double get ratio => width / height;

  // Ratio in panel
  double get preferredRatio => (width ) / (height );

  double get preferredWidth => ratio * AppSettings.fixedPostHeight;

  double get widthInPanel =>
      _widthInPanel == 0 ? preferredWidth : _widthInPanel;

  set widthInPanel(double value) => _widthInPanel = value;

  Post(this.id, this.previewUrl, this.height, this.width);

  Post.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        _rating = json['rating'],
        previewUrl = json['preview_url'],
        sampleUrl = json['sample_url'],
        jpegUrl = json['jpeg_url'],
        fileUrl = json['file_url'],
        width = json['width'],
        height = json['height'];
}

enum Rating { safe, questionable, explicit }
