part of 'nav_page_index_cubit.dart';

@immutable
sealed class NavPageState {}

final class NavPageInitial extends NavPageState {
  final int index = 0;
}

final class NavPageChanged extends NavPageState {
  final int index;
  NavPageChanged({required this.index});
}
