import 'dart:async';

import 'package:chat_application/features/status/domain/entities/status_view.dart';
import 'package:chat_application/features/status/domain/usecase/get_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


part 'statusview_event.dart';
part 'statusview_state.dart';

class StatusviewBloc extends Bloc<StatusviewEvent, StatusviewState> {
  final GetViews _getViews;

  StatusviewBloc({
    required GetViews getViews,
  }) :
  _getViews = getViews, 
  super(StatusviewInitial()) {
    on<GetViewEvent>(_onGetViewEvent);
  }

  FutureOr<void> _onGetViewEvent(
  GetViewEvent event,
  Emitter<StatusviewState> emit,
  ) async {

    emit(StatusviewLoading()); // force new state

    final res = await _getViews(
      GetViewParms(statusId: event.statusId),
    );

    res.fold(
      (l) => emit(StatusviewFailure(l.message)),
      (r) => emit(ViewDisplaySuccess(r)),
    );
  }
}
