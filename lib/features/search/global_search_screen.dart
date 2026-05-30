import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/mock_data.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  String q = '';
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lq = q.toLowerCase();
    final List<dynamic> teams = q.isEmpty
        ? []
        : MockData.teams
            .where((t) =>
                t.name.toLowerCase().contains(lq) ||
                t.shortCode.toLowerCase().contains(lq))
            .toList();
    final List<dynamic> players = q.isEmpty
        ? []
        : MockData.players
            .where((p) => p.fullName.toLowerCase().contains(lq))
            .toList();
    final List<dynamic> matches = q.isEmpty
        ? []
        : MockData.matches
            .where((m) =>
                m.matchName.toLowerCase().contains(lq) ||
                (m.venue ?? '').toLowerCase().contains(lq))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.navyDeep,
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text('BACK',
                        style: AppTextStyles.mono(
                            size: 9, color: AppColors.gold, letterSpacing: 0.25, weight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      controller: _ctrl,
                      onChanged: (v) => setState(() => q = v),
                      style: AppTextStyles.fraunces(
                          size: 14,
                          weight: FontWeight.w500,
                          color: AppColors.cream),
                      cursorColor: AppColors.gold,
                      decoration: InputDecoration(
                        hintText: 'Search teams, players, matches…',
                        hintStyle: AppTextStyles.italicAccent(
                            size: 13,
                            color: AppColors.cream.withValues(alpha: 0.6)),
                        border: InputBorder.none,
                        filled: false,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (q.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _ctrl.clear();
                        setState(() => q = '');
                      },
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.cream),
                    ),
                ],
              ),
            ),
            Expanded(
              child:
                  q.isEmpty ? _trending() : _results(teams, players, matches),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trending() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: [
        Text('SEARCH',
            style: AppTextStyles.mono(
              size: 9,
              color: AppColors.grey,
              letterSpacing: 0.25,
            )),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip('Teams', onTap: () => context.push('/teams')),
            _Chip('Players', onTap: () => context.push('/players')),
            _Chip('Matches', onTap: () => context.push('/matches')),
            _Chip('Tournaments', onTap: () => context.push('/tournaments')),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Type a team, player, venue, or match name. Results come from your saved app data.',
          style: AppTextStyles.italicAccent(size: 13, color: AppColors.grey),
        ),
      ],
    );
  }

  Widget _results(Iterable teams, Iterable players, Iterable matches) {
    final any = teams.isNotEmpty || players.isNotEmpty || matches.isNotEmpty;
    if (!any) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 56, color: AppColors.grey),
              const SizedBox(height: 8),
              Text('No results found',
                  style: AppTextStyles.italicAccent(
                      size: 14, color: AppColors.grey)),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: [
        if (teams.isNotEmpty) ...[
          _header('Teams', teams.length),
          for (final t in teams)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: TeamBadge(team: t, size: 32),
              title: Text(t.name,
                  style: AppTextStyles.fraunces(
                      size: 13, weight: FontWeight.w700)),
              subtitle: Text(t.category.label,
                  style: AppTextStyles.mono(size: 8, letterSpacing: 0.18)),
              onTap: () => context.push('/team/${t.id}'),
            ),
        ],
        if (players.isNotEmpty) ...[
          _header('Players', players.length),
          for (final p in players)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFF57F17), Color(0xFFE65100)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(p.initials,
                    style: AppTextStyles.bebas(size: 12, color: Colors.white)),
              ),
              title: Text(p.fullName,
                  style: AppTextStyles.fraunces(
                      size: 13, weight: FontWeight.w700)),
              subtitle: Text(p.role.label.toUpperCase(),
                  style: AppTextStyles.mono(size: 8, letterSpacing: 0.18)),
              onTap: () => context.push('/player/${p.id}'),
            ),
        ],
        if (matches.isNotEmpty) ...[
          _header('Matches', matches.length),
          for (final m in matches)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.sports_cricket_outlined),
              title: Text(m.matchName,
                  style: AppTextStyles.fraunces(
                      size: 13, weight: FontWeight.w700)),
              subtitle: Text((m.venue ?? '').toUpperCase(),
                  style: AppTextStyles.mono(size: 8, letterSpacing: 0.18)),
              onTap: () => context.push('/match/${m.id}'),
            ),
        ],
      ],
    );
  }

  Widget _header(String s, int n) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Row(
          children: [
            Text(s.toUpperCase(),
                style: AppTextStyles.mono(
                    size: 9, color: AppColors.grey, letterSpacing: 0.25)),
            const SizedBox(width: 6),
            Text('· $n',
                style: AppTextStyles.mono(
                    size: 9,
                    color: AppColors.goldDeep,
                    weight: FontWeight.w700,
                    letterSpacing: 0.2)),
          ],
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _Chip(this.label, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Text(label,
            style: AppTextStyles.dm(
                size: 11, weight: FontWeight.w600, color: AppColors.navyDeep)),
      ),
    );
  }
}
