import 'package:chat_application/features/status/domain/entities/status.dart';

class StatusModel extends Status {
  List<String> viewedBy;

  StatusModel({
    required super.id,
    required super.userId,
    required super.imageUrl,
    required super.caption,
    required super.createdAt,
    required super.expiresAt,
    required super.userName, 
    required super.profilepic,
    required super.likedBy,
    required this.viewedBy,
  }) : super(isViewed: false);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,        
      'image_url': imageUrl,
      'caption': caption,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'name' : userName,
      'profilepic' : profilepic,
      'liked_by' : likedBy,
      'viewed_by' : viewedBy,
    };
  }

  factory StatusModel.fromJson(Map<String, dynamic> map) {
    return StatusModel(
      id: map['id'],
      userId: map['user_id'],
      imageUrl: map['image_url'],
      caption: map['caption'],
      createdAt: DateTime.parse(map['created_at']),
      expiresAt: DateTime.parse(map['expires_at']),
      userName: map['name'] ?? "",
      profilepic: map['profilepic'] ?? "",
      likedBy: map['liked_by'] == null
        ? []
        : List<String>.from(map['liked_by']),
      viewedBy: map['viewed_by'] == null
        ? []
        : List<String>.from(map['viewed_by']),
    );
  }

  StatusModel copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? caption,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? userName,
    String? profilepic,
    List<String>? likedBy,
    List<String>? viewedBy,
  }) {
    return StatusModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      userName: userName ?? this.userName,
      profilepic: profilepic ?? this.profilepic,
      likedBy: likedBy ?? this.likedBy,
      viewedBy: viewedBy ?? this.viewedBy,
    );
  }
}
