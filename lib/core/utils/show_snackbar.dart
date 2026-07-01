import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';

enum SnackbarType { info, success, error }

void showSnackbar(
  BuildContext context,
  String content, {
  SnackbarType type = SnackbarType.info,
  Duration? duration,
}) {
  Color bgColor;
  switch (type) {
    case SnackbarType.success:
      bgColor = AppPallete.statusGreen;
    case SnackbarType.error:
      bgColor = AppPallete.errorColor;
    case SnackbarType.info:
      bgColor = AppPallete.primaryOrange;
  }

  final screenWidth = MediaQuery.of(context).size.width;
  const double maxWidth = 480;
  final horizontalMargin = screenWidth > maxWidth + 32
      ? (screenWidth - maxWidth) / 2
      : 16.0;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          content,
          style: const TextStyle(color: AppPallete.whiteColor),
        ),
        duration: duration ?? const Duration(seconds: 2),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: horizontalMargin,
          vertical: 16,
        ),
      ),
    );
}
