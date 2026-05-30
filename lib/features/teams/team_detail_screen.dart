import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/match_card.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/api_client.dart';
import '../../data/mock_data.dart';
import '../../models/enums.dart';
import '../../models/player.dart';
import '../../models/team.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamId;

  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final team = MockData.teamOrNull(widget.teamId);
    if (team == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [
            const BackBar(title: 'Team', italic: 'Missing'),
            Expanded(
              child: Center(
                child: Text('This team no longer exists.',
                    style: AppTextStyles.bodyLarge),
              ),
            ),
          ],
        ),
      );
    }

    final roster = MockData.playersByTeam(team.id);
    final matches = MockData.matchesForTeam(team.id)
      ..sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(team: team),
            Container(
              color: AppColors.creamSoft,
              child: TabBar(
                controller: _tab,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: 'OVERVIEW'),
                  Tab(text: 'SQUAD'),
                  Tab(text: 'MATCHES'),
                  Tab(text: 'STATS'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _Overview(team: team, roster: roster),
                  _Squad(team: team, players: roster),
                  _Matches(matches: matches),
                  _Stats(team: team, players: roster),
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
  final Team team;

  const _Header({required this.team});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.navyHeroGradient),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Text('BACK',
                    style: AppTextStyles.mono(
                        size: 9, color: AppColors.gold, letterSpacing: 0.25, weight: FontWeight.w700)),
              ),
              const Spacer(),
              if (ApiClient.instance.canManageTeams)
                IconButton(
                  onPressed: () => context.push('/team/${team.id}/edit'),
                  icon:
                      const Icon(Icons.edit_outlined, color: AppColors.cream),
                ),
            ],
          ),
          Row(
            children: [
              TeamBadge(team: team, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: AppTextStyles.fraunces(
                        size: 22,
                        weight: FontWeight.w900,
                        color: AppColors.cream,
                      ),
                    ),
                    Text(
                      '${team.category.label.toUpperCase()}${team.homeVenue != null ? ' - ${team.homeVenue!.toUpperCase()}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.mono(
                        size: 8,
                        color: AppColors.gold,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _heroStat('${team.matchesPlayed}', 'MATCHES'),
              const SizedBox(width: 8),
              _heroStat('${team.wins}', 'WINS'),
              const SizedBox(width: 8),
              _heroStat('${team.winPercentage.toStringAsFixed(0)}%', 'WIN %'),
              const SizedBox(width: 8),
              _heroStat('${team.points}', 'POINTS'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.fraunces(
                  size: 18, weight: FontWeight.w900, color: AppColors.cream),
            ),
            Text(
              label,
              style: AppTextStyles.mono(
                size: 7,
                color: AppColors.cream.withValues(alpha: 0.6),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  final Team team;
  final List<Player> roster;

  const _Overview({required this.team, required this.roster});

  @override
  Widget build(BuildContext context) {
    final captain = MockData.playerOrNull(team.captainId);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Team Profile', style: AppTextStyles.titleLarge),
              const SizedBox(height: 10),
              _kv('Short code', team.shortCode),
              _kv('Category', team.category.label),
              _kv('Home venue', team.homeVenue ?? 'Not set'),
              _kv('Founded', team.foundedYear?.toString() ?? 'Not set'),
              _kv('Captain', captain?.fullName ?? 'Not assigned'),
              _kv('Players', '${roster.length}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Row(
            children: [
              _record('${team.wins}', 'WINS', AppColors.amasGreen),
              _record('${team.losses}', 'LOSSES', AppColors.ballRed),
              _record('${team.ties}', 'TIES', AppColors.gold),
              _record('${team.noResults}', 'NR', AppColors.grey),
            ],
          ),
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
                style:
                    AppTextStyles.fraunces(size: 13, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _record(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.fraunces(
                  size: 20, weight: FontWeight.w900, color: color)),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _Squad extends StatelessWidget {
  final Team team;
  final List<Player> players;

  const _Squad({required this.team, required this.players});

  @override
  Widget build(BuildContext context) {
    final canAdd = ApiClient.instance.canManagePlayers;
    if (players.isEmpty) {
      return _EmptyPanel(
        icon: Icons.person_add_alt_1_outlined,
        title: 'No players yet',
        message: 'Add players to build this team squad.',
        action: canAdd ? 'Add player' : null,
        onAction:
            canAdd ? () => context.push('/player/new?teamId=${team.id}') : null,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
      children: [
        if (canAdd)
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/player/new?teamId=${team.id}'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add player'),
            ),
          ),
        if (canAdd) const SizedBox(height: 8),
        for (final player in players)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PlayerRow(player: player),
          ),
      ],
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final Player player;

  const _PlayerRow({required this.player});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/player/${player.id}'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.ballRed,
              child: Text(player.initials,
                  style: AppTextStyles.bebas(size: 13, color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(player.fullName,
                      style: AppTextStyles.fraunces(
                          size: 13, weight: FontWeight.w700)),
                  Text(
                    '${player.role.label.toUpperCase()} - ${player.runs} runs - ${player.wickets} wickets',
                    style: AppTextStyles.mono(
                        size: 8, letterSpacing: 0.18, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            if (player.jerseyNumber != null)
              Text(
                '#${player.jerseyNumber}',
                style: AppTextStyles.bebas(size: 18, color: AppColors.goldDeep),
              ),
          ],
        ),
      ),
    );
  }
}

class _Matches extends StatelessWidget {
  final List matches;

  const _Matches({required this.matches});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.sports_cricket_outlined,
        title: 'No matches yet',
        message: 'Create matches from the home screen or match list.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
      itemCount: matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => MatchCard(match: matches[i]),
    );
  }
}

class _Stats extends StatelessWidget {
  final Team team;
  final List<Player> players;

  const _Stats({required this.team, required this.players});

  @override
  Widget build(BuildContext context) {
    final topRuns = [...players]..sort((a, b) => b.runs.compareTo(a.runs));
    final topWickets = [...players]
      ..sort((a, b) => b.wickets.compareTo(a.wickets));
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
      children: [
        Text('Team Statistics', style: AppTextStyles.titleLarge),
        const SizedBox(height: 8),
        _card(
          child: Column(
            children: [
              _statLine('Matches', '${team.matchesPlayed}'),
              _statLine('Wins', '${team.wins}'),
              _statLine('Losses', '${team.losses}'),
              _statLine('Ties', '${team.ties}'),
              _statLine('No results', '${team.noResults}'),
              _statLine('Points', '${team.points}'),
              _statLine('Win percentage',
                  '${team.winPercentage.toStringAsFixed(1)}%'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Squad Leaders', style: AppTextStyles.titleLarge),
        const SizedBox(height: 8),
        if (players.isEmpty)
          _card(
            child: Text(
              'Add players and their statistics to populate team leaders.',
              style:
                  AppTextStyles.italicAccent(size: 13, color: AppColors.grey),
            ),
          )
        else ...[
          _LeaderBlock(
              title: 'Most Runs',
              players: topRuns,
              value: (player) => '${player.runs}'),
          const SizedBox(height: 10),
          _LeaderBlock(
              title: 'Most Wickets',
              players: topWickets,
              value: (player) => '${player.wickets}'),
        ],
      ],
    );
  }

  Widget _statLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: AppTextStyles.fraunces(
                      size: 13, weight: FontWeight.w600))),
          Text(value,
              style: AppTextStyles.fraunces(
                  size: 14,
                  weight: FontWeight.w900,
                  color: AppColors.navyDeep)),
        ],
      ),
    );
  }
}

class _LeaderBlock extends StatelessWidget {
  final String title;
  final List<Player> players;
  final String Function(Player) value;

  const _LeaderBlock(
      {required this.title, required this.players, required this.value});

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: AppTextStyles.caption),
          const SizedBox(height: 8),
          for (final player in players.take(3))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(player.fullName,
                  style: AppTextStyles.fraunces(
                      size: 13, weight: FontWeight.w700)),
              subtitle:
                  Text(player.role.label, style: AppTextStyles.mono(size: 8)),
              trailing: Text(value(player),
                  style: AppTextStyles.fraunces(
                      size: 16, weight: FontWeight.w900)),
              onTap: () => context.push('/player/${player.id}'),
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
  final String? action;
  final VoidCallback? onAction;

  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: AppColors.grey),
            const SizedBox(height: 10),
            Text(title,
                style:
                    AppTextStyles.fraunces(size: 16, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.italicAccent(
                    size: 13, color: AppColors.grey)),
            if (action != null && onAction != null) ...[
              const SizedBox(height: 14),
              ElevatedButton(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _card({required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.line),
    ),
    child: child,
  );
}
