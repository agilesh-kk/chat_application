import 'dart:math';
import 'package:chat_application/core/utils/app_images.dart';

String getRandomProfileImage() {
  final random = Random();
  return AppImages.profileImages[
    random.nextInt(AppImages.profileImages.length)
  ];
}