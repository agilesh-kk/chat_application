import 'dart:io';

import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:chat_application/features/profile/data/model/profile_pic_hive_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

abstract interface class ProfilePicLocalDataSource {
  Future<String?> getLocalPath(String userId);

  Future<ProfilePicHiveModel?> getProfilePic(String userId);

  Future<void> saveProfilePic(ProfilePicHiveModel model);

  Future<void> updateProfilePic(String userId, String newUrl);

  Future<void> deleteProfilePic(String userId);

  Future<void> cacheFriendsProfilePics(Map<String, FriendModel> friends);

  Future<void> clearCacheForRemovedFriends(Set<String> activeFriendIds);

  Future<String?> downloadAndSaveImage(String url, String userId);
}

class ProfilePicLocalDataSourceImpl implements ProfilePicLocalDataSource {
  final Box<ProfilePicHiveModel> box;

  static const _cacheFolder = 'profile_pics';

  ProfilePicLocalDataSourceImpl(this.box);

  @override
  Future<String?> getLocalPath(String userId) async {
    if (kIsWeb) return null;
    final cached = box.get(userId);
    if (cached == null || cached.localPath.isEmpty) return null;
    final file = File(cached.localPath);
    if (await file.exists()) return cached.localPath;
    return null;
  }

  @override
  Future<ProfilePicHiveModel?> getProfilePic(String userId) async {
    if (kIsWeb) return null;
    return box.get(userId);
  }

  @override
  Future<void> saveProfilePic(ProfilePicHiveModel model) async {
    if (kIsWeb) return;
    await box.put(model.userId, model);
  }

  @override
  Future<void> updateProfilePic(String userId, String newUrl) async {
    if (kIsWeb) return;
    final existing = box.get(userId);
    if (existing != null && existing.profilePicUrl == newUrl) return;

    final localPath = await downloadAndSaveImage(newUrl, userId);
    await box.put(
      userId,
      ProfilePicHiveModel(
        userId: userId,
        profilePicUrl: newUrl,
        localPath: localPath ?? '',
        lastUpdated: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> deleteProfilePic(String userId) async {
    if (kIsWeb) return;
    final cached = box.get(userId);
    if (cached != null && cached.localPath.isNotEmpty) {
      final file = File(cached.localPath);
      if (await file.exists()) await file.delete();
    }
    await box.delete(userId);
  }

  @override
  Future<void> cacheFriendsProfilePics(Map<String, FriendModel> friends) async {
    if (kIsWeb) return;
    for (final entry in friends.entries) {
      final friendId = entry.key;
      final friend = entry.value;
      final url = friend.profilePic;

      if (url.startsWith('assets/')) continue;

      final cached = box.get(friendId);
      if (cached != null && cached.profilePicUrl == url) continue;

      final localPath = await downloadAndSaveImage(url, friendId);
      if (localPath != null) {
        await box.put(
          friendId,
          ProfilePicHiveModel(
            userId: friendId,
            profilePicUrl: url,
            localPath: localPath,
            lastUpdated: DateTime.now(),
          ),
        );
      }
    }
  }

  @override
  Future<void> clearCacheForRemovedFriends(Set<String> activeFriendIds) async {
    if (kIsWeb) return;
    final cachedIds = box.keys.toSet();
    final removedIds = cachedIds.difference(activeFriendIds);

    for (final id in removedIds) {
      await deleteProfilePic(id);
    }
  }

  @override
  Future<String?> downloadAndSaveImage(String url, String userId) async {
    if (kIsWeb || url.isEmpty || url.startsWith('assets/')) return null;

    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/$_cacheFolder');
    final file = File('${folder.path}/pfp_$userId.jpg');

    if (await file.exists()) {
      return file.path;
    }

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    try {
      await Dio().download(url, file.path);
    } catch (_) {
      return null;
    }

    return file.path;
  }
}
