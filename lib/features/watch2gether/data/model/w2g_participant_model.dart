import 'package:chat_application/features/watch2gether/domain/entity/w2g_participant.dart';

class W2GParticipantModel extends W2GParticipant {
  W2GParticipantModel({
    required super.userId,
    required super.name,
    required super.profilePic,
    required super.joinedAt,
  });

  factory W2GParticipantModel.fromMap(
      String userId, Map<String, dynamic> map) {
    return W2GParticipantModel(
      userId: userId,
      name: map['name'] as String? ?? '',
      profilePic: map['profilePic'] as String? ?? '',
      joinedAt: map['joinedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['joinedAt'] as num).toInt())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'profilePic': profilePic,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
    };
  }
}
