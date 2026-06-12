import 'dart:async';

import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:chat_application/features/friends/data/friends_remote_data_sources.dart';
import 'package:chat_application/features/profile/data/datasources/profile_pic_local_data_source.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'friends_state.dart';

class FriendsCubit extends Cubit<FriendsState> {
  final FriendsRemoteDataSource repository;
  final ProfilePicLocalDataSource _profilePicLocalDataSource;
  StreamSubscription<Map<String,FriendModel>>? _friendsub;
  Timer? _onlineTimer;

  FriendsCubit(this.repository, this._profilePicLocalDataSource) : super(FriendsInitial());

  Future<void> clear()async{
    _friendsub?.cancel();
    emit(FriendsInitial());
  }

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
          _cacheFriendProfilePics(event);
          _startOnlineTimer();
      },);

    } catch (e) {
      emit(FriendsError(e.toString()));
    }
  }

  Future<void> _cacheFriendProfilePics(Map<String, FriendModel> friends) async {
    await _profilePicLocalDataSource.cacheFriendsProfilePics(friends);
    await _profilePicLocalDataSource.clearCacheForRemovedFriends(friends.keys.toSet());
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

  @override
  Future<void> close() {
    _onlineTimer?.cancel();
    _friendsub?.cancel();
    return super.close();
  }
}