class YoutubeVideoData {
  final String videoId;
  final String? title;
  final String? thumbnailUrl;
  final String? originalUrl;
  final String? normalizedUrl;

  YoutubeVideoData({
    required this.videoId,
    this.title,
    this.thumbnailUrl,
    this.originalUrl,
    this.normalizedUrl,
  });
}
