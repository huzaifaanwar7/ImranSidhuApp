class BatterScore {
  final String playerId;
  final int battingOrder;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final bool isOut;
  final bool isStriker;
  final String? dismissalDescription;

  const BatterScore({
    required this.playerId,
    required this.battingOrder,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.isOut = false,
    this.isStriker = false,
    this.dismissalDescription,
  });

  double get strikeRate => balls == 0 ? 0 : (runs / balls) * 100;
}

class BowlerFigures {
  final String playerId;
  final double oversBowled;
  final int maidens;
  final int runsConceded;
  final int wickets;
  final int dots;
  final int fours;
  final int sixes;
  final int wides;
  final int noBalls;
  final bool isCurrent;

  const BowlerFigures({
    required this.playerId,
    this.oversBowled = 0,
    this.maidens = 0,
    this.runsConceded = 0,
    this.wickets = 0,
    this.dots = 0,
    this.fours = 0,
    this.sixes = 0,
    this.wides = 0,
    this.noBalls = 0,
    this.isCurrent = false,
  });

  double get economy => oversBowled == 0 ? 0 : runsConceded / oversBowled;
  String get oversDisplay {
    final whole = oversBowled.floor();
    final balls = ((oversBowled - whole) * 10).round();
    return '$whole.$balls';
  }
}

class Partnership {
  final String batter1Id;
  final String batter2Id;
  final int runs;
  final int balls;
  final bool isUnbroken;

  const Partnership({
    required this.batter1Id,
    required this.batter2Id,
    required this.runs,
    required this.balls,
    this.isUnbroken = false,
  });
}

class FallOfWicket {
  final int wicketNumber;
  final int score;
  final double overs;
  final String batterOutId;

  const FallOfWicket({
    required this.wicketNumber,
    required this.score,
    required this.overs,
    required this.batterOutId,
  });
}

class Innings {
  final String id;
  final String matchId;
  final int inningsNumber;
  final String battingTeamId;
  final String bowlingTeamId;
  final int totalRuns;
  final int wickets;
  final int legalBalls;
  final int wides;
  final int noBalls;
  final int byes;
  final int legByes;
  final int? target;
  final bool isClosed;
  final List<BatterScore> battingCard;
  final List<BowlerFigures> bowlingCard;
  final List<FallOfWicket> fallOfWickets;
  final List<Partnership> partnerships;

  const Innings({
    required this.id,
    required this.matchId,
    required this.inningsNumber,
    required this.battingTeamId,
    required this.bowlingTeamId,
    this.totalRuns = 0,
    this.wickets = 0,
    this.legalBalls = 0,
    this.wides = 0,
    this.noBalls = 0,
    this.byes = 0,
    this.legByes = 0,
    this.target,
    this.isClosed = false,
    this.battingCard = const [],
    this.bowlingCard = const [],
    this.fallOfWickets = const [],
    this.partnerships = const [],
  });

  double get oversBowled {
    final whole = legalBalls ~/ 6;
    final rem = legalBalls % 6;
    return whole + (rem / 10);
  }

  String get oversDisplay {
    final whole = legalBalls ~/ 6;
    final rem = legalBalls % 6;
    return '$whole.$rem';
  }

  double get currentRunRate =>
      legalBalls == 0 ? 0 : (totalRuns / legalBalls) * 6;

  int get extras => wides + noBalls + byes + legByes;

  String get scoreDisplay => '$totalRuns/$wickets';
}
