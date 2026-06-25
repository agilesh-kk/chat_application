import 'package:chat_application/core/utils/youtube_url_parser.dart';
import 'package:chat_application/features/watch2gether/data/repository/youtube_player_repository.dart';
import 'package:chat_application/features/watch2gether/domain/entity/youtube_video_data.dart';

class YoutubePlayerRepositoryImpl implements YoutubePlayerRepository {
  @override
  YoutubeVideoData? parseVideo(String url) {
    final parsed = YoutubeUrlParser.parse(url);
    if (parsed == null) return null;
    return YoutubeVideoData(
      videoId: parsed.videoId,
      originalUrl: parsed.originalUrl,
      normalizedUrl: parsed.normalizedUrl,
      thumbnailUrl: parsed.thumbnailUrl,
    );
  }
}
