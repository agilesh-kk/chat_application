import 'dart:io';

import 'package:chat_application/features/profile/data/model/profile_pic_hive_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ProfilePicProvider {
  static ImageProvider resolve(String? profilePicUrl, {String? userId}) {
    if (profilePicUrl == null || profilePicUrl.isEmpty) {
      return const AssetImage('assets/profile_images/pfp1.png');
    }

    if (profilePicUrl.startsWith('assets/')) {
      return AssetImage(profilePicUrl);
    }

    if (!kIsWeb && userId != null) {
      try {
        final box = Hive.box<ProfilePicHiveModel>('profile_pics');
        final cached = box.get(userId);
        if (cached != null && cached.localPath.isNotEmpty) {
          final file = File(cached.localPath);
          if (file.existsSync()) {
            return FileImage(file);
          }
        }
      } catch (_) {}
    }

    return NetworkImage(profilePicUrl);
  }
}
