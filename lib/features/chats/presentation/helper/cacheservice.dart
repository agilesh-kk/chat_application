import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class CacheService {
  Map<String,Uint8List> cache = {};

  Future<String?> _getPath(String msgId) async {
    if (kIsWeb) return null;
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory("${dir.path}/chat_images");

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    return "${folder.path}/$msgId.jpg";
  }

  // ✅ Used by RECEIVER or fallback
  Future<Uint8List?> getOrDownload(String url, String msgId) async {
    if (kIsWeb) return null;
    final path = await _getPath(msgId);
    if (path == null) return null;
    final file = File(path);

    if(cache.containsKey(msgId)) return cache[msgId]!;

    if (await file.exists()){
      cache[msgId] = await file.readAsBytes();
      return cache[msgId]!;
    }

    await Dio().download(url, path);

    cache[msgId] = await File(path).readAsBytes();

    return cache[msgId]!;
  }

  // ✅ Used by SENDER (skip download)
  Future<Uint8List?> saveLocalFile(XFile image, String msgId) async {
    if (kIsWeb) return null;
    final path = await _getPath(msgId);
    if (path == null) return null;
    final file = File(image.path);
    await file.copy(path);
    cache[msgId] = await file.readAsBytes();

    return cache[msgId]!;
  }
}