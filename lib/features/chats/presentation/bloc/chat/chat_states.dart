
part of "chat_bloc.dart";

sealed class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final Map<String,Message> messages;
  final List<String> ids;
  ChatLoaded(this.messages,this.ids);

}

class ChatClosed extends ChatState {}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}