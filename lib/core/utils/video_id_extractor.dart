class VideoIdExtractor {
  static String? extract(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (host.contains('youtu.be')) {
      final segs = uri.pathSegments;
      if (segs.isNotEmpty) return segs.first;
    }
    if (host.contains('youtube.com')) {
      if (uri.path.contains('/embed/') || uri.path.contains('/shorts/')) {
        final segs = uri.pathSegments;
        if (segs.length >= 2) return segs[1];
      }
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }
}
