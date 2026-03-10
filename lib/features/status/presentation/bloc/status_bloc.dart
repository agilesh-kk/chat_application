import 'dart:async';

import 'package:chat_application/core/usecase/usecase.dart';
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

  StatusBloc({
    required UploadStatus uploadStatus,
    required GetAllStatus getAllStatus,
    required UpdateView updateView,
  }) : 
  _uploadStatus = uploadStatus,
  _getAllStatus = getAllStatus,
  _updateView = updateView,
  super(StatusInitial()) {
    //on<StatusEvent>((event, emit) => emit(StatusLoading()));
    on<UploadStatusEvent>(_onUploadStatusEvent);
    on<GetAllStatusEvent>(_onGetAllStatusEvent);
    on<UpdateViewEvent>(_updateViewEvent);
  }

  FutureOr<void> _onUploadStatusEvent(UploadStatusEvent event, Emitter<StatusState> emit) async{
    emit(StatusLoading());
    final res = await _uploadStatus(
      UploadStatusParams(
        image: event.image!, 
        caption: event.caption, 
        userId: event.userId,
        userName: event.userName,
      ),
    );

    res.fold(
      (l) => emit(StatusFailure(l.message)), 
      (r) => emit(StatusUploadSuccess())
    );
  }

  //fetches the statuses
  FutureOr<void> _onGetAllStatusEvent(GetAllStatusEvent event, Emitter<StatusState> emit) async{
    emit(StatusLoading());
    final res = await _getAllStatus(NoParams());

    return res.fold(
      (l) => emit(StatusFailure(l.message)),
      (r) => emit(StatusDisplaySuccess(r)),
    );
  }

  FutureOr<void> _updateViewEvent(UpdateViewEvent event, Emitter<StatusState> emit) async{
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
