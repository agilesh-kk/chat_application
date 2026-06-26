import 'dart:async';

import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/chats/data/datasources/chat_remote_data_sources.dart';
import 'package:chat_application/features/chats/domain/entities/conversation.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSources chatRemoteDataSources;
  final Set<String> _recentlyDownloadedConvos = {};
  final Map<String, StreamSubscription<Map<String, dynamic>>> _opSub = {};

  ChatRepositoryImpl({
    required this.chatRemoteDataSources,
  });

  @override
  Future<Either<Failure, Stream<List<Conversation>>>> getConversations({
    required String userId,
  }) async {
    try {
      final stream = await chatRemoteDataSources.getConversations(userId: userId);
      return right(stream);
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
      await chatRemoteDataSources.fetchAllMessages(
        conversationId: generateConversationId(userId, friendId),
      );
      _recentlyDownloadedConvos.add(generateConversationId(userId, friendId));
      return right(true);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> downloadAllConversations(String userId) async {
    try {
      final convoIds = await getUserConvoList(userId);
      if (convoIds.isEmpty) return right(false);
      for (final convoId in convoIds) {
        await chatRemoteDataSources.fetchAllMessages(
          conversationId: convoId,
        );
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
  void startOperationListener({
    required String userId,
    required String receiverId,
  }) {
    _startOperationListener(userId, receiverId);
  }

  Future<void> _startOperationListener(
    String userId,
    String receiverId,
  ) async {
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
      onError: (error) {},
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
    try {
      final parts = convoId.split('_');
      if (parts.length >= 2) {
        final user1 = parts[0];
        final user2 = parts[1];
        await chatRemoteDataSources.updateFriendStatus(
          convoId: convoId,
          userId: user1,
          friendId: user2,
          isFriend: isFriend,
        );
        await chatRemoteDataSources.updateFriendStatus(
          convoId: convoId,
          userId: user2,
          friendId: user1,
          isFriend: isFriend,
        );
      }
    } catch (e) {
      //print("Update conversation friend status error: $e");
    }
  }

  @override
  Future<void> markConversationNotFriend(
    String userId,
    String friendId,
  ) async {
    try {
      final convoId = generateConversationId(userId, friendId);
      await chatRemoteDataSources.updateFriendStatus(
        convoId: convoId,
        userId: userId,
        friendId: friendId,
        isFriend: false,
      );
      await chatRemoteDataSources.updateFriendStatus(
        convoId: convoId,
        userId: friendId,
        friendId: userId,
        isFriend: false,
      );
    } catch (e) {
      //print("Mark conversation not friend error: $e");
    }
  }

  @override
  Future<List<Conversation>> queryAllLocalConversations() async {
    return [];
  }

  @override
  Future<String?> getConvoIdByReceiverId(String receiverId) async {
    return null;
  }

  @override
  Future<void> restoreFriendConversation(
    String userId,
    String friendId,
  ) async {}

  @override
  String generateConversationId(String user1, String user2) {
    final sorted = [user1, user2]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }

  String _getOtherOpCollection(String userId, String receiverId) {
    final sorted = [userId, receiverId]..sort();
    return sorted[0] == userId ? "operation_2" : "operation_1";
  }

  String _getMyOpCollection(String userId, String receiverId) {
    final sorted = [userId, receiverId]..sort();
    return sorted[0] == userId ? "operation_1" : "operation_2";
  }

  Future<void> _processOperation(
    Map<String, dynamic> opData,
    String convoId,
    String userId,
    String receiverId,
    String opCollection,
  ) async {
    final docId = opData['_docId'] as String;
    await chatRemoteDataSources.deleteOperation(
      conversationId: convoId,
      opCollection: opCollection,
      opId: docId,
    );
  }

  @override
  Future<Either<Failure, Stream<List<Message>>>> getMessages({
    required String receiverId,
    required String userId,
    int? limit,
  }) async {
    try {
      Stream<List<Message>> res = await chatRemoteDataSources.getMessages(
        receiverId: receiverId,
        userId: userId,
        limit: limit,
      );
      return right(res);
    } on ServerExceptions catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getOlderMessages({
    required String receiverId,
    required String userId,
    required DateTime oldestTimestamp,
    int limit = 50,
  }) async {
    try {
      final res = await chatRemoteDataSources.getOlderMessages(
        receiverId: receiverId,
        userId: userId,
        oldestTimestamp: oldestTimestamp,
        limit: limit,
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
  }) {
    return chatRemoteDataSources.markMessagesDelivered(
      receiverId: receiverId,
      userId: userId,
    );
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
      final imageUrl = await chatRemoteDataSources.uploadImage(
        image: image,
        msgId: msgId,
      );
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
        opCollection: _getMyOpCollection(userId, receiverId),
      );
      return right(null);
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
  Future<Either<Failure, Stream<List<Message>>>> getScheduledMessages({
    required String receiverId,
    required String userId,
  }) async {
    try {
      Stream<List<Message>> res =
          await chatRemoteDataSources.getScheduledMessages(
        receiverId: receiverId,
        userId: userId,
      );
      return right(res);
    } on ServerExceptions catch (e) {
      return left(Failure(e.message));
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
    } catch (e) {
      throw ServerExceptions(e.toString());
    }
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
        opCollection: _getMyOpCollection(userId, receiverId),
      );
    } catch (e) {
      throw ServerExceptions(e.toString());
    }
  }
}
