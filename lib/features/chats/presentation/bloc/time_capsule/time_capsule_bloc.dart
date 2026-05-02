import 'dart:async';

import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/domain/usecase/get_scheduled_messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'time_capsule_event.dart';
part 'time_capsule_state.dart';

class TimeCapsuleBloc extends Bloc<TimeCapsuleEvent, TimeCapsuleState> {
  final GetScheduledMessages _getScheduledMessages;
  StreamSubscription<List<Message>>? _messageSub;

  TimeCapsuleBloc({
    required GetScheduledMessages getScheduledMessages,
  }) : _getScheduledMessages = getScheduledMessages,
       super(TimeCapsuleInitial()) {
    on<LoadScheduledMessagesEvent>(_onLoadMessages);
  }

  Future<void> _onLoadMessages(
    LoadScheduledMessagesEvent event,
    Emitter<TimeCapsuleState> emit,
  ) async {
    //print("BLOC: Calling usecase...");
    emit(TimeCapsuleLoading());

    final result = await _getScheduledMessages(
      GetScheduledMessageParams(
        receiverId: event.receiverId,
        userId: event.userId,
      ),
    );

    await result.fold(
      (failure) async {
        //print("BLOC ERROR: ${failure.message}");
        emit(TimeCapsuleError(failure.message));
      },
      (messageStream) async {
        //print("BLOC: Stream received");

        await emit.forEach<List<Message>>(
          messageStream,
          onData: (messages) {
            //print("BLOC: Messages received: ${messages.length}");
            return TimeCapsuleLoaded(messages);
          },
          onError: (error, stackTrace) {
            return TimeCapsuleError(error.toString());
          },
        );
      },
    );
  }

  @override
  Future<void> close() {
    _messageSub?.cancel();
    return super.close();
  }
}
