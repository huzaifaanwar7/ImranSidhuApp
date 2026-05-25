import 'enums.dart';

class Player {
  final String id;
  final String fullName;
  final DateTime? dateOfBirth;
  final PlayerRole role;
  final BattingHand battingHand;
  final BowlingStyle? bowlingStyle;
  final String? photoUrl;
  final String? city;
  final int? jerseyNumber;
  final String? teamId;
  final bool retired;

  // Career aggregates entered by the scorer/admin.
  final int matches;
  final int innings;
  final int runs;
  final int highestScore;
  final double average;
  final double strikeRate;
  final int fours;
  final int sixes;
  final int fifties;
  final int hundreds;
  final int wickets;
  final String bestBowling;
  final double economy;
  final int catches;

  const Player({
    required this.id,
    required this.fullName,
    this.dateOfBirth,
    this.role = PlayerRole.batter,
    this.battingHand = BattingHand.right,
    this.bowlingStyle,
    this.photoUrl,
    this.city,
    this.jerseyNumber,
    this.teamId,
    this.retired = false,
    this.matches = 0,
    this.innings = 0,
    this.runs = 0,
    this.highestScore = 0,
    this.average = 0,
    this.strikeRate = 0,
    this.fours = 0,
    this.sixes = 0,
    this.fifties = 0,
    this.hundreds = 0,
    this.wickets = 0,
    this.bestBowling = '-',
    this.economy = 0,
    this.catches = 0,
  });

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
