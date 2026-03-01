class Status {
  final String id;
  final String userId;
  final String imageUrl;
  final String caption;
  final DateTime createdAt;
  final DateTime expiresAt;

  Status({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
    required this.expiresAt,
  });
}
