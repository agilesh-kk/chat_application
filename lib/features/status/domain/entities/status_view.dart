// ignore_for_file: public_member_api_docs, sort_constructors_first
class StatusView {
  final String id;
  final String statusId;
  final String viewerId;
  final String viewerName;
  final DateTime viewedAt;
  final bool? isLiked;

  StatusView({
    required this.id,
    required this.statusId,
    required this.viewerId,
    required this.viewerName,
    required this.viewedAt,
    this.isLiked = false,
  });

  
}
