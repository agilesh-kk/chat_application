import 'dart:convert';
import 'dart:io';

Future<String> _notifDir() async {
  return '${Directory.systemTemp.path}/chat_notifs';
}

Future<List<Map<String, dynamic>>> loadChatMessages(String chatId) async {
  try {
    final file = File('${await _notifDir()}/$chatId.json');
    if (await file.exists()) {
      return List<Map<String, dynamic>>.from(
        jsonDecode(await file.readAsString()),
      );
    }
  } catch (_) {}
  return [];
}

Future<void> saveChatMessages(String chatId, List<Map<String, dynamic>> messages) async {
  try {
    final dir = Directory(await _notifDir());
    if (!await dir.exists()) await dir.create(recursive: true);
    await File('${dir.path}/$chatId.json').writeAsString(jsonEncode(messages));
  } catch (_) {}
}

Future<void> removeChatMessages(String chatId) async {
  try {
    final dir = await _notifDir();
    await File('$dir/$chatId.json').delete();
    final chats = await loadActiveChats();
    chats.remove(chatId);
    await saveActiveChats(chats);
  } catch (_) {}
}

Future<List<String>> loadActiveChats() async {
  try {
    final file = File('${await _notifDir()}/_active.json');
    if (await file.exists()) {
      return List<String>.from(jsonDecode(await file.readAsString()));
    }
  } catch (_) {}
  return [];
}

Future<void> saveActiveChats(List<String> chats) async {
  try {
    final dir = Directory(await _notifDir());
    if (!await dir.exists()) await dir.create(recursive: true);
    await File('${dir.path}/_active.json').writeAsString(jsonEncode(chats));
  } catch (_) {}
}
