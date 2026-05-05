import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

abstract interface class ChatLocalDataSource {
  Future<String?> saveImage(XFile image, String msgId);
  Future<String?> getImage(String msgId);
  Future<void> deleteImage(String msgId);
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {

  Future<String?> _getPath(String msgId) async {
    if (kIsWeb) return null;
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory("${dir.path}/chat_images");

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    return "${folder.path}/$msgId.jpg";
  }

  @override
  Future<String?> saveImage(XFile image, String msgId) async {
    if (kIsWeb) return null;
    final path = await _getPath(msgId);
    if (path == null) return null;
    final file = File(image.path);
    return (await file.copy(path)).path;
  }

  @override
  Future<String?> getImage(String msgId) async {
    final path = await _getPath(msgId);
    if (path == null) return null;
    final file = File(path);

    if (await file.exists()) return path;
    return null;
  }

  @override
  Future<void> deleteImage(String msgId) async {
    final path = await _getPath(msgId);
    if (path == null) return;
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
    }
  }
}