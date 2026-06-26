import 'package:chat_application/features/chats/data/models/timeline_rule_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimelineService {
  final FirebaseFirestore firestore;

  TimelineService(this.firestore);

  List<TimelineRule> _cachedRules = [];
  bool _rulesLoaded = false;

  // =========================
  // 🔥 LOAD RULES (ONCE)
  // =========================
  Future<void> _loadRules() async {
    if (_rulesLoaded) return;

    final snapshot = await firestore
        .collection("timeline_rules")
        .where("enabled", isEqualTo: true)
        .get();

    _cachedRules =
        snapshot.docs.map((e) => TimelineRule.fromDoc(e)).toList();

    _rulesLoaded = true;
  }

  // =========================
  // 🔥 MAIN ENTRY FUNCTION
  // =========================
  Future<bool> handleMessage({
    required String messageId,
    required String senderId,
    required String receiverId,
    required String type,
    required String content,
    required Timestamp createdAt,
    bool isFromScheduler = false,
  }) async {
    if (isFromScheduler) return false;
    await _loadRules();

    final convoId = _generateConversationId(senderId, receiverId);

    final convoRef =
        firestore.collection("Conversations").doc(convoId);

    final counterRef =
        convoRef.collection("rule_counters").doc("counters");

    final timelineRef =
        convoRef.collection("timeline");

    Map<String, dynamic> counters = {};
    List<Map<String, dynamic>> triggeredEvents = [];

    // =========================
    // 🔥 SINGLE TRANSACTION
    // =========================
    await firestore.runTransaction((tx) async {
      final snap = await tx.get(counterRef);

      final data = snap.data() ?? {};

      int total = (data["totalMessages"] ?? 0) + 1;
      int text = data["textMessages"] ?? 0;
      int image = data["imageMessages"] ?? 0;

      if (type == "text") text++;
      if (type == "image") image++;

      counters = {
        "totalMessages": total,
        "textMessages": text,
        "imageMessages": image,
      };

      // ✅ SINGLE WRITE
      tx.set(counterRef, counters, SetOptions(merge: true));

      // =========================
      // 🔥 RULE ENGINE (NO DB READ)
      // =========================
      for (final rule in _cachedRules) {
        if (!rule.enabled) continue;

        // 🔹 message type filter
        if (rule.messageType != null && rule.messageType != type) {
          continue;
        }

        int value;

        if (rule.messageType == "image") {
          value = image;
        } else if (rule.messageType == "text") {
          value = text;
        } else {
          value = total;
        }

        bool shouldTrigger = false;

        // 🔹 occurrence rule
        if (rule.occurrence != null && value == rule.occurrence) {
          shouldTrigger = true;
        }

        // 🔹 milestone rule
        if (rule.milestones != null &&
            rule.milestones!.contains(value)) {
          shouldTrigger = true;
        }

        if (!shouldTrigger) continue;

        triggeredEvents.add({
          "rule": rule,
          "value": value,
        });
      }

      // =========================
      // 🔥 CREATE TIMELINE EVENTS
      // =========================
      for (final event in triggeredEvents) {
        final rule = event["rule"] as TimelineRule;
        final value = event["value"];

        final eventId = "${messageId}_${rule.id}";

        final eventDoc = timelineRef.doc(eventId);

        String title =
            rule.title.replaceAll("{index}", value.toString());

        tx.set(eventDoc, {
          "id": eventId,
          "title": title,
          "content": content,
          "type": type,
          "time": createdAt,
          "index": value,
          "messageId": messageId,
        });
      }
    });

    return triggeredEvents.isNotEmpty;
  }

  // =========================
  // 🔥 CONVO ID
  // =========================
  String _generateConversationId(String u1, String u2) {
    final sorted = [u1, u2]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }
}