import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/api_client.dart';
import '../../data/app_store.dart';
import '../../data/mock_data.dart';
import '../../models/enums.dart';
import '../../models/tournament.dart';

class TournamentsListScreen extends StatefulWidget {
  const TournamentsListScreen({super.key});

  @override
  State<TournamentsListScreen> createState() => _TournamentsListScreenState();
}

class _TournamentsListScreenState extends State<TournamentsListScreen> {
  @override
  void initState() {
    super.initState();
    AppStore.instance.addListener(_onData);
  }

  void _onData() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    AppStore.instance.removeListener(_onData);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournaments = [...MockData.tournaments]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(actions: [
              IconBtn(
                  icon: Icons.search_rounded,
                  onTap: () => context.push('/search')),
              if (ApiClient.instance.canManageTournaments) ...[
                const SizedBox(width: 6),
                IconBtn(
                  icon: Icons.add_rounded,
                  onTap: () async {
                    await context.push('/tournament/new');
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(
                      text: 'Tournaments ', style: AppTextStyles.displayMedium),
                  TextSpan(
                    text: '& Cups',
                    style: AppTextStyles.italicAccent(
                        size: 26, color: AppColors.goldDeep),
                  ),
                ]),
              ),
            ),
            Expanded(
              child: tournaments.isEmpty
                  ? _EmptyTournaments()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                      itemCount: tournaments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _TournamentCard(tournament: tournaments[i]),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: ApiClient.instance.canManageTournaments
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.ballRed,
              foregroundColor: Colors.white,
              onPressed: () async {
                await context.push('/tournament/new');
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.add_rounded),
              label: Text('TOURNAMENT',
                  style: AppTextStyles.bebas(size: 14, color: Colors.white)),
            )
          : null,
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final Tournament tournament;

  const _TournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final teams = tournament.teamIds
        .map(MockData.teamOrNull)
        .whereType<dynamic>()
        .toList();
    return InkWell(
      onTap: () => context.push('/tournament/${tournament.id}'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.navy, AppColors.navyDeep, Color(0xFF020A1F)],
          ),
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tournament.format.label.toUpperCase(),
                    style: AppTextStyles.mono(
                        size: 9, color: AppColors.gold, letterSpacing: 0.3),
                  ),
                ),
                if (ApiClient.instance.canManageTournaments)
                  IconButton(
                    onPressed: () =>
                        context.push('/tournament/${tournament.id}/edit'),
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.cream, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              tournament.name,
              style: AppTextStyles.fraunces(
                  size: 22, weight: FontWeight.w900, color: AppColors.cream),
            ),
            Text(
              tournament.edition,
              style:
                  AppTextStyles.italicAccent(size: 18, color: AppColors.gold),
            ),
            const SizedBox(height: 14),
            if (teams.isEmpty)
              Text(
                'No teams attached',
                style: AppTextStyles.mono(
                    size: 9, color: AppColors.cream.withValues(alpha: 0.7)),
              )
            else
              Row(
                children: teams
                    .take(8)
                    .map(
                      (team) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: TeamBadge(team: team, size: 24),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${DateFormat('MMM d').format(tournament.startDate).toUpperCase()} - ${DateFormat('MMM d').format(tournament.endDate).toUpperCase()}',
                  style: AppTextStyles.mono(
                    size: 9,
                    color: AppColors.cream.withValues(alpha: 0.7),
                    letterSpacing: 0.18,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    tournament.stage.label.toUpperCase(),
                    style: AppTextStyles.mono(
                      size: 8,
                      color: AppColors.navyDeep,
                      weight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTournaments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined,
                size: 58, color: AppColors.grey),
            const SizedBox(height: 10),
            Text('No tournaments yet',
                style:
                    AppTextStyles.fraunces(size: 16, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Create a tournament, attach teams, and track fixtures and tables.',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.italicAccent(size: 13, color: AppColors.grey),
            ),
            if (ApiClient.instance.canManageTournaments) ...[
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => context.push('/tournament/new'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add tournament'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
