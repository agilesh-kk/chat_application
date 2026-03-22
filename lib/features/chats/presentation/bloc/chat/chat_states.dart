
part of "chat_bloc.dart";

sealed class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Message> messages;
  ChatLoaded(this.messages);
}

class ChatClosed extends ChatState {}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}