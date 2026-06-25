import 'package:chat_application/features/watch2gether/domain/entity/youtube_video_data.dart';

abstract interface class YoutubePlayerRepository {
  YoutubeVideoData? parseVideo(String url);
}
