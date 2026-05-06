import 'dart:async';

import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/friends/presentation/friends_cubit.dart';
import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:chat_application/features/status/domain/usecase/get_all_status.dart';
import 'package:chat_application/features/status/domain/usecase/update_view.dart';
import 'package:chat_application/features/status/domain/usecase/upload_status.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';


part 'status_event.dart';
part 'status_state.dart';

class StatusBloc extends Bloc<StatusEvent, StatusState> {
  final UploadStatus _uploadStatus;
  final GetAllStatus _getAllStatus;
  final UpdateView _updateView;
  final FriendsCubit _friendsCubit;
  StreamSubscription? friendsStream;
  

  StatusBloc({
    required UploadStatus uploadStatus,
    required GetAllStatus getAllStatus,
    required UpdateView updateView,
    required FriendsCubit friends_cubit,
  }) : 
  _uploadStatus = uploadStatus,
  _getAllStatus = getAllStatus,
  _updateView = updateView,
  _friendsCubit = friends_cubit,
  
  super(StatusInitial()) {
    //on<StatusEvent>((event, emit) => emit(StatusLoading()));
    on<UploadStatusEvent>(_onUploadStatusEvent);
    on<GetAllStatusEvent>(_onGetAllStatusEvent);
    on<UpdateViewEvent>(_onUpdateViewEvent);
    on<UpdateStatusPage>(_updateStatus);
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

    final res = (await _getAllStatus(NoParams()));

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
          print(s.localPath);
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
              profilepic: d.friends[s.userId]?.profilePic ?? "not found"
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
              profilepic: friends.friends[s.userId]?.profilePic ?? "not found"
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
    await _updateView(
      UpdateViewParams(
        statusId: event.statusId,
        viewerId: event.viewerId,
        viewerName: event.viewerName,
        //viewedAt: event.viewedAt,
      ),
    );

    // res.fold(
    //   (l) => emit(StatusFailure(l.message)),
    //   (_) => emit(UpdateViewSuccess()),
    // );
  }

}
