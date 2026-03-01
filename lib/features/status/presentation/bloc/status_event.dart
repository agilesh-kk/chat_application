part of 'status_bloc.dart';

@immutable
sealed class StatusEvent {}

final class UploadStatusEvent extends StatusEvent {
  final String userId;
  final XFile? image;
  final String caption;

  UploadStatusEvent({
    required this.userId,
    required this.image,
    required this.caption,
  });
}
