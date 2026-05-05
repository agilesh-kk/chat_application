import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/timeline/domain/entities/event.dart';
import 'package:chat_application/features/timeline/domain/usecases/add_timeline_event.dart';
import 'package:chat_application/features/timeline/domain/usecases/load_events.dart';
import 'package:chat_application/features/timeline/domain/usecases/remove_timeline_event.dart';

part 'timeline_event.dart';
part 'timeline_state.dart';

class TimelineBloc extends Bloc<TimelineEvent, TimelineState> {
  final LoadEvents _loadEvents;
  final AddTimeLineEvent _addTimeLineEvent;
  final RemoveTimelineEvent _removeTimelineEvent;
  bool closed = false;

  TimelineBloc({
    required LoadEvents loadEvents,
    required AddTimeLineEvent addTimeLineEvent,
    required RemoveTimelineEvent removeTimelineEvent,
    //required this.refreshEvents
  }) : _loadEvents = loadEvents,
       _addTimeLineEvent = addTimeLineEvent,
       _removeTimelineEvent = removeTimelineEvent,

       super(TimelineInitial()) {
    on<FetchTimelineEvent>(_onloadTimeline);
    on<AddEvent>(_onAddEvent);
    on<CloseTimeLineEvent>(_closetimeline);
    on<RemoveEvent>(_onRemoveEvent);
  }

  void _onloadTimeline(
    FetchTimelineEvent event,
    Emitter<TimelineState> emit,
  ) async {
    emit(TimelineLoading());
    final res = await _loadEvents(
      LoadEventsParams(userId: event.userId, receiverId: event.receiverId),
    );
    res.fold(
      (l) => emit(TimelineError(l.message)), 
      (r) => emit(TimelineLoaded(r)) 
    );
  }

  void _closetimeline(
    CloseTimeLineEvent event,
    Emitter<TimelineState> emit,
  ) async {
    emit(TimeLineClosed());
  }

  FutureOr<void> _onAddEvent(
    AddEvent event,
    Emitter<TimelineState> emit,
  ) async {
    try {
      final res = await _addTimeLineEvent(
        AddEventParams(
          message: event.message,
          userId: event.userId,
          receiverId: event.receiverId,
          customTitle: event.customTitle,
          addedByName: event.addedByName,
        ),
      );
      res.fold(
        (failure) {
          emit(TimelineError(failure.message));
        },
        (_) {
          //reloading timeline
          add(
            FetchTimelineEvent(
              userId: event.userId,
              receiverId: event.receiverId,
            ),
          );
        },
      );
    } catch (e) {
      emit(TimelineError(e.toString()));
    }
  }

  FutureOr<void> _onRemoveEvent(
    RemoveEvent event,
    Emitter<TimelineState> emit,
  ) async {
    try{
      final res = await _removeTimelineEvent(
        RemoveTimelineParams(
          eventId: event.eventId,
          messageId: event.messageId,
          userId: event.userId,
          receiverId: event.receiverId,
        ),
      );
      //print("\n\ninbloc\n");
      res.fold(
        (failure) {
          emit(TimelineError(failure.message));
        },
        (_) {
          //reloading timeline
          add(
            FetchTimelineEvent(
              userId: event.userId,
              receiverId: event.receiverId,
            ),
          );
        },
      );
    }
    catch(e){
      emit(TimelineError(e.toString()));
    }
  }
}
