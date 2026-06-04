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

final class GetAllStatusEvent extends StatusEvent {
  final String currentUserId;
  GetAllStatusEvent({required this.currentUserId});
}

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

final class DeleteStatusEvent extends StatusEvent{
  final String statusId;

  DeleteStatusEvent({
    required this.statusId,
  });
}

final class AddLikeEvent extends StatusEvent {
  final String statusId;
  final String userId;

  AddLikeEvent({
    required this.statusId,
    required this.userId,
  });
}

final class ReplyToStatusEvent extends StatusEvent {
  final String receiverId;
  final String userId;
  final String content;
  final String userName;
  final String userProfile;
  final String statusId;
  final String statusUserId;
  final String statusImageUrl;
  final String statusCaption;
  final DateTime statusCreatedAt;
  final DateTime statusExpiresAt;
  final String statusUserName;
  final String statusProfilepic;

  ReplyToStatusEvent({
    required this.receiverId,
    required this.userId,
    required this.content,
    required this.userName,
    required this.userProfile,
    required this.statusId,
    required this.statusUserId,
    required this.statusImageUrl,
    required this.statusCaption,
    required this.statusCreatedAt,
    required this.statusExpiresAt,
    required this.statusUserName,
    required this.statusProfilepic,
  });
}