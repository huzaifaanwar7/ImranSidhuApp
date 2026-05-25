import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_verification_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/dashboard_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/matches/live_scoring_screen.dart';
import '../../features/matches/match_detail_screen.dart';
import '../../features/matches/match_setup_screen.dart';
import '../../features/matches/matches_list_screen.dart';
import '../../features/matches/playing_xi_screen.dart';
import '../../features/matches/toss_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/players/add_player_screen.dart';
import '../../features/players/player_profile_screen.dart';
import '../../features/players/players_list_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/search/global_search_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/sponsors/sponsors_screen.dart';
import '../../features/statistics/statistics_hub_screen.dart';
import '../../features/teams/add_team_screen.dart';
import '../../features/teams/team_detail_screen.dart';
import '../../features/teams/teams_list_screen.dart';
import '../../features/tournaments/add_tournament_screen.dart';
import '../../features/tournaments/tournament_detail_screen.dart';
import '../../features/tournaments/tournaments_list_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(
        path: '/verify-otp', builder: (_, __) => const OtpVerificationScreen()),

    // 4-tab bottom-nav shell: Home · Teams · Tourneys · Profile
    ShellRoute(
      builder: (_, __, child) => HomeShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/teams', builder: (_, __) => const TeamsListScreen()),
        GoRoute(
            path: '/tournaments',
            builder: (_, __) => const TournamentsListScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),

    // Stand-alone screens
    GoRoute(path: '/search', builder: (_, __) => const GlobalSearchScreen()),
    GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/sponsors', builder: (_, __) => const SponsorsScreen()),
    GoRoute(path: '/stats', builder: (_, __) => const StatisticsHubScreen()),
    GoRoute(path: '/matches', builder: (_, __) => const MatchesListScreen()),
    GoRoute(path: '/players', builder: (_, __) => const PlayersListScreen()),

    GoRoute(
      path: '/team/new',
      builder: (_, __) => const AddTeamScreen(),
    ),
    GoRoute(
      path: '/team/:id',
      builder: (_, s) => TeamDetailScreen(teamId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/team/:id/edit',
      builder: (_, s) => AddTeamScreen(teamId: s.pathParameters['id']!),
    ),

    GoRoute(
      path: '/player/new',
      builder: (_, s) =>
          AddPlayerScreen(teamId: s.uri.queryParameters['teamId']),
    ),
    GoRoute(
      path: '/player/:id',
      builder: (_, s) => PlayerProfileScreen(playerId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/player/:id/stats',
      builder: (_, s) => StatisticsHubScreen(playerId: s.pathParameters['id']),
    ),
    GoRoute(
      path: '/player/:id/edit',
      builder: (_, s) => AddPlayerScreen(playerId: s.pathParameters['id']),
    ),

    GoRoute(
      path: '/tournament/new',
      builder: (_, __) => const AddTournamentScreen(),
    ),
    GoRoute(
      path: '/tournament/:id',
      builder: (_, s) =>
          TournamentDetailScreen(tournamentId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/tournament/:id/edit',
      builder: (_, s) =>
          AddTournamentScreen(tournamentId: s.pathParameters['id']!),
    ),

    GoRoute(path: '/match/new', builder: (_, __) => const MatchSetupScreen()),
    GoRoute(
      path: '/match/new/toss',
      builder: (_, s) {
        final m = s.extra as Map<String, dynamic>;
        return TossScreen(homeId: m['home'], awayId: m['away']);
      },
    ),
    GoRoute(
      path: '/match/new/playing-xi',
      builder: (_, s) {
        final m = s.extra as Map<String, dynamic>;
        return PlayingXIScreen(homeId: m['home'], awayId: m['away']);
      },
    ),
    GoRoute(
      path: '/match/:id',
      builder: (_, s) => MatchDetailScreen(matchId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/match/:id/score',
      builder: (_, s) => LiveScoringScreen(matchId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/match/:id/commentary',
      builder: (_, s) =>
          MatchDetailScreen(matchId: s.pathParameters['id']!, initialTab: 1),
    ),
  ],
  errorBuilder: (_, s) => Scaffold(
    appBar: AppBar(title: const Text('Not found')),
    body: Center(child: Text('Route not found: ${s.uri}')),
  ),
);
