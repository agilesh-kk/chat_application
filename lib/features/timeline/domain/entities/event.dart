class Event {
  final String id;
  final String content;
  final String type;
  final String title;
  final DateTime time;
  final int index;

  // manual adding
  final String messageId;
  final String addedBy;
  final String addedByName;
  final bool isManual;

  //personal timeline image
  final bool hasImage;
  final String imageUrl;
  
  Event({
    required this.id, 
    required this.title, 
    required this.content, 
    required this.type, 
    required this.time, 
    required this.index,

    required this.messageId,
    required this.addedBy,
    required this.addedByName,
    required this.isManual,

    this.imageUrl="",
    this.hasImage=false,
  });
}