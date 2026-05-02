import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class MomentsAgo {
  
  static String calculateMomentsAgo(String timestamp) {
    if (timestamp.isEmpty) {
      return "";
    }

    try {
      final DateTime time = DateTime.parse(timestamp).toLocal();
      final DateTime now = DateTime.now();

      final difference = now.difference(time);

      if (difference.inMinutes < 1) {
        return "just now";
      }

      if (difference.inHours < 1) {
        return timeago.format(time);
      }

      if (DateUtils.isSameDay(now, time)) {
        return DateFormat('h:mm a').format(time);
      }

      if (DateUtils.isSameDay(
        now.subtract(const Duration(days: 1)),
        time,
      )) {
        return "Yesterday, ${DateFormat('h:mm a').format(time)}";
      }

      return DateFormat('MMM d, h:mm a').format(time);
    } catch (_) {
      return "";
    }
  }
}