import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/sponsor_banner.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/mock_data.dart';
import '../../data/scoring_service.dart';
import '../../models/enums.dart';

class LiveScoringScreen extends StatefulWidget {
  final String matchId;
  const LiveScoringScreen({super.key, required this.matchId});

  @override
  State<LiveScoringScreen> createState() => _LiveScoringScreenState();
}

class _UndoState {
  final int totalRuns, wickets, legalBalls, overNumber, ballInOver;
  final int strikerRuns, strikerBalls, nonStrikerRuns, nonStrikerBalls;
  final int bowlerRuns, bowlerWickets, bowlerLegalBalls;
  final String strikerId, nonStrikerId, bowlerId;
  final bool isFreeHit;
  final List<String> recent;
  _UndoState({
    required this.totalRuns,
    required this.wickets,
    required this.legalBalls,
    required this.overNumber,
    required this.ballInOver,
    required this.strikerRuns,
    required this.strikerBalls,
    required this.nonStrikerRuns,
    required this.nonStrikerBalls,
    required this.bowlerRuns,
    required this.bowlerWickets,
    required this.bowlerLegalBalls,
    required this.strikerId,
    required this.nonStrikerId,
    required this.bowlerId,
    required this.isFreeHit,
    required this.recent,
  });
}

class _LiveScoringScreenState extends State<LiveScoringScreen> {
  int totalRuns = 0;
  int wickets = 0;
  int legalBalls = 0;
  int overNumber = 1;
  int ballInOver = 0;

  String strikerId = '';
  String nonStrikerId = '';
  String bowlerId = '';

  int strikerRuns = 0;
  int strikerBalls = 0;
  int nonStrikerRuns = 0;
  int nonStrikerBalls = 0;

  int bowlerRuns = 0;
  int bowlerWickets = 0;
  int bowlerLegalBalls = 0;

  int target = 0;

  int? _inningsId;
  bool _initializingInnings = false;

  bool isFreeHit = false;
  bool wideToggle = false;
  bool noBallToggle = false;
  bool byeToggle = false;
  bool legByeToggle = false;

  final List<String> recentBalls = ['·', '4', '1', '6', '·', '—'];
  final List<_UndoState> _history = [];

  @override
  void initState() {
    super.initState();
    recentBalls
      ..clear()
      ..addAll(['-', '-', '-', '-', '-', '-']);
    _ensureInnings();
  }

  Future<void> _ensureInnings() async {
    if (_inningsId != null || _initializingInnings) return;
    final matchIdInt = int.tryParse(widget.matchId);
    if (matchIdInt == null) return; // local-only id, can't sync
    _initializingInnings = true;
    try {
      final m = MockData.matchById(widget.matchId);
      final bat = int.tryParse(m.homeTeamId);
      final bowl = int.tryParse(m.awayTeamId);
      if (bat == null || bowl == null) return;
      final res = await ScoringService.instance.startInnings(
        matchId: matchIdInt, battingTeamId: bat, bowlingTeamId: bowl, inningsNumber: 1,
      );
      _inningsId = res['id'] as int?;
    } catch (_) {
      // Offline — keep scoring locally; backend sync attempted again on next ball.
    } finally {
      _initializingInnings = false;
    }
  }

  /// Fire-and-forget — sends the latest ball to the backend so viewers see live updates.
  Future<void> _pushBall({
    required int runsBatter,
    int runsExtras = 0,
    String? extrasType,
    bool isLegalDelivery = true,
    bool isWicket = false,
    String? wicketType,
  }) async {
    final matchIdInt = int.tryParse(widget.matchId);
    if (matchIdInt == null) return;
    if (_inningsId == null) await _ensureInnings();
    if (_inningsId == null) return;
    try {
      await ScoringService.instance.recordBall(
        matchId: matchIdInt,
        inningsId: _inningsId!,
        overNumber: overNumber,
        ballInOver: ballInOver,
        strikerPlayerId: int.tryParse(strikerId),
        nonStrikerPlayerId: int.tryParse(nonStrikerId),
        bowlerPlayerId: int.tryParse(bowlerId),
        runsBatter: runsBatter,
        runsExtras: runsExtras,
        extrasType: extrasType,
        isLegalDelivery: isLegalDelivery,
        isFreeHit: isFreeHit,
        isWicket: isWicket,
        wicketType: wicketType,
      );
    } catch (_) {/* network errors swallowed — local state is the source of truth */}
  }

  void _snapshot() {
    _history.add(_UndoState(
      totalRuns: totalRuns,
      wickets: wickets,
      legalBalls: legalBalls,
      overNumber: overNumber,
      ballInOver: ballInOver,
      strikerRuns: strikerRuns,
      strikerBalls: strikerBalls,
      nonStrikerRuns: nonStrikerRuns,
      nonStrikerBalls: nonStrikerBalls,
      bowlerRuns: bowlerRuns,
      bowlerWickets: bowlerWickets,
      bowlerLegalBalls: bowlerLegalBalls,
      strikerId: strikerId,
      nonStrikerId: nonStrikerId,
      bowlerId: bowlerId,
      isFreeHit: isFreeHit,
      recent: List.of(recentBalls),
    ));
  }

  void _swap() {
    final tId = strikerId;
    strikerId = nonStrikerId;
    nonStrikerId = tId;
    final r = strikerRuns, b = strikerBalls;
    strikerRuns = nonStrikerRuns;
    strikerBalls = nonStrikerBalls;
    nonStrikerRuns = r;
    nonStrikerBalls = b;
  }

  void _pushRecent(String s) {
    if (recentBalls.first == '—') recentBalls.removeAt(0);
    recentBalls.insert(recentBalls.length, s);
    if (recentBalls.length > 6) recentBalls.removeAt(0);
  }

  void _recordRun(int runs) {
    HapticFeedback.lightImpact();
    _snapshot();
    final bool wasWide = wideToggle, wasNoBall = noBallToggle;
    final bool wasBye = byeToggle, wasLegBye = legByeToggle;
    setState(() {
      if (wideToggle || noBallToggle) {
        totalRuns += 1 + runs;
        bowlerRuns += 1 + runs;
        _pushRecent(wideToggle ? 'Wd' : 'Nb');
        isFreeHit = noBallToggle;
        wideToggle = false;
        noBallToggle = false;
      } else if (byeToggle || legByeToggle) {
        totalRuns += runs;
        strikerBalls++;
        legalBalls++;
        bowlerLegalBalls++;
        ballInOver++;
        _pushRecent('${byeToggle ? "B" : "Lb"}$runs');
        if (runs.isOdd) _swap();
        byeToggle = false;
        legByeToggle = false;
        isFreeHit = false;
      } else {
        totalRuns += runs;
        strikerRuns += runs;
        strikerBalls++;
        bowlerRuns += runs;
        legalBalls++;
        bowlerLegalBalls++;
        ballInOver++;
        _pushRecent(runs == 0 ? '·' : runs.toString());
        if (runs.isOdd) _swap();
        isFreeHit = false;
      }
      if (ballInOver >= 6) {
        ballInOver = 0;
        overNumber++;
        bowlerLegalBalls = 0;
        _swap();
        _showOverEndSheet();
      }
    });
    // After local state settles, sync this ball to backend.
    if (wasWide) {
      _pushBall(runsBatter: 0, runsExtras: 1 + runs, extrasType: 'Wide', isLegalDelivery: false);
    } else if (wasNoBall) {
      _pushBall(runsBatter: runs, runsExtras: 1, extrasType: 'NoBall', isLegalDelivery: false);
    } else if (wasBye) {
      _pushBall(runsBatter: 0, runsExtras: runs, extrasType: 'Bye');
    } else if (wasLegBye) {
      _pushBall(runsBatter: 0, runsExtras: runs, extrasType: 'LegBye');
    } else {
      _pushBall(runsBatter: runs);
    }
  }

  void _wicketSheet() async {
    final r = await showModalBottomSheet<WicketType>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _WicketSheet(),
    );
    if (r != null) {
      HapticFeedback.heavyImpact();
      _snapshot();
      setState(() {
        wickets++;
        legalBalls++;
        bowlerLegalBalls++;
        ballInOver++;
        if (r != WicketType.runOut) bowlerWickets++;
        strikerRuns = 0;
        strikerBalls = 0;
        _pushRecent('W');
        isFreeHit = false;
        if (ballInOver >= 6) {
          ballInOver = 0;
          overNumber++;
          bowlerLegalBalls = 0;
          _swap();
          _showOverEndSheet();
        }
      });
      _pushBall(runsBatter: 0, isWicket: true, wicketType: r.label.replaceAll(' ', ''));
    }
  }

  void _undo() {
    if (_history.isEmpty) return;
    HapticFeedback.lightImpact();
    final s = _history.removeLast();
    setState(() {
      totalRuns = s.totalRuns;
      wickets = s.wickets;
      legalBalls = s.legalBalls;
      overNumber = s.overNumber;
      ballInOver = s.ballInOver;
      strikerRuns = s.strikerRuns;
      strikerBalls = s.strikerBalls;
      nonStrikerRuns = s.nonStrikerRuns;
      nonStrikerBalls = s.nonStrikerBalls;
      bowlerRuns = s.bowlerRuns;
      bowlerWickets = s.bowlerWickets;
      bowlerLegalBalls = s.bowlerLegalBalls;
      strikerId = s.strikerId;
      nonStrikerId = s.nonStrikerId;
      bowlerId = s.bowlerId;
      isFreeHit = s.isFreeHit;
      recentBalls
        ..clear()
        ..addAll(s.recent);
    });
    // Sync undo with backend
    final mid = int.tryParse(widget.matchId);
    if (mid != null) {
      ScoringService.instance.undoLastBall(mid).catchError((_) {});
    }
  }

  void _showOverEndSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
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
              Text('End of Over $overNumber',
                  style: AppTextStyles.headlineLarge),
              const SizedBox(height: 6),
              Text('$totalRuns/$wickets after $overNumber overs',
                  style: AppTextStyles.bodyLarge),
              const SizedBox(height: 14),
              const SponsorBanner(slot: SponsorSlot.overCard),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CHANGE BOWLER'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('NEXT OVER  →'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = MockData.matchById(widget.matchId);
    final batting = MockData.teamById(m.homeTeamId);
    final battingPlayers = MockData.playersByTeam(m.homeTeamId);
    final bowlingPlayers = MockData.playersByTeam(m.awayTeamId);
    if (strikerId.isEmpty && battingPlayers.isNotEmpty) {
      strikerId = battingPlayers.first.id;
    }
    if (nonStrikerId.isEmpty && battingPlayers.length > 1) {
      nonStrikerId = battingPlayers[1].id;
    }
    if (bowlerId.isEmpty && bowlingPlayers.isNotEmpty) {
      bowlerId = bowlingPlayers.first.id;
    }
    final overs = '${legalBalls ~/ 6}.${legalBalls % 6}';
    final maxOvers = '${m.oversPerInnings}.0';
    final crr = legalBalls == 0 ? 0.0 : (totalRuns / legalBalls) * 6;
    final ballsRemaining = (m.oversPerInnings * 6) - legalBalls;
    final rrr =
        ballsRemaining <= 0 ? 0.0 : ((target - totalRuns) / ballsRemaining) * 6;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Score hero
            Container(
              decoration:
                  const BoxDecoration(gradient: AppColors.navyHeroGradient),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text('BACK',
                            style: AppTextStyles.mono(
                                size: 9, color: AppColors.gold, letterSpacing: 0.25, weight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          (m.matchName).toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.mono(
                            size: 9,
                            color: AppColors.cream.withValues(alpha: 0.6),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.ballRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.ballRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text('LIVE',
                                style: AppTextStyles.mono(
                                  size: 9,
                                  color: AppColors.ballRed,
                                  weight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      TeamBadge(team: batting, size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(batting.name.toUpperCase(),
                                style: AppTextStyles.fraunces(
                                  size: 14,
                                  weight: FontWeight.w700,
                                  color: AppColors.cream,
                                )),
                            Text('1st INNINGS',
                                style: AppTextStyles.mono(
                                  size: 8,
                                  color: AppColors.cream.withValues(alpha: 0.6),
                                  letterSpacing: 0.2,
                                )),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: '$totalRuns',
                                style: AppTextStyles.fraunces(
                                  size: 38,
                                  weight: FontWeight.w900,
                                  color: AppColors.cream,
                                  letterSpacing: -0.02,
                                ),
                              ),
                              TextSpan(
                                text: '/$wickets',
                                style: AppTextStyles.fraunces(
                                  size: 20,
                                  color: AppColors.gold,
                                  weight: FontWeight.w400,
                                ),
                              ),
                            ]),
                          ),
                          Text('$overs / $maxOvers OVERS',
                              style: AppTextStyles.mono(
                                size: 9,
                                color: AppColors.cream.withValues(alpha: 0.7),
                                letterSpacing: 0.15,
                              )),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        _hk('CRR', crr.toStringAsFixed(2)),
                        _hk('RRR', rrr.toStringAsFixed(2), gold: true),
                        _hk('TARGET', '$target'),
                        _hk('BALLS LEFT', '$ballsRemaining'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Free hit pill (if active)
            if (isFreeHit)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: AppColors.gold,
                child: Text('FREE HIT',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bebas(
                        size: 14,
                        color: AppColors.navyDeep,
                        letterSpacing: 0.2)),
              ),

            // Batters block
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: Colors.white,
              child: Column(
                children: [
                  _battersHeader(),
                  const Divider(height: 14, color: AppColors.line),
                  _batterRow(strikerId, strikerRuns, strikerBalls,
                      isStriker: true),
                  const SizedBox(height: 6),
                  _batterRow(nonStrikerId, nonStrikerRuns, nonStrikerBalls),
                ],
              ),
            ),

            // Bowler
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.creamSoft,
                border: Border(bottom: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  TeamBadge(team: MockData.teamById(m.awayTeamId), size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(MockData.playerById(bowlerId).fullName,
                            style: AppTextStyles.dm(
                                size: 12, weight: FontWeight.w600)),
                        Text('BOWLING',
                            style: AppTextStyles.mono(
                                size: 8, letterSpacing: 0.18)),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$bowlerWickets/$bowlerRuns',
                          style: AppTextStyles.fraunces(
                              size: 14,
                              weight: FontWeight.w700,
                              color: AppColors.navyDeep)),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                            '${bowlerLegalBalls ~/ 6}.${bowlerLegalBalls % 6} OV',
                            style: AppTextStyles.mono(
                                size: 9, color: AppColors.grey)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // This over
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('THIS OVER · OV $overNumber',
                          style: AppTextStyles.mono(
                              size: 9,
                              letterSpacing: 0.2,
                              color: AppColors.grey)),
                      Text(
                          '${recentBalls.where((b) => b != '—' && b != '·' && b != 'W').fold<int>(0, (s, b) {
                            final n = int.tryParse(b);
                            return s + (n ?? 0);
                          })} RUNS',
                          style: AppTextStyles.mono(
                            size: 9,
                            color: AppColors.navyDeep,
                            weight: FontWeight.w700,
                            letterSpacing: 0.2,
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: recentBalls.map((b) => _ballPill(b)).toList(),
                  ),
                ],
              ),
            ),

            const SponsorBanner(
                slot: SponsorSlot.matchPresentedBy, dense: true),

            const Spacer(),

            // Scoring pad
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
              decoration: const BoxDecoration(
                color: AppColors.creamSoft,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _padRun(0, big: true),
                      _padRun(1, big: true),
                      _padRun(2, big: true),
                      _padRun(3, big: true),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _padBig(4, AppColors.navy),
                      _padBig(6, AppColors.ballRed),
                      _padWicket(),
                      _padExtra('WIDE', wideToggle, () {
                        setState(() {
                          wideToggle = !wideToggle;
                          noBallToggle = byeToggle = legByeToggle = false;
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _padExtra('NB', noBallToggle, () {
                        setState(() {
                          noBallToggle = !noBallToggle;
                          wideToggle = byeToggle = legByeToggle = false;
                        });
                      }),
                      _padExtra('BYE', byeToggle, () {
                        setState(() {
                          byeToggle = !byeToggle;
                          wideToggle = noBallToggle = legByeToggle = false;
                        });
                      }),
                      _padExtra('LB', legByeToggle, () {
                        setState(() {
                          legByeToggle = !legByeToggle;
                          wideToggle = noBallToggle = byeToggle = false;
                        });
                      }),
                      _padExtra('UNDO', false, _history.isEmpty ? null : _undo),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hk(String k, String v, {bool gold = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k,
              style: AppTextStyles.mono(
                size: 9,
                color: AppColors.cream.withValues(alpha: 0.6),
                letterSpacing: 0.15,
              )),
          Text(v,
              style: AppTextStyles.fraunces(
                size: 16,
                weight: FontWeight.w700,
                color: gold ? AppColors.gold : AppColors.cream,
              )),
        ],
      ),
    );
  }

  Widget _battersHeader() {
    return Row(
      children: [
        Expanded(child: Text('BATTER', style: AppTextStyles.caption)),
        SizedBox(
            width: 30,
            child: Text('R',
                textAlign: TextAlign.center, style: AppTextStyles.caption)),
        SizedBox(
            width: 30,
            child: Text('B',
                textAlign: TextAlign.center, style: AppTextStyles.caption)),
        SizedBox(
            width: 30,
            child: Text('4s',
                textAlign: TextAlign.center, style: AppTextStyles.caption)),
        SizedBox(
            width: 36,
            child: Text('SR',
                textAlign: TextAlign.end, style: AppTextStyles.caption)),
      ],
    );
  }

  Widget _batterRow(String id, int r, int b, {bool isStriker = false}) {
    final p = MockData.playerById(id);
    final sr = b == 0 ? 0.0 : (r / b) * 100;
    return Row(
      children: [
        if (isStriker)
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: AppColors.ballRed, shape: BoxShape.circle),
          )
        else
          const SizedBox(width: 6),
        const SizedBox(width: 6),
        Expanded(
          child: Text('${p.fullName}${isStriker ? ' *' : ''}',
              style: AppTextStyles.dm(size: 12, weight: FontWeight.w600)),
        ),
        SizedBox(
            width: 30,
            child: Text('$r',
                textAlign: TextAlign.center,
                style: AppTextStyles.fraunces(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.navyDeep))),
        SizedBox(
            width: 30,
            child: Text('$b',
                textAlign: TextAlign.center,
                style: AppTextStyles.mono(size: 10, color: AppColors.grey))),
        SizedBox(
            width: 30,
            child: Text('${(r / 10).floor()}',
                textAlign: TextAlign.center,
                style: AppTextStyles.mono(size: 10, color: AppColors.grey))),
        SizedBox(
            width: 36,
            child: Text(sr.toStringAsFixed(1),
                textAlign: TextAlign.end,
                style: AppTextStyles.mono(
                    size: 9,
                    color: AppColors.goldDeep,
                    weight: FontWeight.w700))),
      ],
    );
  }

  Widget _ballPill(String b) {
    Color bg;
    Color fg;
    Color border;
    if (b == 'W') {
      bg = AppColors.ink;
      fg = Colors.white;
      border = AppColors.ink;
    } else if (b == '4') {
      bg = AppColors.navy;
      fg = Colors.white;
      border = AppColors.navy;
    } else if (b == '6') {
      bg = AppColors.ballRed;
      fg = Colors.white;
      border = AppColors.ballRed;
    } else if (b == 'Wd' || b == 'Nb') {
      bg = AppColors.gold;
      fg = Colors.white;
      border = AppColors.gold;
    } else if (b == '—') {
      bg = AppColors.creamSoft;
      fg = AppColors.grey;
      border = AppColors.line;
    } else {
      bg = Colors.white;
      fg = b == '·' ? AppColors.grey : AppColors.ink;
      border = AppColors.line;
    }
    return Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.only(right: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: border, width: 1.5),
      ),
      child: Text(b,
          style: AppTextStyles.bebas(size: b.length > 1 ? 10 : 14, color: fg)),
    );
  }

  Widget _padRun(int n, {bool big = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _recordRun(n),
          child: AspectRatio(
            aspectRatio: 1.4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.line),
              ),
              alignment: Alignment.center,
              child: Text('$n',
                  style: AppTextStyles.bebas(
                      size: big ? 22 : 18, color: AppColors.ink)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _padBig(int n, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _recordRun(n),
          child: AspectRatio(
            aspectRatio: 1.4,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text('$n',
                  style: AppTextStyles.bebas(size: 22, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _padWicket() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _wicketSheet,
          child: AspectRatio(
            aspectRatio: 1.4,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text('WICKET',
                  style: AppTextStyles.mono(
                      size: 11,
                      color: Colors.white,
                      weight: FontWeight.w700,
                      letterSpacing: 0.15)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _padExtra(String label, bool active, VoidCallback? onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 1.4,
            child: Container(
              decoration: BoxDecoration(
                color: active ? AppColors.gold : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: active ? AppColors.gold : AppColors.grey,
                    width: 1,
                    style: active ? BorderStyle.solid : BorderStyle.solid),
              ),
              alignment: Alignment.center,
              child: Text(label,
                  style: AppTextStyles.mono(
                      size: 10,
                      color: active
                          ? Colors.white
                          : (onTap == null ? AppColors.line : AppColors.grey),
                      weight: FontWeight.w700,
                      letterSpacing: 0.2)),
            ),
          ),
        ),
      ),
    );
  }
}

class _WicketSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.flag_rounded, color: AppColors.ballRed),
                const SizedBox(width: 8),
                Text('Wicket type', style: AppTextStyles.headlineLarge),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: WicketType.values
                  .map(
                    (w) => InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context, w),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Text(w.label.toUpperCase(),
                            style: AppTextStyles.mono(
                              size: 10,
                              letterSpacing: 0.15,
                              weight: FontWeight.w700,
                            )),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
