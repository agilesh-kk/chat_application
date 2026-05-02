part of 'time_capsule_bloc.dart';

sealed class TimeCapsuleState {}

class TimeCapsuleInitial extends TimeCapsuleState {}

class TimeCapsuleLoading extends TimeCapsuleState {}

class TimeCapsuleLoaded extends TimeCapsuleState {
  final List<Message> messages;

  TimeCapsuleLoaded(this.messages);
}

class TimeCapsuleError extends TimeCapsuleState {
  final String message;

  TimeCapsuleError(this.message);
}
