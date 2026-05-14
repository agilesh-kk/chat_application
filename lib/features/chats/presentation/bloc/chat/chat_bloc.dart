import 'dart:async';

import 'package:chat_application/features/chats/data/models/message_model.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/domain/usecase/delete_message.dart';
import 'package:chat_application/features/chats/domain/usecase/get_messages.dart';
import 'package:chat_application/features/chats/domain/usecase/mark_messages_delivered.dart';
import 'package:chat_application/features/chats/domain/usecase/send_image.dart';
import 'package:chat_application/features/chats/domain/usecase/send_message.dart';
import 'package:chat_application/features/chats/domain/usecase/toggle_reaction.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

part "chat_events.dart";
part "chat_states.dart";

class ChatBloc extends Bloc<ChatEvent,ChatState>{

  final GetMessages _getMessages;
  final SendMessage _sendMessage;
  final SendImage _sendImage;
  final DeleteMessage _deleteMessage;
  final MarkMessagesDelivered _markMessagesDelivered;
  final ToggleReaction _toggleReaction;

  String? _currentUserId;
  String? _currentReceiverId;
  bool _alreadyMarkedRecently = false;
  StreamSubscription<List<Message>>? _messageSub;

  ChatBloc({
    required GetMessages getMessages,
    required SendMessage sendMessage,
    required SendImage sendImage,
    required DeleteMessage deleteMessage,
    required MarkMessagesDelivered markMessagesDelivered,
    required ToggleReaction toggleReaction,
  })
   :
   _getMessages = getMessages,
   _sendMessage = sendMessage,
   _sendImage = sendImage,
   _deleteMessage = deleteMessage, 
   _markMessagesDelivered = markMessagesDelivered,
   _toggleReaction = toggleReaction,
   super(ChatInitial()) {

    on<Closechat>((event, emit)async {
      await _messageSub!.cancel();
      emit(ChatClosed());
    },);

    on<SendImageEvent>((
      SendImageEvent event, Emitter<ChatState> emit) async {

      final current = state as ChatLoaded;

      final msgId = const Uuid().v4();

      // ✅ 1. Create LOCAL MESSAGE
      final localMessage = Message(
        senderId: event.userId,
        createdAt: DateTime.now(),
        deletedfor: [],
        id: msgId,
        content: "",
        type: "image",
        localPath: event.image.path,
        isLocal: true,
        status: "sending",
      );

      // ✅ 2. Emit instantly (NO WAIT)
      emit(ChatLoaded([localMessage, ...current.messages]));

      // ✅ 3. Call usecase (async)
      await _sendImage(
        SendImageParams(
          receiverId: event.receiverId,
          userId: event.userId,
          image: event.image,
          msgId: msgId,
          userName: event.userName,
          userProfile: event.userProfile
        ),
      );
    });

    on<LoadMessagesEvent>((event, emit) async {
      _currentUserId = event.userId;
      _currentReceiverId = event.receiverId;

      emit(ChatLoading());

      if(_messageSub!=null) {
        await _messageSub?.cancel();
      }
      
      //getting messages
      final stream = await _getMessages(
        GetMessageParams(
          receiverId: event.receiverId,
          userId: event.userId,
        ),
      );

      stream.fold(
        (failure) => ChatError(failure.message),
        (convoStream){
          _messageSub = convoStream.listen(
            (messages)=>updateMessages(messages, emit),
          );
        }
      );
    });

    on<SendMessageEvent>((event, emit) async {

      final currentState = state as ChatLoaded;

      var uid = Uuid();

      //deciding whether it is a scheduled message or not and assigning the createdAt time.
      //use it in future
      // final DateTime createdTime =
      //   event.isScheduled && event.sendAt != null
      //   ? event.sendAt!
      //   : DateTime.now();

      // 1️ Create temporary message
      final tempMessage = MessageModel(
        id: uid.v1(),
        status: "uploading",
        senderId: event.userId,
        content: event.content,
        createdAt: DateTime.now(),
        deletedfor: const [],
        isLocal: true,
        isScheduled: event.isScheduled,
      );

      // 2️ Add to current list immediately (UI) if it is a normal message
      // once the shceduled message is sent or pushed it will be updated to the chat UI.
      if(!event.isScheduled){
        final updatedMessages = List<Message>.from(currentState.messages)
          ..insert(0,tempMessage);
        emit(ChatLoaded(updatedMessages));
      }

      //if the message is scheduled
      if(event.isScheduled){
        final res = await _sendMessage(
          SendMessageParams(
            msgId: tempMessage.id,
            receiverId: event.receiverId,
            userId: event.userId,
            content: event.content,
            userName: event.userName,
            userProfile: event.userProfile,

            //time capsule
            sendAt: event.sendAt,
            isScheduled: true,
          )
        );

        res.fold(
          (failure) => emit(ChatError(failure.message)),
          (_) {},
        );

        return; 
      }
    

      // 3️ Send to Firestore in background
      final res = await _sendMessage(
        SendMessageParams(
          msgId: tempMessage.id,
          receiverId: event.receiverId,
          userId: event.userId,
          content: event.content,
          userName: event.userName,
          userProfile: event.userProfile,
          //time capsule
          sendAt: event.sendAt,
          isScheduled: event.isScheduled,
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

    on<DeleteMessageEvent>(_onDeleteMessageEvent);
    on<MarkMessagesDeliveredEvent>(_onMarkMessagesDeleiveredEvent);
    on<ToggleReactionEvent>(_onToggleReactionEvent);

  }

  void updateMessages(List<Message> received, emit) {
    // =========================
    // 🔥 STEP 1: DETECT UNSEEN MESSAGES
    // =========================
    final hasUnseen = received.any(
      (msg) =>
          msg.senderId == _currentReceiverId && // ✅ only incoming
          msg.status == "sent" &&
          !msg.isLocal,
    );

    if (hasUnseen &&
        !_alreadyMarkedRecently &&
        _currentUserId != null &&
        _currentReceiverId != null) {

      _alreadyMarkedRecently = true;

      add(MarkMessagesDeliveredEvent(
        userId: _currentUserId!,
        receiverId: _currentReceiverId!,
      ));

      // debounce reset
      Future.delayed(const Duration(milliseconds: 500), () {
        _alreadyMarkedRecently = false;
      });
    }

    // =========================
    // 🔥 STEP 2: YOUR EXISTING LOGIC
    // =========================
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;

      final Map<String, Message> messageMap = {};

      for (var msg in received) {
        messageMap[msg.id] = msg;
      }

      for (var msg in currentState.messages) {
        if (msg.isLocal && !messageMap.containsKey(msg.id)) {
          messageMap[msg.id] = msg;
        }
      }

      List<Message> updated = messageMap.values.toList();

      updated.sort((a, b) {
        return b.createdAt.compareTo(a.createdAt);
      });

      add(MessagesUpdatedEvent(updated));
    } else {
      add(MessagesUpdatedEvent(received));
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

  //event function for deleteMessage
  FutureOr<void> _onDeleteMessageEvent(DeleteMessageEvent event, Emitter<ChatState> emit) async {
    final res = await _deleteMessage(
      DeleteMessageParams(
        msgId: event.msgId,
        userId: event.userId,
        receiverId: event.receiverId,
        type: event.type,
        deleteForEveryone: event.deleteForEveryone,
      ),
    );

    res.fold(
      (failure) {
        emit(ChatError(failure.message));
      },
      (_) {
        // If delete succeeds, the message stream should update automatically.
        // No immediate state change is required here unless you want optimistic UI.
      },
    );
  }

  FutureOr<void> _onMarkMessagesDeleiveredEvent(MarkMessagesDeliveredEvent event, Emitter<ChatState> emit) async{
    await _markMessagesDelivered(
      MarkMessagesDeliveredParams(
        userId: event.userId, 
        receiverId: event.receiverId
      )
    );
  }

  FutureOr<void> _onToggleReactionEvent(ToggleReactionEvent event, Emitter<ChatState> emit) async {
    await _toggleReaction(
      ToggleReactionParams(
        userId: event.userId,
        receiverId: event.receiverId,
        messageId: event.messageId,
        emoji: event.emoji,
      ),
    );
  }
}