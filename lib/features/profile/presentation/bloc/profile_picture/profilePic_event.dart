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

final class ProfilePicCustomUpload extends ProfilePicEvent{
  final String userId;
  final XFile image;

  ProfilePicCustomUpload({
    required this.userId, 
    required this.image
  });
}