import 'enums.dart';

class Tournament {
  final String id;
  final String name;
  final String edition;
  final TeamCategory category;
  final TournamentFormat format;
  final DateTime startDate;
  final DateTime endDate;
  final TournamentStage stage;
  final String? logoUrl;
  final MatchFormat matchFormat;
  final int oversPerInnings;
  final List<String> teamIds;
  final String? sponsorTitle;
  final int totalRuns;
  final int totalWickets;
  final int totalSixes;

  const Tournament({
    required this.id,
    required this.name,
    this.edition = '2026',
    this.category = TeamCategory.veterans,
    this.format = TournamentFormat.roundRobin,
    required this.startDate,
    required this.endDate,
    this.stage = TournamentStage.groupStage,
    this.logoUrl,
    this.matchFormat = MatchFormat.t20,
    this.oversPerInnings = 20,
    this.teamIds = const [],
    this.sponsorTitle,
    this.totalRuns = 0,
    this.totalWickets = 0,
    this.totalSixes = 0,
  });
}

class Standing {
  final String teamId;
  final String? group;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int ties;
  final int noResults;
  final int points;
  final double netRunRate;
  final List<String> last5Form;

  const Standing({
    required this.teamId,
    this.group,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.ties = 0,
    this.noResults = 0,
    this.points = 0,
    this.netRunRate = 0,
    this.last5Form = const [],
  });
}
