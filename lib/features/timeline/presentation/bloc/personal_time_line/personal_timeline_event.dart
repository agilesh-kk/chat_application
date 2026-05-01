part of 'personal_timeline_bloc.dart';

sealed class PersonalTimelineEvent {
  const PersonalTimelineEvent();
}

class FetchPersonalTimeLine extends PersonalTimelineEvent {
  final String userId;

  FetchPersonalTimeLine({required this.userId});
}

class AddPersonalTimeLineEvent extends PersonalTimelineEvent {
  final String title;
  final String userId;
  final String content;
  final DateTime time;
  final String type;

  AddPersonalTimeLineEvent({
    required this.title,
    required this.userId,
    required this.content,
    required this.time,
    required this.type,
  });
}

class RemovePersonalTimelineEvent extends PersonalTimelineEvent{
  final String userId;
  final String eventId;

  RemovePersonalTimelineEvent({
    required this.userId, 
    required this.eventId
  });
}