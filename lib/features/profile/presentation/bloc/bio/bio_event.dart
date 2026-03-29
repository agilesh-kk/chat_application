part of 'bio_bloc.dart';

@immutable
sealed class BioEvent {}

final class BioUpdate extends BioEvent{
  final String userId;
  final String bio;

  BioUpdate({
    required this.userId, 
    required this.bio
  });

}