class Comment {
  bool isEmpty=false;

  Comment({this.isEmpty});

  int id;
  int postId;
  int creatorId;
  String creator;

  /// Create time
  String createdAt;
  String body;

  Comment.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        postId = json['post_id'],
        creator = json['creator'],
        creatorId = json['creator_id'],
        createdAt = json['created_at'],
        body = json['body'],
        isEmpty=false;
}
