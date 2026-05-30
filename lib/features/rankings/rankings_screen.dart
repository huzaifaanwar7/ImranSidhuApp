import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/api_client.dart';
import '../../data/rankings_service.dart';

/// Global, all-time rankings: Batsmen · Bowlers · Teams.
/// Ratings are computed by the backend per the ISMVCC formulas.
class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.navyHeroGradient),
            padding: const EdgeInsets.fromLTRB(18, 56, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Text('BACK',
                      style: AppTextStyles.mono(
                          size: 9,
                          color: AppColors.gold,
                          letterSpacing: 0.25,
                          weight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: 'Rankings ',
                        style: AppTextStyles.fraunces(
                            size: 26,
                            weight: FontWeight.w900,
                            color: AppColors.cream)),
                    TextSpan(
                        text: '& Ratings',
                        style: AppTextStyles.italicAccent(
                            size: 26, color: AppColors.gold)),
                  ]),
                ),
                const SizedBox(height: 4),
                Text('All-time · updated after every match',
                    style: AppTextStyles.italicAccent(
                        size: 12,
                        color: AppColors.cream.withValues(alpha: 0.7))),
                const SizedBox(height: 10),
                TabBar(
                  controller: _tabs,
                  isScrollable: false,
                  indicatorColor: AppColors.gold,
                  labelColor: AppColors.cream,
                  unselectedLabelColor: AppColors.cream.withValues(alpha: 0.5),
                  labelStyle: AppTextStyles.bebas(size: 14),
                  tabs: const [
                    Tab(text: 'BATTING'),
                    Tab(text: 'BOWLING'),
                    Tab(text: 'TEAMS'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                _RankingList(kind: _Kind.batting),
                _RankingList(kind: _Kind.bowling),
                _RankingList(kind: _Kind.team),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Kind { batting, bowling, team }

class _RankingList extends StatefulWidget {
  final _Kind kind;
  const _RankingList({required this.kind});

  @override
  State<_RankingList> createState() => _RankingListState();
}

class _RankingListState extends State<_RankingList>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>>? _items;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final svc = RankingsService.instance;
      final res = await switch (widget.kind) {
        _Kind.batting => svc.batting(),
        _Kind.bowling => svc.bowling(),
        _Kind.team => svc.teams(),
      };
      if (mounted) setState(() => _items = res);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load rankings.');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_error != null) {
      return Center(
        child: Text(_error!,
            style: AppTextStyles.italicAccent(size: 13, color: AppColors.grey)),
      );
    }
    if (_items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('No rated ${_label()} yet. Play some matches first.',
              textAlign: TextAlign.center,
              style: AppTextStyles.italicAccent(size: 13, color: AppColors.grey)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
        itemCount: _items!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _row(_items![i], i + 1),
      ),
    );
  }

  String _label() => switch (widget.kind) {
        _Kind.batting => 'batsmen',
        _Kind.bowling => 'bowlers',
        _Kind.team => 'teams',
      };

  Widget _row(Map<String, dynamic> m, int rank) {
    final isTeam = widget.kind == _Kind.team;
    final name = (m['name'] as String?) ?? 'Unknown';
    final rating = (m['rating'] as num?)?.toDouble() ?? 0;
    final imgUrl = ApiClient.imageUrl(
        isTeam ? m['logoUrl'] as String? : m['photoUrl'] as String?);

    String sub;
    if (isTeam) {
      sub = '${m['matches'] ?? 0} MATCHES · ${m['points'] ?? 0} PTS';
    } else if (widget.kind == _Kind.batting) {
      sub =
          '${m['innings'] ?? 0} INN · ${m['notOuts'] ?? 0} NO · ${m['matches'] ?? 0} M';
    } else {
      sub =
          '${m['wickets'] ?? 0} WKTS · AVG ${m['average'] ?? 0} · ${m['matches'] ?? 0} M';
    }

    final medal = rank == 1
        ? AppColors.goldDeep
        : rank == 2
            ? AppColors.grey
            : rank == 3
                ? const Color(0xFFB87333)
                : AppColors.navyDeep;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (!isTeam && m['playerId'] != null) {
          context.push('/player/${m['playerId']}');
        } else if (isTeam && m['teamId'] != null) {
          context.push('/team/${m['teamId']}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text('$rank',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.fraunces(
                      size: 16, weight: FontWeight.w900, color: medal)),
            ),
            const SizedBox(width: 6),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: isTeam ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: isTeam ? BorderRadius.circular(8) : null,
                color: AppColors.navyDeep.withValues(alpha: 0.08),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: imgUrl != null
                  ? Image.network(imgUrl,
                      width: 40, height: 40, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initials(name))
                  : _initials(name),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.fraunces(
                          size: 14, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: AppTextStyles.mono(
                          size: 8,
                          color: AppColors.grey,
                          letterSpacing: 0.15)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(rating.toStringAsFixed(1),
                    style: AppTextStyles.fraunces(
                        size: 18,
                        weight: FontWeight.w900,
                        color: AppColors.navyDeep)),
                Text('RATING',
                    style: AppTextStyles.mono(
                        size: 7,
                        color: AppColors.goldDeep,
                        letterSpacing: 0.2)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _initials(String name) {
    final init = name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .take(2)
        .join();
    return Text(init.toUpperCase(),
        style: AppTextStyles.bebas(size: 13, color: AppColors.navyDeep));
  }
}
