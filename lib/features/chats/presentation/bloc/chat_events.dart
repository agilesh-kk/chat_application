
part of "chat_bloc.dart";

sealed class ChatEvent {}

class LoadMessagesEvent extends ChatEvent {
  final String convoId;
  final String userId;

  LoadMessagesEvent({
    required this.convoId,
    required this.userId,
  });
}

class MessagesUpdatedEvent extends ChatEvent {
  final List<Message> messages;

  MessagesUpdatedEvent(this.messages);
}