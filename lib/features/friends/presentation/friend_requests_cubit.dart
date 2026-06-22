import 'dart:async';

import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:chat_application/features/friends/data/friends_remote_data_sources.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'friend_requests_state.dart';

class FriendRequestsCubit extends Cubit<FriendRequestsState> {
  final FriendsRemoteDataSource repository;
  StreamSubscription<Map<String, FriendModel>>? _requestSub;
  StreamSubscription<Set<String>>? _sentRequestSub;
  final Set<String> _sentRequestIds = {};

  FriendRequestsCubit(this.repository) : super(FriendRequestsInitial());

  bool hasSentRequestTo(String userId) => _sentRequestIds.contains(userId);

  Future<void> loadFriendRequests({required String userId}) async {
    if (_requestSub != null) return;
    emit(FriendRequestsLoading());
    try {
      final requestSub = await repository.getFriendRequests(userId);
      _requestSub = requestSub.listen(
        (event) => emit(FriendRequestsLoaded(event)),
      );
    } catch (e) {
      emit(FriendRequestActionError(e.toString()));
    }
  }

  Future<void> loadSentRequests({required String userId}) async {
    if (_sentRequestSub != null) return;
    try {
      final sentSub = await repository.getSentRequests(userId);
      _sentRequestSub = sentSub.listen((sentTargets) {
        final removed = _sentRequestIds
            .difference(sentTargets)
            .where((id) => id.isNotEmpty)
            .toSet();
        _sentRequestIds
          ..clear()
          ..addAll(sentTargets);

        for (final targetId in removed) {
          _checkSentRequestOutcome(userId, targetId);
        }
      });
    } catch (e) {
      emit(FriendRequestActionError(e.toString()));
    }
  }

  Future<void> _checkSentRequestOutcome(
    String userId,
    String targetId,
  ) async {
    try {
      final isFriend = await repository.checkIfUserIsFriend(
        userId: userId,
        targetUserId: targetId,
      );
      if (isFriend) {
        emit(FriendRequestAccepted(targetId));
      } else {
        emit(FriendRequestRejected(targetId));
      }
    } catch (_) {
      emit(FriendRequestActionError("Failed to check request status"));
    }
  }

  Future<void> sendFriendRequest({
    required String userId,
    required String friendId,
  }) async {
    try {
      await repository.sendFriendReq(userId: userId, friendId: friendId);
      _sentRequestIds.add(friendId);
      emit(FriendRequestSent(friendId));
      if (_sentRequestSub == null) {
        loadSentRequests(userId: userId);
      }
    } catch (e) {
      emit(FriendRequestActionError(e.toString()));
    }
  }

  Future<void> acceptFriendRequest({
    required String userId,
    required String requesterId,
  }) async {
    try {
      await repository.acceptFriendRequest(
        userId: userId,
        requesterId: requesterId,
      );
      emit(FriendRequestAccepted(requesterId));
    } catch (e) {
      emit(FriendRequestActionError(e.toString()));
    }
  }

  Future<void> rejectFriendRequest({
    required String userId,
    required String requesterId,
  }) async {
    try {
      await repository.rejectFriendRequest(
        userId: userId,
        requesterId: requesterId,
      );
      emit(FriendRequestRejected(requesterId));
    } catch (e) {
      emit(FriendRequestActionError(e.toString()));
    }
  }

  Future<void> cancelFriendRequest({
    required String userId,
    required String friendId,
  }) async {
    try {
      await repository.cancelFriendRequest(
        userId: userId,
        friendId: friendId,
      );
      _sentRequestIds.remove(friendId);
      emit(FriendRequestCancelled(friendId));
    } catch (e) {
      emit(FriendRequestActionError(e.toString()));
    }
  }

  Future<bool> checkSentRequestStatus(String userId, String targetId) async {
    if (_sentRequestIds.contains(targetId)) return true;
    try {
      return await repository.isUserInRequests(
        userId: targetId,
        targetUserId: userId,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> clear() async {
    _requestSub?.cancel();
    _sentRequestSub?.cancel();
    _sentRequestIds.clear();
    emit(FriendRequestsInitial());
  }

  @override
  Future<void> close() {
    _requestSub?.cancel();
    _sentRequestSub?.cancel();
    return super.close();
  }
}
