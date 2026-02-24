import 'dart:async';

import 'package:chat_application/features/chats/domain/entities/conversation.dart';
import 'package:chat_application/features/chats/domain/usecase/get_conversations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'conversation_events.dart';
part 'conversation_states.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final GetConversations getConversations;
  StreamSubscription<List<Conversation>>? _convoSub;

  ConversationBloc(
    {
      required this.getConversations
    }
  ) : super(ConversationInitial()) {

    // Load all conversations
    on<LoadConversationsEvent>((event, emit) async {
  emit(ConversationLoading());

  try {
    final conversationsStreamEither = await getConversations(event.userId);

    // Use fold synchronously
    await conversationsStreamEither.fold(
      (failure) async {
        // Left (failure)
        emit(ConversationError(failure.message));
      },
      (convoStream) async {
        // Right (Stream<List<Conversation>>)
        await emit.forEach<List<Conversation>>(
          convoStream,
          onData: (convos) => ConversationLoaded(conversations: convos),
          onError: (error, stackTrace) => ConversationError(error.toString()),
        );
      },
    );

  } catch (e) {
    emit(ConversationError(e.toString()));
  }
});

    // Select a conversation
    on<ConversationSelectedEvent>((event, emit) {
      final currentState = state;
      if (currentState is ConversationLoaded) {
        emit(ConversationLoaded(
          conversations: currentState.conversations,
          selectedConvoId: event.convoId,
        ));
      }
    });
}
}