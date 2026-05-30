import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../data/api_client.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = false;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!ApiClient.instance.isAuthed) {
      setState(() => _items = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.get('/api/notifications');
      _items = List<Map<String, dynamic>>.from(res['items'] as List);
    } catch (_) {/* ignore */}
    finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiClient.instance.post('/api/notifications/read-all');
      await _load();
    } catch (_) {/* ignore */}
  }

  IconData _iconFor(String type) => switch (type) {
        'Wicket' => Icons.flag_rounded,
        'Fifty' => Icons.star_rounded,
        'Hundred' => Icons.emoji_events_rounded,
        'MatchStart' => Icons.play_circle_outline_rounded,
        'MatchEnd' => Icons.sports_score_rounded,
        'Announcement' => Icons.campaign_outlined,
        _ => Icons.notifications_outlined,
      };

  Color _colorFor(String type) => switch (type) {
        'Wicket' => AppColors.ballRed,
        'Fifty' || 'Hundred' => AppColors.gold,
        'Announcement' => AppColors.navyDeep,
        _ => AppColors.amasGreen,
      };

  @override
  Widget build(BuildContext context) {
    if (!ApiClient.instance.isAuthed) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [
            const BackBar(title: 'Notifications', italic: ' '),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    'Sign in to see your notifications.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.italicAccent(size: 14, color: AppColors.grey),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          BackBar(
            title: 'Notifications',
            italic: ' ',
            actions: [
              TextButton(
                onPressed: _markAllRead,
                child: const Text('READ ALL', style: TextStyle(color: AppColors.gold)),
              ),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Text('You\'re all caught up.',
                            style: AppTextStyles.italicAccent(size: 14, color: AppColors.grey)),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final n = _items[i];
                            final type = n['type'] as String? ?? '';
                            final isRead = n['isRead'] == true;
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isRead ? Colors.white : AppColors.gold.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: _colorFor(type).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(_iconFor(type), color: _colorFor(type), size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(n['title'] as String? ?? '',
                                                  style: AppTextStyles.fraunces(size: 13, weight: FontWeight.w700)),
                                            ),
                                            Text(_rel(DateTime.tryParse(n['createdAt'] as String? ?? '') ?? DateTime.now()),
                                                style: AppTextStyles.mono(size: 8, letterSpacing: 0.1, color: AppColors.grey)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(n['body'] as String? ?? '',
                                            style: AppTextStyles.fraunces(size: 12, weight: FontWeight.w400)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
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
