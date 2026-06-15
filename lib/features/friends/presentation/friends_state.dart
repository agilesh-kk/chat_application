part of 'friends_cubit.dart';

sealed class FriendsState {}

class FriendsInitial extends FriendsState {}

class FriendsLoading extends FriendsState {}

class FriendsLoaded extends FriendsState {
  final Map<String, FriendModel> friends;

  FriendsLoaded(this.friends);
}

class FriendsError extends FriendsState {
  final String message;

  FriendsError(this.message);
}

class FriendRequestsLoaded extends FriendsState {
  final Map<String, FriendModel> requests;

  FriendRequestsLoaded(this.requests);
}

class FriendRequestSent extends FriendsState {
  final String friendId;

  FriendRequestSent(this.friendId);
}

class FriendRequestActionSuccess extends FriendsState {}

class FriendRequestActionError extends FriendsState {
  final String message;

  FriendRequestActionError(this.message);
}
