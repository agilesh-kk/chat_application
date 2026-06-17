import 'package:chat_application/features/watch2gether/domain/entity/w2g_video_item.dart';

class W2GVideoItemModel extends W2GVideoItem {
  W2GVideoItemModel({
    required super.id,
    required super.url,
    required super.title,
    required super.source,
    required super.addedBy,
    required super.addedAt,
  });

  factory W2GVideoItemModel.fromMap(String id, Map<String, dynamic> map) {
    return W2GVideoItemModel(
      id: id,
      url: map['url'] as String? ?? '',
      title: map['title'] as String? ?? '',
      source: map['type'] == 'youtube'
          ? W2GVideoSource.youtube
          : W2GVideoSource.direct,
      addedBy: map['addedBy'] as String? ?? '',
      addedAt: map['addedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['addedAt'] as num).toInt())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'title': title,
      'type': source == W2GVideoSource.youtube ? 'youtube' : 'direct',
      'addedBy': addedBy,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }
}
