enum UserRole { admin, organizer, scorer, captain, player, fan }

enum PlayerRole { batter, bowler, allRounder, wicketKeeper }

extension PlayerRoleX on PlayerRole {
  String get label => switch (this) {
        PlayerRole.batter => 'Batter',
        PlayerRole.bowler => 'Bowler',
        PlayerRole.allRounder => 'All-Rounder',
        PlayerRole.wicketKeeper => 'Wicket-Keeper',
      };
  String get short => switch (this) {
        PlayerRole.batter => 'BAT',
        PlayerRole.bowler => 'BOWL',
        PlayerRole.allRounder => 'AR',
        PlayerRole.wicketKeeper => 'WK',
      };
}

enum BattingHand { right, left }

enum BowlingStyle {
  rightArmFast,
  rightArmMedium,
  rightArmOffSpin,
  rightArmLegSpin,
  leftArmFast,
  leftArmMedium,
  leftArmOrthodox,
  leftArmChinaman,
}

extension BowlingStyleX on BowlingStyle {
  String get label => switch (this) {
        BowlingStyle.rightArmFast => 'Right-Arm Fast',
        BowlingStyle.rightArmMedium => 'Right-Arm Medium',
        BowlingStyle.rightArmOffSpin => 'Right-Arm Off-Spin',
        BowlingStyle.rightArmLegSpin => 'Right-Arm Leg-Spin',
        BowlingStyle.leftArmFast => 'Left-Arm Fast',
        BowlingStyle.leftArmMedium => 'Left-Arm Medium',
        BowlingStyle.leftArmOrthodox => 'Left-Arm Orthodox',
        BowlingStyle.leftArmChinaman => 'Left-Arm Chinaman',
      };
}

enum TeamCategory { senior, u19, veterans, women }

extension TeamCategoryX on TeamCategory {
  String get label => switch (this) {
        TeamCategory.senior => 'Senior',
        TeamCategory.u19 => 'U-19',
        TeamCategory.veterans => 'Veterans',
        TeamCategory.women => 'Women',
      };
}

enum MatchFormat { t10, t20, odi, custom }

extension MatchFormatX on MatchFormat {
  String get label => switch (this) {
        MatchFormat.t10 => 'T10',
        MatchFormat.t20 => 'T20',
        MatchFormat.odi => 'ODI',
        MatchFormat.custom => 'Custom',
      };
  int get overs => switch (this) {
        MatchFormat.t10 => 10,
        MatchFormat.t20 => 20,
        MatchFormat.odi => 50,
        MatchFormat.custom => 0,
      };
}

enum MatchState {
  scheduled,
  live,
  inningsBreak,
  completed,
  abandoned,
  cancelled
}

extension MatchStateX on MatchState {
  String get label => switch (this) {
        MatchState.scheduled => 'Scheduled',
        MatchState.live => 'LIVE',
        MatchState.inningsBreak => 'Innings Break',
        MatchState.completed => 'Completed',
        MatchState.abandoned => 'Abandoned',
        MatchState.cancelled => 'Cancelled',
      };
}

enum TossDecision { bat, bowl }

enum TournamentFormat { roundRobin, knockout, hybrid }

extension TournamentFormatX on TournamentFormat {
  String get label => switch (this) {
        TournamentFormat.roundRobin => 'Round Robin',
        TournamentFormat.knockout => 'Knockout',
        TournamentFormat.hybrid => 'Hybrid',
      };
}

enum TournamentStage {
  registration,
  groupStage,
  quarterFinals,
  semiFinals,
  finalStage,
  completed,
}

extension TournamentStageX on TournamentStage {
  String get label => switch (this) {
        TournamentStage.registration => 'Registration',
        TournamentStage.groupStage => 'Group Stage',
        TournamentStage.quarterFinals => 'Quarter-Finals',
        TournamentStage.semiFinals => 'Semi-Finals',
        TournamentStage.finalStage => 'Final',
        TournamentStage.completed => 'Completed',
      };
}

enum WicketType {
  bowled,
  caught,
  lbw,
  runOut,
  stumped,
  hitWicket,
  retired,
  obstructing,
  handled,
  timedOut,
}

extension WicketTypeX on WicketType {
  String get label => switch (this) {
        WicketType.bowled => 'Bowled',
        WicketType.caught => 'Caught',
        WicketType.lbw => 'LBW',
        WicketType.runOut => 'Run Out',
        WicketType.stumped => 'Stumped',
        WicketType.hitWicket => 'Hit Wicket',
        WicketType.retired => 'Retired',
        WicketType.obstructing => 'Obstructing the Field',
        WicketType.handled => 'Handled the Ball',
        WicketType.timedOut => 'Timed Out',
      };
  String get short => switch (this) {
        WicketType.bowled => 'b',
        WicketType.caught => 'c',
        WicketType.lbw => 'lbw',
        WicketType.runOut => 'run out',
        WicketType.stumped => 'st',
        WicketType.hitWicket => 'hit wkt',
        WicketType.retired => 'retired',
        WicketType.obstructing => 'obs',
        WicketType.handled => 'handled',
        WicketType.timedOut => 'timed out',
      };
}

enum ExtraType { wide, noBall, bye, legBye, penalty }

extension ExtraTypeX on ExtraType {
  String get label => switch (this) {
        ExtraType.wide => 'Wide',
        ExtraType.noBall => 'No Ball',
        ExtraType.bye => 'Bye',
        ExtraType.legBye => 'Leg Bye',
        ExtraType.penalty => 'Penalty',
      };
  String get short => switch (this) {
        ExtraType.wide => 'Wd',
        ExtraType.noBall => 'Nb',
        ExtraType.bye => 'B',
        ExtraType.legBye => 'Lb',
        ExtraType.penalty => 'P',
      };
}

enum SponsorSlot {
  splash,
  dashboard,
  scorecard,
  commentary,
  overCard,
  kit,
  matchPresentedBy,
}

extension SponsorSlotX on SponsorSlot {
  String get label => switch (this) {
        SponsorSlot.splash => 'Splash',
        SponsorSlot.dashboard => 'Dashboard',
        SponsorSlot.scorecard => 'Scorecard',
        SponsorSlot.commentary => 'Commentary',
        SponsorSlot.overCard => 'Over Card',
        SponsorSlot.kit => 'Kit',
        SponsorSlot.matchPresentedBy => 'Match Presented By',
      };
}
