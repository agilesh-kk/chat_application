import 'dart:async';

import 'package:chat_application/features/timeline/domain/entities/event.dart';
import 'package:chat_application/features/timeline/domain/usecases/add_personal_event.dart';
import 'package:chat_application/features/timeline/domain/usecases/load_personal_events.dart';
import 'package:chat_application/features/timeline/domain/usecases/remove_personal_event.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

part 'personal_timeline_event.dart';
part 'personal_timeline_state.dart';

class PersonalTimelineBloc
    extends Bloc<PersonalTimelineEvent, PersonalTimelineState> {
  final AddPersonalEvent _addPersonalEvent;
  final LoadPersonalEvents _loadPersonalEvents;
  final RemovePersonalEvent _removePersonalEvent;

  PersonalTimelineBloc({
    required AddPersonalEvent addPersonalEvent,
    required LoadPersonalEvents loadPersonalEvents,
    required RemovePersonalEvent removePersonalEvent,
  })
    :
    _addPersonalEvent = addPersonalEvent,
    _loadPersonalEvents = loadPersonalEvents,
    _removePersonalEvent = removePersonalEvent,
      super(PersonalTimelineInitial()) {
    on<FetchPersonalTimeLine>(_onFetchPersonalTimeLine);
    on<AddPersonalTimeLineEvent>(_addPersonalTimeLineEvent);
    on<RemovePersonalTimelineEvent>(_onRemovePersonalTimelineEvent);
  }

  //fetching the personal timeline
  FutureOr<void> _onFetchPersonalTimeLine(
    FetchPersonalTimeLine event,
    Emitter<PersonalTimelineState> emit,
  ) async {
    emit(PersonalTimeLineLoading());

    final res = await _loadPersonalEvents(
      LoadPersonalEventsParams(
        userId: event.userId
      )
    );

    res.fold(
      (l) => emit(PersonalTimelineError(l.message)), 
      (r) => emit(PersonalTimelineLoaded(r))
    );
  }

  //adding events to personal timeline
  FutureOr<void> _addPersonalTimeLineEvent(
    AddPersonalTimeLineEvent event,
    Emitter<PersonalTimelineState> emit,
  ) async{
    emit(PersonalTimeLineLoading());

    final res = await _addPersonalEvent(
      AddPersonalEventParams(
        title: event.title, 
        userId: event.userId, 
        content: event.content, 
        time: event.time, 
        type: event.type
      )
    );

    res.fold(
      (failure) {
        emit(PersonalTimelineError(failure.message));
      },
      (_) {
        //reloading timeline
        add(
          FetchPersonalTimeLine(
            userId: event.userId,
          ),
        );
      },
    );
  }

  FutureOr<void> _onRemovePersonalTimelineEvent(
    RemovePersonalTimelineEvent event, 
    Emitter<PersonalTimelineState> emit
  ) async {
    try{
      final res = await _removePersonalEvent(
        RemovePersonalTimelineParams(
          eventId: event.eventId,
          userId: event.userId,
        ),
      );
      //print("\n\ninbloc\n");
      res.fold(
        (failure) {
          emit(PersonalTimelineError(failure.message));
        },
        (_) {
          //reloading timeline
          add(
            FetchPersonalTimeLine(
              userId: event.userId,
            ),
          );
        },
      );
    }
    catch(e){
      emit(PersonalTimelineError(e.toString()));
    }
  }
}
