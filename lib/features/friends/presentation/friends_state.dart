part of 'friends_cubit.dart';

sealed class FriendsState {}

class FriendsInitial extends FriendsState {}

class FriendsLoading extends FriendsState {}

class FriendsLoaded extends FriendsState {
  final Map<String,FriendModel> friends;

  FriendsLoaded(this.friends);
}

class FriendsError extends FriendsState {
  final String message;

  FriendsError(this.message);
}