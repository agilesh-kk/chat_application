import 'dart:async';

import 'package:chat_application/features/chats/domain/entities/conversation.dart';
import 'package:chat_application/features/chats/domain/usecase/get_conversations.dart';
import 'package:chat_application/features/friends/presentation/friends_cubit.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'conversation_events.dart';
part 'conversation_states.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final GetConversations getConversations;
  final FriendsCubit friendsCubit;

  StreamSubscription<List<Conversation>>? _convoSub;
  StreamSubscription? _friendsub;

  ConversationBloc({
    required this.getConversations,
    required this.friendsCubit
  }) : super(ConversationInitial()) {

    // =========================================================
    // 🔥 LOAD CONVERSATIONS
    // =========================================================
    on<LoadConversationsEvent>((event, emit) async {
      if(state is! ConversationLoaded) {
        emit(ConversationLoading());
      }

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
                if (convos.isEmpty) {
                  add(_ConversationUpdated([]));
                  return;
                }

                var sub = {};
                if (friendsCubit.state is FriendsLoaded) {
                  sub = (friendsCubit.state as FriendsLoaded).friends;
                }

                final List<Conversation> updated = [];
                for (final c in convos) {
                  updated.add(
                    Conversation(
                      convoId: c.convoId,
                      receiverId: c.receiverId,
                      lastMessage: c.lastMessage,
                      lastupdateTime: c.lastupdateTime,
                      profilepicLink: sub[c.receiverId]?.profilePic ?? "loading",
                      receiverName: sub[c.receiverId]?.name ?? "loading",
                      unread: c.unread,
                      lastSender: c.lastSender,
                      receiverIsOnline: sub[c.receiverId]?.isEffectivelyOnline ?? false,
                    ),
                  );
                }
                add(_ConversationUpdated(updated));
              },
              onError: (error) {
                add(_ConversationErrorEvent(error.toString()));
              },
            );

            _friendsub?.cancel();

            _friendsub = (friendsCubit).stream.listen(
              (d) {
                if (d is! FriendsLoaded) return;
                if (state is! ConversationLoaded) return;

                final currentState = state as ConversationLoaded;
                final friends = d.friends;

                final List<Conversation> updated = [];
                for (final c in currentState.conversations) {
                  final friend = friends[c.receiverId];
                  updated.add(
                    Conversation(
                      convoId: c.convoId,
                      receiverId: c.receiverId,
                      lastMessage: c.lastMessage,
                      lastupdateTime: c.lastupdateTime,
                      profilepicLink: friend?.profilePic ?? c.profilepicLink,
                      receiverName: friend?.name ?? c.receiverName,
                      unread: c.unread,
                      lastSender: c.lastSender,
                      receiverIsOnline: friend?.isEffectivelyOnline ?? false,
                    ),
                  );
                }
                add(_ConversationUpdated(updated));
              },
              onError: (error) {
                add(_ConversationErrorEvent(error.toString()));
              },
            );
          },
        );

        // if(state is! ConversationLoaded) {
        //   emit(ConversationLoaded(conversations: []));
        // }
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
    _friendsub?.cancel();
    return super.close();
  }
}