const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendScheduledMessages = functions.pubsub
  .schedule("every 1 minutes")
  .onRun(async (context) => {

    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    console.log("Running scheduler at:", now.toDate());

    const conversationsSnapshot = await db.collection("Conversations").get();

    for (const convoDoc of conversationsSnapshot.docs) {
      const convoRef = convoDoc.ref;

      // 🔍 Get scheduled messages ready to send
      const scheduledSnapshot = await convoRef
        .collection("scheduled_messages")
        .where("sendAt", "<=", now)
        .where("status", "==", "scheduled")
        .get();

      if (scheduledSnapshot.empty) continue;

      const batch = db.batch();

      for (const doc of scheduledSnapshot.docs) {
        const data = doc.data();

        // 🔥 Move message to "messages"
        const messageRef = convoRef
          .collection("messages")
          .doc(doc.id);

        batch.set(messageRef, {
          ...data,
          status: "sent",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // ❌ Delete from scheduled_messages
        batch.delete(doc.ref);

        // 🔥 Update conversation preview
        batch.set(convoRef, {
          lastMessage: data.content,
          lastupdateTime: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      }

      // ✅ Commit batch for this conversation
      await batch.commit();
    }

    console.log("Scheduler completed");
    return null;
  });