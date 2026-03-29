part of 'profilePic_bloc.dart';

@immutable
sealed class ProfilePicState {}

final class ProfileInitial extends ProfilePicState {}

class ProfilePicLoading extends ProfilePicState {}

class ProfilePicUpdateScuccess extends ProfilePicState{
  final String imageUrl;

  ProfilePicUpdateScuccess({required this.imageUrl});
}

class ProfilePicUpdateFailure extends ProfilePicState{
  final String message;

  ProfilePicUpdateFailure(this.message);
}
