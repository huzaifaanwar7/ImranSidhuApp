import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/live_pill.dart';
import '../../core/widgets/match_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/sponsor_banner.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/api_client.dart';
import '../../data/app_store.dart';
import '../../data/mock_data.dart';
import '../../models/enums.dart';
import '../../models/match.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
    final api = ApiClient.instance;
    final apiUser = api.currentUser;
    final isAuthed = api.isAuthed;
    final fullName = (apiUser?['fullName'] as String?) ?? 'Guest viewer';
    final roleLabel = isAuthed ? api.role : 'Viewer';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning,'
        : (hour < 18 ? 'Good afternoon,' : 'Good evening,');
    final featuredMatch = MockData.featuredHomeMatch;
    final recentMatch = MockData.mostRecentMatch;
    final completed = MockData.matches.where((m) => m.isCompleted).toList()
      ..sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            AppTopBar(actions: [
              if (!isAuthed)
                GestureDetector(
                  onTap: () => context.push('/login'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.ballRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('SIGN IN',
                        style: AppTextStyles.bebas(
                            size: 12, color: Colors.white, letterSpacing: 0.15)),
                  ),
                ),
              if (isAuthed) ...[
                IconBtn(
                  icon: Icons.notifications_none_rounded,
                  dot: true,
                  onTap: () => context.push('/notifications'),
                ),
              ] else
                const SizedBox(width: 8),
            ]),
            // Hero
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 0),
              decoration: const BoxDecoration(
                gradient: AppColors.navyHeroGradient,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isAuthed ? greeting : 'Welcome,',
                          style: AppTextStyles.italicAccent(
                              size: 13,
                              color: AppColors.cream.withValues(alpha: 0.65))),
                      const SizedBox(height: 2),
                      Text(isAuthed
                              ? '$roleLabel · ${fullName.split(' ').first}'
                              : 'Browse live cricket',
                          style: AppTextStyles.fraunces(
                              size: 22,
                              weight: FontWeight.w700,
                              color: AppColors.cream)),
                      const SizedBox(height: 14),
                      if (featuredMatch?.isLive == true) ...[
                        const LivePill(),
                        const SizedBox(height: 12),
                      ],
                      featuredMatch == null
                          ? const _HomeSetupCard()
                          : _LiveMatchCard(match: featuredMatch),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Quick actions
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
              child: Row(
                children: [
                  if (api.canManageMatches)
                    const _QA(
                        icon: Icons.add_rounded,
                        label: 'New Match',
                        color: AppColors.ballRed,
                        route: '/match/new'),
                  const _QA(
                      icon: Icons.groups_rounded,
                      label: 'Teams',
                      color: AppColors.navy,
                      route: '/teams'),
                  const _QA(
                      icon: Icons.emoji_events_outlined,
                      label: 'Tourneys',
                      color: AppColors.gold,
                      route: '/tournaments'),
                  const _QA(
                      icon: Icons.leaderboard_rounded,
                      label: 'Rankings',
                      color: AppColors.goldDeep,
                      route: '/rankings'),
                  const _QA(
                      icon: Icons.bar_chart_rounded,
                      label: 'Stats',
                      color: AppColors.ink,
                      route: '/stats'),
                ],
              ),
            ),

            // Management shortcuts — role-gated (hidden from viewers/fans)
            if (_ManageGrid.hasAny(api)) ...[
              const SectionHeader(title: 'Quick', italicAccent: 'Manage'),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, 6),
                child: _ManageGrid(),
              ),
            ],

            const SizedBox(height: 8),
            const SponsorBanner(slot: SponsorSlot.dashboard),

            // Most recent match
            SectionHeader(
              title: 'Most Recent',
              italicAccent: 'Match',
              action: 'See all',
              onAction: () => context.push('/matches'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: recentMatch == null
                  ? const _EmptyHomeSection(
                      text:
                          'No matches yet. Create a match and it will appear here.',
                    )
                  : MatchCard(match: recentMatch),
            ),

            if (completed.isNotEmpty) ...[
              SectionHeader(
                title: 'Recent',
                italicAccent: 'Results',
                action: 'See all',
                onAction: () => context.push('/matches'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: Column(
                  children: [
                    for (final m in completed.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: MatchCard(match: m),
                      ),
                  ],
                ),
              ),
            ],

            // Tournament leaders preview
            SectionHeader(
              title: 'Top Run',
              italicAccent: 'Scorers',
              action: 'View all',
              onAction: () => context.push('/stats'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: _LeaderCard(),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _HomeSetupCard extends StatelessWidget {
  const _HomeSetupCard();

  @override
  Widget build(BuildContext context) {
    final api = ApiClient.instance;
    final canSetup = api.canManageTeams || api.canManageMatches;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            canSetup ? 'Set up your cricket data' : 'No live match right now',
            style: AppTextStyles.fraunces(
              size: 16,
              weight: FontWeight.w800,
              color: AppColors.cream,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            canSetup
                ? 'Create teams, add players, then schedule a match. The newest match will live here.'
                : 'Live and upcoming matches will appear here. Browse teams, tournaments and stats below.',
            style: AppTextStyles.italicAccent(
              size: 12,
              color: AppColors.cream.withValues(alpha: 0.72),
            ),
          ),
          if (canSetup) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (api.canManageTeams)
                  ElevatedButton.icon(
                    onPressed: () => context.push('/team/new'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Team'),
                  ),
                if (api.canManageTeams && api.canManageMatches)
                  const SizedBox(width: 8),
                if (api.canManageMatches)
                  OutlinedButton.icon(
                    onPressed: () => context.push('/match/new'),
                    icon: const Icon(Icons.sports_cricket_rounded),
                    label: const Text('Match'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyHomeSection extends StatelessWidget {
  final String text;

  const _EmptyHomeSection({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        text,
        style: AppTextStyles.italicAccent(size: 13, color: AppColors.grey),
      ),
    );
  }
}

class _LiveMatchCard extends StatelessWidget {
  final CricketMatch match;
  const _LiveMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final home = MockData.teamById(match.homeTeamId);
    final away = MockData.teamById(match.awayTeamId);
    final inn = match.currentInnings;
    final homeScore = inn != null && inn.battingTeamId == home.id
        ? '${inn.totalRuns}/${inn.wickets}'
        : null;
    final awayScore = inn != null && inn.battingTeamId == away.id
        ? '${inn.totalRuns}/${inn.wickets}'
        : null;
    final summary = _summary(home.name, away.name);

    return GestureDetector(
      onTap: () => context.push('/match/${match.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    match.matchName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.mono(
                      size: 8,
                      color: AppColors.gold,
                      letterSpacing: 0.25,
                    ),
                  ),
                ),
                Text(match.state.label.toUpperCase(),
                    style: AppTextStyles.mono(
                      size: 7,
                      color: AppColors.cream.withValues(alpha: 0.5),
                      letterSpacing: 0.2,
                    )),
              ],
            ),
            const SizedBox(height: 10),
            _line(home, homeScore ?? '-',
                inn?.battingTeamId == home.id ? inn?.oversDisplay : null),
            const SizedBox(height: 8),
            _line(away, awayScore ?? '-',
                inn?.battingTeamId == away.id ? inn?.oversDisplay : null),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.gold.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  summary,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.italicAccent(
                      size: 11, color: AppColors.gold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _summary(String homeName, String awayName) {
    if (match.isCompleted && match.resultMargin != null) {
      final winner =
          MockData.teamById(match.resultWinnerTeamId ?? match.homeTeamId);
      return '${winner.name} ${match.resultMargin}';
    }
    if (match.isLive) {
      final inn = match.currentInnings;
      if (inn == null) return '$homeName vs $awayName is live';
      final batting = MockData.teamById(inn.battingTeamId);
      return '${batting.name} ${inn.totalRuns}/${inn.wickets} after ${inn.oversDisplay}';
    }
    if (match.isUpcoming) {
      return 'Starts ${DateFormat('MMM d, h:mm a').format(match.scheduledStart)}';
    }
    return match.state.label;
  }

  Widget _line(team, String score, String? overs) {
    return Row(
      children: [
        TeamBadge(team: team, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Text(team.name,
              style: AppTextStyles.dm(
                  size: 12, weight: FontWeight.w600, color: AppColors.cream)),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(score,
                style: AppTextStyles.fraunces(
                    size: 16, weight: FontWeight.w700, color: AppColors.cream)),
            if (overs != null)
              Text('$overs OVERS',
                  style: AppTextStyles.mono(
                      size: 8,
                      color: AppColors.cream.withValues(alpha: 0.6),
                      letterSpacing: 0.15)),
          ],
        ),
      ],
    );
  }
}

/// Role-gated management shortcuts shown on Home for admins/scorers/captains.
class _ManageGrid extends StatelessWidget {
  const _ManageGrid();

  static bool hasAny(ApiClient api) =>
      api.isSuperAdmin ||
      api.canManageTeams ||
      api.canManageTournaments ||
      api.canManageMatches ||
      api.canManagePlayers;

  @override
  Widget build(BuildContext context) {
    final api = ApiClient.instance;
    final tiles = <Widget>[
      if (api.isSuperAdmin)
        const _ManageTile(Icons.manage_accounts_rounded, 'Users',
            '/admin/users', AppColors.navy),
      if (api.isSuperAdmin)
        const _ManageTile(Icons.verified_user_rounded, 'Approvals',
            '/admin/approvals', AppColors.amasGreen),
      if (api.canManageTeams)
        const _ManageTile(
            Icons.groups_rounded, 'New Team', '/team/new', AppColors.navyDeep),
      if (api.canManageTournaments)
        const _ManageTile(Icons.emoji_events_rounded, 'Tournament',
            '/tournament/new', AppColors.goldDeep),
      if (api.canManageMatches)
        const _ManageTile(Icons.sports_cricket_rounded, 'New Match',
            '/match/new', AppColors.ballRed),
      if (api.canManagePlayers)
        const _ManageTile(Icons.person_add_alt_1_rounded, 'Add Player',
            '/player/new', AppColors.ink),
      const _ManageTile(Icons.workspace_premium_rounded, 'Sponsors',
          '/sponsors', AppColors.gold),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tiles,
    );
  }
}

class _ManageTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _ManageTile(this.icon, this.label, this.route, this.color);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 15),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: AppTextStyles.dm(
                    size: 11,
                    weight: FontWeight.w600,
                    color: AppColors.navyDeep)),
          ],
        ),
      ),
    );
  }
}

class _QA extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _QA({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push(route),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.white, size: 15),
                ),
                const SizedBox(height: 6),
                Text(label,
                    style: AppTextStyles.dm(
                        size: 9,
                        weight: FontWeight.w600,
                        color: AppColors.navyDeep)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final top = [...MockData.players]..sort((a, b) => b.runs.compareTo(a.runs));
    final list = top.take(3).toList();
    if (list.isEmpty) {
      return const _EmptyHomeSection(
        text: 'Add player statistics to see top run scorers.',
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < list.length; i++) ...[
            Row(
              children: [
                SizedBox(
                  width: 18,
                  child: Text('${i + 1}',
                      style: AppTextStyles.fraunces(
                          size: 14,
                          weight: FontWeight.w900,
                          color: i == 0
                              ? AppColors.goldDeep
                              : AppColors.navyDeep)),
                ),
                if (list[i].teamId != null &&
                    MockData.teamOrNull(list[i].teamId) != null)
                  TeamBadge(
                    team: MockData.teamById(list[i].teamId!),
                    size: 24,
                  )
                else
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.ballRed,
                    child: Text(
                      list[i].initials,
                      style: AppTextStyles.bebas(size: 10, color: Colors.white),
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/player/${list[i].id}'),
                    child: Text(list[i].fullName,
                        style: AppTextStyles.dm(
                            size: 12, weight: FontWeight.w600)),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${list[i].runs}',
                        style: AppTextStyles.fraunces(
                            size: 14,
                            weight: FontWeight.w700,
                            color: AppColors.navyDeep)),
                    Text('AVG ${list[i].average.toStringAsFixed(1)}',
                        style:
                            AppTextStyles.mono(size: 8, letterSpacing: 0.18)),
                  ],
                ),
              ],
            ),
            if (i != list.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}
