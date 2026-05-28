import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract interface class ChatLocalDataSource {
  // Image cache
  Future<String?> saveImage(XFile image, String msgId);
  Future<String?> getImage(String msgId);
  Future<void> deleteImage(String msgId);

  // Message DB
  Future<void> initDatabase();
  Future<bool> hasMessages(String conversationId);
  Future<void> upsertMessageFromFirestore(Map<String, dynamic> firestoreData, String docId);
  Future<void> confirmLocalMessage(String msgId, Map<String, dynamic> remoteData);
  Future<void> updateMessageDeletion(String msgId, List<String> deletedfor, bool deletedForEveryone);
  Future<void> updateMessageReaction(String msgId, Map<String, String> reactions);
  Future<void> updateMessageTimeline(String msgId, bool added);
  Future<void> markMessagesSeen(List<String> msgIds, String seenByUserId);
  Future<void> deleteMessageLocally(String msgId);
  Future<void> bulkInsertMessages(List<Map<String, dynamic>> firestoreDocs, List<String> docIds);
  Stream<List<Message>> getMessagesStream(String conversationId);
  void dispose();
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  Database? _db;
  final Map<String, StreamController<List<Message>>> _controllers = {};

  // ===================== Database Init =====================

  @override
  Future<void> initDatabase() async {
    if (_db != null) return;
    if (kIsWeb) return;

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'chat_messages.db');

    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversationId TEXT NOT NULL,
        senderId TEXT NOT NULL,
        content TEXT,
        type TEXT NOT NULL DEFAULT 'text',
        status TEXT NOT NULL DEFAULT 'sent',
        createdAt INTEGER NOT NULL,
        deletedfor TEXT DEFAULT '[]',
        deletedForEveryone INTEGER DEFAULT 0,
        reactions TEXT DEFAULT '{}',
        replyToId TEXT,
        replyToContent TEXT,
        replyToSenderId TEXT,
        replyToType TEXT,
        isScheduled INTEGER DEFAULT 0,
        sendAt INTEGER,
        inTimeline INTEGER DEFAULT 0,
        name TEXT,
        receiverId TEXT,
        profile TEXT,
        isLocal INTEGER DEFAULT 0,
        localPath TEXT
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_messages_conversation ON messages(conversationId, createdAt DESC)');
  }

  // ===================== Image Cache (unchanged) =====================

  Future<String?> _getImagePath(String msgId) async {
    if (kIsWeb) return null;
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory("${dir.path}/chat_images");

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    return "${folder.path}/$msgId.jpg";
  }

  @override
  Future<String?> saveImage(XFile image, String msgId) async {
    if (kIsWeb) return null;
    final imagePath = await _getImagePath(msgId);
    if (imagePath == null) return null;
    final file = File(image.path);
    return (await file.copy(imagePath)).path;
  }

  @override
  Future<String?> getImage(String msgId) async {
    final imagePath = await _getImagePath(msgId);
    if (imagePath == null) return null;
    final file = File(imagePath);
    if (await file.exists()) return imagePath;
    return null;
  }

  @override
  Future<void> deleteImage(String msgId) async {
    final imagePath = await _getImagePath(msgId);
    if (imagePath == null) return;
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // ===================== Message DB Operations =====================

  @override
  Future<bool> hasMessages(String conversationId) async {
    if (_db == null || kIsWeb) return false;
    final result = await _db!.query(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Map<String, dynamic> _firestoreToDb(Map<String, dynamic> data, String docId, String conversationId) {
    return {
      'id': docId,
      'conversationId': conversationId,
      'senderId': data['senderId'],
      'content': data['content'] ?? '',
      'type': data['messageType'] ?? data['type'] ?? 'text',
      'status': data['status'] ?? 'sent',
      'createdAt': data['createdAt'] != null
          ? _toMillis(data['createdAt'])
          : DateTime.now().millisecondsSinceEpoch,
      'deletedfor': _jsonEncode(data['deletedfor']),
      'deletedForEveryone': (data['deletedForEveryone'] ?? false) ? 1 : 0,
      'reactions': _jsonEncode(data['reactions']),
      'replyToId': data['replyToId'],
      'replyToContent': data['replyToContent'],
      'replyToSenderId': data['replyToSenderId'],
      'replyToType': data['replyToType'],
      'isScheduled': (data['isScheduled'] ?? false) ? 1 : 0,
      'sendAt': data['sendAt'] != null ? _toMillis(data['sendAt']) : null,
      'inTimeline': (data['inTimeline'] ?? false) ? 1 : 0,
      'name': data['name'],
      'receiverId': data['receiverId'],
      'profile': data['profile'],
      'isLocal': (data['isLocal'] ?? false) ? 1 : 0,
    };
  }

  int _toMillis(dynamic value) {
    if (value is DateTime) return value.millisecondsSinceEpoch;
    try {
      if (value != null) {
        final date = (value as dynamic).toDate();
        if (date is DateTime) return date.millisecondsSinceEpoch;
      }
    } catch (_) {}
    try {
      return DateTime.parse(value.toString()).millisecondsSinceEpoch;
    } catch (_) {
      return DateTime.now().millisecondsSinceEpoch;
    }
  }

  String _jsonEncode(dynamic value) {
    if (value == null) return '[]';
    if (value is String) return value;
    return jsonEncode(value);
  }

  Message _dbToMessage(Map<String, dynamic> row) {
    return Message(
      id: row['id'] as String,
      senderId: row['senderId'] as String,
      content: row['content'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['createdAt'] as int),
      status: row['status'] as String? ?? 'sent',
      deletedfor: _jsonDecodeList(row['deletedfor']),
      deletedForEveryone: (row['deletedForEveryone'] as int? ?? 0) == 1,
      type: row['type'] as String? ?? 'text',
      isLocal: (row['isLocal'] as int? ?? 0) == 1,
      sendAt: row['sendAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['sendAt'] as int)
          : null,
      isScheduled: (row['isScheduled'] as int? ?? 0) == 1,
      inTimeline: (row['inTimeline'] as int? ?? 0) == 1,
      reactions: _jsonDecodeMap(row['reactions']),
      replyToId: row['replyToId'] as String?,
      replyToContent: row['replyToContent'] as String?,
      replyToSenderId: row['replyToSenderId'] as String?,
      replyToType: row['replyToType'] as String?,
    );
  }

  List<String> _jsonDecodeList(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value);
    try {
      return List<String>.from(jsonDecode(value as String));
    } catch (_) {
      return [];
    }
  }

  Map<String, String> _jsonDecodeMap(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      return Map<String, String>.from(value);
    }
    try {
      final decoded = jsonDecode(value as String);
      return Map<String, String>.from(decoded);
    } catch (_) {
      return {};
    }
  }

  void _notify(String conversationId) {
    final controller = _controllers[conversationId];
    if (controller == null || controller.isClosed) return;
    _queryMessagesSafe(conversationId).then((messages) {
      if (!controller.isClosed) controller.add(messages);
    });
  }

  Future<List<Message>> _queryMessagesSafe(String conversationId) async {
    try {
      return await _queryMessages(conversationId);
    } catch (_) {
      return [];
    }
  }

  Future<List<Message>> _queryMessages(String conversationId) async {
    if (_db == null) return [];
    final rows = await _db!.query(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(_dbToMessage).toList();
  }

  @override
  Future<void> upsertMessageFromFirestore(Map<String, dynamic> firestoreData, String docId) async {
    if (_db == null || kIsWeb) return;
    final convoId = firestoreData['convoId'] as String? ?? '';
    if (convoId.isEmpty) return;
    final row = _firestoreToDb(firestoreData, docId, convoId);
    await _db!.insert(
      'messages',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notify(convoId);
  }

  @override
  Future<void> confirmLocalMessage(String msgId, Map<String, dynamic> remoteData) async {
    if (_db == null || kIsWeb) return;
    final convoId = remoteData['convoId'] as String? ?? '';

    final existing = await _db!.query('messages',
        where: 'id = ?', whereArgs: [msgId], limit: 1);
    final originalCreatedAt = existing.isNotEmpty
        ? existing.first['createdAt']
        : null;

    final row = _firestoreToDb(remoteData, msgId, convoId);
    if (originalCreatedAt != null) {
      row['createdAt'] = originalCreatedAt;
    }
    row['isLocal'] = 0;
    print(row['localPath']); 
    row['localPath'] = null;
    await _db!.insert('messages', row, conflictAlgorithm: ConflictAlgorithm.replace);
    if (convoId.isNotEmpty) _notify(convoId);
  }

  @override
  Future<void> updateMessageDeletion(String msgId, List<String> deletedfor, bool deletedForEveryone) async {
    if (_db == null || kIsWeb) return;
    await _db!.update(
      'messages',
      {
        'deletedfor': jsonEncode(deletedfor),
        'deletedForEveryone': deletedForEveryone ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [msgId],
    );
    final rows = await _db!.query('messages', where: 'id = ?', whereArgs: [msgId], limit: 1);
    if (rows.isNotEmpty) {
      final convoId = rows.first['conversationId'] as String;
      _notify(convoId);
    }
  }

  @override
  Future<void> updateMessageReaction(String msgId, Map<String, String> reactions) async {
    if (_db == null || kIsWeb) return;
    await _db!.update(
      'messages',
      {'reactions': jsonEncode(reactions)},
      where: 'id = ?',
      whereArgs: [msgId],
    );
    final rows = await _db!.query('messages', where: 'id = ?', whereArgs: [msgId], limit: 1);
    if (rows.isNotEmpty) {
      final convoId = rows.first['conversationId'] as String;
      _notify(convoId);
    }
  }

  @override
  Future<void> updateMessageTimeline(String msgId, bool added) async {
    if (_db == null || kIsWeb) return;
    await _db!.update(
      'messages',
      {'inTimeLine': added?1:0},
      where: 'id = ?',
      whereArgs: [msgId],
    );
    final rows = await _db!.query('messages', where: 'id = ?', whereArgs: [msgId], limit: 1);
    if (rows.isNotEmpty) {
      final convoId = rows.first['conversationId'] as String;
      _notify(convoId);
    }
  }

  @override
  Future<void> markMessagesSeen(List<String> msgIds, String seenByUserId) async {
    if (_db == null || kIsWeb) return;
    final batch = _db!.batch();
    for (final msgId in msgIds) {
      batch.update(
        'messages',
        {'status': 'seen'},
        where: 'id = ?',
        whereArgs: [msgId],
      );
    }
    await batch.commit(noResult: true);
    final rows = await _db!.query(
      'messages',
      where: 'id = ?',
      whereArgs: [msgIds.isNotEmpty ? msgIds.first : ''],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final convoId = rows.first['conversationId'] as String;
      _notify(convoId);
    }
  }

  @override
  Future<void> deleteMessageLocally(String msgId) async {
    if (_db == null || kIsWeb) return;
    final rows = await _db!.query('messages', where: 'id = ?', whereArgs: [msgId], limit: 1);
    await _db!.delete('messages', where: 'id = ?', whereArgs: [msgId]);
    if (rows.isNotEmpty) {
      final convoId = rows.first['conversationId'] as String;
      _notify(convoId);
    }
  }

  @override
  Future<void> bulkInsertMessages(List<Map<String, dynamic>> firestoreDocs, List<String> docIds) async {
    if (_db == null || kIsWeb || firestoreDocs.isEmpty) return;
    final batch = _db!.batch();
    String? convoId;

    for (var i = 0; i < firestoreDocs.length; i++) {
      final data = firestoreDocs[i];
      final id = docIds[i];
      final cId = data['convoId'] as String? ?? '';
      convoId ??= cId;
      final row = _firestoreToDb(data, id, cId);
      batch.insert('messages', row, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
    if (convoId != null) _notify(convoId);
  }

  @override
  Stream<List<Message>> getMessagesStream(String conversationId) {
    if (_controllers[conversationId] == null || _controllers[conversationId]!.isClosed) {
      _controllers[conversationId] = StreamController<List<Message>>.broadcast();
    }
    _queryMessagesSafe(conversationId).then((messages) {
      if (!_controllers[conversationId]!.isClosed) {
        _controllers[conversationId]?.add(messages);
      }
    });
    return _controllers[conversationId]!.stream;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _db?.close();
    _db = null;
  }
}
