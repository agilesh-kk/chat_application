import 'dart:async';
import 'dart:convert';

import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:chat_application/features/friends/presentation/friends_cubit.dart';
import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:chat_application/features/status/domain/usecase/add_like.dart';
import 'package:chat_application/features/status/domain/usecase/delete_status.dart';
import 'package:chat_application/features/status/domain/usecase/get_all_status.dart';
import 'package:chat_application/features/status/domain/usecase/update_view.dart';
import 'package:chat_application/features/status/domain/usecase/upload_status.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';


part 'status_event.dart';
part 'status_state.dart';

class StatusBloc extends Bloc<StatusEvent, StatusState> {
  final UploadStatus _uploadStatus;
  final GetAllStatus _getAllStatus;
  final UpdateView _updateView;
  final DeleteStatus _deleteStatus;
  final AddLike _addLike;
  final FriendsCubit _friendsCubit;
  final ChatRepository _chatRepository;
  StreamSubscription? friendsStream;
  

  StatusBloc({
    required UploadStatus uploadStatus,
    required GetAllStatus getAllStatus,
    required UpdateView updateView,
    required DeleteStatus deleteStatus,
    required AddLike addLike,
    required FriendsCubit friends_cubit,
    required ChatRepository chatRepository,
  }) : 
  _uploadStatus = uploadStatus,
  _getAllStatus = getAllStatus,
  _updateView = updateView,
  _deleteStatus = deleteStatus,
  _addLike = addLike,
  _friendsCubit = friends_cubit,
  _chatRepository = chatRepository,
  
  super(StatusInitial()) {
    //on<StatusEvent>((event, emit) => emit(StatusLoading()));
    on<UploadStatusEvent>(_onUploadStatusEvent);
    on<GetAllStatusEvent>(_onGetAllStatusEvent);
    on<UpdateViewEvent>(_onUpdateViewEvent);
    on<UpdateStatusPage>(_updateStatus);
    on<DeleteStatusEvent>(_onDeleteStatus);
    on<AddLikeEvent>(_onAddLikeEvent);
    on<ReplyToStatusEvent>(_onReplyToStatusEvent);
  }

  FutureOr<void> _onUploadStatusEvent(UploadStatusEvent event, Emitter<StatusState> emit) async{
    emit(StatusLoading());
    final res = await _uploadStatus(
      UploadStatusParams(
        image: event.image!, 
        caption: event.caption, 
        userId: event.userId,
        userName: event.userName,
        profilepic: event.profilepic
      ),
    );

    res.fold(
      (l) => emit(StatusFailure(l.message)), 
      (r) => emit(StatusUploadSuccess())
    );
  }

  //fetches the statuses
  FutureOr<void> _onGetAllStatusEvent(GetAllStatusEvent event, Emitter<StatusState> emit) async{
    if(state is! StatusDisplaySuccess){
      emit(StatusLoading());
    }

    final res = (await _getAllStatus(GetAllStatusParams(currentUserId: event.currentUserId)));

    res.fold(
      (l) => emit(StatusFailure(l.message)),
      (r) => _loadStatus(r,emit),
    );
  }

  void _loadStatus(List<Status> r, Emitter emit){
    friendsStream?.cancel();
    final friendsStreamBroadcast = _friendsCubit.stream;
    friendsStream = friendsStreamBroadcast.listen(
      (d){
        if(d is FriendsLoaded){
          final List<Status> updated = <Status>[];
          final current = (state as StatusDisplaySuccess).status;

          for (final s in current) {
            updated.add(
              Status(
                localPath: s.localPath,
                id: s.id, 
                userId: s.userId, 
                imageUrl: s.imageUrl, 
                caption: s.caption, 
                createdAt: s.createdAt, 
                expiresAt: s.expiresAt, 
                userName: d.friends[s.userId]?.name ?? "unknown", 
                profilepic: d.friends[s.userId]?.profilePic ?? "not found",
                likedBy: s.likedBy,
                isViewed: s.isViewed,
              )
            );
          }

          add(UpdateStatusPage(statuses: updated));
        }
    });

    final friends = _friendsCubit.state;
    if(friends is FriendsLoaded){
      final List<Status> updated = <Status>[];

      for (final s in r) {
        updated.add(
          Status(
            localPath: s.localPath,
            id: s.id, 
            userId: s.userId, 
            imageUrl: s.imageUrl, 
            caption: s.caption, 
            createdAt: s.createdAt, 
            expiresAt: s.expiresAt, 
            userName: friends.friends[s.userId]?.name ?? "unknown", 
            profilepic: friends.friends[s.userId]?.profilePic ?? "not found",
            likedBy: s.likedBy,
            isViewed: s.isViewed,
          )
        );
      }
      add(UpdateStatusPage(statuses: updated));
    }
  }

  void _updateStatus(UpdateStatusPage event, Emitter emit){
    emit(StatusDisplaySuccess(event.statuses));
  }

  FutureOr<void> _onUpdateViewEvent(UpdateViewEvent event, Emitter<StatusState> emit) async{
    final res = await _updateView(
      UpdateViewParams(
        statusId: event.statusId,
        viewerId: event.viewerId,
        viewerName: event.viewerName,
      ),
    );

    res.fold(
      (l) => emit(StatusFailure(l.message)),
      (_) {
        if (state is StatusDisplaySuccess) {
          final current = (state as StatusDisplaySuccess).status;
          final updated = current.map((s) {
            if (s.id == event.statusId) {
              return Status(
                id: s.id,
                userId: s.userId,
                imageUrl: s.imageUrl,
                caption: s.caption,
                createdAt: s.createdAt,
                expiresAt: s.expiresAt,
                userName: s.userName,
                profilepic: s.profilepic,
                localPath: s.localPath,
                likedBy: s.likedBy,
                isViewed: true,
              );
            }
            return s;
          }).toList();
          emit(StatusDisplaySuccess(updated));
        }
      },
    );
  }

  FutureOr<void> _onDeleteStatus(DeleteStatusEvent event, Emitter<StatusState> emit) async {
    final res = await _deleteStatus(DeleteStatusParams(statusId: event.statusId));

    res.fold(
      (l) => emit(StatusFailure(l.message)),
      (r) {
        if (state is StatusDisplaySuccess) {
          final updatedList = (state as StatusDisplaySuccess).status
              .where((s) => s.id != event.statusId)
              .toList();
          emit(StatusDisplaySuccess(updatedList));
        } else {
          emit(StatusDeleteSuccess());
        }
      },
    );
  }

  FutureOr<void> _onReplyToStatusEvent(ReplyToStatusEvent event, Emitter<StatusState> emit) async {
    final result = await _chatRepository.sendMessage(
      receiverId: event.receiverId,
      userId: event.userId,
      content: event.content,
      msgId: const Uuid().v1(),
      userName: event.userName,
      userProfile: event.userProfile,
      replyToId: event.statusId,
      replyToContent: jsonEncode({
        'caption': event.statusCaption,
        'imageUrl': event.statusImageUrl,
        'createdAt': event.statusCreatedAt.toIso8601String(),
        'expiresAt': event.statusExpiresAt.toIso8601String(),
        'userName': event.statusUserName,
        'profilepic': event.statusProfilepic,
      }),
      replyToSenderId: event.statusUserId,
      replyToType: "status",
    );
    result.fold(
      (failure) => emit(StatusFailure(failure.message)),
      (_) {},
    );
  }

  FutureOr<void> _onAddLikeEvent(AddLikeEvent event, Emitter<StatusState> emit) async {
    if (state is StatusDisplaySuccess) {
      final current = (state as StatusDisplaySuccess).status;
      final updated = current.map((s) {
        if (s.id == event.statusId) {
          final newLikedBy = List<String>.from(s.likedBy);
          if (newLikedBy.contains(event.userId)) {
            newLikedBy.remove(event.userId);
          } else {
            newLikedBy.add(event.userId);
          }
          return Status(
            id: s.id,
            userId: s.userId,
            imageUrl: s.imageUrl,
            caption: s.caption,
            createdAt: s.createdAt,
            expiresAt: s.expiresAt,
            userName: s.userName,
            profilepic: s.profilepic,
            localPath: s.localPath,
            likedBy: newLikedBy,
            isViewed: s.isViewed,
          );
        }
        return s;
      }).toList();
      emit(StatusDisplaySuccess(updated));
    }

    await _addLike(AddLikeParams(
      statusId: event.statusId,
      userId: event.userId,
    ));
  }
}
