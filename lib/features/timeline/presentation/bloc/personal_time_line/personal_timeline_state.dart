part of 'personal_timeline_bloc.dart';

sealed class PersonalTimelineState {
  const PersonalTimelineState();
}

final class PersonalTimelineInitial extends PersonalTimelineState {}

final class PersonalTimeLineLoading extends PersonalTimelineState{}

class PersonalTimelineLoaded extends PersonalTimelineState {
  final List<Event> events;

  const PersonalTimelineLoaded(this.events);
}

class PersonalTimelineError extends PersonalTimelineState {
  final String message;

  const PersonalTimelineError(this.message);
}