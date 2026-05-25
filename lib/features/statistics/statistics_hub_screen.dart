import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/mock_data.dart';
import '../../models/enums.dart';
import '../../models/player.dart';
import '../../models/team.dart';

class StatisticsHubScreen extends StatelessWidget {
  final String? playerId;

  const StatisticsHubScreen({super.key, this.playerId});

  @override
  Widget build(BuildContext context) {
    final player = MockData.playerOrNull(playerId);
    if (player != null) return _PlayerStats(player: player);
    return const _GlobalStats();
  }
}

class _GlobalStats extends StatelessWidget {
  const _GlobalStats();

  @override
  Widget build(BuildContext context) {
    final players = MockData.players;
    final teams = MockData.teams;
    final topRuns = [...players]..sort((a, b) => b.runs.compareTo(a.runs));
    final topWickets = [...players]
      ..sort((a, b) => b.wickets.compareTo(a.wickets));
    final teamTable = [...teams]..sort((a, b) => b.points.compareTo(a.points));

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              decoration:
                  const BoxDecoration(gradient: AppColors.navyHeroGradient),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Cricket ',
                      style: AppTextStyles.fraunces(
                          size: 24,
                          weight: FontWeight.w900,
                          color: AppColors.cream),
                    ),
                    TextSpan(
                      text: 'Statistics',
                      style: AppTextStyles.italicAccent(
                          size: 24, color: AppColors.gold),
                    ),
                  ],
                ),
              ),
            ),
            _summaryRow(players.length, teams.length, MockData.matches.length),
            _section(
              title: 'Top Run Scorers',
              child: topRuns.isEmpty
                  ? const _EmptyStats(
                      message: 'Add player statistics to see run leaders.')
                  : _LeaderList(
                      players: topRuns,
                      value: (player) => '${player.runs}',
                      label: 'RUNS'),
            ),
            _section(
              title: 'Top Wicket Takers',
              child: topWickets.isEmpty
                  ? const _EmptyStats(
                      message: 'Add bowling statistics to see wicket leaders.')
                  : _LeaderList(
                      players: topWickets,
                      value: (player) => '${player.wickets}',
                      label: 'WKTS'),
            ),
            _section(
              title: 'Team Table',
              child: teamTable.isEmpty
                  ? const _EmptyStats(
                      message:
                          'Create teams and enter team records to populate the table.')
                  : _TeamTable(teams: teamTable),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(int players, int teams, int matches) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _summary('$teams', 'TEAMS'),
          _summary('$players', 'PLAYERS'),
          _summary('$matches', 'MATCHES', last: true),
        ],
      ),
    );
  }

  Widget _summary(String value, String label, {bool last = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
                    size: 20,
                    weight: FontWeight.w900,
                    color: AppColors.navyDeep)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _PlayerStats extends StatelessWidget {
  final Player player;

  const _PlayerStats({required this.player});

  @override
  Widget build(BuildContext context) {
    final team =
        player.teamId == null ? null : MockData.teamOrNull(player.teamId);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            BackBar(title: player.fullName, italic: 'Stats'),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.ballRed,
                    child: Text(player.initials,
                        style:
                            AppTextStyles.bebas(size: 14, color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(player.role.label,
                            style: AppTextStyles.fraunces(
                                size: 13, weight: FontWeight.w700)),
                        Text(
                          team == null ? 'Free agent' : team.name,
                          style: AppTextStyles.mono(
                              size: 8,
                              color: AppColors.grey,
                              letterSpacing: 0.18),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push('/player/${player.id}/edit'),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
            _statGrid([
              ('Runs', '${player.runs}'),
              ('Average', player.average.toStringAsFixed(2)),
              ('Strike rate', player.strikeRate.toStringAsFixed(2)),
              ('Highest', '${player.highestScore}'),
              ('Wickets', '${player.wickets}'),
              ('Economy', player.economy.toStringAsFixed(2)),
              ('Catches', '${player.catches}'),
              ('Matches', '${player.matches}'),
            ]),
            _section(
              title: 'Milestones',
              child: _keyValues([
                ('Fifties', '${player.fifties}'),
                ('Hundreds', '${player.hundreds}'),
                ('Fours', '${player.fours}'),
                ('Sixes', '${player.sixes}'),
                ('Best bowling', player.bestBowling),
              ]),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _statGrid(List<(String, String)> stats) {
    return Container(
      color: AppColors.line,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          childAspectRatio: 1.7,
        ),
        itemCount: stats.length,
        itemBuilder: (_, i) => Container(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(stats[i].$2,
                  style: AppTextStyles.fraunces(
                      size: 25,
                      weight: FontWeight.w900,
                      color: AppColors.navyDeep)),
              const SizedBox(height: 4),
              Text(stats[i].$1.toUpperCase(), style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
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
    return Column(
      children: [
        for (var i = 0; i < players.take(10).length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: SizedBox(
              width: 28,
              child: Text('${i + 1}',
                  style: AppTextStyles.fraunces(
                      size: 16, weight: FontWeight.w900)),
            ),
            title: Text(players[i].fullName,
                style:
                    AppTextStyles.fraunces(size: 13, weight: FontWeight.w700)),
            subtitle: Text(players[i].role.label,
                style: AppTextStyles.mono(size: 8, letterSpacing: 0.18)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value(players[i]),
                    style: AppTextStyles.fraunces(
                        size: 16,
                        weight: FontWeight.w900,
                        color: AppColors.navyDeep)),
                Text(label, style: AppTextStyles.caption),
              ],
            ),
            onTap: () => context.push('/player/${players[i].id}'),
          ),
      ],
    );
  }
}

class _TeamTable extends StatelessWidget {
  final List<Team> teams;

  const _TeamTable({required this.teams});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final team in teams)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: TeamBadge(team: team, size: 32),
            title: Text(team.name,
                style:
                    AppTextStyles.fraunces(size: 13, weight: FontWeight.w700)),
            subtitle: Text(
                '${team.matchesPlayed} matches - ${team.winPercentage.toStringAsFixed(1)}% win',
                style: AppTextStyles.mono(size: 8)),
            trailing: Text('${team.points}',
                style:
                    AppTextStyles.fraunces(size: 18, weight: FontWeight.w900)),
            onTap: () => context.push('/team/${team.id}'),
          ),
      ],
    );
  }
}

class _EmptyStats extends StatelessWidget {
  final String message;

  const _EmptyStats({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(message,
        style: AppTextStyles.italicAccent(size: 13, color: AppColors.grey));
  }
}

Widget _section({required String title, required Widget child}) {
  return Container(
    color: Colors.white,
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTextStyles.fraunces(size: 16, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

Widget _keyValues(List<(String, String)> rows) {
  return Column(
    children: [
      for (final row in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Expanded(
                  child: Text(row.$1,
                      style: AppTextStyles.fraunces(
                          size: 13, weight: FontWeight.w600))),
              Text(row.$2,
                  style: AppTextStyles.fraunces(
                      size: 13,
                      weight: FontWeight.w900,
                      color: AppColors.navyDeep)),
            ],
          ),
        ),
    ],
  );
}
