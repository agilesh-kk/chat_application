part of 'achievement_bloc.dart';

sealed class AchievementState {
  const AchievementState();
}

final class AchievementInitial extends AchievementState {}

class AchievementLoading extends AchievementState {}

class AchievementLoaded extends AchievementState {
  final Achievement data;
  AchievementLoaded(this.data);
}

class AchievementUnlocked extends AchievementState {
  final String achievementId;
  AchievementUnlocked(this.achievementId);
}

class AchievementError extends AchievementState {
  final String message;
  AchievementError(this.message);
}