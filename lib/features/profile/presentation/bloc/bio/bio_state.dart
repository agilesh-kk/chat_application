part of 'bio_bloc.dart';

@immutable
sealed class BioState {}

final class BioInitial extends BioState {}

class BioUpdateSuccess extends BioState{
  final String bio;

  BioUpdateSuccess({required this.bio});
}

class BioUpdateFailure extends BioState{
  final String messsage;

  BioUpdateFailure(this.messsage);
}