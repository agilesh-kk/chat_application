part of 'achievement_bloc.dart';

sealed class AchievementEvent{
  const AchievementEvent();
}

class LoadAchievements extends AchievementEvent {
  final String userId;
  LoadAchievements(this.userId);
}

class AchievementUpdated extends AchievementEvent {
  final Achievement data;
  AchievementUpdated(this.data);
}

class CollectAchievementEvent extends AchievementEvent {
  final String achievementId;
  final String userId;
  CollectAchievementEvent(this.achievementId, this.userId);
}

class MarkAchievementSeenEvent extends AchievementEvent {
  final String userId;
  final String achievementId;

  MarkAchievementSeenEvent({
    required this.userId,
    required this.achievementId,
  });
}