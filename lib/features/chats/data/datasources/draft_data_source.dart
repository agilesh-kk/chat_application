import 'package:shared_preferences/shared_preferences.dart';

class DraftService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _prefsInstance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<String?> getDraft(String convoId) async {
    final prefs = await _prefsInstance;
    return prefs.getString('draft_$convoId');
  }

  Future<void> saveDraft(String convoId, String text) async {
    final prefs = await _prefsInstance;
    await prefs.setString('draft_$convoId', text);
  }

  Future<void> clearDraft(String convoId) async {
    final prefs = await _prefsInstance;
    await prefs.remove('draft_$convoId');
  }
}
