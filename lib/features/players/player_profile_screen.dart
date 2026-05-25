import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/mock_data.dart';
import '../../models/enums.dart';
import '../../models/player.dart';

class PlayerProfileScreen extends StatelessWidget {
  final String playerId;

  const PlayerProfileScreen({super.key, required this.playerId});

  @override
  Widget build(BuildContext context) {
    final player = MockData.playerOrNull(playerId);
    if (player == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [
            const BackBar(title: 'Player', italic: 'Missing'),
            Expanded(
              child: Center(
                child: Text('This player no longer exists.',
                    style: AppTextStyles.bodyLarge),
              ),
            ),
          ],
        ),
      );
    }

    final team =
        player.teamId == null ? null : MockData.teamOrNull(player.teamId);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Header(player: player, team: team),
            Container(
              color: Colors.white,
              child: Row(
                children: [
                  _stat('${player.matches}', 'MATCHES'),
                  _stat('${player.runs}', 'RUNS'),
                  _stat('${player.wickets}', 'WICKETS'),
                  _stat(player.average.toStringAsFixed(1), 'AVG', last: true),
                ],
              ),
            ),
            Container(height: 6, color: AppColors.cream),
            _section(
              title: 'Batting Statistics',
              child: _statTable([
                ('Innings', '${player.innings}'),
                ('Runs', '${player.runs}'),
                ('Highest score', '${player.highestScore}'),
                ('Average', player.average.toStringAsFixed(2)),
                ('Strike rate', player.strikeRate.toStringAsFixed(2)),
                ('Fours', '${player.fours}'),
                ('Sixes', '${player.sixes}'),
                ('Fifties', '${player.fifties}'),
                ('Hundreds', '${player.hundreds}'),
              ]),
            ),
            Container(height: 6, color: AppColors.cream),
            _section(
              title: 'Bowling & Fielding',
              child: _statTable([
                ('Wickets', '${player.wickets}'),
                ('Best bowling', player.bestBowling),
                ('Economy', player.economy.toStringAsFixed(2)),
                ('Catches', '${player.catches}'),
              ]),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navyDeep,
        onPressed: () => context.push('/player/${player.id}/edit'),
        icon: const Icon(Icons.edit_outlined, color: AppColors.gold),
        label: Text('EDIT',
            style: AppTextStyles.bebas(size: 14, color: AppColors.cream)),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
          child: OutlinedButton.icon(
            onPressed: () => context.push('/player/${player.id}/stats'),
            icon: const Icon(Icons.bar_chart_rounded),
            label: const Text('Full statistics'),
          ),
        ),
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
            Text(
              value,
              style: AppTextStyles.fraunces(
                  size: 18, weight: FontWeight.w900, color: AppColors.navyDeep),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.fraunces(size: 15, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _statTable(List<(String, String)> rows) {
    return Column(
      children: [
        for (final row in rows)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                Expanded(
                    child: Text(row.$1.toUpperCase(),
                        style: AppTextStyles.caption)),
                Text(
                  row.$2,
                  style: AppTextStyles.fraunces(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.navyDeep),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final Player player;
  final dynamic team;

  const _Header({required this.player, required this.team});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.navyHeroGradient),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBtn(
                icon: Icons.arrow_back_rounded,
                bg: Colors.white.withValues(alpha: 0.1),
                color: AppColors.cream,
                onTap: () => context.pop(),
              ),
              const Spacer(),
              IconBtn(
                icon: Icons.edit_outlined,
                bg: Colors.white.withValues(alpha: 0.1),
                color: AppColors.cream,
                onTap: () => context.push('/player/${player.id}/edit'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.ballRed,
                child: Text(player.initials,
                    style: AppTextStyles.bebas(size: 30, color: Colors.white)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.fullName,
                      style: AppTextStyles.fraunces(
                          size: 24,
                          weight: FontWeight.w900,
                          color: AppColors.cream),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${player.role.label.toUpperCase()}${player.jerseyNumber != null ? ' - #${player.jerseyNumber}' : ''}',
                      style: AppTextStyles.mono(
                          size: 9, color: AppColors.gold, letterSpacing: 0.15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${player.battingHand == BattingHand.right ? 'Right-hand bat' : 'Left-hand bat'}${player.bowlingStyle != null ? ' - ${player.bowlingStyle!.label}' : ''}',
                      style: AppTextStyles.italicAccent(
                          size: 13,
                          color: AppColors.cream.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (team != null) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: () => context.push('/team/${team.id}'),
              child: Row(
                children: [
                  TeamBadge(team: team, size: 26),
                  const SizedBox(width: 8),
                  Text(team.name,
                      style: AppTextStyles.fraunces(
                          size: 13,
                          weight: FontWeight.w700,
                          color: AppColors.cream)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
