part of 'profilePic_bloc.dart';

@immutable
sealed class ProfilePicEvent {}

final class profilePicUpdate extends ProfilePicEvent{
  final String userId;
  final String imageUrl;

  profilePicUpdate({
    required this.userId, 
    required this.imageUrl
  });
}