import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/features/chats/domain/usecase/search_user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part "search_events.dart";
part "search_states.dart";

class SearchBloc extends Bloc<SearchEvent,SearchState>{
  final SearchUser searchUser;

  SearchBloc({
    required this.searchUser
  }) : super(SearchInitial())
  {
    on<SearchStart>((event, emit)async {
      emit(Searching());
      final res = await searchUser(event.name);
      
      res.fold(
        (failure)=>emit(SearchInitial()),
        (user) => emit(SearchFound(user: user))
      );
    });
  }
  
}