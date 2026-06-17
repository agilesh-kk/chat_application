import 'dart:async';

import 'package:chat_application/features/chats/data/datasources/draft_data_source.dart';
import 'package:chat_application/features/chats/data/repository/chat_repository_impl.dart';
import 'package:chat_application/features/chats/domain/entities/conversation.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:chat_application/features/chats/domain/usecase/get_conversations.dart';
import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:chat_application/features/friends/presentation/friends_cubit.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'conversation_events.dart';
part 'conversation_states.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final GetConversations getConversations;
  final FriendsCubit friendsCubit;
  final Set<String> friends = {};
  final ChatRepository chatRepositoryImpl;
  final DraftService draftService;
  String? userId;

  StreamSubscription<List<Conversation>>? _convoSub;
  StreamSubscription? _friendsub;

  ConversationBloc({
    required this.getConversations,
    required this.friendsCubit,
    required this.chatRepositoryImpl,
    required this.draftService,
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
        userId = event.userId;

        result.fold(
          (failure) {
            if(failure.message == "user-changed"){
              _friendsub = (friendsCubit).stream.listen(
                  (d) {
                  if(d is FriendsLoaded){
                    final ids = d.friends.values.map((e)=>e.id).toList();
                    add(ConversationDownloadEvent(event.userId, ids, (100/ids.length.toInt()).toInt()));
                  }
                });
            }else{
              emit(ConversationError(failure.message));
            }
            
          },
          (convoStream) {
            _convoSub = convoStream
            //timeout to check if no convo arrives
            //removed due to local db
            // .timeout(Duration(seconds: 1),onTimeout: (sink) {
            //   sink.add([]);
            // },)
            .listen(
              (convos) {
                //checks for empty convo list
                if(convos.isEmpty){
                  add(_ConversationUpdated([]));
                }
                //print("📦 BLOC RECEIVED: ${convos.length}");
                var sub = {}; 
                if(friendsCubit.state is FriendsLoaded){
                  sub = (friendsCubit.state as FriendsLoaded).friends;
                }

                final List<Conversation> updated = <Conversation>[];
                  for(final c in convos){
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
                      receiverIsOnline: sub[c.receiverId]?.isEffectivelyOnline ?? false)
                    );
                  }

                  _enrichWithDrafts(updated).then((withDrafts) {
                    add(_ConversationUpdated(withDrafts));
                  });
                
              },
              onError: (error) {
                add(_ConversationErrorEvent(error.toString()));
              },
            );

            _friendsub?.cancel();

            _friendsub = (friendsCubit).stream.listen(
                  (d) {
                  if(d is FriendsLoaded && state is ConversationLoaded){

                  manageListeners(d.friends.values.toList());

                  final loadedState = state as ConversationLoaded;
                  final List<Conversation> updated = <Conversation>[];
                  for(final c in loadedState.conversations){
                    updated.add(
                      Conversation(
                      convoId: c.convoId,
                      receiverId: c.receiverId,
                      lastMessage: c.lastMessage,
                      lastupdateTime: c.lastupdateTime,
                      profilepicLink: d.friends[c.receiverId]!.profilePic,
                      receiverName: d.friends[c.receiverId]!.name,
                      unread: c.unread,
                      lastSender: c.lastSender,
                      receiverIsOnline: d.friends[c.receiverId]?.isEffectivelyOnline ?? false)
                    );
                  }
                  _enrichWithDrafts(updated).then((withDrafts) {
                    add(_ConversationUpdated(withDrafts));
                  });
                }
                },);
          },
        );

        // if(state is! ConversationLoaded) {
        //   emit(ConversationLoaded(conversations: []));
        // }
      } catch (e) {
        emit(ConversationError(e.toString()));
      }
    });

    on<ConversationDownloadEvent>((event, emit) async{
      final reId = event.receiverId.removeLast();
      final res = await chatRepositoryImpl.downloadConversation(userId: event.userId, friendId: reId);
      res.fold((e)=>emit(ConversationError(e.message)), (r){
          if(state is ConversationLoading){
            emit(ConversationDownloading(event.val));
          }else{
            emit(ConversationDownloading((state as ConversationDownloading).loaded + event.val));
          }
          if(event.receiverId.isNotEmpty){
            add(ConversationDownloadEvent(event.userId, event.receiverId, event.val));
          }else{
            add(LoadConversationsEvent(event.userId));
          }
      });
    },);

    // =========================================================
    // 🔥 HANDLE STREAM DATA
    // =========================================================
    on<_ConversationUpdated>((event, emit) {
      //print("🚀 EMITTING STATE");
      print(event.convos.length);
      

      emit(ConversationLoaded(
        
        conversations: List.from(event.convos), // 🔥 IMPORTANT
      ));
    });


    on<ConversationCloseEvent>((event, emit) {
      //print("🚀 EMITTING STATE");
      
    });

    on<RefreshDraftsEvent>((event, emit) {
      final currentState = state;
      if (currentState is ConversationLoaded) {
        _enrichWithDrafts(currentState.conversations).then((withDrafts) {
          add(_ConversationUpdated(withDrafts));
        });
      }
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

  Future<List<Conversation>> _enrichWithDrafts(List<Conversation> conversations) async {
    final result = <Conversation>[];
    for (final c in conversations) {
      final draft = await draftService.getDraft(c.convoId);
      result.add(Conversation(
        convoId: c.convoId,
        receiverId: c.receiverId,
        lastMessage: c.lastMessage,
        lastupdateTime: c.lastupdateTime,
        profilepicLink: c.profilepicLink,
        receiverName: c.receiverName,
        unread: c.unread,
        lastSender: c.lastSender,
        receiverIsOnline: c.receiverIsOnline,
        draft: draft,
      ));
    }
    return result;
  }

  void manageListeners(List<FriendModel> f){
      for(final i in f){
        if(!friends.contains(i.id)){
          chatRepositoryImpl.startOperationListener(userId: userId!, receiverId: i.id);
          friends.add(i.id);
        }
      }
    }

  // =========================================================
  // 🔥 CLEANUP
  // =========================================================
  @override
  Future<void> close() async {
    _convoSub?.cancel();
    await chatRepositoryImpl.stopOperationListener();
    _friendsub!.cancel();
    
    return super.close();
  }
}