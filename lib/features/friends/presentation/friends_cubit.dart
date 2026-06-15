import 'dart:async';

import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:chat_application/features/friends/data/friends_remote_data_sources.dart';
import 'package:chat_application/features/profile/data/datasources/profile_pic_local_data_source.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'friends_state.dart';

class FriendsCubit extends Cubit<FriendsState> {
  final FriendsRemoteDataSource repository;
  final ProfilePicLocalDataSource _profilePicLocalDataSource;
  StreamSubscription<Map<String, FriendModel>>? _friendsub;
  StreamSubscription<Map<String, FriendModel>>? _requestSub;
  Timer? _onlineTimer;

  FriendsCubit(this.repository, this._profilePicLocalDataSource) : super(FriendsInitial());

  Future<void> clear() async {
    _friendsub?.cancel();
    _requestSub?.cancel();
    emit(FriendsInitial());
  }

  Future<void> loadFriends({
    required String userId,
  }) async {
    emit(FriendsLoading());
    _requestSub?.cancel();

    try {
      final friendSub = (await repository.getFriends(userId));
      _friendsub?.cancel();

      _friendsub = friendSub.listen(
        (event) {
          emit(FriendsLoaded(event));
          _cacheFriendProfilePics(event);
          _startOnlineTimer();
        },
      );
    } catch (e) {
      emit(FriendsError(e.toString()));
    }
  }

  Future<void> loadFriendRequests({
    required String userId,
  }) async {
    emit(FriendRequestsLoaded({}));
    _friendsub?.cancel();

    try {
      final requestSub = (await repository.getFriendRequests(userId));
      _requestSub?.cancel();

      _requestSub = requestSub.listen(
        (event) {
          emit(FriendRequestsLoaded(event));
        },
      );
    } catch (e) {
      emit(FriendRequestActionError(e.toString()));
    }
  }

  Future<void> sendFriendRequest({
    required String userId,
    required String friendId,
  }) async {
    try {
      await repository.sendFriendReq(userId: userId, friendId: friendId);
      emit(FriendRequestSent(friendId));
    } catch (e) {
      emit(FriendRequestActionError(e.toString()));
    }
  }

  Future<void> acceptFriendRequest({
    required String userId,
    required String requesterId,
  }) async {
    try {
      await repository.acceptFriendReq(
        userId: userId,
        requesterId: requesterId,
      );
      emit(FriendRequestActionSuccess());
    } catch (e) {
      emit(FriendRequestActionError(e.toString()));
    }
  }

  Future<void> rejectFriendRequest({
    required String userId,
    required String requesterId,
  }) async {
    try {
      await repository.rejectFriendReq(
        userId: userId,
        requesterId: requesterId,
      );
      emit(FriendRequestActionSuccess());
    } catch (e) {
      emit(FriendRequestActionError(e.toString()));
    }
  }

  Future<void> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    try {
      await repository.removeFriend(userId, friendId);
    } catch (e) {
      emit(FriendRequestActionError(e.toString()));
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
    _requestSub?.cancel();
    return super.close();
  }
}
