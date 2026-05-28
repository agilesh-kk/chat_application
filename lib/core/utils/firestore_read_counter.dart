import 'package:flutter/foundation.dart';

class FirestoreReadCounter {
  static final FirestoreReadCounter _instance = FirestoreReadCounter._();
  factory FirestoreReadCounter() => _instance;
  FirestoreReadCounter._();

  final Map<String, int> _serverReads = {};
  int _grandTotal = 0;

  void countServerRead(String feature, int docCount) {
    if (docCount <= 0) return;
    _serverReads[feature] = (_serverReads[feature] ?? 0) + docCount;
    _grandTotal += docCount;
    debugPrint(
        '📖 FIRESTORE SERVER READ [$feature] +$docCount | grand total: $_grandTotal');
  }

  void printSummary() {
    if (_serverReads.isEmpty) return;
    debugPrint('═══════════════════════════════════════');
    debugPrint('🔥 FIRESTORE SERVER READ SUMMARY');
    _serverReads.forEach((k, v) {
      debugPrint('  $k: $v');
    });
    debugPrint('───────────────────────────────────────');
    debugPrint('  ALL READS TOTAL: $_grandTotal server reads');
    debugPrint('═══════════════════════════════════════');
  }

  void reset() {
    _serverReads.clear();
    _grandTotal = 0;
  }
}
