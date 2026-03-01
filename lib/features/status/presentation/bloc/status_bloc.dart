import 'dart:async';

import 'package:chat_application/features/status/domain/usecase/upload_status.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';


part 'status_event.dart';
part 'status_state.dart';

class StatusBloc extends Bloc<StatusEvent, StatusState> {
  final UploadStatus _uploadStatus;

  StatusBloc({
    required UploadStatus uploadStatus,
  }) : 
  _uploadStatus = uploadStatus,
  super(StatusInitial()) {
    on<StatusEvent>((event, emit) => emit(StatusLoading()));
    on<UploadStatusEvent>(_onUploadStatusEvent);
  }

  FutureOr<void> _onUploadStatusEvent(UploadStatusEvent event, Emitter<StatusState> emit) async{
    final res = await _uploadStatus(
      UploadStatusParams(
        image: event.image!, 
        caption: event.caption, 
        userId: event.userId
      ),
    );

    res.fold(
      (l) => emit(StatusFailure(l.message)), 
      (r) => emit(StatusUploadSuccess())
    );
  }
}
