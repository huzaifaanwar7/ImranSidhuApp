import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

/// Local outbox for ball submissions made while offline.
///
/// Scorer's [LiveScoringScreen] enqueues a payload after every ball.
/// Drain runs on next successful network call and on app start. The
/// backend's `BallGuid` makes each POST idempotent — a flushed payload
/// that the server already saw is a no-op.
class BallOutbox {
  BallOutbox._();
  static final BallOutbox instance = BallOutbox._();

  static const _key = 'ismvcc.outbox.balls.v1';
  bool _draining = false;

  Future<void> enqueue(int matchId, Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _decode(prefs.getString(_key));
    list.add({'matchId': matchId, 'payload': payload});
    await prefs.setString(_key, jsonEncode(list));
  }

  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _decode(prefs.getString(_key));
      if (list.isEmpty) return;
      final remaining = <Map<String, dynamic>>[];
      for (final item in list) {
        final matchId = item['matchId'] as int;
        final payload = Map<String, dynamic>.from(item['payload'] as Map);
        try {
          await ApiClient.instance.post('/api/matches/$matchId/balls', payload);
        } catch (_) {
          remaining.add(item);
        }
      }
      await prefs.setString(_key, jsonEncode(remaining));
    } finally {
      _draining = false;
    }
  }

  Future<int> pendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_key)).length;
  }

  List<Map<String, dynamic>> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
      }
    } catch (_) {}
    return [];
  }
}
