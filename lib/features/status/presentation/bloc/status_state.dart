part of 'status_bloc.dart';

@immutable
sealed class StatusState {}

final class StatusInitial extends StatusState {}

final class StatusLoading extends StatusState{}

final class StatusUploadSuccess extends StatusState{}

final class StatusFailure extends StatusState{
  final String error;
  StatusFailure(this.error);
}

final class StatusDisplaySuccess extends StatusState{
  final List<Status> status;
  StatusDisplaySuccess(this.status);
}