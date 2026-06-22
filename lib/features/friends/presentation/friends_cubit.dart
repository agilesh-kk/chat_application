import 'dart:async';

import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:chat_application/features/friends/data/friends_remote_data_sources.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'friends_state.dart';

class FriendsCubit extends Cubit<FriendsState> {
  final FriendsRemoteDataSource repository;
  StreamSubscription<Map<String,FriendModel>>? _friendsub;
  Timer? _onlineTimer;

  FriendsCubit(this.repository) : super(FriendsInitial());

  /// 🔹 Fetch friends using IDs from user doc
  Future<void> loadFriends({
    required String userId,
  }) async {

    emit(FriendsLoading());

    try {

      final friendSub = (await repository.getFriends(userId));
      _friendsub?.cancel();

      _friendsub = friendSub.listen(
        (event) {
          emit(FriendsLoaded(event));
          _startOnlineTimer();
      },);

    } catch (e) {
      emit(FriendsError(e.toString()));
    }
  }

  void _startOnlineTimer() {
    _onlineTimer?.cancel();
    _onlineTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _reEvaluateOnline(),
    );
  }

  void _reEvaluateOnline() {
    if (state is FriendsLoaded) {
      emit(FriendsLoaded((state as FriendsLoaded).friends));
    }
  }

  Future<void> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    try {
      await repository.removeFriend(userId, friendId);
    } catch (e) {
      emit(FriendsError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _onlineTimer?.cancel();
    _friendsub?.cancel();
    return super.close();
  }
}