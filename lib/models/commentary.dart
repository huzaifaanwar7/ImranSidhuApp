class CommentaryLine {
  final String id;
  final String matchId;
  final String ballId;
  final int overNumber;
  final int ballInOver;
  final String text;
  final bool isMilestone;
  final String? milestoneType;
  final DateTime createdAt;

  const CommentaryLine({
    required this.id,
    required this.matchId,
    required this.ballId,
    required this.overNumber,
    required this.ballInOver,
    required this.text,
    this.isMilestone = false,
    this.milestoneType,
    required this.createdAt,
  });

  String get overBallLabel => '$overNumber.$ballInOver';
}
