import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/timeline/features/timeline/data/models/event_model.dart';
import 'package:chat_application/features/timeline/features/timeline/domain/entities/event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class TimelineRemoteDataSources {
    Future<List<Event>> getEvents({
    required String userId,
    required String receiverId,
  });

  Future<List<Event>> refreshAndfetchEvents({
    required String userId,
    required String receiverId,
  });
}

class TimelineRemoteDataSourcesImpl implements TimelineRemoteDataSources{
  final FirebaseFirestore firebaseFirestore;

  TimelineRemoteDataSourcesImpl({
    required this.firebaseFirestore
  });

  @override
  Future<List<Event>> getEvents({required String userId, required String receiverId}) async {
    String convoId = generateConversationId(userId, receiverId);

    final timelineEvents =  (await firebaseFirestore
                              .collection("Conversations")
                              .doc(convoId)
                              .collection("timeline")
                              .orderBy("time")
                              .get()).docs;

    return timelineEvents.map(
      (e){
        return EventModel.fromJson(e.data(), e.id);
      }
    ).toList();
           
  }

  Future<void> migrateIndexes({
  required String userId,
  required String receiverId,
}) async {
  final convoId = generateConversationId(userId, receiverId);

  final messagesRef = FirebaseFirestore.instance
      .collection("Conversations")
      .doc(convoId)
      .collection("messages");

  const int limit = 200;

  DocumentSnapshot? lastDoc;
  int index = 1;

  while (true) {
    Query query = messagesRef
        .orderBy("createdAt")
        .limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) break;

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {
        "index": index,
      });
      index++;
    }

    await batch.commit();

    lastDoc = snapshot.docs.last;

    if (snapshot.docs.length < limit) break;
  }
}

  @override
Future<List<Event>> refreshAndfetchEvents({
  required String userId,
  required String receiverId,
}) async {
  await migrateIndexes(userId: userId, receiverId: receiverId);

  try{
  final convoId = generateConversationId(userId, receiverId);
  

    final messagesRef = firebaseFirestore
        .collection("Conversations")
        .doc(convoId)
        .collection("messages");

    final timelineRef = firebaseFirestore
        .collection("Conversations")
        .doc(convoId)
        .collection("timeline");

    await firebaseFirestore.runTransaction((transaction) async {
      try{
      final unIndexedQuery = await messagesRef
          .where("index", isNull: true)
          .orderBy("createdAt")
          .get();

      if (unIndexedQuery.docs.isEmpty) return;

      final lastIndexedQuery = await messagesRef
          .orderBy("index", descending: true)
          .limit(1)
          .get();

      int currentIndex = lastIndexedQuery.docs.isEmpty
          ? 0
          : (lastIndexedQuery.docs.first.data()["index"] ?? 0);

      for (var doc in unIndexedQuery.docs) {
        currentIndex++;
        transaction.update(doc.reference, {
          "index": currentIndex,
        });
      }
      }catch(e){
        print(e.toString());
      }
    });

    await deleteCollection(timelineRef);

    final tr = firebaseFirestore
        .collection("Conversations")
        .doc(convoId)
        .collection("timeline");

    await event_generator(messagesRef, tr);


  }catch(e){
    rethrow;
  }


    return await getEvents(
      userId: userId,
      receiverId: receiverId,
    );
}

Future<void> deleteCollection(CollectionReference collection) async {
  const int batchSize = 100;

  QuerySnapshot snapshot = await collection.limit(batchSize).get();

  while (snapshot.docs.isNotEmpty) {
    final batch = FirebaseFirestore.instance.batch();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    snapshot = await collection.limit(batchSize).get();
  }
}


  Future<void> event_generator(final messagesRef, final timelineRef)async {
    final messagesSnapshot =
    await messagesRef.orderBy("index").get();

    final rulesSnapshot = await firebaseFirestore
        .collection("timeline_rules")
        .where("enabled", isEqualTo: true)
        .get();

    final batch = firebaseFirestore.batch();

    Map<String, int> counters = {};

    for (var doc in messagesSnapshot.docs) {
      final data = doc.data();
      final int index = data["index"];
      final DateTime time =
          (data["createdAt"] as Timestamp).toDate();

      for (var ruleDoc in rulesSnapshot.docs) {
        final rule = ruleDoc.data();
        final String ruleId = ruleDoc.id;

        final conditions = rule["conditions"] ?? {};
        print(conditions);

        bool shouldCreate = true;

        // messageType filter
        if (conditions.containsKey("messageType")) {
          if (data["type"] != conditions["messageType"]) {
            shouldCreate = false;
          }
        }

        if (!shouldCreate) continue;

        // counter per rule
        counters[ruleId] = (counters[ruleId] ?? 0) + 1;

        // interval condition
        if (conditions.containsKey("interval")) {
          final int interval = conditions["interval"];

          if (counters[ruleId]! % interval != 0) {
            shouldCreate = false;
          }
        }

        // occurrence condition
        if (conditions.containsKey("occurrence")) {
          if (counters[ruleId] != conditions["occurrence"]) {
            shouldCreate = false;
          }
        }

        if (!shouldCreate) continue;

        final eventId = "${doc.id}_$ruleId";

          String title = rule["title"] ?? "";
          String content = rule["content"] ?? data["content"];

          title = title.replaceAll("{index}", index.toString());
          content = content.replaceAll("{index}", index.toString());

          final event = EventModel(
            id: eventId,
            title: title,
            content: content,
            type: data["type"],
            time: time,
            index: index,
          );

          batch.set(
            timelineRef.doc(eventId),
            event.toJson(),
          );
      }
    }

    await batch.commit();
  }

  String generateConversationId(String user1,String user2){
    final sorted = [user1, user2]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }
  
}