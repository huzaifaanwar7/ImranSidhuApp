import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock_data.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const u = MockData.currentUser;
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
                    u.fullName.split(' ').map((s) => s[0]).take(2).join(),
                    style: AppTextStyles.bebas(size: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(u.fullName,
                    style: AppTextStyles.fraunces(
                        size: 22,
                        weight: FontWeight.w900,
                        color: AppColors.cream)),
                Text(u.email,
                    style: AppTextStyles.italicAccent(
                        size: 13,
                        color: AppColors.cream.withValues(alpha: 0.7))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: u.roles
                      .map((r) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.4)),
                            ),
                            child: Text(r.name.toUpperCase(),
                                style: AppTextStyles.mono(
                                  size: 8,
                                  color: AppColors.gold,
                                  letterSpacing: 0.2,
                                  weight: FontWeight.w700,
                                )),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section('CRICKET'),
          _tile(context, Icons.person_outline, 'My player profile',
              'View players', () => context.push('/players')),
          _tile(context, Icons.notifications_outlined, 'Notifications',
              'Manage match alerts', () => context.push('/notifications')),
          _tile(context, Icons.bookmark_outline_rounded, 'My subscriptions',
              'Teams, players, tournaments', () => context.push('/stats')),
          _section('ORGANIZING'),
          _tile(
              context,
              Icons.add_box_outlined,
              'Create tournament',
              'Round Robin - Knockout - Hybrid',
              () => context.push('/tournament/new')),
          _tile(context, Icons.workspace_premium_rounded, 'Sponsors',
              'Manage sponsor slots', () => context.push('/sponsors')),
          _tile(context, Icons.cloud_sync_outlined, 'Offline sync',
              'Pending balls in queue', () {}),
          _section('APP'),
          _tile(context, Icons.translate_rounded, 'Language', 'English (US)',
              () {}),
          _tile(context, Icons.color_lens_outlined, 'Theme', 'System default',
              () {}),
          _tile(
              context, Icons.help_outline_rounded, 'Help & support', '', () {}),
          _tile(context, Icons.info_outline_rounded, 'About', 'v1.0.0', () {}),
          _tile(context, Icons.logout_rounded, 'Sign out', '',
              () => context.go('/login'),
              danger: true),
          const SizedBox(height: 100),
        ],
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
            const Icon(Icons.chevron_right_rounded, color: AppColors.grey),
          ],
        ),
      ),
    );
  }
}
