part of 'status_bloc.dart';

@immutable
sealed class StatusEvent {}

final class UploadStatusEvent extends StatusEvent {
  final String userId;
  final XFile? image;
  final String caption;
  final String userName;

  UploadStatusEvent({
    required this.userId,
    required this.image,
    required this.caption,
    required this.userName,
  });
}

final class GetAllStatusEvent extends StatusEvent{}