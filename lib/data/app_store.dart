import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/enums.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/tournament.dart';

class AppStore extends ChangeNotifier {
  AppStore._();

  static final AppStore instance = AppStore._();

  static const _teamsKey = 'ismvcc.teams.v1';
  static const _playersKey = 'ismvcc.players.v1';
  static const _tournamentsKey = 'ismvcc.tournaments.v1';
  static const _matchesKey = 'ismvcc.matches.v1';

  final List<Team> _teams = [];
  final List<Player> _players = [];
  final List<Tournament> _tournaments = [];
  final List<CricketMatch> _matches = [];

  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<Team> get teams => List.unmodifiable(_teams);
  List<Player> get players => List.unmodifiable(_players);
  List<Tournament> get tournaments => List.unmodifiable(_tournaments);
  List<CricketMatch> get matches => List.unmodifiable(_matches);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _teams
      ..clear()
      ..addAll(_decodeList(prefs.getString(_teamsKey), _teamFromJson));
    _players
      ..clear()
      ..addAll(_decodeList(prefs.getString(_playersKey), _playerFromJson));
    _tournaments
      ..clear()
      ..addAll(_decodeList(
        prefs.getString(_tournamentsKey),
        _tournamentFromJson,
      ));
    _matches
      ..clear()
      ..addAll(_decodeList(prefs.getString(_matchesKey), _matchFromJson));
    _loaded = true;
    notifyListeners();
  }

  String nextId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

  Team? teamById(String? id) {
    if (id == null) return null;
    for (final team in _teams) {
      if (team.id == id) return team;
    }
    return null;
  }

  Player? playerById(String? id) {
    if (id == null) return null;
    for (final player in _players) {
      if (player.id == id) return player;
    }
    return null;
  }

  Tournament? tournamentById(String? id) {
    if (id == null) return null;
    for (final tournament in _tournaments) {
      if (tournament.id == id) return tournament;
    }
    return null;
  }

  CricketMatch? matchById(String? id) {
    if (id == null) return null;
    for (final match in _matches) {
      if (match.id == id) return match;
    }
    return null;
  }

  List<Player> playersByTeam(String teamId) =>
      _players.where((player) => player.teamId == teamId).toList();

  List<CricketMatch> matchesForTeam(String teamId) => _matches
      .where(
          (match) => match.homeTeamId == teamId || match.awayTeamId == teamId)
      .toList();

  List<CricketMatch> matchesForTournament(String tournamentId) =>
      _matches.where((match) => match.tournamentId == tournamentId).toList();

  CricketMatch? get mostRecentMatch {
    if (_matches.isEmpty) return null;
    final sorted = [..._matches]..sort((a, b) {
        final ad = a.actualEnd ?? a.actualStart ?? a.scheduledStart;
        final bd = b.actualEnd ?? b.actualStart ?? b.scheduledStart;
        return bd.compareTo(ad);
      });
    return sorted.first;
  }

  CricketMatch? get featuredHomeMatch {
    final live = _matches.where((match) => match.isLive).toList()
      ..sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));
    if (live.isNotEmpty) return live.first;
    return mostRecentMatch;
  }

  List<Standing> standingsForTournament(String tournamentId) {
    final tournament = tournamentById(tournamentId);
    if (tournament == null) return const [];
    final teamIds = tournament.teamIds.isEmpty
        ? _teams.map((team) => team.id).toList()
        : tournament.teamIds;
    return teamIds.map((teamId) {
      final completed = matchesForTournament(tournamentId)
          .where((match) =>
              match.isCompleted &&
              (match.homeTeamId == teamId || match.awayTeamId == teamId))
          .toList();
      var wins = 0;
      var losses = 0;
      var ties = 0;
      var noResults = 0;
      for (final match in completed) {
        if (match.resultWinnerTeamId == null) {
          noResults++;
        } else if (match.resultWinnerTeamId == teamId) {
          wins++;
        } else {
          losses++;
        }
      }
      return Standing(
        teamId: teamId,
        matchesPlayed: completed.length,
        wins: wins,
        losses: losses,
        ties: ties,
        noResults: noResults,
        points: wins * 2 + ties + noResults,
      );
    }).toList()
      ..sort((a, b) {
        final points = b.points.compareTo(a.points);
        if (points != 0) return points;
        return b.wins.compareTo(a.wins);
      });
  }

  Future<void> saveTeam(Team team) async {
    final index = _teams.indexWhere((item) => item.id == team.id);
    if (index == -1) {
      _teams.add(team);
    } else {
      _teams[index] = team;
    }
    await _save();
  }

  Future<void> deleteTeam(String id) async {
    _teams.removeWhere((team) => team.id == id);
    for (var i = 0; i < _players.length; i++) {
      final player = _players[i];
      if (player.teamId == id) {
        _players[i] = _copyPlayer(player, teamId: null);
      }
    }
    for (var i = 0; i < _tournaments.length; i++) {
      final tournament = _tournaments[i];
      if (tournament.teamIds.contains(id)) {
        _tournaments[i] = _copyTournament(
          tournament,
          teamIds: tournament.teamIds.where((teamId) => teamId != id).toList(),
        );
      }
    }
    await _save();
  }

  Future<void> savePlayer(Player player) async {
    final index = _players.indexWhere((item) => item.id == player.id);
    if (index == -1) {
      _players.add(player);
    } else {
      _players[index] = player;
    }
    await _save();
  }

  Future<void> deletePlayer(String id) async {
    _players.removeWhere((player) => player.id == id);
    await _save();
  }

  Future<void> saveTournament(Tournament tournament) async {
    final index = _tournaments.indexWhere((item) => item.id == tournament.id);
    if (index == -1) {
      _tournaments.add(tournament);
    } else {
      _tournaments[index] = tournament;
    }
    await _save();
  }

  Future<void> deleteTournament(String id) async {
    _tournaments.removeWhere((tournament) => tournament.id == id);
    for (var i = 0; i < _matches.length; i++) {
      final match = _matches[i];
      if (match.tournamentId == id) {
        _matches[i] = _copyMatch(match, tournamentId: null);
      }
    }
    await _save();
  }

  Future<void> saveMatch(CricketMatch match) async {
    final index = _matches.indexWhere((item) => item.id == match.id);
    if (index == -1) {
      _matches.add(match);
    } else {
      _matches[index] = match;
    }
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _teamsKey, jsonEncode(_teams.map(_teamToJson).toList()));
    await prefs.setString(
      _playersKey,
      jsonEncode(_players.map(_playerToJson).toList()),
    );
    await prefs.setString(
      _tournamentsKey,
      jsonEncode(_tournaments.map(_tournamentToJson).toList()),
    );
    await prefs.setString(
      _matchesKey,
      jsonEncode(_matches.map(_matchToJson).toList()),
    );
    notifyListeners();
  }

  List<T> _decodeList<T>(String? source, T Function(Map<String, dynamic>) map) {
    if (source == null || source.isEmpty) return [];
    try {
      final decoded = jsonDecode(source);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => map(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static T _enumValue<T extends Enum>(
    List<T> values,
    Object? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  static int _intValue(Object? value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double _doubleValue(Object? value, [double fallback = 0]) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static Color _colorValue(Object? value, Color fallback) {
    if (value is int) return Color(value);
    if (value is String) {
      return Color(int.tryParse(value) ?? fallback.toARGB32());
    }
    return fallback;
  }

  static DateTime _dateValue(Object? value, DateTime fallback) {
    if (value is String) return DateTime.tryParse(value) ?? fallback;
    return fallback;
  }

  static Team _teamFromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? 'Unnamed Team',
        shortCode: (json['shortCode'] as String?) ?? 'TBD',
        category: _enumValue(
          TeamCategory.values,
          json['category'],
          TeamCategory.senior,
        ),
        foundedYear:
            json['foundedYear'] == null ? null : _intValue(json['foundedYear']),
        homeVenue: json['homeVenue'] as String?,
        primaryColor: _colorValue(
          json['primaryColor'],
          const Color(0xFF0F2447),
        ),
        secondaryColor: _colorValue(
          json['secondaryColor'],
          const Color(0xFFD4AF37),
        ),
        flagUrl: json['flagUrl'] as String?,
        captainId: json['captainId'] as String?,
        matchesPlayed: _intValue(json['matchesPlayed']),
        wins: _intValue(json['wins']),
        losses: _intValue(json['losses']),
        ties: _intValue(json['ties']),
        noResults: _intValue(json['noResults']),
      );

  static Map<String, dynamic> _teamToJson(Team team) => {
        'id': team.id,
        'name': team.name,
        'shortCode': team.shortCode,
        'category': team.category.name,
        'foundedYear': team.foundedYear,
        'homeVenue': team.homeVenue,
        'primaryColor': team.primaryColor.toARGB32(),
        'secondaryColor': team.secondaryColor.toARGB32(),
        'flagUrl': team.flagUrl,
        'captainId': team.captainId,
        'matchesPlayed': team.matchesPlayed,
        'wins': team.wins,
        'losses': team.losses,
        'ties': team.ties,
        'noResults': team.noResults,
      };

  static Player _playerFromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        fullName: (json['fullName'] as String?) ?? 'Unnamed Player',
        dateOfBirth: json['dateOfBirth'] == null
            ? null
            : _dateValue(json['dateOfBirth'], DateTime.now()),
        role: _enumValue(PlayerRole.values, json['role'], PlayerRole.batter),
        battingHand: _enumValue(
          BattingHand.values,
          json['battingHand'],
          BattingHand.right,
        ),
        bowlingStyle: json['bowlingStyle'] == null
            ? null
            : _enumValue(
                BowlingStyle.values,
                json['bowlingStyle'],
                BowlingStyle.rightArmMedium,
              ),
        photoUrl: json['photoUrl'] as String?,
        city: json['city'] as String?,
        jerseyNumber: json['jerseyNumber'] == null
            ? null
            : _intValue(json['jerseyNumber']),
        teamId: json['teamId'] as String?,
        retired: json['retired'] == true,
        matches: _intValue(json['matches']),
        innings: _intValue(json['innings']),
        runs: _intValue(json['runs']),
        highestScore: _intValue(json['highestScore']),
        average: _doubleValue(json['average']),
        strikeRate: _doubleValue(json['strikeRate']),
        fours: _intValue(json['fours']),
        sixes: _intValue(json['sixes']),
        fifties: _intValue(json['fifties']),
        hundreds: _intValue(json['hundreds']),
        wickets: _intValue(json['wickets']),
        bestBowling: (json['bestBowling'] as String?) ?? '-',
        economy: _doubleValue(json['economy']),
        catches: _intValue(json['catches']),
      );

  static Map<String, dynamic> _playerToJson(Player player) => {
        'id': player.id,
        'fullName': player.fullName,
        'dateOfBirth': player.dateOfBirth?.toIso8601String(),
        'role': player.role.name,
        'battingHand': player.battingHand.name,
        'bowlingStyle': player.bowlingStyle?.name,
        'photoUrl': player.photoUrl,
        'city': player.city,
        'jerseyNumber': player.jerseyNumber,
        'teamId': player.teamId,
        'retired': player.retired,
        'matches': player.matches,
        'innings': player.innings,
        'runs': player.runs,
        'highestScore': player.highestScore,
        'average': player.average,
        'strikeRate': player.strikeRate,
        'fours': player.fours,
        'sixes': player.sixes,
        'fifties': player.fifties,
        'hundreds': player.hundreds,
        'wickets': player.wickets,
        'bestBowling': player.bestBowling,
        'economy': player.economy,
        'catches': player.catches,
      };

  static Tournament _tournamentFromJson(Map<String, dynamic> json) =>
      Tournament(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? 'Unnamed Tournament',
        edition: (json['edition'] as String?) ?? DateTime.now().year.toString(),
        category: _enumValue(
          TeamCategory.values,
          json['category'],
          TeamCategory.senior,
        ),
        format: _enumValue(
          TournamentFormat.values,
          json['format'],
          TournamentFormat.roundRobin,
        ),
        startDate: _dateValue(json['startDate'], DateTime.now()),
        endDate: _dateValue(json['endDate'], DateTime.now()),
        stage: _enumValue(
          TournamentStage.values,
          json['stage'],
          TournamentStage.registration,
        ),
        logoUrl: json['logoUrl'] as String?,
        matchFormat: _enumValue(
          MatchFormat.values,
          json['matchFormat'],
          MatchFormat.t20,
        ),
        oversPerInnings: _intValue(json['oversPerInnings'], 20),
        teamIds: (json['teamIds'] as List?)?.whereType<String>().toList() ??
            const [],
        sponsorTitle: json['sponsorTitle'] as String?,
        totalRuns: _intValue(json['totalRuns']),
        totalWickets: _intValue(json['totalWickets']),
        totalSixes: _intValue(json['totalSixes']),
      );

  static Map<String, dynamic> _tournamentToJson(Tournament tournament) => {
        'id': tournament.id,
        'name': tournament.name,
        'edition': tournament.edition,
        'category': tournament.category.name,
        'format': tournament.format.name,
        'startDate': tournament.startDate.toIso8601String(),
        'endDate': tournament.endDate.toIso8601String(),
        'stage': tournament.stage.name,
        'logoUrl': tournament.logoUrl,
        'matchFormat': tournament.matchFormat.name,
        'oversPerInnings': tournament.oversPerInnings,
        'teamIds': tournament.teamIds,
        'sponsorTitle': tournament.sponsorTitle,
        'totalRuns': tournament.totalRuns,
        'totalWickets': tournament.totalWickets,
        'totalSixes': tournament.totalSixes,
      };

  static CricketMatch _matchFromJson(Map<String, dynamic> json) => CricketMatch(
        id: json['id'] as String,
        tournamentId: json['tournamentId'] as String?,
        matchName: (json['matchName'] as String?) ?? 'Untitled Match',
        homeTeamId: (json['homeTeamId'] as String?) ?? '',
        awayTeamId: (json['awayTeamId'] as String?) ?? '',
        venue: json['venue'] as String?,
        scheduledStart: _dateValue(json['scheduledStart'], DateTime.now()),
        actualStart: json['actualStart'] == null
            ? null
            : _dateValue(json['actualStart'], DateTime.now()),
        actualEnd: json['actualEnd'] == null
            ? null
            : _dateValue(json['actualEnd'], DateTime.now()),
        format: _enumValue(MatchFormat.values, json['format'], MatchFormat.t20),
        oversPerInnings: _intValue(json['oversPerInnings'], 20),
        powerplayOvers: _intValue(json['powerplayOvers'], 6),
        tossWinnerTeamId: json['tossWinnerTeamId'] as String?,
        tossDecision: json['tossDecision'] == null
            ? null
            : _enumValue(
                TossDecision.values,
                json['tossDecision'],
                TossDecision.bat,
              ),
        state:
            _enumValue(MatchState.values, json['state'], MatchState.scheduled),
        resultWinnerTeamId: json['resultWinnerTeamId'] as String?,
        resultMargin: json['resultMargin'] as String?,
        manOfTheMatchPlayerId: json['manOfTheMatchPlayerId'] as String?,
        stageLabel: json['stageLabel'] as String?,
        homePlayingXI:
            (json['homePlayingXI'] as List?)?.whereType<String>().toList() ??
                const [],
        awayPlayingXI:
            (json['awayPlayingXI'] as List?)?.whereType<String>().toList() ??
                const [],
      );

  static Map<String, dynamic> _matchToJson(CricketMatch match) => {
        'id': match.id,
        'tournamentId': match.tournamentId,
        'matchName': match.matchName,
        'homeTeamId': match.homeTeamId,
        'awayTeamId': match.awayTeamId,
        'venue': match.venue,
        'scheduledStart': match.scheduledStart.toIso8601String(),
        'actualStart': match.actualStart?.toIso8601String(),
        'actualEnd': match.actualEnd?.toIso8601String(),
        'format': match.format.name,
        'oversPerInnings': match.oversPerInnings,
        'powerplayOvers': match.powerplayOvers,
        'tossWinnerTeamId': match.tossWinnerTeamId,
        'tossDecision': match.tossDecision?.name,
        'state': match.state.name,
        'resultWinnerTeamId': match.resultWinnerTeamId,
        'resultMargin': match.resultMargin,
        'manOfTheMatchPlayerId': match.manOfTheMatchPlayerId,
        'stageLabel': match.stageLabel,
        'homePlayingXI': match.homePlayingXI,
        'awayPlayingXI': match.awayPlayingXI,
      };

  static Player _copyPlayer(Player player, {String? teamId}) => Player(
        id: player.id,
        fullName: player.fullName,
        dateOfBirth: player.dateOfBirth,
        role: player.role,
        battingHand: player.battingHand,
        bowlingStyle: player.bowlingStyle,
        photoUrl: player.photoUrl,
        city: player.city,
        jerseyNumber: player.jerseyNumber,
        teamId: teamId,
        retired: player.retired,
        matches: player.matches,
        innings: player.innings,
        runs: player.runs,
        highestScore: player.highestScore,
        average: player.average,
        strikeRate: player.strikeRate,
        fours: player.fours,
        sixes: player.sixes,
        fifties: player.fifties,
        hundreds: player.hundreds,
        wickets: player.wickets,
        bestBowling: player.bestBowling,
        economy: player.economy,
        catches: player.catches,
      );

  static Tournament _copyTournament(
    Tournament tournament, {
    List<String>? teamIds,
  }) =>
      Tournament(
        id: tournament.id,
        name: tournament.name,
        edition: tournament.edition,
        category: tournament.category,
        format: tournament.format,
        startDate: tournament.startDate,
        endDate: tournament.endDate,
        stage: tournament.stage,
        logoUrl: tournament.logoUrl,
        matchFormat: tournament.matchFormat,
        oversPerInnings: tournament.oversPerInnings,
        teamIds: teamIds ?? tournament.teamIds,
        sponsorTitle: tournament.sponsorTitle,
        totalRuns: tournament.totalRuns,
        totalWickets: tournament.totalWickets,
        totalSixes: tournament.totalSixes,
      );

  static CricketMatch _copyMatch(
    CricketMatch match, {
    String? tournamentId,
  }) =>
      CricketMatch(
        id: match.id,
        tournamentId: tournamentId,
        matchName: match.matchName,
        homeTeamId: match.homeTeamId,
        awayTeamId: match.awayTeamId,
        venue: match.venue,
        scheduledStart: match.scheduledStart,
        actualStart: match.actualStart,
        actualEnd: match.actualEnd,
        format: match.format,
        oversPerInnings: match.oversPerInnings,
        powerplayOvers: match.powerplayOvers,
        tossWinnerTeamId: match.tossWinnerTeamId,
        tossDecision: match.tossDecision,
        state: match.state,
        resultWinnerTeamId: match.resultWinnerTeamId,
        resultMargin: match.resultMargin,
        manOfTheMatchPlayerId: match.manOfTheMatchPlayerId,
        stageLabel: match.stageLabel,
        innings: match.innings,
        homePlayingXI: match.homePlayingXI,
        awayPlayingXI: match.awayPlayingXI,
      );
}
