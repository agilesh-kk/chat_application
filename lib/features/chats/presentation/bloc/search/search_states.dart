part of "search_bloc.dart";


abstract class SearchState {}

class SearchInitial extends SearchState {}

class Searching extends SearchState {}

class SearchFound extends SearchState {
  final User? user;
  SearchFound({
    required this.user,
  });
}

class SearchError extends SearchState {
  final String message;
  SearchError(this.message);
}