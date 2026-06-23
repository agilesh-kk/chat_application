enum W2GVideoSource { youtube, direct }

class W2GVideoItem {
  final String id;
  final String url;
  final String title;
  final String? thumbnailUrl;
  final W2GVideoSource source;
  final String addedBy;
  final DateTime addedAt;

  W2GVideoItem({
    required this.id,
    required this.url,
    required this.title,
    this.thumbnailUrl,
    required this.source,
    required this.addedBy,
    required this.addedAt,
  });

  static W2GVideoSource detectSource(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return W2GVideoSource.youtube;
    }
    return W2GVideoSource.direct;
  }
}
