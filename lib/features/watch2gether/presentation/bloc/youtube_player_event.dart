import 'package:equatable/equatable.dart';

sealed class YoutubePlayerEvent extends Equatable {
  const YoutubePlayerEvent();

  @override
  List<Object?> get props => [];
}

final class LoadYoutubeVideo extends YoutubePlayerEvent {
  final String url;

  const LoadYoutubeVideo(this.url);

  @override
  List<Object?> get props => [url];
}

final class ResetYoutubePlayer extends YoutubePlayerEvent {
  const ResetYoutubePlayer();
}

final class DisposeYoutubePlayer extends YoutubePlayerEvent {
  const DisposeYoutubePlayer();
}
