part of "conversation_bloc.dart";

abstract class ConversationState {}

class ConversationInitial extends ConversationState {}

class ConversationLoading extends ConversationState {}

class ConversationLoaded extends ConversationState with EquatableMixin {
  final List<Conversation> conversations;
  final String? selectedConvoId; // currently active conversation
  ConversationLoaded({
    required this.conversations,
    this.selectedConvoId,
  });

  @override
  List<Object?> get props => [conversations, selectedConvoId];
}

class ConversationDownloading extends ConversationState{
  int loaded;
  ConversationDownloading(this.loaded);
}

class ConversationError extends ConversationState {
  final String message;
  ConversationError(this.message);
}