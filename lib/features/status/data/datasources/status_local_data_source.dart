import 'dart:io';

import 'package:chat_application/features/status/data/model/status_hive_model.dart';
import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

abstract interface class StatusLocalDataSource {

  Future<List<Status>> getAllStatuses();

  Future<void> updateStatuses(List<StatusHiveModel> statuses);
}

class StatusLocalDataSourceImpl implements StatusLocalDataSource {

  final Box<StatusHiveModel> box;

  StatusLocalDataSourceImpl(this.box);

  @override
  Future<List<Status>> getAllStatuses() async {
    final now = DateTime.now();

    for (final entry in box.toMap().entries) {
      final status = entry.value;
      print(status.localPath);

      if (status.expiresAt.isBefore(now)) {
        File(status.localPath).delete();
        await box.delete(entry.key);
        
      }
    }

    // return remaining
    return box.values.map((e) => e.toEntity()).toList()
    ..sort(
      (e,e1){
        return e1.createdAt.compareTo(e.createdAt);
      }
    );
  }

  @override
  Future<void> updateStatuses(List<StatusHiveModel> statuses) async {
    for (final status in statuses) {
          final localPath = await downloadAndSaveImage(status.imageUrl, status.id);
          await box.put(status.id, status.copyWith(localPath: localPath));
    }
  }

  Future<String> downloadAndSaveImage(String url, String id) async {

    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/status_img');

    if(!await folder.exists()){
      folder.create(recursive: true);
    }

    final file = File('${folder.path}/status_$id.jpg');

    await Dio().download(url, file.path);
    

    return file.path;
  }
}