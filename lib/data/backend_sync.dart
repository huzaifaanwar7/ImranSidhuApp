import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/innings.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/tournament.dart';
import 'api_client.dart';
import 'app_store.dart';

/// Bridges the ASP.NET Core backend with the local [AppStore] cache.
///
/// On [refreshAll] we pull every list (teams, players, tournaments, matches),
/// convert them to the local model types, and replace the in-memory cache.
/// All screens read from [AppStore] so the rest of the app keeps working
/// unchanged — it just now sees server data.
class BackendSync {
  BackendSync._();
  static final BackendSync instance = BackendSync._();

  final _api = ApiClient.instance;
  final _store = AppStore.instance;

  /// Pulls everything from the backend in parallel.
  /// Works for both authenticated and anonymous users — all list endpoints are public.
  Future<void> refreshAll() async {
    try {
      // Start all requests concurrently, then await.
      final teamsF = _fetchTeams();
      final playersF = _fetchPlayers();
      final tournamentsF = _fetchTournaments();
      final matchesF = _fetchMatches();

      final teams = await teamsF;
      final players = await playersF;
      final tournaments = await tournamentsF;
      final (matches, embeddedTeams) = await matchesF;

      // Merge teams referenced by matches (e.g. teams removed from the public
      // list, or not yet synced) so the UI shows real names instead of
      // "Unknown team". Real team records take priority over embedded stubs.
      final byId = <String, Team>{};
      for (final t in embeddedTeams) {
        byId[t.id] = t;
      }
      for (final t in teams) {
        byId[t.id] = t;
      }

      await _store.replaceAll(
        teams: byId.values.toList(),
        players: players,
        tournaments: tournaments,
        matches: matches,
      );
    } catch (e) {
      debugPrint('[BackendSync] refreshAll failed: $e');
    }
  }

  // -------- CREATE / UPDATE --------

  Future<Team> upsertTeam(Team t, {String? logoBase64, int? captainUserId}) async {
    final body = <String, dynamic>{
      'name': t.name,
      'shortCode': t.shortCode,
      'category': t.category.label.replaceAll('-', ''),
      'city': null,
      'homeVenue': t.homeVenue,
      'foundedYear': t.foundedYear,
      'primaryColorHex': _hexFromColor(t.primaryColor),
      'secondaryColorHex': _hexFromColor(t.secondaryColor),
      if (captainUserId != null) 'captainUserId': captainUserId,
      if (logoBase64 != null) 'logoBase64': logoBase64,
    };
    final isNew = int.tryParse(t.id) == null;
    final res = isNew
        ? await _api.post('/api/teams', body)
        : await _api.put('/api/teams/${t.id}', body);
    final fresh = _teamFromApi(Map<String, dynamic>.from(res as Map));
    await _store.saveTeam(fresh);
    return fresh;
  }

  Future<void> deleteTeam(String id) async {
    if (int.tryParse(id) != null) {
      await _api.delete('/api/teams/$id');
    }
    await _store.deleteTeam(id);
  }

  Future<void> assignCaptain(String teamId, int captainUserId) async {
    await _api.post('/api/teams/$teamId/captain', {'captainUserId': captainUserId});
  }

  Future<Player> upsertPlayer(Player p, {String? photoBase64}) async {
    final body = <String, dynamic>{
      'fullName': p.fullName,
      'dateOfBirth': p.dateOfBirth?.toIso8601String(),
      'role': _playerRoleString(p.role),
      'battingHandedness': p.battingHand == BattingHand.left ? 'Left' : 'Right',
      'bowlingStyle': p.bowlingStyle?.label,
      'city': p.city,
      'teamId': int.tryParse(p.teamId ?? ''),
      'jerseyNumber': p.jerseyNumber,
      if (photoBase64 != null) 'photoBase64': photoBase64,
    };
    final isNew = int.tryParse(p.id) == null;
    final res = isNew
        ? await _api.post('/api/players', body)
        : await _api.put('/api/players/${p.id}', body);
    final fresh = _playerFromApi(Map<String, dynamic>.from(res as Map));
    await _store.savePlayer(fresh);
    return fresh;
  }

  Future<void> deletePlayer(String id) async {
    if (int.tryParse(id) != null) {
      await _api.delete('/api/players/$id');
    }
    await _store.deletePlayer(id);
  }

  Future<Tournament> upsertTournament(Tournament t, {String? logoBase64}) async {
    final body = <String, dynamic>{
      'name': t.name,
      'edition': t.edition,
      'category': t.category.label.replaceAll('-', ''),
      'format': _tFormat(t.format),
      'matchFormat': t.matchFormat.label,
      'oversPerInnings': t.oversPerInnings,
      'startDate': t.startDate.toIso8601String(),
      'endDate': t.endDate.toIso8601String(),
      if (logoBase64 != null) 'logoBase64': logoBase64,
    };
    final isNew = int.tryParse(t.id) == null;
    final res = isNew
        ? await _api.post('/api/tournaments', body)
        : await _api.put('/api/tournaments/${t.id}', body);
    final fresh = _tournamentFromApi(Map<String, dynamic>.from(res as Map));
    await _store.saveTournament(fresh);
    return fresh;
  }

  Future<void> deleteTournament(String id) async {
    if (int.tryParse(id) != null) {
      await _api.delete('/api/tournaments/$id');
    }
    await _store.deleteTournament(id);
  }

  Future<CricketMatch> upsertMatch(
    CricketMatch m, {
    int? ballsPerOver,
    int? homePenaltyRuns,
    int? awayPenaltyRuns,
    String? penaltyReason,
  }) async {
    final body = <String, dynamic>{
      'tournamentId': int.tryParse(m.tournamentId ?? ''),
      'matchName': m.matchName,
      'homeTeamId': int.tryParse(m.homeTeamId),
      'awayTeamId': int.tryParse(m.awayTeamId),
      'venue': m.venue,
      'scheduledStart': m.scheduledStart.toIso8601String(),
      'matchFormat': m.format.label,
      'oversPerInnings': m.oversPerInnings,
      if (ballsPerOver != null) 'ballsPerOver': ballsPerOver,
      if (homePenaltyRuns != null) 'homePenaltyRuns': homePenaltyRuns,
      if (awayPenaltyRuns != null) 'awayPenaltyRuns': awayPenaltyRuns,
      if (penaltyReason != null && penaltyReason.isNotEmpty) 'penaltyReason': penaltyReason,
      'stageLabel': m.stageLabel,
    };
    final isNew = int.tryParse(m.id) == null;
    final res = isNew
        ? await _api.post('/api/matches', body)
        : await _api.put('/api/matches/${m.id}', body);
    final fresh = _matchFromApi(Map<String, dynamic>.from(res as Map));
    await _store.saveMatch(fresh);
    return fresh;
  }

  // -------- LIST FETCH --------

  Future<List<Team>> _fetchTeams() async {
    final res = await _api.get('/api/teams', query: {'pageSize': 500});
    final items = (res['items'] as List).cast<Map>().map((m) => Map<String, dynamic>.from(m));
    return items.map(_teamFromApi).toList();
  }

  Future<List<Player>> _fetchPlayers() async {
    final res = await _api.get('/api/players', query: {'pageSize': 500});
    final items = (res['items'] as List).cast<Map>().map((m) => Map<String, dynamic>.from(m));
    return items.map(_playerFromApi).toList();
  }

  Future<List<Tournament>> _fetchTournaments() async {
    final res = await _api.get('/api/tournaments', query: {'pageSize': 500});
    final items = (res['items'] as List).cast<Map>().map((m) => Map<String, dynamic>.from(m));
    return items.map(_tournamentFromApi).toList();
  }

  /// Returns parsed matches plus any teams embedded in the match payloads
  /// (homeTeam/awayTeam), so referenced teams resolve to real names.
  Future<(List<CricketMatch>, List<Team>)> _fetchMatches() async {
    final res = await _api.get('/api/matches', query: {'pageSize': 500});
    final items = (res['items'] as List)
        .cast<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final matches = items.map(_matchFromApi).toList();
    final embedded = <Team>[];
    for (final m in items) {
      for (final key in const ['homeTeam', 'awayTeam']) {
        if (m[key] is Map) {
          final t = Map<String, dynamic>.from(m[key] as Map);
          if (t['id'] != null) embedded.add(_teamFromApi(t));
        }
      }
    }
    return (matches, embedded);
  }

  // -------- MODEL CONVERTERS --------

  Team _teamFromApi(Map<String, dynamic> j) {
    Map<String, dynamic> t = j;
    if (j['team'] is Map) t = Map<String, dynamic>.from(j['team'] as Map);
    return Team(
      id: '${t['id']}',
      name: t['name'] as String? ?? '',
      shortCode: t['shortCode'] as String? ?? '',
      category: _teamCategoryFrom(t['category']),
      foundedYear: t['foundedYear'] as int?,
      homeVenue: t['homeVenue'] as String?,
      primaryColor: _colorFromHex(t['primaryColorHex'] as String?, const Color(0xFF0F2447)),
      secondaryColor: _colorFromHex(t['secondaryColorHex'] as String?, const Color(0xFFD4AF37)),
      flagUrl: t['logoUrl'] as String?,
      captainId: t['captainPlayerId']?.toString(),
    );
  }

  Player _playerFromApi(Map<String, dynamic> j) {
    Map<String, dynamic> p = j;
    if (j['player'] is Map) p = Map<String, dynamic>.from(j['player'] as Map);
    return Player(
      id: '${p['id']}',
      fullName: p['fullName'] as String? ?? '',
      dateOfBirth: _parseDate(p['dateOfBirth']),
      role: _playerRoleFrom(p['role']),
      battingHand: (p['battingHandedness'] == 'Left') ? BattingHand.left : BattingHand.right,
      bowlingStyle: _bowlingStyleFrom(p['bowlingStyle']),
      photoUrl: p['photoUrl'] as String?,
      city: p['city'] as String?,
      jerseyNumber: p['jerseyNumber'] as int?,
      teamId: p['teamId']?.toString(),
    );
  }

  Tournament _tournamentFromApi(Map<String, dynamic> j) {
    Map<String, dynamic> t = j;
    if (j['tournament'] is Map) t = Map<String, dynamic>.from(j['tournament'] as Map);
    return Tournament(
      id: '${t['id']}',
      name: t['name'] as String? ?? '',
      edition: t['edition'] as String? ?? '${DateTime.now().year}',
      category: _teamCategoryFrom(t['category']),
      format: _tournamentFormatFrom(t['format']),
      matchFormat: _matchFormatFrom(t['matchFormat']),
      oversPerInnings: (t['oversPerInnings'] as int?) ?? 20,
      startDate: _parseDate(t['startDate']) ?? DateTime.now(),
      endDate: _parseDate(t['endDate']) ?? DateTime.now(),
      stage: _stageFrom(t['stage']),
      logoUrl: t['logoUrl'] as String?,
    );
  }

  CricketMatch _matchFromApi(Map<String, dynamic> j) {
    Map<String, dynamic> m = j;
    if (j['match'] is Map) m = Map<String, dynamic>.from(j['match'] as Map);
    return CricketMatch(
      id: '${m['id']}',
      tournamentId: m['tournamentId']?.toString(),
      matchName: m['matchName'] as String? ?? 'Untitled Match',
      homeTeamId: '${m['homeTeamId'] ?? m['homeTeam']?['id'] ?? ''}',
      awayTeamId: '${m['awayTeamId'] ?? m['awayTeam']?['id'] ?? ''}',
      venue: m['venue'] as String?,
      scheduledStart: _parseDate(m['scheduledStart']) ?? DateTime.now(),
      actualStart: _parseDate(m['actualStart']),
      actualEnd: _parseDate(m['actualEnd']),
      format: _matchFormatFrom(m['matchFormat']),
      oversPerInnings: (m['oversPerInnings'] as int?) ?? 20,
      tossWinnerTeamId: m['tossWinnerTeamId']?.toString(),
      tossDecision: _tossDecisionFrom(m['tossDecision']),
      state: _matchStateFrom(m['matchState']),
      resultWinnerTeamId: m['resultWinnerTeamId']?.toString(),
      resultMargin: m['resultMargin'] as String?,
      manOfTheMatchPlayerId: m['manOfTheMatchPlayerId']?.toString(),
      stageLabel: m['stageLabel'] as String?,
      innings: _inningsSummariesFromApi(m['innings']),
    );
  }

  /// Lightweight innings list from the match-list payload so cards can show
  /// scores. Full batting/bowling cards come from the /scorecard endpoint.
  List<Innings> _inningsSummariesFromApi(dynamic raw) {
    if (raw is! List) return const [];
    int gi(Object? v) => (v is num) ? v.toInt() : (int.tryParse('$v') ?? 0);
    return raw.whereType<Map>().map((e) {
      final i = Map<String, dynamic>.from(e);
      return Innings(
        id: '${i['id']}',
        matchId: '${i['matchId']}',
        inningsNumber: gi(i['inningsNumber']) == 2 ? 2 : 1,
        battingTeamId: '${i['battingTeamId']}',
        bowlingTeamId: '${i['bowlingTeamId']}',
        totalRuns: gi(i['totalRuns']),
        wickets: gi(i['wickets']),
        legalBalls: gi(i['legalBallsBowled']),
        target: i['target'] == null ? null : gi(i['target']),
      );
    }).toList();
  }

  // -------- ENUM HELPERS --------

  TeamCategory _teamCategoryFrom(dynamic v) {
    final s = (v as String?)?.toLowerCase() ?? '';
    if (s.contains('u19') || s.contains('u-19')) return TeamCategory.u19;
    if (s.contains('vet')) return TeamCategory.veterans;
    if (s.contains('women')) return TeamCategory.women;
    return TeamCategory.senior;
  }

  PlayerRole _playerRoleFrom(dynamic v) {
    final s = (v as String?)?.toLowerCase() ?? '';
    if (s.startsWith('bow')) return PlayerRole.bowler;
    if (s.startsWith('all')) return PlayerRole.allRounder;
    if (s.startsWith('wic')) return PlayerRole.wicketKeeper;
    return PlayerRole.batter;
  }

  String _playerRoleString(PlayerRole r) => switch (r) {
        PlayerRole.batter => 'Batter',
        PlayerRole.bowler => 'Bowler',
        PlayerRole.allRounder => 'AllRounder',
        PlayerRole.wicketKeeper => 'WicketKeeper',
      };

  BowlingStyle? _bowlingStyleFrom(dynamic v) {
    final s = v as String?;
    if (s == null) return null;
    for (final b in BowlingStyle.values) {
      if (b.label == s) return b;
    }
    return null;
  }

  TournamentFormat _tournamentFormatFrom(dynamic v) {
    final s = (v as String?) ?? 'RoundRobin';
    if (s == 'Knockout') return TournamentFormat.knockout;
    if (s == 'Hybrid') return TournamentFormat.hybrid;
    return TournamentFormat.roundRobin;
  }

  String _tFormat(TournamentFormat f) => switch (f) {
        TournamentFormat.knockout => 'Knockout',
        TournamentFormat.hybrid => 'Hybrid',
        TournamentFormat.roundRobin => 'RoundRobin',
      };

  MatchFormat _matchFormatFrom(dynamic v) {
    final s = (v as String?) ?? 'T20';
    if (s == 'T10') return MatchFormat.t10;
    if (s == 'ODI') return MatchFormat.odi;
    if (s == 'Custom') return MatchFormat.custom;
    return MatchFormat.t20;
  }

  TournamentStage _stageFrom(dynamic v) {
    final s = (v as String?) ?? '';
    return switch (s) {
      'GroupStage' => TournamentStage.groupStage,
      'QuarterFinals' => TournamentStage.quarterFinals,
      'SemiFinals' => TournamentStage.semiFinals,
      'Final' => TournamentStage.finalStage,
      'Completed' => TournamentStage.completed,
      _ => TournamentStage.registration,
    };
  }

  MatchState _matchStateFrom(dynamic v) {
    final s = (v as String?) ?? 'Scheduled';
    return switch (s) {
      'Live' => MatchState.live,
      'InningsBreak' => MatchState.inningsBreak,
      'Completed' => MatchState.completed,
      'Abandoned' => MatchState.abandoned,
      'Cancelled' => MatchState.cancelled,
      _ => MatchState.scheduled,
    };
  }

  TossDecision? _tossDecisionFrom(dynamic v) {
    final s = v as String?;
    if (s == 'Bat') return TossDecision.bat;
    if (s == 'Bowl') return TossDecision.bowl;
    return null;
  }

  DateTime? _parseDate(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  Color _colorFromHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final clean = hex.replaceAll('#', '');
    if (clean.length != 6) return fallback;
    final v = int.tryParse('FF$clean', radix: 16);
    return v == null ? fallback : Color(v);
  }

  String _hexFromColor(Color c) {
    final v = c.toARGB32() & 0xFFFFFF;
    return '#${v.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
