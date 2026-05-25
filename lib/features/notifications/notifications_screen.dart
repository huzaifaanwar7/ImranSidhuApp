import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../data/mock_data.dart';
import '../../models/notification.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _icon(NotificationKind k) => switch (k) {
        NotificationKind.matchStart => Icons.play_circle_outline_rounded,
        NotificationKind.wicket => Icons.flag_rounded,
        NotificationKind.fifty => Icons.star_rounded,
        NotificationKind.hundred => Icons.emoji_events_rounded,
        NotificationKind.inningsEnd => Icons.timer_outlined,
        NotificationKind.matchEnd => Icons.sports_score_rounded,
        NotificationKind.announcement => Icons.campaign_outlined,
        NotificationKind.stageChange => Icons.swap_horiz_rounded,
      };

  Color _color(NotificationKind k) => switch (k) {
        NotificationKind.wicket => AppColors.ballRed,
        NotificationKind.fifty || NotificationKind.hundred => AppColors.gold,
        NotificationKind.announcement => AppColors.navyDeep,
        _ => AppColors.amasGreen,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          const BackBar(title: 'Notifications', italic: ' '),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              itemCount: MockData.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final n = MockData.notifications[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: n.isRead
                        ? Colors.white
                        : AppColors.gold.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _color(n.kind).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Icon(_icon(n.kind),
                            color: _color(n.kind), size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(n.title,
                                      style: AppTextStyles.fraunces(
                                          size: 13, weight: FontWeight.w700)),
                                ),
                                Text(_rel(n.createdAt),
                                    style: AppTextStyles.mono(
                                        size: 8,
                                        letterSpacing: 0.1,
                                        color: AppColors.grey)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(n.body,
                                style: AppTextStyles.fraunces(
                                    size: 12, weight: FontWeight.w400)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _rel(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'NOW';
    if (diff.inMinutes < 60) return '${diff.inMinutes}M';
    if (diff.inHours < 24) return '${diff.inHours}H';
    return '${diff.inDays}D';
  }
}
