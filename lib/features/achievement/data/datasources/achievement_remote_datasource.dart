import 'package:chat_application/features/achievement/data/model/achievement_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class AchievementRemoteDatasource {
  Stream<AchievementModel> getAchievements(String userId);

  Future<void> collectAchievement({
    required String userId,
    required String achievementId,
  });

  Future<void> markAchievementSeen({
    required String userId,
    required String achievementId,
  });
}

class AchievementRemoteDatasourceImpl implements AchievementRemoteDatasource{
  final FirebaseFirestore firestore;

  AchievementRemoteDatasourceImpl({required this.firestore});

  @override
  Stream<AchievementModel> getAchievements(String userId) {
    return firestore
        .collection("users")
        .doc(userId)
        .collection("achievement")
        .doc("stats")
        .snapshots()
        .map((doc) {
      final data = doc.data() ?? {};
      return AchievementModel.fromMap(data);
    });
  }

  @override
  Future<void> collectAchievement({
    required String userId,
    required String achievementId,
  }) async {
    await firestore
        .collection("users")
        .doc(userId)
        .collection("achievement")
        .doc("stats")
        .update({
      "collected": FieldValue.arrayUnion([achievementId]),
    });
  }

  @override
  Future<void> markAchievementSeen({
    required String userId,
    required String achievementId,
  }) async {
    await firestore
        .collection("users")
        .doc(userId)
        .collection("achievement")
        .doc("stats")
        .update({
      "seen": FieldValue.arrayUnion([achievementId]),
    });
  }
}