part of 'w2g_bloc.dart';

sealed class W2GEvent {}

final class W2GLoadRoom extends W2GEvent {
  final String roomId;
  final String currentUserId;
  final String currentUserName;
  final String currentUserProfilePic;
  W2GLoadRoom({
    required this.roomId,
    required this.currentUserId,
    this.currentUserName = '',
    this.currentUserProfilePic = '',
  });
}

final class W2GJoinRoom extends W2GEvent {
  final String roomId;
  final String userId;
  final String userName;
  final String userProfilePic;
  W2GJoinRoom({
    required this.roomId,
    required this.userId,
    required this.userName,
    required this.userProfilePic,
  });
}

final class W2GLeaveRoom extends W2GEvent {
  final String roomId;
  final String userId;
  final bool isHost;
  W2GLeaveRoom({required this.roomId, required this.userId, this.isHost = false});
}

final class W2GDeleteRoom extends W2GEvent {
  final String roomId;
  final String userId;
  W2GDeleteRoom({required this.roomId, required this.userId});
}

final class W2GPlay extends W2GEvent {
  final String roomId;
  final String userId;
  final double position;
  W2GPlay({
    required this.roomId,
    required this.userId,
    required this.position,
  });
}

final class W2GPause extends W2GEvent {
  final String roomId;
  final String userId;
  final double position;
  W2GPause({
    required this.roomId,
    required this.userId,
    required this.position,
  });
}

final class W2GSeek extends W2GEvent {
  final String roomId;
  final String userId;
  final double position;
  W2GSeek({
    required this.roomId,
    required this.userId,
    required this.position,
  });
}

final class W2GSyncPosition extends W2GEvent {
  final String roomId;
  final String userId;
  final double position;
  W2GSyncPosition({
    required this.roomId,
    required this.userId,
    required this.position,
  });
}

final class W2GAddToQueue extends W2GEvent {
  final String roomId;
  final String url;
  final String title;
  final String addedBy;
  W2GAddToQueue({
    required this.roomId,
    required this.url,
    required this.title,
    required this.addedBy,
  });
}

final class W2GRemoveFromQueue extends W2GEvent {
  final String roomId;
  final String itemId;
  W2GRemoveFromQueue({required this.roomId, required this.itemId});
}

final class W2GSendMessage extends W2GEvent {
  final String roomId;
  final String senderId;
  final String senderName;
  final String text;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderId;
  final String? replyToType;
  W2GSendMessage({
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderId,
    this.replyToType,
  });
}

final class W2GSendImage extends W2GEvent {
  final String roomId;
  final String senderId;
  final String senderName;
  final String imagePath;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderId;
  final String? replyToType;
  W2GSendImage({
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.imagePath,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderId,
    this.replyToType,
  });
}

final class W2GCreateRoom extends W2GEvent {
  final String name;
  final String createdBy;
  W2GCreateRoom({required this.name, required this.createdBy});
}

final class W2GLoadRooms extends W2GEvent {
  final String userId;
  W2GLoadRooms({required this.userId});
}

final class W2GJoinRoomByCode extends W2GEvent {
  final String roomId;
  final String userId;
  final String userName;
  final String userProfilePic;
  W2GJoinRoomByCode({
    required this.roomId,
    required this.userId,
    required this.userName,
    this.userProfilePic = '',
  });
}

final class W2GNext extends W2GEvent {
  final String roomId;
  final String userId;
  W2GNext({required this.roomId, required this.userId});
}

final class W2GInviteFriend extends W2GEvent {
  final String roomId;
  final String roomName;
  final String hostId;
  final String hostName;
  final String invitedUserId;
  W2GInviteFriend({
    required this.roomId,
    required this.roomName,
    required this.hostId,
    required this.hostName,
    required this.invitedUserId,
  });
}

final class W2GToggleReaction extends W2GEvent {
  final String roomId;
  final String messageId;
  final String userId;
  final String emoji;
  W2GToggleReaction({
    required this.roomId,
    required this.messageId,
    required this.userId,
    required this.emoji,
  });
}

final class W2GSetTyping extends W2GEvent {
  final String roomId;
  final String userId;
  final bool isTyping;
  W2GSetTyping({required this.roomId, required this.userId, required this.isTyping});
}

class _W2GRoomStreamError extends W2GEvent {
  final String message;
  _W2GRoomStreamError(this.message);
}

class _W2GRoomUpdated extends W2GEvent {
  final W2GRoom room;
  _W2GRoomUpdated(this.room);
}

class _W2GMessagesUpdated extends W2GEvent {
  final List<W2GChatMessage> messages;
  _W2GMessagesUpdated(this.messages);
}

class _W2GTypingUpdated extends W2GEvent {
  final Set<String> typingUserIds;
  _W2GTypingUpdated(this.typingUserIds);
}
