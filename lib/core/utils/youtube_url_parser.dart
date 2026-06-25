import 'package:chat_application/core/utils/video_id_extractor.dart';

class ParsedUrl {
  final String videoId;
  final String originalUrl;
  final String normalizedUrl;
  final String thumbnailUrl;

  ParsedUrl({
    required this.videoId,
    required this.originalUrl,
    required this.normalizedUrl,
    required this.thumbnailUrl,
  });
}

class YoutubeUrlParser {
  static ParsedUrl? parse(String url) {
    final videoId = VideoIdExtractor.extract(url);
    if (videoId == null) return null;
    return ParsedUrl(
      videoId: videoId,
      originalUrl: url,
      normalizedUrl: 'https://www.youtube.com/watch?v=$videoId',
      thumbnailUrl: 'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
    );
  }

  static bool isValid(String url) => VideoIdExtractor.extract(url) != null;
}
