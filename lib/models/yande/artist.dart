class Artist {
  const Artist({
    required this.id,
    required this.name,
    required this.aliasId,
    required this.groupId,
    required this.urls,
  });

  final int id;
  final String name;
  final int? aliasId;
  final int? groupId;
  final List<String> urls;

  factory Artist.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final aliasId = json['alias_id'];
    final groupId = json['group_id'];
    final urls = json['urls'];

    return Artist(
      id: id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      aliasId: aliasId is int ? aliasId : int.tryParse(aliasId?.toString() ?? ''),
      groupId: groupId is int ? groupId : int.tryParse(groupId?.toString() ?? ''),
      urls: urls is List ? urls.map((e) => e.toString()).toList() : const <String>[],
    );
  }
}
