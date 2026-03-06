import 'package:chat_application/features/status/domain/entities/status.dart';

class StatusModel extends Status {
  StatusModel({
    required super.id,
    required super.userId,
    required super.imageUrl,
    required super.caption,
    required super.createdAt,
    required super.expiresAt,
    required super.userName, 
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,        
      'image_url': imageUrl,
      'caption': caption,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'name' : userName
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
  }) {
    return StatusModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      userName: userName ?? this.userName,
    );
  }
}