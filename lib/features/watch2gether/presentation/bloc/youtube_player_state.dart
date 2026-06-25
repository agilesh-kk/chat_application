import 'package:chat_application/features/watch2gether/domain/entity/youtube_video_data.dart';
import 'package:equatable/equatable.dart';

sealed class YoutubePlayerState extends Equatable {
  const YoutubePlayerState();

  @override
  List<Object?> get props => [];
}

final class YoutubePlayerInitial extends YoutubePlayerState {
  const YoutubePlayerInitial();
}

final class YoutubePlayerLoading extends YoutubePlayerState {
  const YoutubePlayerLoading();
}

final class YoutubePlayerLoaded extends YoutubePlayerState {
  final YoutubeVideoData videoData;

  const YoutubePlayerLoaded(this.videoData);

  @override
  List<Object?> get props => [videoData];
}

final class YoutubePlayerError extends YoutubePlayerState {
  final String message;

  const YoutubePlayerError(this.message);

  @override
  List<Object?> get props => [message];
}
