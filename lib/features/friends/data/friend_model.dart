class FriendModel {
  final String id;
  final String name;
  final String profilePic;
  final String email;

  FriendModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profilePic
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'],
      name: json['name'],
      profilePic: json['profilePic'],
      email: json['email']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profilePic': profilePic,
      'email': email
    };
  }
}