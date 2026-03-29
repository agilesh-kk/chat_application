part of 'profilePic_bloc.dart';

@immutable
sealed class ProfilePicEvent {}

final class ProfilePicUpdate extends ProfilePicEvent{
  final String userId;
  final String imageUrl;

  ProfilePicUpdate({
    required this.userId, 
    required this.imageUrl
  });
}