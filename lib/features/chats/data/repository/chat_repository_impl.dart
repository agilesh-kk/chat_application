import 'dart:async';

import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/chats/data/datasources/chat_local_data_sources.dart';
import 'package:chat_application/features/chats/data/datasources/chat_remote_data_sources.dart';
import 'package:chat_application/features/chats/domain/entities/conversation.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSources chatRemoteDataSources;
  final ChatLocalDataSource chatLocalDataSource;

  StreamSubscription<Map<String, dynamic>>? _opSub;

  ChatRepositoryImpl({
    required this.chatRemoteDataSources,
    required this.chatLocalDataSource,
  });

  @override
  Future<Either<Failure, Stream<List<Conversation>>>> getConversations({
    required String userId,
  }) async {
    try {
      Stream<List<Conversation>> res = await chatRemoteDataSources
          .getConversations(userId: userId);
      return right(res);
    } on ServerExceptions catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, Stream<List<Message>>>> getMessages({
    required String receiverId,
    required String userId,
  }) async {
    try {
      final convoId = generateConversationId(userId, receiverId);

      await chatLocalDataSource.initDatabase();

      // Initial load if local DB is empty
      final hasLocal = await chatLocalDataSource.hasMessages(convoId);
      if (!hasLocal) {
        final docs = await chatRemoteDataSources.fetchAllMessages(
          conversationId: convoId,
        );
        if (docs.isNotEmpty) {
          final docIds = docs.map((d) => d['_docId'] as String).toList();
          await chatLocalDataSource.bulkInsertMessages(docs, docIds);
        }
      }

      // Start operation listener in background
      startOperationListener(userId: userId, receiverId: receiverId);

      return right(chatLocalDataSource.getMessagesStream(convoId));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<void> startOperationListener({
    required String userId,
    required String receiverId,
  }) async {
    await _opSub?.cancel();
    final convoId = generateConversationId(userId, receiverId);
    final opCollection = _getOtherOpCollection(userId, receiverId);

    final stream = await chatRemoteDataSources.listenToOperations(
      conversationId: convoId,
      opCollection: opCollection,
    );

    _opSub = stream.listen(
      (opData) async {
        await _processOperation(opData, convoId, opCollection);
      },
      onError: (error) {
        // Operation listener error (e.g., permissions) - log and retry is handled by Firestore SDK
      },
    );
  }

  @override
  Future<void> stopOperationListener() async {
    await _opSub?.cancel();
    _opSub = null;
  }

  Future<void> _processOperation(
    Map<String, dynamic> opData,
    String convoId,
    String opCollection,
  ) async {
    final type = opData['type'] as String?;
    final docId = opData['_docId'] as String?;

    if (type == null || docId == null) return;

    try {
      switch (type) {
        case 'new_message':
          await chatLocalDataSource.upsertMessageFromFirestore(opData, docId);
          break;

        case 'delete_message':
          final msgId = opData['messageId'] as String? ?? docId;
          final deletedfor = List<String>.from(opData['deletedfor'] ?? []);
          final deletedForEveryone = opData['deletedForEveryone'] ?? false;
          await chatLocalDataSource.updateMessageDeletion(
            msgId, deletedfor, deletedForEveryone,
          );
          break;

        case 'reaction':
          final msgId = opData['messageId'] as String? ?? docId;
          final userId = opData['userId'] as String;
          final emoji = opData['emoji'] as String;
          final reactions = Map<String, String>.from(opData['reactions'] as Map? ?? {});

          await chatLocalDataSource.updateMessageReaction(msgId, reactions, emoji, userId);
          break;

        case 'seen':
          final msgIds = List<String>.from(opData['messageIds'] ?? []);
          final seenByUserId = opData['seenByUserId'] as String? ?? '';
          if (msgIds.isNotEmpty) {
            await chatLocalDataSource.markMessagesSeen(msgIds, seenByUserId);
          }
          break;

        case 'timeline':
          final msgId = opData['messageId'] as String? ?? docId;
          final added = opData['addedToTimeline'] as bool? ?? false;
          await chatLocalDataSource.updateMessageTimeline(msgId, added);
      }

      // Delete the operation after successful processing
      await chatRemoteDataSources.deleteOperation(
        conversationId: convoId,
        opCollection: opCollection,
        opId: docId,
      );
    } catch (e) {
      // If processing fails, don't delete the op - it will be retried
    }
  }

  @override
  Future<Either<Failure, void>> sendMessage({
    required String receiverId,
    required String userId,
    required String content,
    required String msgId,
    String? userName,
    String? userProfile,
    DateTime? sendAt,
    bool isScheduled = false,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
    String? replyToType,
  }) async {
    try {
      final opCollection = _getMyOpCollection(userId, receiverId);

      if (!isScheduled) {
        final convoId = generateConversationId(userId, receiverId);
        chatLocalDataSource.confirmLocalMessage(msgId, {
          'senderId': userId,
          'content': content,
          'type': 'text',
          'messageType': 'text',
          'status': 'sent',
          'createdAt': DateTime.now(),
          'deletedfor': <String>[],
          'deletedForEveryone': false,
          'reactions': <String, String>{},
          'replyToId': replyToId,
          'replyToContent': replyToContent,
          'replyToSenderId': replyToSenderId,
          'replyToType': replyToType,
          'isScheduled': false,
          'inTimeline': false,
          'name': userName ?? 'Unknown',
          'receiverId': receiverId,
          'profile': userProfile,
          'convoId': convoId,
        });
      }

      await chatRemoteDataSources.sendMessage(
        receiverId: receiverId,
        userId: userId,
        content: content,
        userName: userName,
        userProfile: userProfile,
        msgId: msgId,
        sendAt: sendAt,
        replyToId: replyToId,
        replyToContent: replyToContent,
        replyToSenderId: replyToSenderId,
        replyToType: replyToType,
        opCollection: isScheduled ? null : opCollection,
      );

      return right(null);
    } on ServerExceptions catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> sendImage({
    required String receiverId,
    required String userId,
    required XFile image,
    required String msgId,
    String? userName,
    String? userProfile,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
    String? replyToType,
  }) async {
    try {
      await chatLocalDataSource.saveImage(image, msgId);

      final imageUrl = await chatRemoteDataSources.uploadImage(
        image: image,
        msgId: msgId,
      );

      // Confirm local message
      final convoId = generateConversationId(userId, receiverId);
      await chatLocalDataSource.confirmLocalMessage(msgId, {
        'senderId': userId,
        'content': imageUrl,
        'type': 'image',
        'messageType': 'image',
        'status': 'sent',
        'createdAt': DateTime.now(),
        'deletedfor': <String>[],
        'deletedForEveryone': false,
        'reactions': <String, String>{},
        'replyToId': replyToId,
        'replyToContent': replyToContent,
        'replyToSenderId': replyToSenderId,
        'replyToType': replyToType,
        'isScheduled': false,
        'inTimeline': false,
        'name': userName ?? 'Unknown',
        'receiverId': receiverId,
        'profile': userProfile,
        'convoId': convoId,
      });

      await chatRemoteDataSources.sendMessage(
        type: "image",
        receiverId: receiverId,
        userId: userId,
        msgId: msgId,
        content: imageUrl,
        userName: userName,
        userProfile: userProfile,
        replyToId: replyToId,
        replyToContent: replyToContent,
        replyToSenderId: replyToSenderId,
        replyToType: replyToType,
        opCollection: _getMyOpCollection(userId, receiverId),
      );

      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<void> deleteMessage({
    required String msgId,
    required String userId,
    required String receiverId,
    required String type,
    bool deleteForEveryone = false,
  }) async {
    try {
      await chatRemoteDataSources.deleteMessage(
        msgId: msgId,
        userId: userId,
        receiverId: receiverId,
        deleteForEveryone: deleteForEveryone,
        opCollection: _getMyOpCollection(userId, receiverId),
      );

      // Update local DB
      if (deleteForEveryone) {
        await chatLocalDataSource.updateMessageDeletion(
          msgId, [userId, receiverId], true,
        );
      } else {
        await chatLocalDataSource.updateMessageDeletion(
          msgId, [userId], false,
        );
      }

      if (type == "image") {
        await chatLocalDataSource.deleteImage(msgId);
      }
    } catch (e) {
      throw ServerExceptions(e.toString());
    }
  }

  @override
  Future<Either<Failure, Stream<List<Message>>>> getScheduledMessages({
    required String receiverId,
    required String userId,
  }) async {
    try {
      Stream<List<Message>> res = await chatRemoteDataSources
          .getScheduledMessages(receiverId: receiverId, userId: userId);
      return right(res);
    } on ServerExceptions catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<User>>> searchUser({
    required String receiverName,
    required String currentUserId,
  }) async {
    try {
      final res = await chatRemoteDataSources.searchUser(
        receiverName: receiverName,
        currentUserId: currentUserId,
      );
      return right(res);
    } on ServerExceptions catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<void> markMessagesDelivered({
    required String userId,
    required String receiverId,
  }) async {
    await chatRemoteDataSources.markMessagesDelivered(
      receiverId: receiverId,
      userId: userId,
    );
  }

  @override
  Future<void> toggleReaction({
    required String userId,
    required String receiverId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      await chatRemoteDataSources.toggleReaction(
        userId: userId,
        receiverId: receiverId,
        messageId: messageId,
        emoji: emoji,
        opCollection: _getMyOpCollection(userId, receiverId),
      );

      // Update local DB
      await chatLocalDataSource.updateMessageReaction(
        messageId, {userId: emoji}, emoji, userId
      );
    } catch (e) {
      throw ServerExceptions(e.toString());
    }
  }

  @override
  Future<void> editMessage({
    required String userId,
    required String receiverId,
    required String msgId,
    required String newContent,
  }) async {
    try {
      await chatRemoteDataSources.editMessage(
        userId: userId,
        receiverId: receiverId,
        msgId: msgId,
        newContent: newContent,
      );
    } catch (e) {
      throw ServerExceptions(e.toString());
    }
  }
  // ===================== Helpers =====================

  String generateConversationId(String user1, String user2) {
    final sorted = [user1, user2]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }

  String _getMyOpCollection(String userId, String receiverId) {
    final sorted = [userId, receiverId]..sort();
    return sorted[0] == userId ? "operation_1" : "operation_2";
  }

  String _getOtherOpCollection(String userId, String receiverId) {
    final sorted = [userId, receiverId]..sort();
    return sorted[0] == userId ? "operation_2" : "operation_1";
  }
}
