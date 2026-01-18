import 'package:booru_app/models/yande/post.dart';

class Pool {
  const Pool({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.isPublic,
    required this.postCount,
    required this.description,
    this.posts,
  });

  final int id;
  final String name;
  final String? createdAt;
  final String? updatedAt;
  final int? userId;
  final bool isPublic;
  final int postCount;
  final String? description;
  final List<Post>? posts;

  factory Pool.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final userId = json['user_id'];
    final postCount = json['post_count'];
    final postsJson = json['posts'];

    return Pool(
      id: id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      userId: userId is int ? userId : int.tryParse(userId?.toString() ?? ''),
      isPublic: json['is_public'] == true,
      postCount: postCount is int ? postCount : int.tryParse(postCount?.toString() ?? '') ?? 0,
      description: json['description']?.toString(),
      posts: postsJson is List ? postsJson.map((m) => Post.fromJson(Map<String, dynamic>.from(m as Map))).toList() : null,
    );
  }
}
