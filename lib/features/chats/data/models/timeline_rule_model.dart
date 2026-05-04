import 'package:cloud_firestore/cloud_firestore.dart';

class TimelineRule {
  final String id;
  final String? messageType;
  final int? occurrence;
  final List<int>? milestones;
  final String title;
  final bool enabled;

  TimelineRule({
    required this.id,
    required this.title,
    required this.enabled,
    this.messageType,
    this.occurrence,
    this.milestones,
  });

  factory TimelineRule.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final conditions = data["conditions"] ?? {};

    return TimelineRule(
      id: doc.id,
      title: data["title"] ?? "",
      enabled: data["enabled"] ?? true,
      messageType: conditions["messageType"],
      occurrence: conditions["occurrence"],
      milestones: conditions["milestones"] != null
          ? List<int>.from(conditions["milestones"])
          : null,
    );
  }
}