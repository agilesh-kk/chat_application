import 'package:hive/hive.dart';
import '../../domain/entities/status.dart';

@HiveType(typeId: 1)
class StatusHiveModel{

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String imageUrl;

  @HiveField(3)
  final String caption;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime expiresAt;

  @HiveField(6)
  final String userName;

  @HiveField(7)
  final String localPath;

  @HiveField(8)
  final String profilepic;

  @HiveField(9)
  final List<String> likedBy;

  @HiveField(10)
  final bool isViewed;

  StatusHiveModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
    required this.expiresAt,
    required this.userName,
    required this.localPath,
    required this.profilepic,
    required this.likedBy,
    required this.isViewed,
  });

  factory StatusHiveModel.fromJson(Map<String, dynamic> map) {
    return StatusHiveModel(
      id: map['id'],
      userId: map['user_id'],
      imageUrl: map['image_url'],
      caption: map['caption'],
      createdAt: DateTime.parse(map['created_at']),
      expiresAt: DateTime.parse(map['expires_at']),
      userName: map['name'] ?? "",
      localPath: map['localpath'] ?? "",
      profilepic: map['profilepic'] ?? "",
      likedBy: List<String>.from(map['liked_by'] ?? []),
      isViewed: map['is_viewed'] as bool? ?? false,
    );
  }

  Status toEntity() {
    return Status(
      id: id,
      userId: userId,
      imageUrl: imageUrl,
      caption: caption,
      createdAt: createdAt,
      expiresAt: expiresAt,
      userName: userName,
      localPath: localPath,
      profilepic: profilepic,
      likedBy: likedBy,
      isViewed: isViewed,
    );
  }

  factory StatusHiveModel.fromEntity(Status status) {
    return StatusHiveModel(
      id: status.id,
      userId: status.userId,
      imageUrl: status.imageUrl,
      caption: status.caption,
      createdAt: status.createdAt,
      expiresAt: status.expiresAt,
      userName: status.userName,
      localPath: status.localPath ?? "Not Loaded",
      profilepic: status.profilepic,
      likedBy: status.likedBy,
      isViewed: status.isViewed,
    );
  }

  StatusHiveModel copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? caption,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? userName,
    String? localPath,
    String? profilepic,
    List<String>? likedBy,
    bool? isViewed,
  }) {
    return StatusHiveModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      userName: userName ?? this.userName,
      localPath: localPath ?? this.localPath,
      profilepic: profilepic ?? this.profilepic,
      likedBy: likedBy ?? this.likedBy,
      isViewed: isViewed ?? this.isViewed,
    );
  }

}