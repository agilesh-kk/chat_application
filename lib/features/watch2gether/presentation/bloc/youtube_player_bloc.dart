import 'package:chat_application/features/watch2gether/domain/usecase/load_youtube_video.dart' as usecase;
import 'package:chat_application/features/watch2gether/presentation/bloc/youtube_player_event.dart';
import 'package:chat_application/features/watch2gether/presentation/bloc/youtube_player_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class YoutubePlayerBloc extends Bloc<YoutubePlayerEvent, YoutubePlayerState> {
  final usecase.LoadYoutubeVideo _loadYoutubeVideo;

  YoutubePlayerBloc({required usecase.LoadYoutubeVideo loadYoutubeVideo})
      : _loadYoutubeVideo = loadYoutubeVideo,
        super(const YoutubePlayerInitial()) {
    on<LoadYoutubeVideo>(_onLoadYoutubeVideo);
    on<ResetYoutubePlayer>(_onReset);
    on<DisposeYoutubePlayer>(_onDispose);
  }

  Future<void> _onLoadYoutubeVideo(
    LoadYoutubeVideo event,
    Emitter<YoutubePlayerState> emit,
  ) async {
    emit(const YoutubePlayerLoading());
    final result = await _loadYoutubeVideo(event.url);
    result.fold(
      (failure) => emit(YoutubePlayerError(failure.message)),
      (data) => emit(YoutubePlayerLoaded(data)),
    );
  }

  void _onReset(ResetYoutubePlayer event, Emitter<YoutubePlayerState> emit) {
    emit(const YoutubePlayerInitial());
  }

  void _onDispose(
    DisposeYoutubePlayer event,
    Emitter<YoutubePlayerState> emit,
  ) {
    emit(const YoutubePlayerInitial());
  }
}
