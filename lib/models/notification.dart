enum NotificationKind {
  matchStart,
  wicket,
  fifty,
  hundred,
  inningsEnd,
  matchEnd,
  announcement,
  stageChange
}

class AppNotification {
  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? matchId;
  final String? teamId;
  final String? playerId;
  final String? tournamentId;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.matchId,
    this.teamId,
    this.playerId,
    this.tournamentId,
  });
}
