part of 'notification_details_cubit.dart';

sealed class NotificationDetailsState {
  const NotificationDetailsState();
}

final class NotificationDetailsInitial extends NotificationDetailsState {
  const NotificationDetailsInitial();
}

final class PendingNotificationDetails extends NotificationDetailsState {
  final String convoId;
  final String receiverId;
  final String receiverName;

  const PendingNotificationDetails({
    required this.convoId,
    required this.receiverId,
    required this.receiverName,
  });
}

final class NoPending extends NotificationDetailsState {
  const NoPending();
}
