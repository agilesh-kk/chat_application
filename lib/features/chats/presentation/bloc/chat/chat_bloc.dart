import 'dart:async';

import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/domain/usecase/get_messages.dart';
import 'package:chat_application/features/chats/domain/usecase/send_message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part "chat_events.dart";
part "chat_states.dart";

class ChatBloc extends Bloc<ChatEvent,ChatState>{

  final  GetMessages getMessages;
  final  SendMessage sendMessage;
  StreamSubscription<List<Message>>? _messageSub;

  ChatBloc({
    required this.getMessages,
    required this.sendMessage,
  }) : super(ChatInitial()) {

    on<LoadMessagesEvent>((event, emit) async {

      emit(ChatLoading());

      if(_messageSub!=null) {
        await _messageSub?.cancel();
      }

      final stream = await getMessages(
        GetMessageParams(
          receiverId: event.receiverId,
          userId: event.userId,
        ),
      );

      await stream.fold(
      (failure) {
        // Left (failure)
        emit(ChatError(failure.message));
      },
      (convoStream) async {
        // Right (Stream<List<Message>>)
        await emit.forEach<List<Message>>(
          convoStream,
          onData: (msg) => ChatLoaded(msg),
          onError: (error, stackTrace) => ChatError(error.toString()),
        );
      },
    );
    });

    on<SendMessageEvent>((event, emit) async {

  // Only proceed if messages already loaded
  if (state is ChatLoaded) {
    final currentState = state as ChatLoaded;

    // 1️ Create temporary message
    final tempMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: event.userId,
      content: event.content,
      createdAt: DateTime.now().toString(),
      deletedfor: const [],
    );

    // 2️ Add to current list immediately
    final updatedMessages = List<Message>.from(currentState.messages)
      ..insert(0,tempMessage);

    emit(ChatLoaded(updatedMessages));
  }

  // 3️ Send to Firestore in background
  final res = await sendMessage(
    SendMessageParams(
      receiverId: event.receiverId,
      userId: event.userId,
      content: event.content,
      userName: event.userName,
      userProfile: event.userProfile
    ),
  );

  res.fold(
    (failure) {
      emit(ChatError(failure.message));
    },
    (_) {
      // Do nothing
      // Stream will update automatically
    },
  );
});

    on<MessagesUpdatedEvent>((event, emit) {
      emit(ChatLoaded(event.messages));
    });

  }

  String generateConversationId(String user1,String user2){
    final sorted = [user1, user2]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }

  @override
  Future<void> close() {
    _messageSub?.cancel();
    return super.close();
  }
}