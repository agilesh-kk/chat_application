import 'dart:async';

import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/chats/data/datasources/chat_local_data_sources.dart';
import 'package:chat_application/features/chats/data/datasources/chat_remote_data_sources.dart';
import 'package:chat_application/features/chats/domain/entities/conversation.dart';
import 'package:chat_application/features/chats/domain/entities/list_operation.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSources chatRemoteDataSources;
  final ChatLocalDataSource chatLocalDataSource;
  final Set<String> _recentlyDownloadedConvos = {};

  final Map<String, StreamSubscription<Map<String, dynamic>>> _opSub = {};

  ChatRepositoryImpl({
    required this.chatRemoteDataSources,
    required this.chatLocalDataSource,
  });

  @override
  Future<Either<Failure, Stream<List<Conversation>>>> getConversations({
    required String userId,
  }) async {
    try {
      await chatLocalDataSource.initDatabase();

      final userChanged = await chatLocalDataSource.ischeckUserChanged(userId);

      if (userChanged) {
        await chatLocalDataSource.updateUser(userId);
        return left(Failure('user-changed'));
      }

      Stream<List<Conversation>> res =
          chatLocalDataSource.getConversationsStream();
      return right(res);
    } on ServerExceptions catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> downloadConversation({
    required String userId,
    required String friendId,
  }) async {
    try {
      final docs = await chatRemoteDataSources.fetchAllMessages(
        conversationId: generateConversationId(userId, friendId),
      );
      if (docs.isNotEmpty) {
        final docIds = docs.map((d) => d['_docId'] as String).toList();
        await chatLocalDataSource.bulkInsertMessages(docs, docIds, friendId);
      }

      _recentlyDownloadedConvos.add(generateConversationId(userId, friendId));

      return right(true);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> downloadAllConversations(String userId) async {
    try {
      final convoIds = await chatRemoteDataSources.getUserConvoList(userId);
      if (convoIds.isEmpty) return right(false);

      for (final convoId in convoIds) {
        final docs = await chatRemoteDataSources.fetchAllMessages(
          conversationId: convoId,
        );
        if (docs.isNotEmpty) {
          final docIds = docs.map((d) => d['_docId'] as String).toList();
          final parts = convoId.split('_');
          final receiverId = parts[0] == userId ? parts[1] : parts[0];
          await chatLocalDataSource.bulkInsertMessages(
            docs,
            docIds,
            receiverId,
          );
        }
      }
      _recentlyDownloadedConvos.addAll(convoIds);
      return right(true);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<List<String>> getUserConvoList(String userId) async {
    return chatRemoteDataSources.getUserConvoList(userId);
  }

  @override
  Future<Either<Failure, Stream<ListOperation<Message>>>> getMessages({
    required String receiverId,
    required String userId,
  }) async {
    try {
      final convoId = generateConversationId(userId, receiverId);

      // Initial load if local DB is empty
      final hasLocal = await chatLocalDataSource.hasMessages(convoId);
      if (!hasLocal) {
        // final docs = await chatRemoteDataSources.fetchAllMessages(
        //   conversationId: convoId,
        // );
        // if (docs.isNotEmpty) {
        //   final docIds = docs.map((d) => d['_docId'] as String).toList();
        //   await chatLocalDataSource.bulkInsertMessages(docs, docIds);
        // }
      }

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
    final convoId = generateConversationId(userId, receiverId);
    final opCollection = _getOtherOpCollection(userId, receiverId);

    final bool skipFirst = _recentlyDownloadedConvos.contains(convoId);

    final stream = await chatRemoteDataSources.listenToOperations(
      conversationId: convoId,
      opCollection: opCollection,
      skipFirst: skipFirst,
    );

    await _opSub[convoId]?.cancel();

    _opSub[convoId] = stream.listen(
      (opData) async {
        _recentlyDownloadedConvos.remove(convoId);
        await _processOperation(
          opData,
          convoId,
          userId,
          receiverId,
          opCollection,
        );
      },
      onError: (error) {
        // Operation listener error (e.g., permissions) - log and retry is handled by Firestore SDK
      },
    );
  }

  @override
  Future<void> stopOperationListener() async {
    for (final e in _opSub.values) {
      e.cancel();
    }
  }

  @override
  Future<void> stopOperationListenerForReceiver(
    String userId,
    String receiverId,
  ) async {
    final convoId = generateConversationId(userId, receiverId);
    await _opSub[convoId]?.cancel();
    _opSub.remove(convoId);
  }

  @override
  Future<void> updateConversationFriendStatus(
    String convoId,
    bool isFriend,
  ) async {
    await chatLocalDataSource.updateConversationFriendStatus(convoId, isFriend);
  }

  @override
  Future<String?> getConvoIdByReceiverId(String receiverId) async {
    return chatLocalDataSource.getConvoIdByReceiverId(receiverId);
  }

  @override
  Future<void> restoreFriendConversation(String userId, String friendId) async {
    final convoId = generateConversationId(userId, friendId);
    await chatRemoteDataSources.updateConversationFriendStatus(
      convoId: convoId,
      userId: userId,
      friendId: friendId,
      isFriend: true,
    );
  }

  @override
  Future<void> markConversationNotFriend(String userId, String friendId) async {
    final convoId = generateConversationId(userId, friendId);
    await chatRemoteDataSources.updateConversationFriendStatus(
      convoId: convoId,
      userId: userId,
      friendId: friendId,
      isFriend: false,
    );
  }

  @override
  Future<List<Conversation>> queryAllLocalConversations() async {
    return chatLocalDataSource.queryAllConversations();
  }

  Future<void> _processOperation(
    Map<String, dynamic> opData,
    String convoId,
    String userId,
    String receiverId,
    String opCollection,
  ) async {
    final type = opData['type'] as String?;
    final docId = opData['_docId'] as String?;

    if (type == null || docId == null) return;

    //print("listeningggggggggggggggggggg");
    //print(type);

    try {
      switch (type) {
        case 'new_message':
          final msgId = opData['messageId'] as String? ?? docId;
          final content =
              opData['messageType'] == "text" ? opData['content'] : "📷 Image";
          await chatLocalDataSource.updateConvo(
            convoId,
            msgId,
            content,
            opData['createdAt'],
            receiverId,
            opData['senderId'],
          );
          await chatLocalDataSource.upsertMessageFromFirestore(opData, msgId);
          break;

        case 'delete_message':
          final msgId = opData['messageId'] as String? ?? docId;
          final deletedfor = List<String>.from(opData['deletedfor'] ?? []);
          final deletedForEveryone = opData['deletedForEveryone'] ?? false;
          await chatLocalDataSource.updateMessageDeletion(
            msgId,
            convoId,
            userId,
            receiverId,
            deletedfor,
            deletedForEveryone,
          );
          break;

        case 'reaction':
          final msgId = opData['messageId'] as String? ?? docId;
          final userId = opData['userId'] as String;
          final emoji = opData['emoji'] as String;
          final reactions = Map<String, String>.from(
            opData['reactions'] as Map? ?? {},
          );
          await chatLocalDataSource.updateMessageReaction(
            msgId,
            convoId,
            userId,
            receiverId,
            reactions,
            emoji,
            userId,
          );
          break;

        case 'seen':
          final seenMsgIds = List<String>.from(opData['seenMsgIds'] as List? ?? []);
          final seenByUserId = opData['seenByUserId'] as String? ?? '';
          await chatLocalDataSource.markMessagesSeen(seenMsgIds, seenByUserId, convoId);
          break;

        case 'timeline':
          final msgId = opData['messageId'] as String? ?? docId;
          final added = opData['addedToTimeline'] as bool? ?? false;
          await chatLocalDataSource.updateMessageTimeline(msgId, added);
          break;

        case 'edit_message':
          final msgId = opData['messageId'] as String? ?? docId;
          final newContent = opData['new_content'] as String? ?? '';
          await chatLocalDataSource.updateMessageContent(msgId, newContent);
          break;
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

      final convoId = generateConversationId(userId, receiverId);

      if (!isScheduled) {
        await chatLocalDataSource.initDatabase();
        await chatLocalDataSource.confirmLocalMessage(msgId, {
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
        chatLocalDataSource.updateConvo(
          convoId,
          msgId,
          content,
          DateTime.now(),
          receiverId,
          userId,
        );
      }

      final isNewConvo = !isScheduled && !await chatLocalDataSource.hasConversation(convoId);
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
        isNewConvo: isNewConvo,
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

      chatLocalDataSource.updateConvo(
        convoId,
        msgId,
        "📷 Image",
        DateTime.now(),
        receiverId,
        userId,
      );

      final isNewConvo = !await chatLocalDataSource.hasConversation(convoId);
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
        isNewConvo: isNewConvo,
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
          msgId,
          generateConversationId(userId, receiverId),
          userId,
          receiverId,
          [],
          true,
        );
      } else {
        await chatLocalDataSource.updateMessageDeletion(
          msgId,
          generateConversationId(userId, receiverId),
          userId,
          receiverId,
          [userId],
          false,
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
    print("llllllllllllllllllllllllllllllllllllllllllllllllllllllllllll");
    chatLocalDataSource.resetUnread(generateConversationId(userId, receiverId));
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

       chatLocalDataSource.updateMessageReaction(
        messageId,
        generateConversationId(userId, receiverId),
        userId,
        receiverId,
        {userId: emoji},
        emoji,
        userId,
      );

      await chatRemoteDataSources.toggleReaction(
        userId: userId,
        receiverId: receiverId,
        messageId: messageId,
        emoji: emoji,
        opCollection: _getMyOpCollection(userId, receiverId),
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
      chatLocalDataSource.updateMessageContent(msgId, newContent);

      await chatRemoteDataSources.editMessage(
        userId: userId,
        receiverId: receiverId,
        msgId: msgId,
        newContent: newContent,
        opCollection: _getMyOpCollection(userId, receiverId),
      );
    } catch (e) {
      throw ServerExceptions(e.toString());
    }
  }
  // ===================== Helpers =====================

  @override
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
