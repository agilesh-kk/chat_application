import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CacheService {
  final Map<String, Uint8List> cache = {};

  Future<Uint8List?> getOrDownload(String url, String id) async {
    if (cache.containsKey(id)) {
      return cache[id];
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        cache[id] = bytes;
        return bytes;
      }
    } catch (_) {}
    return null;
  }
}
