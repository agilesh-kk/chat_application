import 'package:chat_application/features/friends/data/friend_model.dart';

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
