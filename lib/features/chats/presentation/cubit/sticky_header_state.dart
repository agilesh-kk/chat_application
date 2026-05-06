part of 'sticky_header_cubit.dart';

sealed class StickyHeaderState {
  final String? dateLabel;
  final bool showHeader;
  const StickyHeaderState({this.dateLabel, this.showHeader = true});
}

final class StickyHeaderInitial extends StickyHeaderState {
  const StickyHeaderInitial() : super();
}

final class StickyHeaderUpdate extends StickyHeaderState {
  const StickyHeaderUpdate({super.dateLabel, super.showHeader});
}
