class Post {
  int id;
  String preview_url;
  String jpeg_url;
  String file_url;
  String sample_url;
  int preview_width;
  int preview_height;
  String _rating;

  Rating get rating{
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
    }
  }

  Post(this.id, this.preview_url, this.preview_height, this.preview_width);

  Post.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        _rating = json['rating'],
        preview_url = json['preview_url'],
        sample_url = json['sample_url'],
        jpeg_url = json['jpeg_url'],
        file_url = json['file_url'],
        preview_width = json['preview_width'],
        preview_height = json['preview_height'];
}

enum Rating { safe, questionable, explicit }
