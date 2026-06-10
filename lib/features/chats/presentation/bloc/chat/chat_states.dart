
part of "chat_bloc.dart";

sealed class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState with EquatableMixin {
  final List<Message> messages;
  final bool hasMore;
  final bool isLoadingMore;

  ChatLoaded(this.messages, {this.hasMore = true, this.isLoadingMore = false});

  ChatLoaded copyWith({
    List<Message>? messages,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ChatLoaded(
      messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [messages, hasMore, isLoadingMore];
}

class ChatClosed extends ChatState {}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}