import 'package:flutter/material.dart';

class TimeCapsulePicker {
  static Future<DateTime?> pick(BuildContext context) async {
    final now = DateTime.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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

    /// ❌ Past time
    if (difference.isNegative) {
      _showError(context, "Please select a future time");
      return null;
    }

    /// ❌ Beyond 24 hrs
    if (difference.inHours >= 24) {
      _showError(context, "Time must be within 24 hours");
      return null;
    }

    return selectedDateTime;
  }

  static void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}