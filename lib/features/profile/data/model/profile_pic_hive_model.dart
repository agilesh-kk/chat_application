import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class ProfilePicHiveModel {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String profilePicUrl;

  @HiveField(2)
  final String localPath;

  @HiveField(3)
  final DateTime lastUpdated;

  ProfilePicHiveModel({
    required this.userId,
    required this.profilePicUrl,
    required this.localPath,
    required this.lastUpdated,
  });

  factory ProfilePicHiveModel.fromJson(Map<String, dynamic> map) {
    return ProfilePicHiveModel(
      userId: map['userId'] as String,
      profilePicUrl: map['profilePicUrl'] as String,
      localPath: map['localPath'] as String? ?? '',
      lastUpdated: DateTime.tryParse(map['lastUpdated'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'profilePicUrl': profilePicUrl,
      'localPath': localPath,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  ProfilePicHiveModel copyWith({
    String? userId,
    String? profilePicUrl,
    String? localPath,
    DateTime? lastUpdated,
  }) {
    return ProfilePicHiveModel(
      userId: userId ?? this.userId,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      localPath: localPath ?? this.localPath,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
