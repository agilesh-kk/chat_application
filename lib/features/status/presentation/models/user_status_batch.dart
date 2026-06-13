import 'package:chat_application/features/status/domain/entities/status.dart';

class UserStatusBatch {
  final String userId;
  final String userName;
  final String profilePic;
  final List<Status> statuses;

  UserStatusBatch({
    required this.userId,
    required this.userName,
    required this.profilePic,
    required this.statuses,
  });
}
