import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class MomentsAgo {
  
  static String calculateMomentsAgo(String timestamp) {
    DateTime time = DateTime.parse(timestamp).toLocal();
    DateTime now = DateTime.now();

    Duration difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return "just now";
    }

    if (difference.inHours < 1) {
      return timeago.format(time);
    }

    if (difference.inHours < 24 &&
        now.day == time.day &&
        now.month == time.month &&
        now.year == time.year) {
      return DateFormat('h:mm a').format(time);
    }

    if (difference.inHours < 48 &&
        now.subtract(const Duration(days: 1)).day == time.day) {
      return "Yesterday, ${DateFormat('h:mm a').format(time)}";
    }

    return DateFormat('dd MMM, h:mm a').format(time);
  }
}