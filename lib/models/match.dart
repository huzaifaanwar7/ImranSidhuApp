import 'enums.dart';
import 'innings.dart';

class CricketMatch {
  final String id;
  final String? tournamentId;
  final String matchName;
  final String homeTeamId;
  final String awayTeamId;
  final String? venue;
  final DateTime scheduledStart;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final MatchFormat format;
  final int oversPerInnings;
  final int powerplayOvers;
  final String? tossWinnerTeamId;
  final TossDecision? tossDecision;
  final MatchState state;
  final String? resultWinnerTeamId;
  final String? resultMargin;
  final String? manOfTheMatchPlayerId;
  final String? stageLabel;
  final List<Innings> innings;
  final List<String> homePlayingXI;
  final List<String> awayPlayingXI;

  const CricketMatch({
    required this.id,
    this.tournamentId,
    required this.matchName,
    required this.homeTeamId,
    required this.awayTeamId,
    this.venue,
    required this.scheduledStart,
    this.actualStart,
    this.actualEnd,
    this.format = MatchFormat.t20,
    this.oversPerInnings = 20,
    this.powerplayOvers = 6,
    this.tossWinnerTeamId,
    this.tossDecision,
    this.state = MatchState.scheduled,
    this.resultWinnerTeamId,
    this.resultMargin,
    this.manOfTheMatchPlayerId,
    this.stageLabel,
    this.innings = const [],
    this.homePlayingXI = const [],
    this.awayPlayingXI = const [],
  });

  bool get isLive => state == MatchState.live;
  bool get isCompleted => state == MatchState.completed;
  bool get isUpcoming => state == MatchState.scheduled;

  Innings? get currentInnings => innings.isEmpty ? null : innings.last;
  Innings? get firstInnings => innings.isNotEmpty ? innings.first : null;
}
