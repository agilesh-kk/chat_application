import 'package:chat_application/features/status/domain/entities/status_view.dart';

class StatusViewModel extends StatusView {
  StatusViewModel({
    required super.id,
    required super.statusId,
    required super.viewerId,
    required super.viewerName,
    required super.viewedAt,
  });

  factory StatusViewModel.fromJson(Map<String, dynamic> json){
    return StatusViewModel(
      id: json['id'], 
      statusId: json['status_id'], 
      viewerId: json['viewer_id'], 
      viewerName: json['viewer_name'], 
       viewedAt: DateTime.parse(json['viewed_at']),
    );
  }

  Map<String, dynamic> toJson(){
    return{
      'id' : id,
      'status_id' : statusId,
      'viewer_id' : viewerId,
      'viewer_name' : viewerName,
      'viewed_at' : viewedAt.toIso8601String(),
    };
  }

  StatusViewModel copyWith({
    String? id,
    String? statusId,
    String? viewerId,
    String? viewerName,
    DateTime? viewedAt,
  }) {
    return StatusViewModel(
      id: id ?? this.id,
      statusId: statusId ?? this.statusId,
      viewerId: viewerId ?? this.viewerId,
      viewerName: viewerName ?? this.viewerName,
      viewedAt: viewedAt ?? this.viewedAt,
    );
  }
}
