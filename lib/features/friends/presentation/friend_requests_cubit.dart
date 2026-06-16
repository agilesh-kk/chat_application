export 'friend_requests_state.dart';

import 'dart:async';

import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:chat_application/features/friends/data/friends_remote_data_sources.dart';
import 'package:chat_application/features/friends/presentation/friend_requests_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FriendRequestsCubit extends Cubit<FriendRequestsState> {
  final FriendsRemoteDataSource repository;
  StreamSubscription<Map<String, FriendModel>>? _requestSub;
  final Set<String> _sentRequestIds = {};
  final Map<String, bool> _sentStatusCache = {};

  FriendRequestsCubit(this.repository) : super(FriendRequestsInitial());

  bool hasSentRequestTo(String userId) => _sentRequestIds.contains(userId);

  Future<bool> checkSentRequestStatus(
    String currentUserId,
    String targetUserId,
  ) async {
    final cacheKey = '$currentUserId->$targetUserId';
    if (_sentStatusCache.containsKey(cacheKey)) {
      return _sentStatusCache[cacheKey]!;
    }
    try {
      final isPending = await repository.isUserInRequests(
        userId: currentUserId,
        targetUserId: targetUserId,
      );
      if (isPending) {
        _sentRequestIds.add(targetUserId);
      } else {
        _sentRequestIds.remove(targetUserId);
      }
      _sentStatusCache[cacheKey] = isPending;
      return isPending;
    } catch (e) {
      return _sentRequestIds.contains(targetUserId);
    }
  }

  Future<void> loadFriendRequests({required String userId}) async {
    emit(FriendRequestsLoading());
    try {
      final requestSub = await repository.getFriendRequests(userId);
      _requestSub?.cancel();
      _requestSub = requestSub.listen(
        (event) => emit(FriendRequestsLoaded(event)),
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
      _sentRequestIds.add(friendId);
      _sentStatusCache.remove('$userId->$friendId');
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

  Future<void> cancelFriendRequest({
    required String userId,
    required String friendId,
  }) async {
    try {
      await repository.rejectFriendReq(
        userId: friendId,
        requesterId: userId,
      );
      _sentRequestIds.remove(friendId);
      _sentStatusCache['$userId->$friendId'] = false;
      emit(FriendRequestCancelled(friendId));
    } catch (e) {
      emit(FriendRequestActionError(e.toString()));
    }
  }

  Future<void> clear() async {
    _requestSub?.cancel();
    _sentRequestIds.clear();
    _sentStatusCache.clear();
    emit(FriendRequestsInitial());
  }

  @override
  Future<void> close() {
    _requestSub?.cancel();
    return super.close();
  }
}
