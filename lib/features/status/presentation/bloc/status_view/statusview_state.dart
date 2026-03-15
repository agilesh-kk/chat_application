part of 'statusview_bloc.dart';

@immutable
sealed class StatusviewState {}

final class StatusviewInitial extends StatusviewState {}

final class StatusviewLoading extends StatusviewState {}

final class StatusviewFailure extends StatusviewState{
  final String error;
  StatusviewFailure(this.error);
}

final class ViewDisplaySuccess extends StatusviewState{
  final List<StatusView> statusView;
  ViewDisplaySuccess(this.statusView);
}