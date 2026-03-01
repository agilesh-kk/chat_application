class Conversation {
  final String convoId;
  final String receiverId;
  final String lastMessage;
  final String lastupdateTime;
  final String profilepicLink;
  final String receiverName;

  Conversation({
    required this.convoId,
    required this.receiverId,
    required this.lastMessage,
    required this.lastupdateTime,
    required this.profilepicLink,
    required this.receiverName
  });
}