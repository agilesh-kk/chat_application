import 'dart:async';

import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:chat_application/features/friends/data/friends_remote_data_sources.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'friends_state.dart';

class FriendsCubit extends Cubit<FriendsState> {
  final FriendsRemoteDataSource repository;
  StreamSubscription<Map<String,FriendModel>>? _friendsub;

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
      },);

    } catch (e) {
      emit(FriendsError(e.toString()));
    }
  }
}