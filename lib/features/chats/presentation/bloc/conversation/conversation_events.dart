part of 'conversation_bloc.dart';

abstract class ConversationEvent {}

class LoadConversationsEvent extends ConversationEvent {
  final String userId;
  LoadConversationsEvent(this.userId);
}

class ConversationSelectedEvent extends ConversationEvent {
  final String convoId;
  ConversationSelectedEvent(this.convoId);
}

class ConversationCreatedEvent extends ConversationEvent {
  final String userId;
  ConversationCreatedEvent(this.userId);
}