import 'package:booru_app/settings/app_settings.dart';
import 'package:booru_app/models/rx/task_bloc.dart';

class Post implements Downloadable {
  int id;
  String previewUrl;
  String jpegUrl;
  String fileUrl;
  String sampleUrl;
  int width;
  int height;
  String _rating;
  String tags;
  int creatorId;
  bool hasChildren;
  int score;
  String author;
  int fileSize;

  /// Source url
  String sourceUrl;

  @override
  // Get download url
  String get url => fileUrl;

  Post(this.id, this.previewUrl, this.height, this.width);

  Post.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        creatorId = json['creator_id'],
        sourceUrl = json['source'],
        score = json['score'],
        author = json['author'],
        tags = json['tags'],
        hasChildren = json['has_children'],
        _rating = json['rating'],
        previewUrl = json['preview_url'],
        sampleUrl = json['sample_url'],
        jpegUrl = json['jpeg_url'],
        fileUrl = json['file_url'],
        width = json['width'],
        height = json['height'],
        fileSize = json['file_size'];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = id;
    data['creator_id'] = creatorId;
    data['source'] = sourceUrl;
    data['score'] = score;
    data['author'] = author;
    data['tags'] = tags;
    data['has_children'] = hasChildren;
    data['rating'] = _rating;
    data['preview_url'] = previewUrl;
    data['sample_url'] = sampleUrl;
    data['jpeg_url'] = jpegUrl;
    data['file_url'] = fileUrl;
    data['width'] = width;
    data['height'] = height;
    data['file_size'] = fileSize;
    return data;
  }

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
  double get preferredRatio => (width) / (height);

  double get preferredWidth => ratio * AppSettings.fixedPostHeight;

  double get widthInPanel =>
      _widthInPanel == 0 ? preferredWidth : _widthInPanel;

  set widthInPanel(double value) => _widthInPanel = value;
}

enum Rating { safe, questionable, explicit }
