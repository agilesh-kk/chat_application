import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/features/chats/domain/usecase/search_user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

part "search_events.dart";
part "search_states.dart";

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchUser searchUser;

  SearchBloc({required this.searchUser}) : super(SearchInitial()) {

    on<SearchStart>(
      _onSearchStart,
      transformer: debounce(const Duration(milliseconds: 400)), // ✅ APPLY HERE
    );

    on<ResetSearch>((event, emit) => emit(SearchInitial()));
  }

  // ✅ Debounce transformer
  EventTransformer<T> debounce<T>(Duration duration) {
    return (events, mapper) =>
        events.debounceTime(duration).switchMap(mapper);
  }

  // ✅ Actual logic
  Future<void> _onSearchStart(
    SearchStart event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.name.trim().toLowerCase();

    // 🚫 Stop unnecessary calls
    if (query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(Searching());

    final res = await searchUser(
      SearchUserParams(
        receiverName: event.name, 
        currentUserId: event.currentUserId
      )
    );

    res.fold(
      (failure) => emit(SearchError(failure.toString())),

      // ✅ Expect LIST now
      (users) => emit(SearchFound(user: users)),
    );
  }
}