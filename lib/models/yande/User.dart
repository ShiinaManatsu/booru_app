class User {
  String? name;
  List<dynamic>? blacklistedTags;
  int? id;

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        blacklistedTags = json['blacklisted_tags'];
}
