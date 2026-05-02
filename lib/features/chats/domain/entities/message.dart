class Message{
  final String id;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final String type;
  final List<String> deletedfor;
  final bool deletedForEveryone;
  final bool isLocal;
  final String status; 
  final String? localPath;
  final DateTime? sendAt;
  final bool? isScheduled;
  final bool inTimeline;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.deletedfor,
    this.deletedForEveryone = false,
    required this.status,
    this.isLocal = false,
    this.type = "text",
    this.localPath,
    this.sendAt,
    this.isScheduled,
    this.inTimeline=false,
  });
}