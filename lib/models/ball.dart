import 'enums.dart';

class Ball {
  final String id;
  final String inningsId;
  final int overNumber;
  final int ballInOver;
  final int sequence;
  final String strikerId;
  final String nonStrikerId;
  final String bowlerId;
  final int runsBatter;
  final int runsExtras;
  final ExtraType? extraType;
  final bool isLegalDelivery;
  final bool isFreeHit;
  final bool isWicket;
  final WicketType? wicketType;
  final String? dismissedPlayerId;
  final String? fielderId;
  final DateTime bowledAt;
  final bool isUndone;

  const Ball({
    required this.id,
    required this.inningsId,
    required this.overNumber,
    required this.ballInOver,
    required this.sequence,
    required this.strikerId,
    required this.nonStrikerId,
    required this.bowlerId,
    this.runsBatter = 0,
    this.runsExtras = 0,
    this.extraType,
    this.isLegalDelivery = true,
    this.isFreeHit = false,
    this.isWicket = false,
    this.wicketType,
    this.dismissedPlayerId,
    this.fielderId,
    required this.bowledAt,
    this.isUndone = false,
  });

  int get totalRuns => runsBatter + runsExtras;

  String get shortNotation {
    if (isWicket) return 'W';
    if (extraType == ExtraType.wide) {
      return runsBatter == 0 ? 'Wd' : '${runsBatter}wd';
    }
    if (extraType == ExtraType.noBall) {
      return runsBatter == 0 ? 'Nb' : '${runsBatter}nb';
    }
    if (extraType == ExtraType.bye) return '${runsExtras}b';
    if (extraType == ExtraType.legBye) return '${runsExtras}lb';
    return totalRuns.toString();
  }
}
