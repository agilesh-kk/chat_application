part of 'friend_requests_cubit.dart';

abstract class FriendRequestsState {}

class FriendRequestsInitial extends FriendRequestsState {}

class FriendRequestsLoading extends FriendRequestsState {}

class FriendRequestsLoaded extends FriendRequestsState {
  final Map<String, FriendModel> requests;
  FriendRequestsLoaded(this.requests);
}

class FriendRequestSent extends FriendRequestsState {
  final String userId;
  FriendRequestSent(this.userId);
}

class FriendRequestAccepted extends FriendRequestsState {
  final String userId;
  FriendRequestAccepted(this.userId);
}

class FriendRequestRejected extends FriendRequestsState {
  final String userId;
  FriendRequestRejected(this.userId);
}

class FriendRequestCancelled extends FriendRequestsState {
  final String userId;
  FriendRequestCancelled(this.userId);
}

class FriendRequestActionError extends FriendRequestsState {
  final String message;
  FriendRequestActionError(this.message);
}
