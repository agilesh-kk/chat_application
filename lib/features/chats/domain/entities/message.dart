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
  final bool isEdited;
  final Map<String, String> reactions;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderId;
  final String? replyToType;

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
    this.isEdited = false,
    this.reactions = const {},
    this.replyToId,
    this.replyToContent,
    this.replyToSenderId,
    this.replyToType,
  });

  Message copyWith({
    String? id,
    String? senderId,
    String? content,
    DateTime? createdAt,
    String? type,
    List<String>? deletedfor,
    bool? deletedForEveryone,
    bool? isLocal,
    String? status,
    String? localPath,
    DateTime? sendAt,
    bool? isScheduled,
    bool? inTimeline,
    bool? isEdited,
    Map<String, String>? reactions,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
    String? replyToType,
  }) =>
      Message(
        id: id ?? this.id,
        senderId: senderId ?? this.senderId,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        type: type ?? this.type,
        deletedfor: deletedfor ?? this.deletedfor,
        deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
        isLocal: isLocal ?? this.isLocal,
        status: status ?? this.status,
        localPath: localPath ?? this.localPath,
        sendAt: sendAt ?? this.sendAt,
        isScheduled: isScheduled ?? this.isScheduled,
        inTimeline: inTimeline ?? this.inTimeline,
        isEdited: isEdited ?? this.isEdited,
        reactions: reactions ?? this.reactions,
        replyToId: replyToId ?? this.replyToId,
        replyToContent: replyToContent ?? this.replyToContent,
        replyToSenderId: replyToSenderId ?? this.replyToSenderId,
        replyToType: replyToType ?? this.replyToType,
      );
}