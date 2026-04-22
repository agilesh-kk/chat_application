import 'dart:async';

import 'package:chat_application/features/chats/domain/entities/conversation.dart';
import 'package:chat_application/features/chats/domain/usecase/get_conversations.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'conversation_events.dart';
part 'conversation_states.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final GetConversations getConversations;

  StreamSubscription<List<Conversation>>? _convoSub;

  ConversationBloc({
    required this.getConversations,
  }) : super(ConversationInitial()) {

    // =========================================================
    // 🔥 LOAD CONVERSATIONS
    // =========================================================
    on<LoadConversationsEvent>((event, emit) async {
      emit(ConversationLoading());

      // Cancel previous stream if exists
      await _convoSub?.cancel();

      try {
        final result = await getConversations(event.userId);

        result.fold(
          (failure) {
            emit(ConversationError(failure.message));
          },
          (convoStream) {
            _convoSub = convoStream.listen(
              (convos) {
                //print("📦 BLOC RECEIVED: ${convos.length}");
                
                add(_ConversationUpdated(convos));
              },
              onError: (error) {
                add(_ConversationErrorEvent(error.toString()));
              },
            );
          },
        );
      } catch (e) {
        emit(ConversationError(e.toString()));
      }
    });

    // =========================================================
    // 🔥 HANDLE STREAM DATA
    // =========================================================
    on<_ConversationUpdated>((event, emit) {
      //print("🚀 EMITTING STATE");
      emit(ConversationLoaded(
        
        conversations: List.from(event.convos), // 🔥 IMPORTANT
      ));
    });

    // =========================================================
    // 🔥 HANDLE STREAM ERROR
    // =========================================================
    on<_ConversationErrorEvent>((event, emit) {
      emit(ConversationError(event.message));
    });

    // =========================================================
    // 🔥 SELECT CONVERSATION
    // =========================================================
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

  // =========================================================
  // 🔥 CLEANUP
  // =========================================================
  @override
  Future<void> close() {
    _convoSub?.cancel();
    return super.close();
  }
}