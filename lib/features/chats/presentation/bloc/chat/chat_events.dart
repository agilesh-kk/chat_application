
part of "chat_bloc.dart";

sealed class ChatEvent {}

class LoadMessagesEvent extends ChatEvent {
  final String receiverId;
  final String userId;

  LoadMessagesEvent({
    required this.receiverId,
    required this.userId,
  });
}

class SendMessageEvent extends ChatEvent{
  final String receiverId;
  final String userId;
  final String content;
  String? userName;
  String? userProfile;
  SendMessageEvent({
    required this.userId,
    required this.receiverId,
    required this.content,
    this.userName,
    this.userProfile
  });
}

class MessagesUpdatedEvent extends ChatEvent {
  final List<Message> messages;

  MessagesUpdatedEvent(this.messages);
}