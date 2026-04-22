import 'dart:async';

import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:chat_application/features/friends/data/friends_remote_data_sources.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'friends_state.dart';

class FriendsCubit extends Cubit<FriendsState> {
  final FriendsRemoteDataSource repository;
  StreamSubscription<List<FriendModel>>? _friendSub;

  FriendsCubit(this.repository) : super(FriendsInitial());

  /// 🔹 Fetch friends using IDs from user doc
  Future<void> loadFriends({
    required String userId,
  }) async {

    emit(FriendsLoading());

    try {
      _friendSub?.cancel();

      _friendSub = (await repository.getFriends(userId)).listen(onData);
      emit(FriendsLoaded(friends));
    } catch (e) {
      emit(FriendsError(e.toString()));
    }
  }

  /// 🔹 Refresh (no loading UI flicker)
  Future<void> refresh(List<String> friendIds) async {
    try {
      final friends = await repository.getFriendsByIds(friendIds);
      emit(FriendsLoaded(friends));
    } catch (e) {
      emit(FriendsError(e.toString()));
    }
  }

  /// 🔹 Optimistic add (optional)
  void addFriendLocal(FriendModel friend) {
    if (state is FriendsLoaded) {
      final current = List<FriendModel>.from(
        (state as FriendsLoaded).friends,
      );

      current.add(friend);
      emit(FriendsLoaded(current));
    }
  }

  /// 🔹 Optimistic remove
  void removeFriendLocal(String friendId) {
    if (state is FriendsLoaded) {
      final current = (state as FriendsLoaded)
          .friends
          .where((f) => f.id != friendId)
          .toList();

      emit(FriendsLoaded(current));
    }
  }
}