part of 'timeline_bloc.dart';

abstract class TimelineEvent {
  const TimelineEvent();
}

class FetchTimelineEvent extends TimelineEvent {
  final String userId;
  final String receiverId;

  const FetchTimelineEvent({required this.userId, required this.receiverId});
}

class RefreshTimelineEvent extends TimelineEvent {
  final String userId;
  final String receiverId;

  const RefreshTimelineEvent({required this.userId, required this.receiverId});
}

class AddEvent extends TimelineEvent {
  final Message message;
  final String userId;
  final String receiverId;
  final String customTitle;
  final String addedByName;

  AddEvent({
    required this.message,
    required this.userId,
    required this.receiverId,
    required this.customTitle,
    required this.addedByName,
  });
}

class RemoveEvent extends TimelineEvent {
  final String eventId;
  final String messageId;
  final String userId;
  final String receiverId;

  RemoveEvent({
    required this.eventId,
    required this.messageId,
    required this.userId,
    required this.receiverId,
  });
}

class CloseTimeLineEvent extends TimelineEvent {}
