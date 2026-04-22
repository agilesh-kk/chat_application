class FriendModel {
  final String id;
  final String name;
  final String? avatar;

  FriendModel({
    required this.id,
    required this.name,
    this.avatar,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
    };
  }
}