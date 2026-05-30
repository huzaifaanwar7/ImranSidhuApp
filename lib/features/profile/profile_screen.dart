import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/api_client.dart';
import '../../data/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiClient.instance;
    if (!api.isAuthed) return _viewerCta(context);

    final apiUser = api.currentUser;
    final fullName = (apiUser?['fullName'] as String?) ?? '';
    final email = (apiUser?['email'] as String?) ?? '';
    final role = api.role;
    final isSuperAdmin = api.isSuperAdmin;
    final isCaptain = api.isCaptain;
    final isScorer = api.isScorer;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration:
                const BoxDecoration(gradient: AppColors.navyHeroGradient),
            padding: const EdgeInsets.fromLTRB(18, 60, 18, 26),
            child: Column(
              children: [
                Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.settings_outlined,
                          color: AppColors.cream),
                    ),
                  ],
                ),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF57F17), Color(0xFFE65100)],
                    ),
                    border: Border.all(color: AppColors.gold, width: 3),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    fullName.split(' ').map((s) => s.isEmpty ? '' : s[0]).take(2).join(),
                    style: AppTextStyles.bebas(size: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(fullName,
                    style: AppTextStyles.fraunces(
                        size: 22,
                        weight: FontWeight.w900,
                        color: AppColors.cream)),
                Text(email,
                    style: AppTextStyles.italicAccent(
                        size: 13,
                        color: AppColors.cream.withValues(alpha: 0.7))),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                  ),
                  child: Text(role.toUpperCase(),
                      style: AppTextStyles.mono(
                        size: 8,
                        color: AppColors.gold,
                        letterSpacing: 0.2,
                        weight: FontWeight.w700,
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (isSuperAdmin) ...[
            _section('SUPER ADMIN'),
            _tile(context, Icons.verified_user_outlined, 'Approval queue',
                'Approve teams, players & captain signups',
                () => context.push('/admin/approvals')),
            _tile(context, Icons.manage_accounts_outlined, 'User management',
                'Manage users, roles, password resets',
                () => context.push('/admin/users')),
          ],
          _section('CRICKET'),
          _tile(context, Icons.person_outline, 'Players',
              'Browse all players', () => context.push('/players')),
          _tile(context, Icons.groups_rounded, 'Teams',
              'Browse all teams', () => context.push('/teams')),
          _tile(context, Icons.leaderboard_rounded, 'Rankings',
              'Batsmen · Bowlers · Teams ratings',
              () => context.push('/rankings')),
          _tile(context, Icons.search_rounded, 'Global search',
              'Players, teams, tournaments, matches',
              () => context.push('/search')),
          _tile(context, Icons.notifications_outlined, 'Notifications',
              'Manage match alerts', () => context.push('/notifications')),
          if (isCaptain || isSuperAdmin || isScorer) ...[
            _section('ORGANIZING'),
            if (isSuperAdmin || isScorer)
              _tile(context, Icons.add_box_outlined, 'Create tournament',
                  'Round Robin · Knockout · Hybrid',
                  () => context.push('/tournament/new')),
            // Only Admin / SuperAdmin can create teams (Captains are then assigned by Admin).
            if (isSuperAdmin)
              _tile(context, Icons.add_rounded, 'New team',
                  'Create a team and assign its captain',
                  () => context.push('/team/new')),
            if (isCaptain)
              _tile(context, Icons.person_add_alt_1_rounded, 'Add player to my team',
                  'Submitted players need SuperAdmin approval',
                  () => context.push('/player/new')),
            _tile(context, Icons.workspace_premium_rounded, 'Sponsors',
                'Manage sponsor slots', () => context.push('/sponsors')),
          ],
          _section('APP'),
          _tile(context, Icons.translate_rounded, 'Language', 'English (US)', () {}),
          _tile(context, Icons.color_lens_outlined, 'Theme', 'System default', () {}),
          _tile(context, Icons.help_outline_rounded, 'Help & support', '', () {}),
          _tile(context, Icons.info_outline_rounded, 'About', 'v1.0.0', () {}),
          _tile(context, Icons.logout_rounded, 'Sign out', '', () async {
            await AuthService.instance.logout();
            if (context.mounted) context.go('/login');
          }, danger: true),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _viewerCta(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.navyDeep.withValues(alpha: 0.08),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.person_outline, size: 48, color: AppColors.navyDeep),
                ),
                const SizedBox(height: 18),
                Text('You are browsing as a viewer',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.fraunces(size: 18, weight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  'Sign in as a Captain, Scorer or SuperAdmin to add teams, players, score matches, or manage approvals.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.italicAccent(size: 13, color: AppColors.grey),
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('SIGN IN'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('CREATE ACCOUNT'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String s) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
        child: Text(s,
            style: AppTextStyles.mono(
                size: 9, color: AppColors.grey, letterSpacing: 0.25)),
      );

  Widget _tile(
      BuildContext c, IconData i, String t, String s, VoidCallback onTap,
      {bool danger = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        color: Colors.white,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (danger ? AppColors.ballRed : AppColors.navy)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(i,
                  color: danger ? AppColors.ballRed : AppColors.navyDeep,
                  size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t,
                      style: AppTextStyles.fraunces(
                          size: 13,
                          weight: FontWeight.w700,
                          color: danger ? AppColors.ballRed : AppColors.ink)),
                  if (s.isNotEmpty)
                    Text(s,
                        style: AppTextStyles.mono(
                            size: 8,
                            color: AppColors.grey,
                            letterSpacing: 0.1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
