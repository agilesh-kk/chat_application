part of "conversation_bloc.dart";

abstract class ConversationState {}

class ConversationInitial extends ConversationState {}

class ConversationLoading extends ConversationState {}

class ConversationLoaded extends ConversationState {
  final List<Conversation> conversations;
  final String? selectedConvoId; // currently active conversation
  ConversationLoaded({
    required this.conversations,
    this.selectedConvoId,
  });
}

class ConversationError extends ConversationState {
  final String message;
  ConversationError(this.message);
}