part of 'status_bloc.dart';

@immutable
sealed class StatusEvent {}

final class UploadStatusEvent extends StatusEvent {
  final String userId;
  final XFile? image;
  final String caption;
  final String userName;
  final String profilepic;

  UploadStatusEvent({
    required this.userId,
    required this.image,
    required this.caption,
    required this.userName,
    required this.profilepic
  });
}

final class GetAllStatusEvent extends StatusEvent {}

final class UpdateViewEvent extends StatusEvent {
  final String statusId;
  final String viewerId;
  final String viewerName;
  //final DateTime viewedAt;

  UpdateViewEvent({
    required this.statusId,
    required this.viewerId,
    required this.viewerName,
    //required this.viewedAt,
  });
}

final class UpdateStatusPage extends StatusEvent {
  final List<Status> statuses;

  UpdateStatusPage({
    required this.statuses
  });
  
}
