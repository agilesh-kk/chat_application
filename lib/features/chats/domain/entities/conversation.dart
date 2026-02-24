class Conversation {
  final String convoId;
  final List<String> participantsId;
  final String lastMessage;
  final String lastupdateTime;

  Conversation({
    required this.convoId,
    required this.participantsId,
    required this.lastMessage,
    required this.lastupdateTime
  });
}