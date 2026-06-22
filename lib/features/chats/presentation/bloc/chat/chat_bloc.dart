import 'dart:async';

import 'package:chat_application/features/chats/data/datasources/chat_local_data_sources.dart';
import 'package:chat_application/features/chats/domain/entities/list_operation.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:chat_application/features/chats/domain/usecase/delete_message.dart';
import 'package:chat_application/features/chats/domain/usecase/edit_message.dart';
import 'package:chat_application/features/chats/domain/usecase/get_messages.dart';
import 'package:chat_application/features/chats/domain/usecase/mark_messages_delivered.dart';
import 'package:chat_application/features/chats/domain/usecase/send_image.dart';
import 'package:chat_application/features/chats/domain/usecase/send_message.dart';
import 'package:chat_application/features/chats/domain/usecase/toggle_reaction.dart';
import 'package:equatable/equatable.dart';
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
  final EditMessage _editMessage;
  final ChatRepository _chatRepository;
  final ChatLocalDataSource _chatLocalDataSource;

  StreamSubscription<ListOperation<Message>>? _messageSub;

  String? _currentUserId;
  String? _currentReceiverId;
  bool _alreadyMarkedRecently = false;

  ChatBloc({
    required GetMessages getMessages,
    required SendMessage sendMessage,
    required SendImage sendImage,
    required DeleteMessage deleteMessage,
    required MarkMessagesDelivered markMessagesDelivered,
    required ToggleReaction toggleReaction,
    required EditMessage editMessage,
    required ChatRepository chatRepository,
    required ChatLocalDataSource chatLocalDataSource,
  })
   :
   _getMessages = getMessages,
   _sendMessage = sendMessage,
   _sendImage = sendImage,
   _deleteMessage = deleteMessage, 
   _markMessagesDelivered = markMessagesDelivered,
   _toggleReaction = toggleReaction,
   _editMessage = editMessage,
   _chatRepository = chatRepository,
   _chatLocalDataSource = chatLocalDataSource,
   super(ChatInitial()) {

    on<Closechat>((event, emit) async {
      await _messageSub?.cancel();
      //await _chatRepository.stopOperationListener();
      print("cancelled");
      emit(ChatClosed());
    });

    on<SendImageEvent>((
      SendImageEvent event, Emitter<ChatState> emit) async {

      final current = state as ChatLoaded;
      final msgId = const Uuid().v4();

      // 1. Create local message
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
        replyToId: event.replyToId,
        replyToContent: event.replyToContent,
        replyToSenderId: event.replyToSenderId,
        replyToType: event.replyToType,
      );

      // 2. Add to local DB (optimistic)
      final convoId = _generateConversationId(event.userId, event.receiverId);
      await _chatLocalDataSource.upsertMessageFromFirestore({
        'senderId': event.userId,
        'content': '',
        'type': 'image',
        'messageType': 'image',
        'status': 'sending',
        'createdAt': DateTime.now(),
        'deletedfor': <String>[],
        'deletedForEveryone': false,
        'reactions': <String, String>{},
        'replyToId': event.replyToId,
        'replyToContent': event.replyToContent,
        'replyToSenderId': event.replyToSenderId,
        'replyToType': event.replyToType,
        'isScheduled': false,
        'inTimeline': false,
        'name': event.userName ?? 'Unknown',
        'receiverId': event.receiverId,
        'profile': event.userProfile,
        'convoId': convoId,
        'isLocal': true,
      }, msgId);

      // 3. Emit instantly
      //emit(ChatLoaded([localMessage, ...current.messages]));

      // 4. Send in background
      await _sendImage(
        SendImageParams(
          receiverId: event.receiverId,
          userId: event.userId,
          image: event.image,
          msgId: msgId,
          userName: event.userName,
          userProfile: event.userProfile,
          replyToId: event.replyToId,
          replyToContent: event.replyToContent,
          replyToSenderId: event.replyToSenderId,
          replyToType: event.replyToType,
        ),
      );
    });

    on<LoadMessagesEvent>((event, emit) async {
      emit(ChatLoading());

      if (_messageSub != null) {
        await _messageSub?.cancel();
      }

      // Stop previous op listener
      //await _chatRepository.stopOperationListener();

      _currentUserId = event.userId;
      _currentReceiverId = event.receiverId;

      // Init local DB
      await _chatLocalDataSource.initDatabase();

      // Getting messages (repository handles initial load + local DB stream)
      final stream = await _getMessages(
        GetMessageParams(
          receiverId: event.receiverId,
          userId: event.userId,
        ),
      );

      stream.fold(
        (failure) => emit(ChatError(failure.message)),
        (messageStream) {
          _messageSub = messageStream.listen(
            
            (operation)  {
              final st = state;
              if(st is ChatLoaded){
                operation.performOperation(st.ids, st.messages);
                add(MessagesUpdatedEvent( st.ids,st.messages));
              }else{
                Map<String,Message> temp = {};
                List<String> ids = [];
                operation.performOperation(ids, temp);
                add(MessagesUpdatedEvent(ids,temp));
              }
            },
          );
        }
      );
    });

    on<SendMessageEvent>((event, emit) async {
      final currentState = state as ChatLoaded;
      final msgId = const Uuid().v1();
      final convoId = _generateConversationId(event.userId, event.receiverId);

      // 1. Create temp message
      final tempMessage = Message(
        id: msgId,
        status: "sent",
        senderId: event.userId,
        content: event.content,
        createdAt: DateTime.now(),
        deletedfor: const [],
        isLocal: true,
        isScheduled: event.isScheduled,
        replyToId: event.replyToId,
        replyToContent: event.replyToContent,
        replyToSenderId: event.replyToSenderId,
        replyToType: event.replyToType,
      );

      // 2. Add to local DB (optimistic)
      if (!event.isScheduled) {
        await _chatLocalDataSource.upsertMessageFromFirestore({
          'senderId': event.userId,
          'content': event.content,
          'type': 'text',
          'messageType': 'text',
          'status': 'sent',
          'createdAt': DateTime.now(),
          'deletedfor': <String>[],
          'deletedForEveryone': false,
          'reactions': <String, String>{},
          'replyToId': event.replyToId,
          'replyToContent': event.replyToContent,
          'replyToSenderId': event.replyToSenderId,
          'replyToType': event.replyToType,
          'isScheduled': false,
          'inTimeline': false,
          'name': event.userName ?? 'Unknown',
          'receiverId': event.receiverId,
          'profile': event.userProfile,
          'convoId': convoId,
          'isLocal': true,
        }, msgId);

        // final updatedMessages = List<Message>.from(currentState.messages)
        //   ..insert(0, tempMessage);
        // emit(ChatLoaded(updatedMessages));
      }

      // 3. Send to remote
      if (event.isScheduled) {
        final res = await _sendMessage(
          SendMessageParams(
            msgId: tempMessage.id,
            receiverId: event.receiverId,
            userId: event.userId,
            content: event.content,
            userName: event.userName,
            userProfile: event.userProfile,
            sendAt: event.sendAt,
            isScheduled: true,
            replyToId: event.replyToId,
            replyToContent: event.replyToContent,
            replyToSenderId: event.replyToSenderId,
            replyToType: event.replyToType,
          )
        );

        res.fold(
          (failure) => emit(ChatError(failure.message)),
          (_) {},
        );
        return;
      }

      final res = await _sendMessage(
        SendMessageParams(
          msgId: tempMessage.id,
          receiverId: event.receiverId,
          userId: event.userId,
          content: event.content,
          userName: event.userName,
          userProfile: event.userProfile,
          sendAt: event.sendAt,
          isScheduled: event.isScheduled,
          replyToId: event.replyToId,
          replyToContent: event.replyToContent,
          replyToSenderId: event.replyToSenderId,
          replyToType: event.replyToType,
        ),
      );

      res.fold(
        (failure) {
          emit(ChatError(failure.message));
        },
        (_) {
          // Local DB updated by repository; stream will auto-emit
        },
      );
    });

    on<MessagesUpdatedEvent>((event, emit) {
      _updateMessages(event.ids,event.messages,emit);
    });

    on<DeleteMessageEvent>(_onDeleteMessageEvent);
    on<MarkMessagesDeliveredEvent>(_onMarkMessagesDeleiveredEvent);
    on<ToggleReactionEvent>(_onToggleReactionEvent);
    on<EditMessageEvent>(_onEditMessageEvent);
  }
  

  @override
  Future<void> close() async{
    await _messageSub?.cancel();
    await _chatRepository.stopOperationListener();
    return super.close();
  }

  String _generateConversationId(String user1, String user2) {
    final sorted = [user1, user2]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }

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
      (_) {},
    );
  }

  FutureOr<void> _onMarkMessagesDeleiveredEvent(MarkMessagesDeliveredEvent event, Emitter<ChatState> emit) async {
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

  FutureOr<void> _onEditMessageEvent(EditMessageEvent event, Emitter<ChatState> emit) async {
    await _editMessage(EditMessageParams(
      userId: event.userId,
      receiverId: event.receiverId,
      msgId: event.msgId,
      newContent: event.newContent,
    ));
  }

  void _updateMessages(List<String> ids,Map<String,Message> received,Emitter<ChatState> emit) {

    final hasUnseen = ids.any(
      (msg) =>
          received[msg]!.status == "sent" &&
          !received[msg]!.isLocal,
    );


    if (hasUnseen &&
        _currentUserId != null &&
        _currentReceiverId != null) {
      _alreadyMarkedRecently = true;

      add(MarkMessagesDeliveredEvent(
        userId: _currentUserId!,
        receiverId: _currentReceiverId!,
      ));

      // Future.delayed(const Duration(milliseconds: 500), () {
      //   _alreadyMarkedRecently = false;
      // });
    }

    //received.removeWhere((e)=>(e.deletedfor.contains(_currentUserId)&&!e.deletedForEveryone));

    emit(ChatLoaded(received,ids));
    }
    }
