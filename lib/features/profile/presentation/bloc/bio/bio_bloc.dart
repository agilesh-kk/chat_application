import 'dart:async';

import 'package:chat_application/features/friends/presentation/friends_cubit.dart';
import 'package:chat_application/features/profile/domain/usecase/update_bio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'bio_event.dart';
part 'bio_state.dart';

class BioBloc extends Bloc<BioEvent, BioState> {
  final UpdateBio _updateBio;
  BioBloc({
    required UpdateBio updateBio,
  }) : 
  _updateBio = updateBio,
  super(BioInitial()) {
    on<BioEvent>((event, emit) {});
    on<BioUpdate>(_onUpdateBio);
  }
  

  FutureOr<void> _onUpdateBio(BioUpdate event, Emitter<BioState> emit) async{
    final res = await _updateBio(
      UpdateBioParams(
        bio: event.bio, 
        userId: event.userId
      )
    );
    
    return res.fold(
      (failure) => emit(BioUpdateFailure(failure.message)), 
      (_) => emit(BioUpdateSuccess(bio: event.bio)),
    );
  }
}
