import 'package:chat_application/features/friends/data/friend_model.dart';

sealed class FriendRequestsState {}

class FriendRequestsInitial extends FriendRequestsState {}

class FriendRequestsLoading extends FriendRequestsState {}

class FriendRequestsLoaded extends FriendRequestsState {
  final Map<String, FriendModel> requests;
  FriendRequestsLoaded(this.requests);
}

class FriendRequestSent extends FriendRequestsState {
  final String friendId;
  FriendRequestSent(this.friendId);
}

class FriendRequestCancelled extends FriendRequestsState {
  final String friendId;
  FriendRequestCancelled(this.friendId);
}

class FriendRequestAccepted extends FriendRequestsState {
  final String requesterId;
  FriendRequestAccepted(this.requesterId);
}

class FriendRequestRejected extends FriendRequestsState {
  final String requesterId;
  FriendRequestRejected(this.requesterId);
}

class FriendRequestActionError extends FriendRequestsState {
  final String message;
  FriendRequestActionError(this.message);
}
