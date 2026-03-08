import 'dart:async';

import 'package:chat_application/features/chats/data/models/message_model.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/domain/usecase/get_messages.dart';
import 'package:chat_application/features/chats/domain/usecase/send_message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

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
          onData: (msg) => updateMessages(msg, emit),
          onError: (error, stackTrace) => ChatError(error.toString()),
        );
      },
    );
    });

    on<SendMessageEvent>((event, emit) async {

    final currentState = state as ChatLoaded;

    var uid = Uuid();

    // 1️ Create temporary message
    final tempMessage = MessageModel(
      id: uid.v1(),
      senderId: event.userId,
      content: event.content,
      createdAt: DateTime.now().toString(),
      deletedfor: const [],
      isLocal: true
    );

    // 2️ Add to current list immediately
    final updatedMessages = List<Message>.from(currentState.messages)
      ..insert(0,tempMessage);

    emit(ChatLoaded(updatedMessages));
  

  // 3️ Send to Firestore in background
  final res = await sendMessage(
    SendMessageParams(
      msgId: tempMessage.id,
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

  ChatState updateMessages(List<Message> received, emit){
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      List<Message> local = currentState.messages.where((test)=>test.isLocal).toList();

      List<Message> updated = [...received,...local.where((test)=>!received.any((t)=>test.id==t.id))];

      return ChatLoaded(updated);
    }
    else{
      return ChatLoaded(received);
    }
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