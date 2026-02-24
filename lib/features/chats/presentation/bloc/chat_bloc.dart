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
          convoId: event.convoId,
          userId: event.userId,
        ),
      );

      stream.fold(
      (failure) => emit(ChatError(failure.message)),
      (user) {
        _messageSub = user.listen(
        (messages) {
          add(MessagesUpdatedEvent(messages));
        },
      );
      },
      );
    });

    on<MessagesUpdatedEvent>((event, emit) {
      emit(ChatLoaded(event.messages));
    });

  }

  @override
  Future<void> close() {
    _messageSub?.cancel();
    return super.close();
  }
}