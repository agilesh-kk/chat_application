part of 'search_bloc.dart';

abstract class SearchEvent {}

class SearchStart extends SearchEvent {
  final String name;
  final String currentUserId;
  SearchStart({
    required this.name,
    required this.currentUserId,
  });
}

