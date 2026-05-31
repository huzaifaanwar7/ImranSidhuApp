import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/sponsor_banner.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/api_client.dart';
import '../../data/backend_sync.dart';
import '../../data/mock_data.dart';
import '../../data/scoring_service.dart';
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

class _LiveScoreBanner extends StatelessWidget {
  final Map<String, dynamic> card;
  const _LiveScoreBanner({required this.card});

  @override
  Widget build(BuildContext context) {
    final innings = (card['innings'] as List?) ?? const [];
    if (innings.isEmpty) return const SizedBox.shrink();
    final current = Map<String, dynamic>.from(innings.last as Map);
    final runs = current['totalRuns'] ?? 0;
    final wkts = current['wickets'] ?? 0;
    final legalBalls = current['legalBallsBowled'] as int? ?? 0;
    final overs = '${legalBalls ~/ 6}.${legalBalls % 6}';
    final match = card['match'] is Map ? Map<String, dynamic>.from(card['match'] as Map) : null;
    final homePen = match?['homePenaltyRuns'] ?? 0;
    final awayPen = match?['awayPenaltyRuns'] ?? 0;
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('LIVE',
              style: AppTextStyles.mono(
                  size: 9, color: AppColors.ballRed, weight: FontWeight.w800, letterSpacing: 0.25)),
          const SizedBox(width: 10),
          Text('$runs/$wkts',
              style: AppTextStyles.fraunces(
                  size: 18, weight: FontWeight.w900, color: AppColors.cream)),
          const SizedBox(width: 8),
          Text('($overs ov)',
              style: AppTextStyles.mono(
                  size: 10, color: AppColors.gold, letterSpacing: 0.2)),
          const Spacer(),
          if ((homePen as int) > 0 || (awayPen as int) > 0)
            Text('PENALTY  H:$homePen  A:$awayPen',
                style: AppTextStyles.mono(
                    size: 8, color: AppColors.gold, letterSpacing: 0.2, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MatchDetailScreenState extends State<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab =
      TabController(length: 4, vsync: this, initialIndex: widget.initialTab);

  Timer? _pollTimer;
  Map<String, dynamic>? _liveScorecard;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    final mid = int.tryParse(widget.matchId);
    if (mid == null) return;
    _refresh(mid);
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh(mid));
  }

  Future<void> _refresh(int mid) async {
    try {
      final card = await ScoringService.instance.scorecard(mid);
      if (mounted) setState(() => _liveScorecard = card);
    } catch (_) {/* keep last known */}
  }

  Future<void> _startMatch(CricketMatch m) async {
    final mid = int.tryParse(m.id);
    if (mid == null) return;
    try {
      await ScoringService.instance.startMatch(mid);
      await BackendSync.instance.refreshAll();
      if (!mounted) return;
      setState(() {});
      context.push('/match/${m.id}/score');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start match: $e')),
        );
      }
    }
  }

  Future<void> _endMatch(CricketMatch m) async {
    final mid = int.tryParse(m.id);
    if (mid == null) return;
    final home = MockData.teamById(m.homeTeamId);
    final away = MockData.teamById(m.awayTeamId);
    final squad = [
      ...MockData.playersByTeam(m.homeTeamId),
      ...MockData.playersByTeam(m.awayTeamId),
    ];
    String? winnerId;
    String? momId;
    final marginCtrl = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('End Match', style: AppTextStyles.headlineLarge),
                const SizedBox(height: 14),
                Text('SELECT WINNER', style: AppTextStyles.caption),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _winnerChip(home.shortCode, winnerId == home.id,
                        () => setModal(() => winnerId = home.id)),
                    const SizedBox(width: 8),
                    _winnerChip(away.shortCode, winnerId == away.id,
                        () => setModal(() => winnerId = away.id)),
                    const SizedBox(width: 8),
                    _winnerChip('TIE', winnerId == 'tie',
                        () => setModal(() => winnerId = 'tie')),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: marginCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Result margin (e.g. "5 wickets" or "12 runs")',
                  ),
                  style:
                      AppTextStyles.fraunces(size: 13, weight: FontWeight.w600),
                ),
                if (squad.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('MAN OF THE MATCH (optional)',
                      style: AppTextStyles.caption),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showModalBottomSheet<String>(
                        context: ctx,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (c2) => Container(
                          decoration: const BoxDecoration(
                            color: AppColors.cream,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(c2).size.height * 0.6),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              for (final p in squad)
                                ListTile(
                                  title: Text(p.fullName,
                                      style: AppTextStyles.fraunces(
                                          size: 13, weight: FontWeight.w700)),
                                  onTap: () => Navigator.pop(c2, p.id),
                                ),
                            ],
                          ),
                        ),
                      );
                      if (picked != null) setModal(() => momId = picked);
                    },
                    icon: const Icon(Icons.star_rounded, size: 18),
                    label: Text(momId == null
                        ? 'Select player'
                        : MockData.playerById(momId!).fullName),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: winnerId == null
                            ? null
                            : () => Navigator.pop(ctx, true),
                        child: const Text('END MATCH'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;
    try {
      await ScoringService.instance.endMatch(
        matchId: mid,
        winnerTeamId: winnerId == 'tie' ? null : int.tryParse(winnerId ?? ''),
        resultMargin:
            marginCtrl.text.trim().isEmpty ? null : marginCtrl.text.trim(),
        manOfTheMatchPlayerId: momId == null ? null : int.tryParse(momId!),
      );
      await BackendSync.instance.refreshAll();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not end match: $e')),
        );
      }
    }
  }

  Widget _winnerChip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.line,
              width: selected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: AppTextStyles.bebas(
                  size: 14,
                  color: selected ? AppColors.cream : AppColors.navyDeep)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
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
                    child: Text('BACK',
                        style: AppTextStyles.mono(
                            size: 9, color: AppColors.gold, letterSpacing: 0.25, weight: FontWeight.w700)),
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
            // Result banner once the match is completed.
            if (m.isCompleted &&
                (m.resultWinnerTeamId != null || m.resultMargin != null))
              _ResultBanner(match: m)
            // Otherwise, the live score banner — polled every 5s from /scorecard.
            else if (_liveScorecard != null)
              _LiveScoreBanner(card: _liveScorecard!),
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
                  _ScorecardTab(match: m, card: _liveScorecard),
                  _StatsTab(match: m, card: _liveScorecard),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          (ApiClient.instance.canScore && (m.isUpcoming || m.isLive))
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: m.isUpcoming
                        ? ElevatedButton.icon(
                            onPressed: () => _startMatch(m),
                            icon: const Icon(Icons.play_circle_fill_rounded),
                            label: const Text('START MATCH'),
                          )
                        : Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      context.push('/match/${m.id}/score'),
                                  icon:
                                      const Icon(Icons.sports_cricket_rounded),
                                  label: const Text('OPEN SCORING'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _endMatch(m),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.ballRed,
                                    side: const BorderSide(
                                        color: AppColors.ballRed),
                                  ),
                                  child: const Text('END'),
                                ),
                              ),
                            ],
                          ),
                  ),
                )
              : null,
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
              if (match.resultWinnerTeamId != null ||
                  match.resultMargin != null)
                _kv(
                    'RESULT',
                    match.resultWinnerTeamId == null
                        ? (match.resultMargin ?? 'Match tied')
                        : '${MockData.teamById(match.resultWinnerTeamId!).name} ${(match.resultMargin == null || match.resultMargin!.isEmpty) ? 'won' : match.resultMargin}'),
              if (match.manOfTheMatchPlayerId != null)
                _kv('MAN OF MATCH',
                    MockData.playerById(match.manOfTheMatchPlayerId!).fullName),
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

int _ji(Object? v) => (v is num) ? v.toInt() : (int.tryParse('$v') ?? 0);
List<Map<String, dynamic>> _jlist(Object? v) => ((v as List?) ?? const [])
    .map((e) => Map<String, dynamic>.from(e as Map))
    .toList();

class _ScorecardTab extends StatelessWidget {
  final CricketMatch match;
  final Map<String, dynamic>? card;
  const _ScorecardTab({required this.match, this.card});

  @override
  Widget build(BuildContext context) {
    final innings = _jlist(card?['innings']);
    if (innings.isEmpty) {
      return Center(
          child: Text('No innings yet', style: AppTextStyles.bodyLarge));
    }
    final batting = _jlist(card?['batting']);
    final bowling = _jlist(card?['bowling']);
    final fow = _jlist(card?['fallOfWickets']);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (final inn in innings)
          _InningsCard(
              innings: inn, batting: batting, bowling: bowling, fow: fow),
        const SponsorBanner(slot: SponsorSlot.scorecard),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _InningsCard extends StatelessWidget {
  final Map<String, dynamic> innings;
  final List<Map<String, dynamic>> batting;
  final List<Map<String, dynamic>> bowling;
  final List<Map<String, dynamic>> fow;
  const _InningsCard({
    required this.innings,
    required this.batting,
    required this.bowling,
    required this.fow,
  });

  @override
  Widget build(BuildContext context) {
    final inningsId = _ji(innings['id']);
    final team = MockData.teamById('${innings['battingTeamId']}');
    final runs = _ji(innings['totalRuns']);
    final wkts = _ji(innings['wickets']);
    final lb = _ji(innings['legalBallsBowled']);
    final overs = '${lb ~/ 6}.${lb % 6}';
    final innNo = _ji(innings['inningsNumber']);
    final wides = _ji(innings['extrasWides']);
    final noBalls = _ji(innings['extrasNoBalls']);
    final byes = _ji(innings['extrasByes']);
    final legByes = _ji(innings['extrasLegByes']);
    final pen = _ji(innings['extrasPenalty']);
    final extras = wides + noBalls + byes + legByes + pen;

    final bat = batting.where((b) => _ji(b['inningsId']) == inningsId).toList()
      ..sort((a, b) => _ji(a['battingOrder']).compareTo(_ji(b['battingOrder'])));
    final bowl =
        bowling.where((b) => _ji(b['inningsId']) == inningsId).toList();
    final myFow = fow.where((f) => _ji(f['inningsId']) == inningsId).toList()
      ..sort((a, b) => _ji(a['wicketNumber']).compareTo(_ji(b['wicketNumber'])));

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
                    Text('${innNo == 2 ? '2nd' : '1st'} INNINGS · $overs OV',
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
                      text: '$runs',
                      style: AppTextStyles.fraunces(
                          size: 22,
                          weight: FontWeight.w900,
                          color: AppColors.gold)),
                  TextSpan(
                      text: '/$wkts',
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
              _batHeader(),
              if (bat.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('No batting yet',
                      style: AppTextStyles.mono(size: 10, color: AppColors.grey)),
                ),
              for (final b in bat) _batRow(b),
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
              Text('$extras', style: AppTextStyles.bodyMedium),
              const Spacer(),
              Text(
                'WD $wides · NB $noBalls · LB $legByes · B $byes',
                style: AppTextStyles.mono(
                    size: 9, color: AppColors.grey, letterSpacing: 0.1),
              ),
            ],
          ),
        ),
        // Bowling table
        if (bowl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _bowlHeader(),
                for (final b in bowl) _bowlRow(b),
              ],
            ),
          ),
        // Fall of wickets
        if (myFow.isNotEmpty)
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
                    for (final f in myFow)
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
                                text: '${_ji(f['wicketNumber'])}-${_ji(f['runs'])}',
                                style: AppTextStyles.mono(
                                  size: 9,
                                  color: AppColors.ballRed,
                                  weight: FontWeight.w700,
                                  letterSpacing: 0.05,
                                )),
                            TextSpan(
                                text:
                                    '  ${'${f['player'] ?? ''}'.split(' ').last} · ${f['overs']}',
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

  Widget _batHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.ink, width: 1.5)),
      ),
      child: Row(
        children: [
          Expanded(child: Text('BATTER', style: AppTextStyles.caption)),
          for (final h in const ['R', 'B', '4s', '6s'])
            SizedBox(
                width: 28,
                child: Text(h,
                    textAlign: TextAlign.end, style: AppTextStyles.caption)),
          SizedBox(
              width: 38,
              child: Text('SR',
                  textAlign: TextAlign.end, style: AppTextStyles.caption)),
        ],
      ),
    );
  }

  Widget _batRow(Map<String, dynamic> b) {
    final runs = _ji(b['runs']);
    final balls = _ji(b['ballsFaced']);
    final sr = balls == 0 ? 0.0 : (runs / balls) * 100;
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
                Text('${b['fullName'] ?? 'Batter'}',
                    style: AppTextStyles.dm(size: 11, weight: FontWeight.w700)),
                Text(
                  b['isOut'] == true
                      ? '${b['dismissalDescription'] ?? 'out'}'
                      : 'not out',
                  style: AppTextStyles.mono(
                      size: 8, color: AppColors.grey, letterSpacing: 0.05),
                ),
              ],
            ),
          ),
          SizedBox(
              width: 28,
              child: Text('$runs',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.fraunces(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.navyDeep))),
          SizedBox(
              width: 28,
              child: Text('$balls',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.mono(size: 9, color: AppColors.grey))),
          SizedBox(
              width: 28,
              child: Text('${_ji(b['fours'])}',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.mono(size: 9, color: AppColors.grey))),
          SizedBox(
              width: 28,
              child: Text('${_ji(b['sixes'])}',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.mono(size: 9, color: AppColors.grey))),
          SizedBox(
              width: 38,
              child: Text(sr.toStringAsFixed(1),
                  textAlign: TextAlign.end,
                  style: AppTextStyles.mono(
                      size: 9,
                      color: AppColors.goldDeep,
                      weight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _bowlHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.ink, width: 1.5)),
      ),
      child: Row(
        children: [
          Expanded(child: Text('BOWLER', style: AppTextStyles.caption)),
          for (final h in const ['O', 'R', 'W'])
            SizedBox(
                width: 30,
                child: Text(h,
                    textAlign: TextAlign.end, style: AppTextStyles.caption)),
          SizedBox(
              width: 42,
              child: Text('ECON',
                  textAlign: TextAlign.end, style: AppTextStyles.caption)),
        ],
      ),
    );
  }

  Widget _bowlRow(Map<String, dynamic> b) {
    final oversStr = '${b['overs'] ?? '0.0'}';
    final parts = oversStr.split('.');
    final balls = (int.tryParse(parts.first) ?? 0) * 6 +
        (parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
    final runs = _ji(b['runsConceded']);
    final econ = balls == 0 ? 0.0 : runs * 6 / balls;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('${b['fullName'] ?? 'Bowler'}',
                style: AppTextStyles.dm(size: 11, weight: FontWeight.w700)),
          ),
          SizedBox(
              width: 30,
              child: Text(oversStr,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.mono(size: 9, color: AppColors.grey))),
          SizedBox(
              width: 30,
              child: Text('$runs',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.mono(size: 9, color: AppColors.grey))),
          SizedBox(
              width: 30,
              child: Text('${_ji(b['wickets'])}',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.fraunces(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.navyDeep))),
          SizedBox(
              width: 42,
              child: Text(econ.toStringAsFixed(1),
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

class _ResultBanner extends StatelessWidget {
  final CricketMatch match;
  const _ResultBanner({required this.match});

  @override
  Widget build(BuildContext context) {
    final winner = match.resultWinnerTeamId == null
        ? null
        : MockData.teamById(match.resultWinnerTeamId!).name;
    var margin = match.resultMargin;
    if ((margin == null || margin.isEmpty) && match.resultWinnerTeamId != null) {
      margin = match.computedMargin(match.resultWinnerTeamId!);
    }
    final text = winner == null
        ? (match.resultMargin ?? 'Match tied')
        : ((margin == null || margin.isEmpty) ? '$winner won' : '$winner $margin');
    return Container(
      width: double.infinity,
      color: AppColors.amasGreen,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text.toUpperCase(),
                style: AppTextStyles.mono(
                    size: 11,
                    color: Colors.white,
                    weight: FontWeight.w700,
                    letterSpacing: 0.2)),
          ),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  final CricketMatch match;
  final Map<String, dynamic>? card;
  const _StatsTab({required this.match, this.card});

  @override
  Widget build(BuildContext context) {
    final innings = _jlist(card?['innings']);
    if (innings.isEmpty) {
      return Center(child: Text('No data yet', style: AppTextStyles.bodyLarge));
    }
    final inn = innings.last;
    final inningsId = _ji(inn['id']);
    final runs = _ji(inn['totalRuns']);
    final wkts = _ji(inn['wickets']);
    final lb = _ji(inn['legalBallsBowled']);
    final overs = '${lb ~/ 6}.${lb % 6}';
    final crr = lb == 0 ? 0.0 : (runs / lb) * 6;
    final wides = _ji(inn['extrasWides']);
    final noBalls = _ji(inn['extrasNoBalls']);
    final byes = _ji(inn['extrasByes']);
    final legByes = _ji(inn['extrasLegByes']);
    final pen = _ji(inn['extrasPenalty']);
    final extras = wides + noBalls + byes + legByes + pen;
    final boundaries = _jlist(card?['batting'])
        .where((b) => _ji(b['inningsId']) == inningsId)
        .fold<int>(0, (s, b) => s + _ji(b['fours']) + _ji(b['sixes']));
    final stats = [
      ('Run Rate', crr.toStringAsFixed(2)),
      ('Wickets', '$wkts'),
      ('Boundaries', '$boundaries'),
      ('Extras', '$extras'),
      ('Overs', overs),
      ('Legal Balls', '$lb'),
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
