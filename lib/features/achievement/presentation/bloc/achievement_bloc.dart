import 'dart:async';

import 'package:chat_application/features/achievement/domain/entity/achievement.dart';
import 'package:chat_application/features/achievement/domain/usecase/collect_achievement.dart';
import 'package:chat_application/features/achievement/domain/usecase/get_achievements.dart';
import 'package:chat_application/features/achievement/domain/usecase/mark_achievement_seen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'achievement_event.dart';
part 'achievement_state.dart';

class AchievementBloc extends Bloc<AchievementEvent, AchievementState> {
  final GetAchievements getAchievements;
  final CollectAchievement collectAchievement;
  final MarkAchievementSeen markAchievementSeen;

  StreamSubscription<Achievement>? _subscription;

  AchievementBloc({
    required this.getAchievements,
    required this.collectAchievement,
    required this.markAchievementSeen,
  }) : super(AchievementInitial()) {
    on<LoadAchievements>(_onLoad);
    on<AchievementUpdated>(_onUpdated);
    on<CollectAchievementEvent>(_onCollect);
    on<MarkAchievementSeenEvent>(_onMarkSeen);
  }

  // =========================
  // LOAD STREAM
  // =========================
  Future<void> _onLoad(
    LoadAchievements event,
    Emitter<AchievementState> emit,
  ) async {
    emit(AchievementLoading());

    final result = await getAchievements(
      GetAchievementsParams(userId: event.userId),
    );

    result.fold((failure) => emit(AchievementError(failure.message)), (stream) {
      _subscription?.cancel();
      _subscription = stream.listen((data) {
        add(AchievementUpdated(data));
      });
    });
  }

  // =========================
  // HANDLE DATA UPDATE
  // =========================
  void _onUpdated(AchievementUpdated event, Emitter<AchievementState> emit) {
    final data = event.data;

    // 🚨 IMPORTANT CHANGE:
    // Always emit LOADED state
    emit(AchievementLoaded(data));
  }

  // =========================
  // COLLECT
  // =========================
  Future<void> _onCollect(
    CollectAchievementEvent event,
    Emitter<AchievementState> emit,
  ) async {
    final result = await collectAchievement(
      CollectAchievementParams(
        userId: event.userId,
        achievementId: event.achievementId,
      ),
    );

    result.fold((failure) => emit(AchievementError(failure.message)), (_) {});
  }

  //marking seen achievements
  Future<void> _onMarkSeen(
    MarkAchievementSeenEvent event,
    Emitter<AchievementState> emit,
  ) async {
    await markAchievementSeen(
      MarkAchievementSeenParams(
        userId: event.userId,
        achievementId: event.achievementId,
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
