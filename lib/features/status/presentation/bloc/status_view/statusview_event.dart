part of 'statusview_bloc.dart';

@immutable
sealed class StatusviewEvent {}

final class GetViewEvent extends StatusviewEvent{
  final String statusId;

  GetViewEvent({required this.statusId});
}