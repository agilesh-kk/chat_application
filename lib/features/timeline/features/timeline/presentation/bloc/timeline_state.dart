part of 'timeline_bloc.dart';

abstract class TimelineState {
  const TimelineState();
}

class TimelineInitial extends TimelineState {}

class TimelineLoading extends TimelineState {}

class TimelineLoaded extends TimelineState {
  final List<Event> events;

  const TimelineLoaded(this.events);
}

class TimelineError extends TimelineState {
  final String message;

  const TimelineError(this.message);
}

class TimeLineClosed extends TimelineState{
  
}