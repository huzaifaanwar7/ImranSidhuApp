import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/sponsor_banner.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/mock_data.dart';
import '../../models/enums.dart';
import '../../models/match.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;
  final int initialTab; // 0=Info, 1=Live/Commentary, 2=Scorecard, 3=Stats
  const MatchDetailScreen({
    super.key,
    required this.matchId,
    this.initialTab = 2,
  });

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab =
      TabController(length: 4, vsync: this, initialIndex: widget.initialTab);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = MockData.matchById(widget.matchId);
    final home = MockData.teamById(m.homeTeamId);
    final away = MockData.teamById(m.awayTeamId);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Navy back/info bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: AppColors.navyDeep,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 16, color: AppColors.cream),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${home.shortCode} vs ${away.shortCode}',
                            style: AppTextStyles.fraunces(
                                size: 13,
                                weight: FontWeight.w700,
                                color: AppColors.cream)),
                        Text((m.matchName).toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.mono(
                              size: 8,
                              color: AppColors.gold,
                              letterSpacing: 0.18,
                            )),
                      ],
                    ),
                  ),
                  if (m.isLive)
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppColors.ballRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text('LIVE',
                            style: AppTextStyles.mono(
                              size: 8,
                              color: AppColors.ballRed,
                              letterSpacing: 0.18,
                              weight: FontWeight.w700,
                            )),
                      ],
                    ),
                ],
              ),
            ),
            // Score strip (only if has innings)
            if (m.innings.isNotEmpty)
              _ScoreStrip(match: m, home: home, away: away),
            // Tabs
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tab,
                isScrollable: false,
                tabs: const [
                  Tab(text: 'INFO'),
                  Tab(text: 'COMMENTARY'),
                  Tab(text: 'SCORECARD'),
                  Tab(text: 'STATS'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _InfoTab(match: m),
                  _CommentaryTab(matchId: m.id),
                  _ScorecardTab(match: m),
                  _StatsTab(match: m),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: m.isLive
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/match/${m.id}/score'),
                  icon: const Icon(Icons.sports_cricket_rounded),
                  label: const Text('OPEN SCORING'),
                ),
              ),
            )
          : null,
    );
  }
}

class _ScoreStrip extends StatelessWidget {
  final CricketMatch match;
  final dynamic home;
  final dynamic away;
  const _ScoreStrip(
      {required this.match, required this.home, required this.away});

  @override
  Widget build(BuildContext context) {
    final inn = match.currentInnings!;
    final battingTeam = MockData.teamById(inn.battingTeamId);
    final ballsRemaining = (match.oversPerInnings * 6) - inn.legalBalls;
    return Container(
      width: double.infinity,
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(battingTeam.name,
                    style: AppTextStyles.fraunces(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.cream)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${inn.totalRuns}/${inn.wickets}',
                        style: AppTextStyles.fraunces(
                            size: 24,
                            weight: FontWeight.w900,
                            color: AppColors.gold,
                            letterSpacing: -0.02)),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${inn.oversDisplay} OV',
                          style: AppTextStyles.mono(
                              size: 10,
                              color: AppColors.cream.withValues(alpha: 0.6))),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (match.innings.length > 1)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('NEED ${(inn.target ?? 0) - inn.totalRuns}',
                    style: AppTextStyles.mono(
                      size: 9,
                      letterSpacing: 0.18,
                      color: AppColors.cream.withValues(alpha: 0.7),
                    )),
                Text('$ballsRemaining BALLS',
                    style: AppTextStyles.fraunces(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AppColors.cream)),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('CRR',
                    style: AppTextStyles.mono(
                      size: 9,
                      letterSpacing: 0.18,
                      color: AppColors.cream.withValues(alpha: 0.7),
                    )),
                Text(inn.currentRunRate.toStringAsFixed(2),
                    style: AppTextStyles.fraunces(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AppColors.cream)),
              ],
            ),
        ],
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final CricketMatch match;
  const _InfoTab({required this.match});

  @override
  Widget build(BuildContext context) {
    final home = MockData.teamById(match.homeTeamId);
    final away = MockData.teamById(match.awayTeamId);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: Column(
                    children: [
                      TeamBadge(team: home, size: 56),
                      const SizedBox(height: 8),
                      Text(home.name,
                          style: AppTextStyles.fraunces(
                              size: 13, weight: FontWeight.w700)),
                    ],
                  )),
                  Text('VS',
                      style: AppTextStyles.italicAccent(
                          size: 18, color: AppColors.grey)),
                  Expanded(
                      child: Column(
                    children: [
                      TeamBadge(team: away, size: 56),
                      const SizedBox(height: 8),
                      Text(away.name,
                          style: AppTextStyles.fraunces(
                              size: 13, weight: FontWeight.w700)),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 16),
              _kv('FORMAT',
                  '${match.format.label} · ${match.oversPerInnings} ov'),
              _kv('VENUE', match.venue ?? '—'),
              _kv('STAGE', match.stageLabel ?? '—'),
              if (match.tossWinnerTeamId != null)
                _kv('TOSS',
                    '${MockData.teamById(match.tossWinnerTeamId!).name} · ${match.tossDecision == TossDecision.bat ? 'Bat' : 'Bowl'} first'),
              if (match.resultMargin != null)
                _kv('RESULT',
                    '${MockData.teamById(match.resultWinnerTeamId ?? match.homeTeamId).name} ${match.resultMargin}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(k, style: AppTextStyles.caption)),
          Expanded(
            child: Text(v,
                style:
                    AppTextStyles.fraunces(size: 13, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _CommentaryTab extends StatelessWidget {
  final String matchId;

  const _CommentaryTab({required this.matchId});

  @override
  Widget build(BuildContext context) {
    final lines =
        MockData.commentary.where((line) => line.matchId == matchId).toList();
    if (lines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notes_outlined, size: 54, color: AppColors.grey),
              const SizedBox(height: 10),
              Text('No commentary yet',
                  style: AppTextStyles.fraunces(
                      size: 16, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'Ball-by-ball notes will appear here once scoring creates them.',
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.italicAccent(size: 13, color: AppColors.grey),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: lines.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final line = lines[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppColors.navy,
            child: Text(
              '${line.overNumber}.${line.ballInOver}',
              style: AppTextStyles.bebas(size: 10, color: Colors.white),
            ),
          ),
          title: Text(line.text,
              style: AppTextStyles.fraunces(size: 13, weight: FontWeight.w600)),
        );
      },
    );
  }
}

class _Evt {
  final String number;
  final String ball;
  final String type;
  final String text;
  const _Evt(this.number, this.ball, this.type, this.text);
}

// ignore: unused_element
class _OverBlock extends StatelessWidget {
  final String overLabel;
  final String bowlerName;
  final String summary;
  final List<_Evt> events;
  const _OverBlock({
    required this.overLabel,
    required this.bowlerName,
    required this.summary,
    required this.events,
  });

  Color _ballColor(String type) {
    switch (type) {
      case 'be-four':
        return AppColors.navy;
      case 'be-six':
        return AppColors.ballRed;
      case 'be-wkt':
        return AppColors.ink;
      default:
        return Colors.white;
    }
  }

  Color _ballFg(String type) {
    return type == 'be-dot' || type == 'be-one' ? AppColors.ink : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                      text: overLabel,
                      style: AppTextStyles.fraunces(
                          size: 13, weight: FontWeight.w700)),
                  TextSpan(
                      text: '  $bowlerName',
                      style: AppTextStyles.mono(
                          size: 9, color: AppColors.grey, letterSpacing: 0.18)),
                ]),
              ),
              Text(summary,
                  style: AppTextStyles.mono(
                    size: 9,
                    color: AppColors.ballRed,
                    weight: FontWeight.w700,
                    letterSpacing: 0.18,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          for (final e in events)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: e == events.last
                      ? BorderSide.none
                      : const BorderSide(color: AppColors.line, width: 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(e.number,
                        style: AppTextStyles.mono(
                            size: 9,
                            color: AppColors.grey,
                            letterSpacing: 0.1)),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _ballColor(e.type),
                      border: Border.all(
                          color: e.type == 'be-dot' || e.type == 'be-one'
                              ? AppColors.line
                              : _ballColor(e.type),
                          width: 1.5),
                    ),
                    child: Text(e.ball,
                        style: AppTextStyles.bebas(
                            size: 13, color: _ballFg(e.type))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _richText(e.text)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _richText(String s) {
    // Lightweight markdown: **bold**, _italic_
    final spans = <TextSpan>[];
    final pattern = RegExp(r'(\*\*[^*]+\*\*|_[^_]+_|[^*_]+)');
    for (final m in pattern.allMatches(s)) {
      final t = m.group(0)!;
      if (t.startsWith('**')) {
        spans.add(TextSpan(
            text: t.substring(2, t.length - 2),
            style: AppTextStyles.fraunces(
                size: 12, weight: FontWeight.w700, color: AppColors.navyDeep)));
      } else if (t.startsWith('_')) {
        spans.add(TextSpan(
            text: t.substring(1, t.length - 1),
            style: AppTextStyles.fraunces(
                size: 12,
                weight: FontWeight.w400,
                color: AppColors.ballRed,
                italic: true)));
      } else {
        spans.add(TextSpan(
            text: t,
            style: AppTextStyles.fraunces(
                size: 12, weight: FontWeight.w400, color: AppColors.ink)));
      }
    }
    return RichText(text: TextSpan(children: spans));
  }
}

class _ScorecardTab extends StatelessWidget {
  final CricketMatch match;
  const _ScorecardTab({required this.match});

  @override
  Widget build(BuildContext context) {
    if (match.innings.isEmpty) {
      return Center(
          child: Text('No innings yet', style: AppTextStyles.bodyLarge));
    }
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (final inn in match.innings) _InningsCard(innings: inn),
        const SponsorBanner(slot: SponsorSlot.scorecard),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _InningsCard extends StatelessWidget {
  final dynamic innings;
  const _InningsCard({required this.innings});

  @override
  Widget build(BuildContext context) {
    final team = MockData.teamById(innings.battingTeamId);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: AppColors.navyDeep,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.name,
                        style: AppTextStyles.fraunces(
                            size: 14,
                            weight: FontWeight.w700,
                            color: AppColors.cream)),
                    Text('1st INNINGS · ${innings.oversDisplay} OV',
                        style: AppTextStyles.mono(
                          size: 8,
                          color: AppColors.cream.withValues(alpha: 0.6),
                          letterSpacing: 0.15,
                        )),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                      text: '${innings.totalRuns}',
                      style: AppTextStyles.fraunces(
                          size: 22,
                          weight: FontWeight.w900,
                          color: AppColors.gold)),
                  TextSpan(
                      text: '/${innings.wickets}',
                      style: AppTextStyles.mono(
                          size: 11,
                          color: AppColors.cream.withValues(alpha: 0.6))),
                ]),
              ),
            ],
          ),
        ),
        // Batting table
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _scardHeader(),
              for (final b in innings.battingCard) _scardRow(b),
            ],
          ),
        ),
        // Extras
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.creamSoft,
          child: Row(
            children: [
              Text('EXTRAS',
                  style: AppTextStyles.fraunces(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AppColors.navyDeep)),
              const SizedBox(width: 8),
              Text('${innings.extras}', style: AppTextStyles.bodyMedium),
              const Spacer(),
              Text(
                'WD ${innings.wides} · NB ${innings.noBalls} · LB ${innings.legByes} · B ${innings.byes}',
                style: AppTextStyles.mono(
                    size: 9, color: AppColors.grey, letterSpacing: 0.1),
              ),
            ],
          ),
        ),
        // Fall of wickets
        if (innings.fallOfWickets.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            color: Colors.white,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FALL OF WICKETS',
                    style: AppTextStyles.mono(
                        size: 9, letterSpacing: 0.2, color: AppColors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final f in innings.fallOfWickets)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.creamSoft,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: RichText(
                          text: TextSpan(children: [
                            TextSpan(
                                text: '${f.wicketNumber}-${f.score}',
                                style: AppTextStyles.mono(
                                  size: 9,
                                  color: AppColors.ballRed,
                                  weight: FontWeight.w700,
                                  letterSpacing: 0.05,
                                )),
                            TextSpan(
                                text:
                                    '  ${MockData.playerById(f.batterOutId).fullName.split(' ').last} · ${f.overs}',
                                style: AppTextStyles.mono(
                                  size: 9,
                                  color: AppColors.ink,
                                  letterSpacing: 0.05,
                                )),
                          ]),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _scardHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.ink, width: 1.5)),
      ),
      child: Row(
        children: [
          Expanded(child: Text('BATTER', style: AppTextStyles.caption)),
          SizedBox(
              width: 28,
              child: Text('R',
                  textAlign: TextAlign.end, style: AppTextStyles.caption)),
          SizedBox(
              width: 28,
              child: Text('B',
                  textAlign: TextAlign.end, style: AppTextStyles.caption)),
          SizedBox(
              width: 28,
              child: Text('4s',
                  textAlign: TextAlign.end, style: AppTextStyles.caption)),
          SizedBox(
              width: 28,
              child: Text('6s',
                  textAlign: TextAlign.end, style: AppTextStyles.caption)),
          SizedBox(
              width: 38,
              child: Text('SR',
                  textAlign: TextAlign.end, style: AppTextStyles.caption)),
        ],
      ),
    );
  }

  Widget _scardRow(b) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(MockData.playerById(b.playerId).fullName,
                    style: AppTextStyles.dm(size: 11, weight: FontWeight.w700)),
                Text(
                  b.isOut ? (b.dismissalDescription ?? 'out') : 'not out',
                  style: AppTextStyles.mono(
                    size: 8,
                    color: AppColors.grey,
                    letterSpacing: 0.05,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
              width: 28,
              child: Text('${b.runs}',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.fraunces(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.navyDeep))),
          SizedBox(
              width: 28,
              child: Text('${b.balls}',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.mono(size: 9, color: AppColors.grey))),
          SizedBox(
              width: 28,
              child: Text('${b.fours}',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.mono(size: 9, color: AppColors.grey))),
          SizedBox(
              width: 28,
              child: Text('${b.sixes}',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.mono(size: 9, color: AppColors.grey))),
          SizedBox(
              width: 38,
              child: Text(b.strikeRate.toStringAsFixed(1),
                  textAlign: TextAlign.end,
                  style: AppTextStyles.mono(
                      size: 9,
                      color: AppColors.goldDeep,
                      weight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  final CricketMatch match;
  const _StatsTab({required this.match});

  @override
  Widget build(BuildContext context) {
    final inn = match.currentInnings;
    if (inn == null) {
      return Center(child: Text('No data yet', style: AppTextStyles.bodyLarge));
    }
    final boundaries =
        inn.battingCard.fold<int>(0, (s, b) => s + b.fours + b.sixes);
    final stats = [
      ('Run Rate', inn.currentRunRate.toStringAsFixed(2)),
      ('Wickets', '${inn.wickets}'),
      ('Boundaries', '$boundaries'),
      ('Extras', '${inn.extras}'),
      ('Overs', inn.oversDisplay),
      ('Legal Balls', '${inn.legalBalls}'),
    ];
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(stats[i].$1.toUpperCase(), style: AppTextStyles.caption),
            Text(stats[i].$2,
                style: AppTextStyles.fraunces(
                    size: 24,
                    weight: FontWeight.w900,
                    color: AppColors.navyDeep)),
          ],
        ),
      ),
    );
  }
}
