class Message{
  final String id;
  final String senderId;
  final String content;
  final String createdAt;
  final List<String> deletedfor;
  final bool isLocal;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.deletedfor,
    this.isLocal = false
  });
}