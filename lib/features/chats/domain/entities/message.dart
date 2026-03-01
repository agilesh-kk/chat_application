class Message{
  final String id;
  final String senderId;
  final String content;
  final String createdAt;
  final List<String> deletedfor;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.deletedfor
  });
}