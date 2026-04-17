import 'package:bloc/bloc.dart';
import 'package:chat_application/features/timeline/domain/entities/event.dart';
import 'package:chat_application/features/timeline/domain/usecases/load_events.dart';
import 'package:chat_application/features/timeline/domain/usecases/refresh_events.dart';


part 'timeline_event.dart';
part 'timeline_state.dart';

class TimelineBloc extends Bloc<TimelineEvent, TimelineState> {
  final LoadEvents loadEvents;
  final RefreshEvents refreshEvents;
  bool closed = false;

  TimelineBloc({
    required this.loadEvents,
    required this.refreshEvents
  }) : super(TimelineInitial()) {
    on<FetchTimelineEvent>(loadTimeline);
    on<RefreshTimelineEvent>(refreshTimeline);
    on<CloseTimeLineEvent>(_closetimeline);
  }

  void loadTimeline(FetchTimelineEvent event, Emitter<TimelineState> emit)async {
    emit(TimelineLoading());
    final res = await loadEvents(
      LoadEventsParams(userId: event.userId, receiverId: event.receiverId)
    );


      res.fold(
      (l) => emit(TimelineError(l.message)),
      (r) {
        if(r.isEmpty){
          add(RefreshTimelineEvent(userId: event.userId, receiverId: event.receiverId));
        }else{
          emit(TimelineLoaded(r));
        }
      }
    );
  }

  void refreshTimeline(RefreshTimelineEvent event, Emitter<TimelineState> emit)async{
    emit(TimelineLoading());
    final res = await refreshEvents(
      RefreshEventsParams(userId: event.userId, receiverId: event.receiverId)
    );

      res.fold(
      (l) => emit(TimelineError(l.message)),
      (r) {
        if(r.isEmpty){
          emit(TimelineError("Nothing To Show"));
        }else{
          emit(TimelineLoaded(r));
        }
      }
    );
  }

  void _closetimeline(CloseTimeLineEvent event, Emitter<TimelineState> emit)async {
    emit(TimeLineClosed());
  }
}
