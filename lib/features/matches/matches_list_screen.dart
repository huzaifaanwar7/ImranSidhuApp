import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/match_card.dart';
import '../../data/mock_data.dart';

class MatchesListScreen extends StatefulWidget {
  const MatchesListScreen({super.key});

  @override
  State<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends State<MatchesListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = MockData.matches.where((m) => m.isLive).toList();
    final upcoming = MockData.matches.where((m) => m.isUpcoming).toList();
    final completed = MockData.matches.where((m) => m.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(actions: [
              IconBtn(
                  icon: Icons.search_rounded,
                  onTap: () => context.push('/search')),
              const SizedBox(width: 6),
              const IconBtn(icon: Icons.tune_rounded),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(text: 'All ', style: AppTextStyles.displayMedium),
                  TextSpan(
                      text: 'Matches',
                      style: AppTextStyles.italicAccent(
                          size: 26, color: AppColors.goldDeep)),
                ]),
              ),
            ),
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tab,
                tabs: [
                  Tab(text: 'LIVE (${live.length})'),
                  Tab(text: 'UPCOMING (${upcoming.length})'),
                  Tab(text: 'COMPLETED (${completed.length})'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _list(live, 'No live matches right now'),
                  _list(upcoming, 'No upcoming fixtures'),
                  _list(completed, 'No completed matches yet'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ballRed,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/match/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text('NEW MATCH',
            style: AppTextStyles.bebas(size: 14, color: Colors.white)),
      ),
    );
  }

  Widget _list(List list, String emptyText) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_cricket_outlined,
                  size: 56, color: AppColors.grey),
              const SizedBox(height: 8),
              Text(emptyText,
                  style: AppTextStyles.italicAccent(
                      size: 14, color: AppColors.grey)),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => MatchCard(match: list[i]),
    );
  }
}
