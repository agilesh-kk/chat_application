class Conversation {
  final String convoId;
  final String receiverId;
  final String lastMessage;
  final String lastupdateTime;
  final String profilepicLink;
  final String receiverName;
  final int unread;
  final String lastSender;
  final bool receiverIsOnline;

  Conversation({
    required this.convoId,
    required this.receiverId,
    required this.lastMessage,
    required this.lastupdateTime,
    required this.profilepicLink,
    required this.receiverName,
    required this.unread,
    required this.lastSender,
    this.receiverIsOnline = false,
  });
}