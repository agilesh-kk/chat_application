part of 'time_capsule_bloc.dart';

sealed class TimeCapsuleEvent {}

class LoadScheduledMessagesEvent extends TimeCapsuleEvent {
  final String userId;
  final String receiverId;

  LoadScheduledMessagesEvent({
    required this.userId,
    required this.receiverId,
  });
}