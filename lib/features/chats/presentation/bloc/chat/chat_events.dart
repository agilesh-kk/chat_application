
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

class MarkMessagesDeliveredEvent extends ChatEvent {
  final String userId;
  final String receiverId;

  MarkMessagesDeliveredEvent({
    required this.userId,
    required this.receiverId,
  });
}

class SendMessageEvent extends ChatEvent{
  final String receiverId;
  final String userId;
  final String content;
  String? userName;
  String? userProfile;

  final DateTime? sendAt;
  final bool isScheduled;

  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderId;
  final String? replyToType;

  SendMessageEvent({
    required this.userId,
    required this.receiverId,
    required this.content,
    this.userName,
    this.userProfile,
    this.sendAt,
    this.isScheduled=false,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderId,
    this.replyToType,
  });
}

class SendImageEvent extends ChatEvent {
  final String receiverId;
  final String userId;
  final XFile image;
  String? userName;
  String? userProfile;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderId;
  final String? replyToType;
  SendImageEvent({
    required this.userId,
    required this.receiverId,
    required this.image,
    this.userName,
    this.userProfile,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderId,
    this.replyToType,
  });
}

class MessagesUpdatedEvent extends ChatEvent {
  final List<Message> messages;

  MessagesUpdatedEvent(this.messages);
}

class DeleteMessageEvent extends ChatEvent{
  final String msgId;
  final String userId;
  final String receiverId;
  final String type;
  final bool deleteForEveryone;

  DeleteMessageEvent({
    required this.msgId, 
    required this.userId, 
    required this.receiverId,
    required this.type, 
    required this.deleteForEveryone
  });
}

class Closechat extends ChatEvent{}

class ToggleReactionEvent extends ChatEvent {
  final String userId;
  final String receiverId;
  final String messageId;
  final String emoji;

  ToggleReactionEvent({
    required this.userId,
    required this.receiverId,
    required this.messageId,
    required this.emoji,
  });
}