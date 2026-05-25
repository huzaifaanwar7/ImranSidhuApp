import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../models/ball.dart';
import '../models/commentary.dart';
import '../models/enums.dart';
import '../models/match.dart';
import '../models/notification.dart';
import '../models/player.dart';
import '../models/sponsor.dart';
import '../models/team.dart';
import '../models/tournament.dart';
import '../models/user.dart';
import 'app_store.dart';

class MockData {
  MockData._();

  static final AppStore store = AppStore.instance;

  static const AppUser currentUser = AppUser(
    id: 'admin',
    fullName: 'Administrator',
    email: 'admin@ismvcc.app',
    phone: '',
    roles: [UserRole.admin, UserRole.scorer, UserRole.organizer],
    emailVerified: true,
    photoUrl: null,
  );

  static Future<void> load() => store.load();

  static List<Team> get teams => store.teams;
  static List<Player> get players => store.players;
  static List<Tournament> get tournaments => store.tournaments;
  static List<CricketMatch> get matches => store.matches;
  static List<Sponsor> get sponsors => const [
        Sponsor(
          id: 'amas',
          name: 'Amas',
          tagline: 'Feel The Difference',
          logoUrl: AppAssets.amasLogo,
          slots: [
            SponsorSlot.splash,
            SponsorSlot.dashboard,
            SponsorSlot.scorecard,
            SponsorSlot.commentary,
            SponsorSlot.overCard,
            SponsorSlot.matchPresentedBy,
          ],
        ),
        Sponsor(
          id: 'pm-sports-hosiery',
          name: 'PM Sports Hosiery',
          tagline: 'Sublimation Shirt Maker',
          logoUrl: AppAssets.pmSportsLogo,
          contactPhone: '0307-7590838',
          slots: [
            SponsorSlot.splash,
            SponsorSlot.dashboard,
            SponsorSlot.scorecard,
            SponsorSlot.commentary,
            SponsorSlot.overCard,
            SponsorSlot.kit,
            SponsorSlot.matchPresentedBy,
          ],
        ),
      ];
  static List<AppNotification> get notifications => const [];
  static List<Ball> get recentBalls => const [];
  static List<CommentaryLine> get commentary => const [];

  static Tournament get tournament => tournaments.isNotEmpty
      ? tournaments.first
      : Tournament(
          id: 'empty',
          name: 'No tournament',
          edition: DateTime.now().year.toString(),
          startDate: DateTime.now(),
          endDate: DateTime.now(),
          stage: TournamentStage.registration,
        );

  static List<Standing> get standings => tournaments.isEmpty
      ? const []
      : store.standingsForTournament(tournaments.first.id);

  static Team? teamOrNull(String? id) => store.teamById(id);
  static Player? playerOrNull(String? id) => store.playerById(id);
  static Tournament? tournamentOrNull(String? id) => store.tournamentById(id);
  static CricketMatch? matchOrNull(String? id) => store.matchById(id);

  static Team teamById(String id) =>
      teamOrNull(id) ??
      Team(
        id: id,
        name: 'Unknown team',
        shortCode: 'TBD',
        primaryColor: const Color(0xFF0F2447),
        secondaryColor: const Color(0xFFD4AF37),
      );

  static Player playerById(String id) =>
      playerOrNull(id) ??
      Player(
        id: id,
        fullName: 'Unknown player',
      );

  static Tournament tournamentById(String id) =>
      tournamentOrNull(id) ??
      Tournament(
        id: id,
        name: 'Unknown tournament',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );

  static CricketMatch matchById(String id) =>
      matchOrNull(id) ??
      CricketMatch(
        id: id,
        matchName: 'Match not found',
        homeTeamId: '',
        awayTeamId: '',
        scheduledStart: DateTime.now(),
      );

  static List<Player> playersByTeam(String teamId) =>
      store.playersByTeam(teamId);
  static List<CricketMatch> matchesForTeam(String teamId) =>
      store.matchesForTeam(teamId);
  static List<CricketMatch> matchesForTournament(String tournamentId) =>
      store.matchesForTournament(tournamentId);
  static List<Standing> standingsForTournament(String tournamentId) =>
      store.standingsForTournament(tournamentId);

  static CricketMatch? get mostRecentMatch => store.mostRecentMatch;
  static CricketMatch? get featuredHomeMatch => store.featuredHomeMatch;

  static String nextId(String prefix) => store.nextId(prefix);

  static Future<void> saveTeam(Team team) => store.saveTeam(team);
  static Future<void> deleteTeam(String id) => store.deleteTeam(id);
  static Future<void> savePlayer(Player player) => store.savePlayer(player);
  static Future<void> deletePlayer(String id) => store.deletePlayer(id);
  static Future<void> saveTournament(Tournament tournament) =>
      store.saveTournament(tournament);
  static Future<void> deleteTournament(String id) => store.deleteTournament(id);
  static Future<void> saveMatch(CricketMatch match) => store.saveMatch(match);
}
