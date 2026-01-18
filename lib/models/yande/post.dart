import 'package:booru_app/settings/app_settings.dart';
import 'package:booru_app/models/rx/task_bloc.dart';

class Post implements Downloadable {
  int id;
  String previewUrl;
  String? jpegUrl;
  String? fileUrl;
  String? sampleUrl;
  int width;
  int height;
  int? parentId;
  bool hasParent = false;
  String? _rating;
  String? tags;
  int creatorId = 0;
  bool hasChildren = false;
  int score = 0;
  String? author;
  int fileSize = 0;
  bool evaluated = false;

  /// Source url
  String? sourceUrl;

  @override
  // Get download url
  String get url => fileUrl ?? "";

  Post(this.id, this.previewUrl, this.height, this.width);

  static int _asInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static bool _asBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes') return true;
      if (v == 'false' || v == '0' || v == 'no') return false;
    }
    return defaultValue;
  }

  static String? _asStringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static String _asString(dynamic value, {String defaultValue = ''}) {
    return _asStringOrNull(value) ?? defaultValue;
  }

  Post.fromJson(Map<String, dynamic> json)
      : id = _asInt(json['id'], defaultValue: 0),
        creatorId = _asInt(json['creator_id'], defaultValue: 0),
        parentId = json['parent_id'] == null ? null : _asInt(json['parent_id'], defaultValue: 0),
        hasParent = _asBool(json['has_parent'], defaultValue: false),
        sourceUrl = _asStringOrNull(json['source']),
        score = _asInt(json['score'], defaultValue: 0),
        author = _asStringOrNull(json['author']),
        tags = _asStringOrNull(json['tags']),
        hasChildren = _asBool(json['has_children'], defaultValue: false),
        _rating = _asStringOrNull(json['rating']),
        previewUrl = _asString(json['preview_url'], defaultValue: ''),
        sampleUrl = _asStringOrNull(json['sample_url']),
        jpegUrl = _asStringOrNull(json['jpeg_url']),
        fileUrl = _asStringOrNull(json['file_url']),
        width = _asInt(json['width'], defaultValue: 0),
        height = _asInt(json['height'], defaultValue: 1),
        fileSize = _asInt(json['file_size'], defaultValue: 0);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = id;
    data['creator_id'] = creatorId;
    data['parent_id'] = parentId;
    data['has_parent'] = hasParent;
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
      case 'q':
        return Rating.questionable;
      case 'e':
        return Rating.explicit;
      default:
        return Rating.safe;
    }
  }

  // Post ratio
  double get ratio => width / height;

  // Ratio in panel
  double get preferredRatio => (width) / (height);

  double get preferredWidth => ratio * AppSettings.fixedPostHeight;

  double get widthInPanel => _widthInPanel == 0 ? preferredWidth : _widthInPanel;

  set widthInPanel(double value) => _widthInPanel = value;
}

enum Rating { safe, questionable, explicit }
