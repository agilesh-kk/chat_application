import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/show_snackbar.dart';
import 'package:flutter/material.dart';

class TimeCapsulePicker {
  static Future<DateTime?> pick(BuildContext context) async {
    final now = DateTime.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppPallete.primaryOrange,
              onPrimary: AppPallete.whiteColor,
              surface: AppPallete.cardBg,
              onSurface: AppPallete.whiteColor,
            ),
            dialogBackgroundColor: AppPallete.cardBg,
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return null;

    final selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );

    final difference = selectedDateTime.difference(now);

    if (difference.isNegative) {
      _showError(context, "Please select a future time");
      return null;
    }

    if (difference.inHours >= 24) {
      _showError(context, "Time must be within 24 hours");
      return null;
    }

    return selectedDateTime;
  }

  static void _showError(BuildContext context, String msg) {
    showSnackbar(context, msg);
  }
}