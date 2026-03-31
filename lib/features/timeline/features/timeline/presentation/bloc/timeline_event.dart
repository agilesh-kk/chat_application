part of 'timeline_bloc.dart';

abstract class TimelineEvent {
  const TimelineEvent();
}

class FetchTimelineEvent extends TimelineEvent {
  final String userId;
  final String receiverId;

  const FetchTimelineEvent({
    required this.userId,
    required this.receiverId,
  });
}

class RefreshTimelineEvent extends TimelineEvent {
  final String userId;
  final String receiverId;

  const RefreshTimelineEvent({
    required this.userId,
    required this.receiverId,
  });
}

class CloseTimeLineEvent extends TimelineEvent{
}