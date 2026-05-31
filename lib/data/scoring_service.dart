import 'dart:async';

import 'api_client.dart';
import 'ball_outbox.dart';

/// Thin wrapper around the live scoring endpoints.
class ScoringService {
  ScoringService._();
  static final ScoringService instance = ScoringService._();
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> startInnings({
    required int matchId,
    required int battingTeamId,
    required int bowlingTeamId,
    int inningsNumber = 1,
    int? target,
  }) async {
    final res = await _api.post('/api/matches/$matchId/innings', {
      'battingTeamId': battingTeamId,
      'bowlingTeamId': bowlingTeamId,
      'inningsNumber': inningsNumber,
      if (target != null) 'target': target,
    });
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>?> recordBall({
    required int matchId,
    required int inningsId,
    required int overNumber,
    required int ballInOver,
    int? strikerPlayerId,
    int? nonStrikerPlayerId,
    int? bowlerPlayerId,
    int runsBatter = 0,
    int runsExtras = 0,
    String? extrasType,
    bool isLegalDelivery = true,
    bool isFreeHit = false,
    bool isWicket = false,
    String? wicketType,
    int? dismissedPlayerId,
    int? fielderPlayerId,
    String? commentary,
  }) async {
    final payload = {
      'ballGuid': _newGuid(),
      'inningsId': inningsId,
      'overNumber': overNumber,
      'ballInOver': ballInOver,
      'strikerPlayerId': strikerPlayerId,
      'nonStrikerPlayerId': nonStrikerPlayerId,
      'bowlerPlayerId': bowlerPlayerId,
      'runsBatter': runsBatter,
      'runsExtras': runsExtras,
      'extrasType': extrasType,
      'isLegalDelivery': isLegalDelivery,
      'isFreeHit': isFreeHit,
      'isWicket': isWicket,
      'wicketType': wicketType,
      'dismissedPlayerId': dismissedPlayerId,
      'fielderPlayerId': fielderPlayerId,
      'commentary': commentary,
    };
    try {
      final res = await _api.post('/api/matches/$matchId/balls', payload);
      // Opportunistic flush of any earlier offline-queued balls.
      unawaited(BallOutbox.instance.drain());
      return Map<String, dynamic>.from(res as Map);
    } catch (_) {
      // Network failure — enqueue for later. BallGuid keeps it idempotent.
      await BallOutbox.instance.enqueue(matchId, payload);
      return null;
    }
  }

  Future<void> undoLastBall(int matchId) async {
    await _api.post('/api/matches/$matchId/balls/undo');
  }

  Future<void> endMatch({
    required int matchId,
    int? winnerTeamId,
    String? resultMargin,
    int? manOfTheMatchPlayerId,
  }) async {
    await _api.post('/api/matches/$matchId/end', {
      'winnerTeamId': winnerTeamId,
      'resultMargin': resultMargin,
      'manOfTheMatchPlayerId': manOfTheMatchPlayerId,
    });
  }

  /// Public — no auth required. Used by viewers to poll for live updates.
  Future<Map<String, dynamic>> scorecard(int matchId) async {
    final res = await _api.get('/api/matches/$matchId/scorecard');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> applyPenalty({
    required int matchId,
    int? homePenaltyRuns,
    int? awayPenaltyRuns,
    String? reason,
  }) async {
    final res = await _api.post('/api/matches/$matchId/penalty', {
      'homePenaltyRuns': homePenaltyRuns,
      'awayPenaltyRuns': awayPenaltyRuns,
      'penaltyReason': reason,
    });
    return Map<String, dynamic>.from(res as Map);
  }

  // ---

  String _newGuid() {
    // RFC4122-ish v4 GUID; backend only needs uniqueness for idempotency.
    final r = DateTime.now().microsecondsSinceEpoch;
    return '${_hex(r, 8)}-${_hex(r >> 32, 4)}-4${_hex(r >> 16, 3)}-8${_hex(r, 3)}-${_hex(r * 31, 12)}';
  }

  String _hex(int v, int len) =>
      v.abs().toRadixString(16).padLeft(len, '0').substring(0, len);
}
