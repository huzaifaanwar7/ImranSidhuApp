import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/api_client.dart';
import '../../data/app_store.dart';
import '../../data/mock_data.dart';
import '../../models/enums.dart';
import '../../models/team.dart';

class TeamsListScreen extends StatefulWidget {
  const TeamsListScreen({super.key});

  @override
  State<TeamsListScreen> createState() => _TeamsListScreenState();
}

class _TeamsListScreenState extends State<TeamsListScreen> {
  String query = '';
  TeamCategory? category;

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
    var list = MockData.teams;
    if (category != null) {
      list = list.where((t) => t.category == category).toList();
    }
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list
          .where((t) =>
              t.name.toLowerCase().contains(q) ||
              t.shortCode.toLowerCase().contains(q))
          .toList();
    }

    final totalPlayers = MockData.players.length;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Navy header
            Container(
              width: double.infinity,
              decoration:
                  const BoxDecoration(gradient: AppColors.navyHeroGradient),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: 'Teams ',
                          style: AppTextStyles.fraunces(
                              size: 26,
                              weight: FontWeight.w900,
                              color: AppColors.cream)),
                      TextSpan(
                          text: '& ',
                          style: AppTextStyles.fraunces(
                              size: 26,
                              weight: FontWeight.w900,
                              color: AppColors.cream)),
                      TextSpan(
                          text: 'Squads',
                          style: AppTextStyles.italicAccent(
                              size: 26, color: AppColors.gold)),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                      '${MockData.teams.length} registered teams - $totalPlayers active players',
                      style: AppTextStyles.italicAccent(
                          size: 12,
                          color: AppColors.cream.withValues(alpha: 0.7))),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded,
                            size: 14,
                            color: AppColors.cream.withValues(alpha: 0.7)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => query = v),
                            style: AppTextStyles.italicAccent(
                                size: 12, color: AppColors.cream),
                            cursorColor: AppColors.gold,
                            decoration: InputDecoration(
                              hintText: 'Search teams...',
                              hintStyle: AppTextStyles.italicAccent(
                                  size: 12,
                                  color:
                                      AppColors.cream.withValues(alpha: 0.6)),
                              border: InputBorder.none,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Filter pills
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _pill('All', category == null,
                        () => setState(() => category = null)),
                    const SizedBox(width: 6),
                    for (final c in TeamCategory.values) ...[
                      _pill(c.label, category == c,
                          () => setState(() => category = c)),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.line),
            Expanded(
              child: list.isEmpty
                  ? _EmptyTeams(
                      hasFilter: query.isNotEmpty || category != null,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _TeamRow(team: list[i]),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: ApiClient.instance.canManageTeams
          ? FloatingActionButton(
              backgroundColor: AppColors.ballRed,
              foregroundColor: Colors.white,
              onPressed: () async {
                await context.push('/team/new');
                if (mounted) setState(() {});
              },
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  Widget _pill(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.navyDeep : AppColors.creamSoft,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: active ? AppColors.navyDeep : AppColors.line),
        ),
        child: Text(label.toUpperCase(),
            style: AppTextStyles.mono(
              size: 9,
              color: active ? AppColors.cream : AppColors.grey,
              letterSpacing: 0.15,
              weight: FontWeight.w700,
            )),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final Team team;
  const _TeamRow({required this.team});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/team/${team.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            TeamBadge(team: team, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team.name,
                      style: AppTextStyles.fraunces(
                          size: 14, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _meta(
                          '${MockData.playersByTeam(team.id).length} PLAYERS'),
                      const SizedBox(width: 10),
                      _meta(team.category.label.toUpperCase()),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${team.wins}-${team.losses}',
                    style: AppTextStyles.fraunces(
                        size: 16,
                        weight: FontWeight.w900,
                        color: AppColors.navyDeep)),
                Text('W-L',
                    style: AppTextStyles.mono(
                      size: 8,
                      color: AppColors.goldDeep,
                      letterSpacing: 0.18,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(String s) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
              color: AppColors.gold, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(s,
            style: AppTextStyles.mono(
                size: 8, letterSpacing: 0.18, color: AppColors.grey)),
      ],
    );
  }
}

class _EmptyTeams extends StatelessWidget {
  final bool hasFilter;

  const _EmptyTeams({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_outlined, size: 58, color: AppColors.grey),
            const SizedBox(height: 10),
            Text(
              hasFilter ? 'No teams match this filter' : 'No teams yet',
              style: AppTextStyles.fraunces(
                size: 16,
                weight: FontWeight.w700,
                color: AppColors.navyDeep,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilter
                  ? 'Clear the search or change category.'
                  : 'Create your first team, then add players from its squad tab.',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.italicAccent(size: 13, color: AppColors.grey),
            ),
            if (!hasFilter && ApiClient.instance.canManageTeams) ...[
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => context.push('/team/new'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add team'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
