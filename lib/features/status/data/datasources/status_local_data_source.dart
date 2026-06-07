import 'dart:io';

import 'package:chat_application/features/status/data/model/status_hive_model.dart';
import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class StatusLocalDataSource {

  Future<List<Status>> getAllStatuses();

  Future<void> updateStatuses(List<StatusHiveModel> statuses);

  Future<bool> isEmpty();

  Future<DateTime?> getLastFetchTime();

  Future<void> setLastFetchTime(DateTime time);

  Future<void> saveStatus(StatusHiveModel status);

  Future<void> markAsViewed(String statusId);

  Future<void> deleteById(String statusId);
}

class StatusLocalDataSourceImpl implements StatusLocalDataSource {

  final Box<StatusHiveModel>? box;

  StatusLocalDataSourceImpl(this.box);

  @override
  Future<List<Status>> getAllStatuses() async {
    if (kIsWeb || box == null) {
      return [];
    }

    final now = DateTime.now();
    final List<String> toDelete = [];

    for (final entry in box!.toMap().entries) {
      final status = entry.value;

      if (status.expiresAt.isBefore(now)) {
        toDelete.add(entry.key);
      }
    }

    for (final key in toDelete) {
      await box!.delete(key);
    }

    return box!.values.map((e) => e.toEntity()).toList()
      ..sort(
        (e, e1) {
          return e1.createdAt.compareTo(e.createdAt);
        },
      );
  }

  @override
  Future<void> updateStatuses(List<StatusHiveModel> statuses) async {
    if (kIsWeb || box == null) {
      return;
    }

    final existingIsViewed = <String, bool>{};
    for (final entry in box!.toMap().entries) {
      existingIsViewed[entry.key] = entry.value.isViewed;
    }

    await box!.clear();

    for (final status in statuses) {
      final mergedIsViewed = existingIsViewed[status.id] == true || status.isViewed;
      final localPath = await downloadAndSaveImage(status.imageUrl, status.id);
      await box!.put(status.id, status.copyWith(localPath: localPath, isViewed: mergedIsViewed));
    }
  }

  @override
  Future<bool> isEmpty() async {
    if (kIsWeb || box == null) return true;

    final now = DateTime.now();
    for (final entry in box!.toMap().entries) {
      if (!entry.value.expiresAt.isBefore(now)) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<DateTime?> getLastFetchTime() async {
    if (kIsWeb) return null;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('status_last_fetch_time');
    if (stored == null) return null;
    return DateTime.tryParse(stored);
  }

  @override
  Future<void> setLastFetchTime(DateTime time) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('status_last_fetch_time', time.toIso8601String());
  }

  @override
  Future<void> saveStatus(StatusHiveModel status) async {
    if (kIsWeb || box == null) return;
    final localPath = await downloadAndSaveImage(status.imageUrl, status.id);
    await box!.put(status.id, status.copyWith(localPath: localPath));
  }

  @override
  Future<void> markAsViewed(String statusId) async {
    if (kIsWeb || box == null) return;
    final existing = box!.get(statusId);
    if (existing != null) {
      await box!.put(statusId, existing.copyWith(isViewed: true));
    }
  }

  @override
  Future<void> deleteById(String statusId) async {
    if (kIsWeb || box == null) return;
    await box!.delete(statusId);
  }

  Future<String?> downloadAndSaveImage(String url, String id) async {
    if (kIsWeb) return null;
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/status_img');

    if(!await folder.exists()){
      folder.create(recursive: true);
    }

    final file = File('${folder.path}/status_$id.jpg');

    try {
      await Dio().download(url, file.path);
    } catch (_) {
      return null;
    }

    return file.path;
  }
}
