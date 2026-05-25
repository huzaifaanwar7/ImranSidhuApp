import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/match_card.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/mock_data.dart';
import '../../models/enums.dart';
import '../../models/player.dart';
import '../../models/tournament.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournament = MockData.tournamentOrNull(widget.tournamentId);
    if (tournament == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [
            const BackBar(title: 'Tournament', italic: 'Missing'),
            Expanded(
              child: Center(
                child: Text('This tournament no longer exists.',
                    style: AppTextStyles.bodyLarge),
              ),
            ),
          ],
        ),
      );
    }

    final fixtures = MockData.matchesForTournament(tournament.id)
      ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
    final standings = MockData.standingsForTournament(tournament.id);
    final players = MockData.players
        .where((player) =>
            player.teamId != null && tournament.teamIds.contains(player.teamId))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(tournament: tournament),
            _Summary(tournament: tournament, fixtures: fixtures),
            Container(
              color: AppColors.creamSoft,
              child: TabBar(
                controller: _tab,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: 'OVERVIEW'),
                  Tab(text: 'TABLE'),
                  Tab(text: 'FIXTURES'),
                  Tab(text: 'TOP STATS'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _Overview(tournament: tournament, players: players),
                  _Table(standings: standings),
                  _Fixtures(matches: fixtures),
                  _TopStats(players: players),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Tournament tournament;

  const _Header({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.navyDeep, Color(0xFF020A1F)],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(Icons.arrow_back_rounded,
                      size: 18, color: AppColors.cream),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tournament.format.label.toUpperCase(),
                    style: AppTextStyles.mono(
                        size: 9, color: AppColors.gold, letterSpacing: 0.3),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      context.push('/tournament/${tournament.id}/edit'),
                  icon: const Icon(Icons.edit_outlined, color: AppColors.cream),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tournament.name,
                  style: AppTextStyles.fraunces(
                      size: 24,
                      weight: FontWeight.w900,
                      color: AppColors.cream),
                ),
                Text(
                  '${tournament.edition} - ${tournament.category.label}',
                  style: AppTextStyles.italicAccent(
                      size: 16, color: AppColors.gold),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${DateFormat('MMM d').format(tournament.startDate).toUpperCase()} - ${DateFormat('MMM d').format(tournament.endDate).toUpperCase()}',
                  style: AppTextStyles.mono(
                    size: 9,
                    color: AppColors.cream.withValues(alpha: 0.8),
                    letterSpacing: 0.15,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(14)),
                  child: Text(
                    tournament.stage.label.toUpperCase(),
                    style: AppTextStyles.mono(
                        size: 8,
                        color: AppColors.navyDeep,
                        letterSpacing: 0.2,
                        weight: FontWeight.w700),
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

class _Summary extends StatelessWidget {
  final Tournament tournament;
  final List fixtures;

  const _Summary({required this.tournament, required this.fixtures});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _stat('${tournament.teamIds.length}', 'TEAMS'),
          _stat('${fixtures.length}', 'MATCHES'),
          _stat('${tournament.totalRuns}', 'RUNS'),
          _stat('${tournament.totalWickets}', 'WICKETS', last: true),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, {bool last = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          border: Border(
            right: last
                ? BorderSide.none
                : const BorderSide(color: AppColors.line),
            bottom: const BorderSide(color: AppColors.line),
          ),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTextStyles.fraunces(
                    size: 18,
                    weight: FontWeight.w900,
                    color: AppColors.ballRed)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  final Tournament tournament;
  final List<Player> players;

  const _Overview({required this.tournament, required this.players});

  @override
  Widget build(BuildContext context) {
    final teams = tournament.teamIds
        .map(MockData.teamOrNull)
        .whereType<dynamic>()
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tournament Setup', style: AppTextStyles.titleLarge),
              const SizedBox(height: 10),
              _kv('Format', tournament.format.label),
              _kv('Match type',
                  '${tournament.matchFormat.label} - ${tournament.oversPerInnings} overs'),
              _kv('Stage', tournament.stage.label),
              _kv('Sponsor', tournament.sponsorTitle ?? 'Not set'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Teams', style: AppTextStyles.titleLarge),
        const SizedBox(height: 8),
        if (teams.isEmpty)
          _empty('No teams are attached to this tournament.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final team in teams)
                InkWell(
                  onTap: () => context.push('/team/${team.id}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line)),
                    child: TeamBadge(team: team, size: 30, showName: true),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
              width: 92,
              child: Text(label.toUpperCase(), style: AppTextStyles.caption)),
          Expanded(
              child: Text(value,
                  style: AppTextStyles.fraunces(
                      size: 13, weight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _Table extends StatelessWidget {
  final List<Standing> standings;

  const _Table({required this.standings});

  @override
  Widget build(BuildContext context) {
    if (standings.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.table_chart_outlined,
        title: 'No table yet',
        message: 'Attach teams to the tournament to build the standings table.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
      children: [
        _card(
          child: Column(
            children: [
              _row(['#', 'TEAM', 'P', 'W', 'L', 'PTS'], isHeader: true),
              for (var i = 0; i < standings.length; i++)
                _row([
                  '${i + 1}',
                  MockData.teamById(standings[i].teamId).name,
                  '${standings[i].matchesPlayed}',
                  '${standings[i].wins}',
                  '${standings[i].losses}',
                  '${standings[i].points}',
                ], teamId: standings[i].teamId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(List<String> cells, {bool isHeader = false, String? teamId}) {
    final style = isHeader
        ? AppTextStyles.caption
        : AppTextStyles.mono(size: 10, color: AppColors.ink);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          SizedBox(width: 24, child: Text(cells[0], style: style)),
          Expanded(
            child: Row(
              children: [
                if (teamId != null) ...[
                  TeamBadge(team: MockData.teamById(teamId), size: 22),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    cells[1],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: isHeader
                        ? AppTextStyles.caption
                        : AppTextStyles.dm(size: 11, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          for (final cell in cells.skip(2))
            SizedBox(
                width: 34,
                child: Text(cell, textAlign: TextAlign.end, style: style)),
        ],
      ),
    );
  }
}

class _Fixtures extends StatelessWidget {
  final List matches;

  const _Fixtures({required this.matches});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.sports_cricket_outlined,
        title: 'No fixtures yet',
        message: 'Create matches and assign this tournament.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
      itemCount: matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => MatchCard(match: matches[i]),
    );
  }
}

class _TopStats extends StatelessWidget {
  final List<Player> players;

  const _TopStats({required this.players});

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.bar_chart_rounded,
        title: 'No player stats yet',
        message: 'Add players to tournament teams and enter career statistics.',
      );
    }
    final runs = [...players]..sort((a, b) => b.runs.compareTo(a.runs));
    final wickets = [...players]
      ..sort((a, b) => b.wickets.compareTo(a.wickets));
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
      children: [
        Text('Most Runs', style: AppTextStyles.titleLarge),
        const SizedBox(height: 8),
        _LeaderList(
            players: runs, value: (player) => '${player.runs}', label: 'RUNS'),
        const SizedBox(height: 18),
        Text('Most Wickets', style: AppTextStyles.titleLarge),
        const SizedBox(height: 8),
        _LeaderList(
            players: wickets,
            value: (player) => '${player.wickets}',
            label: 'WKTS'),
      ],
    );
  }
}

class _LeaderList extends StatelessWidget {
  final List<Player> players;
  final String Function(Player) value;
  final String label;

  const _LeaderList(
      {required this.players, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        children: [
          for (var i = 0; i < players.take(5).length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text('${i + 1}',
                  style: AppTextStyles.fraunces(
                      size: 16, weight: FontWeight.w900)),
              title: Text(players[i].fullName,
                  style: AppTextStyles.fraunces(
                      size: 13, weight: FontWeight.w700)),
              subtitle: Text(players[i].role.label,
                  style: AppTextStyles.mono(size: 8)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(value(players[i]),
                      style: AppTextStyles.fraunces(
                          size: 16, weight: FontWeight.w900)),
                  Text(label, style: AppTextStyles.caption),
                ],
              ),
              onTap: () => context.push('/player/${players[i].id}'),
            ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyPanel(
      {required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 54, color: AppColors.grey),
              const SizedBox(height: 10),
              Text(title,
                  style: AppTextStyles.fraunces(
                      size: 16, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.italicAccent(
                      size: 13, color: AppColors.grey)),
            ],
          ),
        ),
      );
}

Widget _card({required Widget child}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );

Widget _empty(String text) => _card(
      child: Text(text,
          style: AppTextStyles.italicAccent(size: 13, color: AppColors.grey)),
    );
