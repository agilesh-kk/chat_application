part of 'conversation_bloc.dart';

abstract class ConversationEvent {}

class LoadConversationsEvent extends ConversationEvent {
  final String userId;
  LoadConversationsEvent(this.userId);
}

class ConversationDownloadEvent extends ConversationEvent {
  final String userId;
  final List<String> receiverId;
  final int val;
  ConversationDownloadEvent(this.userId, this.receiverId, this.val);
}

class ConvoListDownloadEvent extends ConversationEvent {
  final String userId;
  final List<String> convoIds;
  final int val;
  ConvoListDownloadEvent(this.userId, this.convoIds, this.val);
}

class ConversationSelectedEvent extends ConversationEvent {
  final String convoId;
  ConversationSelectedEvent(this.convoId);
}

class ConversationCreatedEvent extends ConversationEvent {
  final String userId;
  ConversationCreatedEvent(this.userId);
}

class DraftSavedEvent extends ConversationEvent {}

// 🔥 INTERNAL EVENTS (VERY IMPORTANT)
class _ConversationUpdated extends ConversationEvent {
  final List<Conversation> convos;
  _ConversationUpdated(this.convos);
}

class _ConversationErrorEvent extends ConversationEvent {
  final String message;
  _ConversationErrorEvent(this.message);
}
