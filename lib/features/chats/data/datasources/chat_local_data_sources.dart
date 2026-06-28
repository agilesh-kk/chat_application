import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chat_application/features/chats/data/models/message_model.dart';
import 'package:chat_application/features/chats/domain/entities/conversation.dart';
import 'package:chat_application/features/chats/domain/entities/list_operation.dart';
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
  Future<void> updateMessageDeletion(String msgId, String convoId,String userId, String receiverId,List<String> deletedfor, bool deletedForEveryone);
  Future<void> updateMessageReaction(String msgId, String convoId,String userId, String receiverId, Map<String, String> reactions, String emoji, String reacterId);
  Future<void> updateMessageTimeline(String msgId, bool added);
  Future<void> updateMessageContent(String msgId, String newContent, );
  Future<void> markMessagesSeen(List<String> msgIds, String seenByUserId, String convoId);
  Future<void> updateConvo(String convoId, String msgId ,String content, dynamic lastMessageTime, String receiverId, String lastSender);
  Future<void> resetUnread(String convoId);
  Future<void> deleteMessageLocally(String msgId);
  Future<void> bulkInsertMessages(List<Map<String, dynamic>> firestoreDocs, List<String> docIds, String receiverId);
  Stream<ListOperation<Message>> getMessagesStream(String conversationId);
  Stream<List<Conversation>> getConversationsStream();

  Future<bool> ischeckUserChanged(String userId);
  Future<void> updateUser(String userId);
  Future<void> truncateDb();
  Future<void> populateMessages(List<Map<String,dynamic>> messages, String receiverId, String convoId);

  Future<void> updateConversationFriendStatus(String convoId, bool isFriend);
  Future<String?> getConvoIdByReceiverId(String receiverId);
  Future<List<Conversation>> queryAllConversations();
  Future<bool> hasConversation(String convoId);

  // Pending message queue
  Future<void> insertPendingMessage({
    required String msgId,
    required String userId,
    required String receiverId,
    required String content,
    String type = 'text',
    String? userName,
    String? userProfile,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
    String? replyToType,
  });
  Future<List<Map<String, dynamic>>> getPendingMessages();
  Future<void> deletePendingMessage(String msgId);
  Future<void> updateMessageStatus(String msgId, String status);

  void dispose();
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  Database? _db;
  final Map<String, StreamController<ListOperation<Message>>> _controllers = {};
  StreamController<List<Conversation>>? _convoController;

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
      version: 8,
      onCreate: _createTables,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            ALTER TABLE messages 
            ADD COLUMN isEdited INTEGER DEFAULT 0
          ''');
        }

        if (oldVersion < 4) {
          await convoUpgrade(db);
        }

        if (oldVersion < 6) {
          try {
            await db.execute('''
              ALTER TABLE conversations 
              ADD COLUMN isFriend INTEGER DEFAULT 1
            ''');
          } catch (_) {}
        }

        if (oldVersion < 7) {
          await db.execute('''
            CREATE INDEX IF NOT EXISTS idx_messages_conversation_time
            ON messages(conversationId, createdAt DESC)
          ''');
        }

        if (oldVersion < 8) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS pending_messages (
              msgId TEXT PRIMARY KEY,
              userId TEXT NOT NULL,
              receiverId TEXT NOT NULL,
              content TEXT NOT NULL,
              type TEXT DEFAULT 'text',
              userName TEXT,
              userProfile TEXT,
              replyToId TEXT,
              replyToContent TEXT,
              replyToSenderId TEXT,
              replyToType TEXT,
              retryCount INTEGER DEFAULT 0,
              lastError TEXT,
              createdAt INTEGER NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<bool> ischeckUserChanged(String userId)async{
    if (_db == null || kIsWeb) return false;
    final row = await _db!.rawQuery("SELECT * FROM user");
    
    if(row.isEmpty) {
      return true;
    }

    final user = row.first;
    final prevUserId = user['userId'] as String ;

    if(prevUserId == userId){
      return false;
    }

    return true;
  }

  Future<void> truncateDb()async{
    if (_db == null || kIsWeb) return;
    await _db!.rawQuery("DELETE FROM messages");
    await _db!.rawQuery("DELETE FROM conversations");
  }

  Future<void> updateUser(String userId)async{
    if (_db == null || kIsWeb) return;
    final row = await _db!.rawQuery("SELECT * FROM user");
    
    if(row.isEmpty) {
      await _db!.insert("user", {"userId":userId,"lastfetchTime":_toMillis(DateTime.now())});
      return;
    }

    final user = row.first;
    final prevUserId = user['userId'] as String ;

    if(prevUserId == userId){
      return;
    }

    await _db!.update("user", {"userId":userId,"lastfetchTime":_toMillis(DateTime.now())});
  }

  Future<void> populateMessages(List<Map<String,dynamic>> messages, String receiverId, String convoId)async{
    if (_db == null || kIsWeb) return;

    final batch = _db!.batch();
    for (final msg in messages) {
      batch.insert("messages", _firestoreToDb(msg, msg['id'],convoId));
    }
    await batch.commit(noResult: true);

    final rows = await _db!.query('messages',
      where: 'conversationId = ?',
      whereArgs: [convoId],
      limit: 1,
      orderBy: "createdAt DESC",
    );

    if(rows.isNotEmpty){
      final first = rows[0];
      print(first['content']);
      updateConvo(convoId, first['id'] as String, first['content'] as String, DateTime.fromMillisecondsSinceEpoch(first['createdAt'] as int), receiverId, first['senderId'] as String);
    }
  }



  Future<void> convoUpgrade(Database db)async {
     await db.execute('''
      CREATE TABLE conversations (
        convoId TEXT PRIMARY KEY,
        lastMessage TEXT,
        lastUpdateTime  Integer,
        unread Integer,
        receiverId TEXT,
        lastSender TEXT,
        msgId TEXT,
        isFriend INTEGER DEFAULT 1
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_conversation ON conversations(convoId, lastUpdateTime DESC)');

    await db.execute('''
      CREATE TABLE user (
        userId TEXT,
        lastfetchTime Integer
      )
    ''');
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
        isEdited INTEGER DEFAULT 0,
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
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_messages_conversation_time
      ON messages(conversationId, createdAt DESC)
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_messages (
        msgId TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        receiverId TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT DEFAULT 'text',
        userName TEXT,
        userProfile TEXT,
        replyToId TEXT,
        replyToContent TEXT,
        replyToSenderId TEXT,
        replyToType TEXT,
        retryCount INTEGER DEFAULT 0,
        lastError TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');
    await convoUpgrade(db);
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
      'status': data['status'] ?? 'loading',
      'createdAt': data['createdAt'] != null
          ? _toMillis(data['createdAt'])
          : DateTime.now().millisecondsSinceEpoch,
      'isEdited' : (data['isEdited'] ?? false) ? 1 : 0,
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
      'localPath': data['localPath'],
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

  Conversation _dbToConversation(Map<String, dynamic> row){
    return Conversation(
      convoId: row['convoId'] as String,
      lastMessage: row['lastMessage'] as String,
      lastSender: row['lastSender'] as String,
      lastupdateTime: DateTime.fromMillisecondsSinceEpoch((row['lastUpdateTime'] ?? 0) as int).toString(),
      receiverId: row['receiverId'] as String,
      unread: (row['unread'] ?? 0) as int,
      profilepicLink: '',
      receiverName:'',
      isFriend: (row['isFriend'] ?? 1) == 1,
    );
  }

  Message _dbToMessage(Map<String, dynamic> row) {
    return Message(
      id: row['id'] as String,
      senderId: row['senderId'] as String,
      content: row['content'] as String? ?? '',
      isEdited: (row['isEdited'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['createdAt'] as int),
      status: row['status'] as String? ?? 'sent',
      deletedfor: _jsonDecodeList(row['deletedfor']),
      deletedForEveryone: (row['deletedForEveryone'] as int? ?? 0) == 1,
      type: row['type'] as String? ?? 'text',
      isLocal: (row['isLocal'] as int? ?? 0) == 1,
      localPath: row['localPath'] as String?,
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

  void _notify(String conversationId, ListOperation<Message> lp) {
    final controller = _controllers[conversationId];
    if (controller == null || controller.isClosed) return;
    _queryMessagesSafe(conversationId).then((messages) {
     if (!controller.isClosed) controller.add(lp);
    });
  }

  void _notifyConvo() {
    
    if (_convoController == null || _convoController!.isClosed) return;
    _queryConversations().then((convos) {
      if (!_convoController!.isClosed){
        print("added");
         _convoController!.add(convos);}
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

  Future<List<Conversation>> _queryConversations() async {
    if (_db == null) return [];
    final rows = await _db!.query(
      'conversations',
      orderBy: 'lastUpdateTime DESC',
    );
    return rows.map(_dbToConversation).toList();
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
    _notify(convoId,NewMessageOperation(_dbToMessage(row)));
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
    _db!.insert('messages', row, conflictAlgorithm: ConflictAlgorithm.replace);
    if (convoId.isNotEmpty) _notify(convoId,NewMessageOperation(_dbToMessage(row)));
  }

  @override
  Future<void> updateMessageDeletion(String msgId, String convoId,String userId, String receiverId,List<String> deletedfor, bool deletedForEveryone) async {
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

    final convo = await _db!.query("conversations",where: "convoId = ?",whereArgs: [convoId],limit: 1);

    if(convo.first['msgId'] == msgId){
      if(deletedForEveryone){
        await _db!.update("conversations", {"lastMessage":"this message was deleted","lastUpdateTime":_toMillis(DateTime.now())},where : "convoId = ?" , whereArgs: [convoId]);
      }else if(deletedfor.contains(userId)){
        await changeLastMessageToPreviousMessage(convoId, userId, receiverId, 1);
      }
      _notifyConvo();
    }

    final rows = await _db!.query('messages', where: 'id = ?', whereArgs: [msgId], limit: 1);
    if (rows.isNotEmpty) {
      final convoId = rows.first['conversationId'] as String;
      _notify(convoId,DeleteMessageOperation(msgId, deletedfor,deleteForEveryone: deletedForEveryone));
    }
  }

  Future<void> changeLastMessageToPreviousMessage(String convoId,String userId,String receiverId, int place) async{
    final row = await _db!.query("messages",where: "deletedfor NOT LIKE ? and conversationId = ?",whereArgs: ["%$userId%",convoId],limit: place,orderBy: "createdAt DESC");
    if(row.isNotEmpty){
      final prev = row[place-1];
      await updateConvo(convoId, prev['id'] as String, prev['content'] as String, DateTime.fromMillisecondsSinceEpoch(prev['createdAt'] as int), receiverId, prev['senderId'] as String);
    }
  }

  @override
  Future<void> updateMessageReaction(String msgId, String convoId,String userId, String receiverId,Map<String, String> reactions, String emoji, String reacterId) async {
    if (_db == null || kIsWeb) return;
    final row = await _db!.query('messages', where: 'id = ?', whereArgs: [msgId], limit: 1);
    final reacts = Map<String, String>.from(jsonDecode(row.first['reactions'] as String? ?? "") as Map? ?? {});
    final currenReaction = reacts[reacterId]?? "";
    if(currenReaction == emoji){
      reacts.remove(reacterId);
      _notify(convoId,SetReactionOperation(msgId, reacts));
      await changeLastMessageToPreviousMessage(convoId, userId, receiverId, 1);
      _notifyConvo();
    }else{
      reacts[reacterId] = emoji;
      _notify(convoId,SetReactionOperation(msgId, reacts));
        try
        {
          final row = await _db!.query("messages",where: "id = ?",whereArgs: [msgId],limit: 1);
        if(row.isNotEmpty){
          await updateConvo(row.first['conversationId'] as String, msgId, "Reacted $emoji to \"${row.first["content"] as String}\"", DateTime.now(), receiverId, reacterId);
          _notifyConvo();

        }
        }catch(_){}
        
    }

    await _db!.update(
      'messages',
      {'reactions': jsonEncode(reacts)},
      where: 'id = ?',
      whereArgs: [msgId],
    );


    final rows = await _db!.query('messages', where: 'id = ?', whereArgs: [msgId], limit: 1);
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
      _notify(convoId,TimeLineOperation(msgId, added));
    }
  }

  @override
  Future<void> updateMessageContent(String msgId, String newContent)async {
   if (_db == null || kIsWeb) return;
    await _db!.update(
      'messages',
      {'content': newContent,'isEdited' : 1},
      where: 'id = ?',
      whereArgs: [msgId],
    );
    final rows = await _db!.query('messages', where: 'id = ?', whereArgs: [msgId], limit: 1);
    final convoId = rows.first['conversationId'] as String;

    final convo = await _db!.query("conversations",where: "convoId = ?",whereArgs: [convoId],limit: 1);

    if(convo.first['msgId'] == msgId){
        await _db!.update("conversations", {"lastMessage":newContent,"lastUpdateTime":_toMillis(DateTime.now())},where : "convoId = ?" , whereArgs: [convoId]);
      _notifyConvo();
    }

    if (rows.isNotEmpty) {
      final convoId = rows.first['conversationId'] as String;
      _notify(convoId,EditMessageOperation(msgId, newContent));
    }

    
  }

    @override
  Future<void> updateConvo(String convoId, String msgId ,String content, dynamic lastMessageTime, String receiverId, String lastSender, {int incUnread = 1}) async{
    if (_db == null || kIsWeb) return;

    final time = lastMessageTime!=null
          ? _toMillis(lastMessageTime)
          : DateTime.now().millisecondsSinceEpoch;

    try{

      await _db!.transaction((txn) async {
        bool exist = (await txn.query('conversations', where: 'convoId = ?', whereArgs: [convoId], limit: 1)).isNotEmpty;
        if (exist) {
          await txn.update(
            'conversations',
            {"msgId":msgId,"lastMessage":content, "lastUpdateTime":time, "receiverId":receiverId, "lastSender":lastSender},
            where: 'convoId = ?',
            whereArgs: [convoId],
          );
        } else {
          await txn.insert("conversations",{
            "convoId" : convoId,
            "lastMessage" : content,
            "lastUpdateTime" : time,
            "msgId" : msgId,
            "receiverId" : receiverId,
            "lastSender" : lastSender,
            "unread" : 0,
            "isFriend" : 1,
          });
        }

        if(receiverId == lastSender){
          await txn.rawUpdate(
          'UPDATE conversations SET unread = unread + $incUnread WHERE convoId = ?',
          [convoId],
          );
          print("updatinnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn");
        }
      });
    
    

    }catch(e){
      print(e);
    }finally{
      final unread = await _db!.query("conversations",where: "convoId = ?",whereArgs: [convoId]);
      print(unread.first['unread']);
    }
    

    //final rows = await _db!.query('conversations', where: 'convoId = ?', whereArgs: [convoId], limit: 1);
    //if (rows.isNotEmpty) {
      _notifyConvo();
    //}
  }

  @override
  Future<void> markMessagesSeen(List<String> msgIds, String seenByUserId, String convoId) async {
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
      _notify(convoId,MarkSeenOperation(msgIds,"seen"));
      _notifyConvo();
    }
  }

  @override
  Future<bool> hasConversation(String convoId) async {
    if (_db == null || kIsWeb) return false;
    final result = await _db!.query('conversations',
      where: 'convoId = ?',
      whereArgs: [convoId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  @override
  Future<void> insertPendingMessage({
    required String msgId,
    required String userId,
    required String receiverId,
    required String content,
    String type = 'text',
    String? userName,
    String? userProfile,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
    String? replyToType,
  }) async {
    if (_db == null || kIsWeb) return;
    await _db!.insert('pending_messages', {
      'msgId': msgId,
      'userId': userId,
      'receiverId': receiverId,
      'content': content,
      'type': type,
      'userName': userName,
      'userProfile': userProfile,
      'replyToId': replyToId,
      'replyToContent': replyToContent,
      'replyToSenderId': replyToSenderId,
      'replyToType': replyToType,
      'retryCount': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingMessages() async {
    if (_db == null || kIsWeb) return [];
    return await _db!.query('pending_messages', orderBy: 'createdAt ASC');
  }

  @override
  Future<void> deletePendingMessage(String msgId) async {
    if (_db == null || kIsWeb) return;
    await _db!.delete('pending_messages', where: 'msgId = ?', whereArgs: [msgId]);
  }

  @override
  Future<void> updateMessageStatus(String msgId, String status) async {
    if (_db == null || kIsWeb) return;
    await _db!.update(
      'messages',
      {'status': status},
      where: 'id = ?',
      whereArgs: [msgId],
    );
    final rows = await _db!.query('messages', where: 'id = ?', whereArgs: [msgId], limit: 1);
    if (rows.isNotEmpty) {
      final convoId = rows.first['conversationId'] as String;
      _notify(convoId, MarkSeenOperation([msgId],"sent"));
    }
  }

  @override
  Future<void> deleteMessageLocally(String msgId) async {
    if (_db == null || kIsWeb) return;
    final rows = await _db!.query('messages', where: 'id = ?', whereArgs: [msgId], limit: 1);
    await _db!.delete('messages', where: 'id = ?', whereArgs: [msgId]);
    if (rows.isNotEmpty) {
      final convoId = rows.first['conversationId'] as String;
      //_notify(convoId);
    }
  }

  @override
  Future<void> bulkInsertMessages(List<Map<String, dynamic>> firestoreDocs, List<String> docIds, String receiverId) async {
    if (_db == null || kIsWeb || firestoreDocs.isEmpty) return;
    final batch = _db!.batch();
    String? convoId;
    int unread = 0;

    for (var i = 0; i < firestoreDocs.length; i++) {
      final data = firestoreDocs[i];
      final id = docIds[i];
      final cId = data['convoId'] as String? ?? '';
      convoId ??= cId;
      final row = _firestoreToDb(data, id, cId);
      unread += (row['status']=='sent' && row['senderId']==receiverId)?1:0;
      batch.insert('messages', row, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
    //if (convoId != null) _notify(convoId);

    final rows = await _db!.query('messages',where: "conversationId = ?",whereArgs: [convoId], limit: 1, orderBy: "createdAt DESC");

    if(rows.isNotEmpty){
      final first = rows[0];
      print(first['content']);
      updateConvo(convoId!, first['id'] as String, first['content'] as String, DateTime.fromMillisecondsSinceEpoch(first['createdAt'] as int), receiverId, first['senderId'] as String,incUnread: unread);
    }
  }

  @override
  Stream<ListOperation<Message>> getMessagesStream(String conversationId) {
    if (_controllers[conversationId] == null || _controllers[conversationId]!.isClosed) {
      _controllers[conversationId] = StreamController<ListOperation<Message>>.broadcast();
    }
    _queryMessagesSafe(conversationId).then((messages) {
      if (!_controllers[conversationId]!.isClosed) {
        _controllers[conversationId]?.add(FirstFetch<Message>(messages));
      }
    });
    return _controllers[conversationId]!.stream;
  }

  @override
  Stream<List<Conversation>> getConversationsStream() {
    if (_convoController == null|| _convoController!.isClosed) {
      _convoController = StreamController<List<Conversation>>.broadcast();
    }
    _queryConversations().then((convos) {
      print("convo lengthhhhhhhh ${convos.length}");
      _convoController!.add(convos);
    });
    return _convoController!.stream;
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
  
  @override
  Future<void> resetUnread(String convoId) async{
    if (_db == null || kIsWeb) return;
    await _db!.update(
      'conversations',
      {"unread" : 0},
      where: 'convoId = ?',
      whereArgs: [convoId],
    );
    _notifyConvo();
  }

  @override
  Future<void> updateConversationFriendStatus(String convoId, bool isFriend) async {
    if (_db == null || kIsWeb) return;
    await _db!.update(
      'conversations',
      {'isFriend': isFriend ? 1 : 0},
      where: 'convoId = ?',
      whereArgs: [convoId],
    );
    _notifyConvo();
  }

  @override
  Future<String?> getConvoIdByReceiverId(String receiverId) async {
    if (_db == null || kIsWeb) return null;
    final rows = await _db!.query(
      'conversations',
      where: 'receiverId = ?',
      whereArgs: [receiverId],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first['convoId'] as String? : null;
  }

  @override
  Future<List<Conversation>> queryAllConversations() async {
    if (_db == null) return [];
    final rows = await _db!.query(
      'conversations',
      orderBy: 'lastUpdateTime DESC',
    );
    return rows.map(_dbToConversation).toList();
  }

}
