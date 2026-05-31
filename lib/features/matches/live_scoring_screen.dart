import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/sponsor_banner.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/backend_sync.dart';
import '../../data/mock_data.dart';
import '../../data/scoring_service.dart';
import '../../models/enums.dart';
import '../../models/player.dart';

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
  int inningsNo = 1;
  int firstInningsRuns = 0;

  int? _inningsId;
  bool _initializingInnings = false;
  bool _ending = false;
  bool _setupPrompted = false;

  // ---- Team resolution (respects toss) ----
  String get _firstBatId {
    final m = MockData.matchById(widget.matchId);
    if (m.tossWinnerTeamId != null && m.tossWinnerTeamId!.isNotEmpty) {
      final winner = m.tossWinnerTeamId!;
      final other = winner == m.homeTeamId ? m.awayTeamId : m.homeTeamId;
      return m.tossDecision == TossDecision.bowl ? other : winner;
    }
    return m.homeTeamId;
  }

  String get _secondBatId {
    final m = MockData.matchById(widget.matchId);
    return _firstBatId == m.homeTeamId ? m.awayTeamId : m.homeTeamId;
  }

  String get _battingTeamId => inningsNo == 1 ? _firstBatId : _secondBatId;
  String get _bowlingTeamId => inningsNo == 1 ? _secondBatId : _firstBatId;
  bool get _isChasing => inningsNo == 2;

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
      // 1. Resume: if scoring already started, restore the live state from the
      //    backend so the scorer continues from the current score instead of 0/0.
      try {
        final card = await ScoringService.instance.scorecard(matchIdInt);
        final inns = (card['innings'] as List?) ?? const [];
        if (inns.isNotEmpty) {
          final cur = Map<String, dynamic>.from(inns.last as Map);
          _inningsId = (cur['id'] as num?)?.toInt();
          // Track first-innings total for target/result math.
          final first = Map<String, dynamic>.from(inns.first as Map);
          firstInningsRuns = (first['totalRuns'] as num?)?.toInt() ?? 0;
          if (mounted) _restoreFromScorecard(cur, card);
        }
      } catch (_) {/* no existing scorecard — fall through to create */}

      // 2. No innings yet — create the first one.
      if (_inningsId == null) {
        final bat = int.tryParse(_battingTeamId);
        final bowl = int.tryParse(_bowlingTeamId);
        if (bat == null || bowl == null) return;
        final res = await ScoringService.instance.startInnings(
          matchId: matchIdInt,
          battingTeamId: bat,
          bowlingTeamId: bowl,
          inningsNumber: inningsNo,
          target: _isChasing ? target : null,
        );
        _inningsId = (res['id'] as num?)?.toInt();
      }
    } catch (_) {
      // Offline — keep scoring locally; backend sync attempted again on next ball.
    } finally {
      _initializingInnings = false;
    }
  }

  /// Rebuild the in-memory scoring state from a backend scorecard so navigating
  /// back into the screen resumes rather than restarting the innings.
  void _restoreFromScorecard(
    Map<String, dynamic> inn,
    Map<String, dynamic> card,
  ) {
    int gi(Object? v) => (v is num) ? v.toInt() : (int.tryParse('$v') ?? 0);

    final inningsId = gi(inn['id']);
    final lb = gi(inn['legalBallsBowled']);

    // Current (not-out) batters from the batting card, busiest first.
    final batting = ((card['batting'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((b) => gi(b['inningsId']) == inningsId && b['isOut'] != true)
        .toList()
      ..sort((a, b) => gi(b['ballsFaced']).compareTo(gi(a['ballsFaced'])));

    // Rebuild the current over's pills, oldest-first (recentBalls is desc).
    // Filter by THIS innings so a fresh 2nd innings doesn't pick up the 1st
    // innings' balls that share the same over number.
    final curOver = (lb ~/ 6) + 1;
    final overBalls = ((card['recentBalls'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((b) {
          // If backend provides inningsId, restrict to this innings so a fresh
          // 2nd innings doesn't reuse the 1st innings' same-numbered over.
          final sameInnings =
              b['inningsId'] == null ? true : gi(b['inningsId']) == inningsId;
          return sameInnings && gi(b['overNumber']) == curOver;
        })
        .toList()
      ..sort((a, b) => gi(a['ballSequence']).compareTo(gi(b['ballSequence'])));
    final pills = overBalls.map(_pillFor).toList();

    setState(() {
      inningsNo = gi(inn['inningsNumber']) == 2 ? 2 : 1;
      totalRuns = gi(inn['totalRuns']);
      wickets = gi(inn['wickets']);
      legalBalls = lb;
      overNumber = curOver;
      ballInOver = lb % 6;
      target = gi(inn['target']);
      if (batting.isNotEmpty) {
        strikerId = '${batting[0]['playerId']}';
        strikerRuns = gi(batting[0]['runs']);
        strikerBalls = gi(batting[0]['ballsFaced']);
      }
      if (batting.length > 1) {
        nonStrikerId = '${batting[1]['playerId']}';
        nonStrikerRuns = gi(batting[1]['runs']);
        nonStrikerBalls = gi(batting[1]['ballsFaced']);
      }
      recentBalls
        ..clear()
        ..addAll(pills.isEmpty ? ['-', '-', '-', '-', '-', '-'] : pills);
    });
  }

  String _pillFor(Map<String, dynamic> b) {
    int gi(Object? v) => (v is num) ? v.toInt() : (int.tryParse('$v') ?? 0);
    if (b['isWicket'] == true) return 'W';
    final extras = b['extrasType'] as String?;
    if (extras == 'Wide') return 'Wd';
    if (extras == 'NoBall') return 'Nb';
    if (extras == 'Bye') return 'B${gi(b['runsExtras'])}';
    if (extras == 'LegBye') return 'Lb${gi(b['runsExtras'])}';
    final r = gi(b['runsBatter']);
    return r == 0 ? '·' : '$r';
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

  /// Manual change of strike (e.g. batsmen crossed, or correction).
  void _rotateStrike() {
    HapticFeedback.selectionClick();
    setState(_swap);
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
    bool overEnded = false;
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
        overEnded = true;
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
    // Check innings/match end AFTER state update so values are current.
    final m = MockData.matchById(widget.matchId);
    if (_isChasing && target > 0 && totalRuns >= target) {
      _finishMatch();
    } else if (overEnded && overNumber > m.oversPerInnings) {
      _handleInningsEnd('OversComplete');
    } else if (overEnded) {
      _showOverEndSheet();
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
      bool overEnded = false;
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
          overEnded = true;
        }
      });
      _pushBall(runsBatter: 0, isWicket: true, wicketType: r.label.replaceAll(' ', ''));
      final m = MockData.matchById(widget.matchId);
      if (_isChasing && target > 0 && totalRuns >= target) {
        _finishMatch();
      } else if (wickets >= 10) {
        _handleInningsEnd('AllOut');
      } else if (overEnded && overNumber > m.oversPerInnings) {
        _handleInningsEnd('OversComplete');
      } else if (overEnded) {
        _showOverEndSheet();
      } else {
        _promptNextBatter();
      }
    }
  }

  /// 1st innings -> innings break + start 2nd; 2nd innings -> finish match.
  void _handleInningsEnd(String reason) {
    if (inningsNo == 1) {
      _showInningsBreakSheet(reason);
    } else {
      _finishMatch();
    }
  }

  void _showInningsBreakSheet(String reason) {
    final battingTeam = MockData.teamById(_battingTeamId);
    final chasingTeam = MockData.teamById(_secondBatId);
    final newTarget = totalRuns + 1;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      builder: (ctx) => Container(
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
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
              const SizedBox(height: 12),
              Text('Innings Break', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 6),
              Text(
                  '${battingTeam.name} scored $totalRuns/$wickets in ${legalBalls ~/ 6}.${legalBalls % 6} overs',
                  style: AppTextStyles.bodyLarge),
              const SizedBox(height: 8),
              Text('${chasingTeam.name} need $newTarget to win',
                  style: AppTextStyles.italicAccent(
                      size: 14, color: AppColors.ballRed)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startSecondInnings(reason, newTarget);
                  },
                  child: const Text('START 2ND INNINGS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startSecondInnings(String reason, int newTarget) async {
    final matchIdInt = int.tryParse(widget.matchId);
    // Close innings 1 on the backend.
    if (matchIdInt != null && _inningsId != null) {
      try {
        await ScoringService.instance
            .closeInnings(matchIdInt, _inningsId!, reason);
      } catch (_) {}
    }
    // Reset local state for the chase.
    setState(() {
      firstInningsRuns = totalRuns;
      target = newTarget;
      inningsNo = 2;
      totalRuns = 0;
      wickets = 0;
      legalBalls = 0;
      overNumber = 1;
      ballInOver = 0;
      strikerId = '';
      nonStrikerId = '';
      bowlerId = '';
      strikerRuns = strikerBalls = nonStrikerRuns = nonStrikerBalls = 0;
      bowlerRuns = bowlerWickets = bowlerLegalBalls = 0;
      isFreeHit = false;
      _inningsId = null;
      _setupPrompted = false; // prompt openers/bowler again for the chase
      _history.clear();
      recentBalls
        ..clear()
        ..addAll(['-', '-', '-', '-', '-', '-']);
    });
    // Create innings 2 (with target) on the backend — directly, NOT via
    // _ensureInnings (which would re-restore the just-closed first innings).
    if (matchIdInt != null) {
      final bat = int.tryParse(_battingTeamId);
      final bowl = int.tryParse(_bowlingTeamId);
      if (bat != null && bowl != null) {
        try {
          final res = await ScoringService.instance.startInnings(
            matchId: matchIdInt,
            battingTeamId: bat,
            bowlingTeamId: bowl,
            inningsNumber: 2,
            target: newTarget,
          );
          _inningsId = (res['id'] as num?)?.toInt();
        } catch (_) {}
      }
    }
  }

  Future<void> _finishMatch() async {
    if (_ending) return;
    _ending = true;
    String? winnerId;
    String margin;
    if (target > 0 && totalRuns >= target) {
      winnerId = _secondBatId;
      final w = 10 - wickets;
      margin = 'won by $w wicket${w == 1 ? '' : 's'}';
    } else if (target > 0 && totalRuns == target - 1) {
      winnerId = null; // tie
      margin = 'Match tied';
    } else if (target > 0) {
      winnerId = _firstBatId;
      final r = (target - 1) - totalRuns;
      margin = 'won by $r run${r == 1 ? '' : 's'}';
    } else {
      // No target context (manual/abandoned) — leave to manual sheet.
      _ending = false;
      _showMatchEndSheet();
      return;
    }
    // Close the 2nd innings, then show result + Man of the Match picker.
    final matchIdInt = int.tryParse(widget.matchId);
    if (matchIdInt != null && _inningsId != null) {
      try {
        await ScoringService.instance
            .closeInnings(matchIdInt, _inningsId!, 'TargetReached');
      } catch (_) {}
    }
    if (mounted) _showResultSheet(winnerId, margin);
  }

  /// Result + Man of the Match. The scorer picks MoM, then we end the match.
  void _showResultSheet(String? winnerId, String margin) {
    final winnerName =
        winnerId == null ? null : MockData.teamById(winnerId).name;
    final squad = <Player>[
      ...MockData.playersByTeam(_firstBatId),
      ...MockData.playersByTeam(_secondBatId),
    ];
    String? momId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: AppColors.goldDeep, size: 48),
                const SizedBox(height: 12),
                Text('Match Complete', style: AppTextStyles.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  winnerName == null ? margin : '$winnerName $margin',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.fraunces(
                      size: 16, weight: FontWeight.w700, color: AppColors.navy),
                ),
                if (squad.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text('MAN OF THE MATCH', style: AppTextStyles.caption),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _pickPlayer(
                        'Man of the Match', squad, (id) => setModal(() => momId = id)),
                    icon: const Icon(Icons.star_rounded, size: 18),
                    label: Text(momId == null
                        ? 'Select player'
                        : MockData.playerById(momId!).fullName),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final matchIdInt = int.tryParse(widget.matchId);
                      if (matchIdInt != null) {
                        try {
                          await ScoringService.instance.endMatch(
                            matchId: matchIdInt,
                            winnerTeamId: winnerId == null
                                ? null
                                : int.tryParse(winnerId),
                            resultMargin: margin,
                            manOfTheMatchPlayerId:
                                momId == null ? null : int.tryParse(momId!),
                          );
                        } catch (_) {}
                      }
                      // Refresh local cache then return to home.
                      await BackendSync.instance.refreshAll();
                      if (mounted) context.go('/home');
                    },
                    child: const Text('CONFIRM RESULT'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// At the start of an innings, let the scorer pick the two openers and the
  /// opening bowler so per-player stats record against the right players.
  void _promptInningsSetup() {
    final bat = MockData.playersByTeam(_battingTeamId);
    final bowl = MockData.playersByTeam(_bowlingTeamId);
    if (bat.length < 2 || bowl.isEmpty) return; // no roster — keep auto/Unknown
    _pickPlayer('Opening striker', bat, (s) {
      setState(() {
        strikerId = s;
        strikerRuns = 0;
        strikerBalls = 0;
      });
      final rest = bat.where((p) => p.id != s).toList();
      _pickPlayer('Non-striker', rest, (ns) {
        setState(() {
          nonStrikerId = ns;
          nonStrikerRuns = 0;
          nonStrikerBalls = 0;
        });
        _pickPlayer('Opening bowler', bowl, (b) {
          setState(() {
            bowlerId = b;
            bowlerRuns = 0;
            bowlerWickets = 0;
            bowlerLegalBalls = 0;
          });
        });
      });
    });
  }

  /// After a wicket (not all-out / over-end), let the scorer pick the new batter.
  void _promptNextBatter() {
    final players = MockData.playersByTeam(_battingTeamId)
        .where((p) => p.id != nonStrikerId)
        .toList();
    if (players.isEmpty) return; // no roster — keep "Unknown" placeholder
    _pickPlayer('Select new batter', players, (id) {
      setState(() {
        strikerId = id;
        strikerRuns = 0;
        strikerBalls = 0;
      });
    });
  }

  void _showMatchEndSheet({String reason = ''}) {
    final m = MockData.matchById(widget.matchId);
    final home = MockData.teamById(m.homeTeamId);
    final away = MockData.teamById(m.awayTeamId);
    String? selectedWinnerId;
    final marginCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
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
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('End Match', style: AppTextStyles.headlineLarge),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(reason, style: AppTextStyles.italicAccent(size: 13, color: AppColors.grey)),
                ],
                const SizedBox(height: 16),
                Text('Final Score: $totalRuns/$wickets in ${legalBalls ~/ 6}.${legalBalls % 6} overs',
                    style: AppTextStyles.bodyLarge),
                const SizedBox(height: 14),
                Text('SELECT WINNER', style: AppTextStyles.caption),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _winnerBtn(home, selectedWinnerId == home.id, () =>
                        setModalState(() => selectedWinnerId = home.id)),
                    const SizedBox(width: 8),
                    _winnerBtn(away, selectedWinnerId == away.id, () =>
                        setModalState(() => selectedWinnerId = away.id)),
                    const SizedBox(width: 8),
                    _winnerBtn(null, selectedWinnerId == 'tie', () =>
                        setModalState(() => selectedWinnerId = 'tie')),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: marginCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Result margin (e.g. "5 wickets" or "12 runs")',
                  ),
                  style: AppTextStyles.fraunces(size: 13, weight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('KEEP SCORING'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selectedWinnerId == null
                            ? null
                            : () async {
                          Navigator.pop(ctx);
                          final matchIdInt = int.tryParse(widget.matchId);
                          if (matchIdInt != null) {
                            final winnerId = selectedWinnerId == 'tie'
                                ? null
                                : int.tryParse(selectedWinnerId ?? '');
                            await ScoringService.instance.endMatch(
                              matchId: matchIdInt,
                              winnerTeamId: winnerId,
                              resultMargin: marginCtrl.text.trim().isEmpty
                                  ? null
                                  : marginCtrl.text.trim(),
                            );
                          }
                          await BackendSync.instance.refreshAll();
                          if (mounted) context.go('/home');
                        },
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
  }

  Widget _winnerBtn(dynamic team, bool selected, VoidCallback onTap) {
    final label = team == null ? 'TIE' : (team.shortCode as String);
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

  /// Generic player picker bottom sheet.
  void _pickPlayer(String title, List<Player> players, void Function(String) onPick) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6),
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
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
              const SizedBox(height: 12),
              Text(title, style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: players.length,
                  itemBuilder: (_, i) {
                    final p = players[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.navy,
                        child: Text(p.initials,
                            style: AppTextStyles.bebas(
                                size: 11, color: Colors.white)),
                      ),
                      title: Text(p.fullName,
                          style: AppTextStyles.fraunces(
                              size: 13, weight: FontWeight.w700)),
                      subtitle: Text(p.role.label,
                          style: AppTextStyles.mono(size: 9)),
                      onTap: () {
                        Navigator.pop(ctx);
                        onPick(p.id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectStriker() {
    final players = MockData.playersByTeam(_battingTeamId)
        .where((p) => p.id != nonStrikerId)
        .toList();
    if (players.isEmpty) return;
    _pickPlayer('Select striker', players, (id) {
      setState(() {
        strikerId = id;
        strikerRuns = 0;
        strikerBalls = 0;
      });
    });
  }

  void _selectNonStriker() {
    final players = MockData.playersByTeam(_battingTeamId)
        .where((p) => p.id != strikerId)
        .toList();
    if (players.isEmpty) return;
    _pickPlayer('Select non-striker', players, (id) {
      setState(() {
        nonStrikerId = id;
        nonStrikerRuns = 0;
        nonStrikerBalls = 0;
      });
    });
  }

  void _selectBowler() {
    final players = MockData.playersByTeam(_bowlingTeamId).toList();
    if (players.isEmpty) return;
    _pickPlayer('Select bowler', players, (id) {
      setState(() {
        bowlerId = id;
        bowlerRuns = 0;
        bowlerWickets = 0;
        bowlerLegalBalls = 0;
      });
    });
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
                      onPressed: () {
                        Navigator.pop(context);
                        _selectBowler();
                      },
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
    final batting = MockData.teamById(_battingTeamId);
    final battingPlayers = MockData.playersByTeam(_battingTeamId);
    final bowlingPlayers = MockData.playersByTeam(_bowlingTeamId);
    if (strikerId.isEmpty && battingPlayers.isNotEmpty) {
      strikerId = battingPlayers.first.id;
    }
    if (nonStrikerId.isEmpty && battingPlayers.length > 1) {
      nonStrikerId = battingPlayers[1].id;
    }
    if (bowlerId.isEmpty && bowlingPlayers.isNotEmpty) {
      bowlerId = bowlingPlayers.first.id;
    }
    // At the very start of an innings, prompt for openers + opening bowler once.
    if (!_setupPrompted &&
        !_initializingInnings &&
        legalBalls == 0 &&
        battingPlayers.length >= 2 &&
        bowlingPlayers.isNotEmpty) {
      _setupPrompted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _promptInningsSetup();
      });
    }
    final overs = '${legalBalls ~/ 6}.${legalBalls % 6}';
    final maxOvers = '${m.oversPerInnings}.0';
    final crr = legalBalls == 0 ? 0.0 : (totalRuns / legalBalls) * 6;
    final ballsRemaining = (m.oversPerInnings * 6) - legalBalls;
    final rrr = (!_isChasing || ballsRemaining <= 0)
        ? 0.0
        : ((target - totalRuns) / ballsRemaining) * 6;
    final projected = legalBalls == 0
        ? 0
        : ((totalRuns / legalBalls) * (m.oversPerInnings * 6)).round();

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
                            Text('${inningsNo == 1 ? '1st' : '2nd'} INNINGS',
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
                        if (_isChasing) ...[
                          _hk('RRR', rrr.toStringAsFixed(2), gold: true),
                          _hk('TARGET', '$target'),
                          _hk('BALLS LEFT', '$ballsRemaining'),
                        ] else ...[
                          _hk('PROJECTED', '$projected'),
                          _hk('OVERS', '$overs/${m.oversPerInnings}'),
                        ],
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
                  InkWell(
                    onTap: _selectStriker,
                    child: _batterRow(strikerId, strikerRuns, strikerBalls,
                        isStriker: true),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _selectNonStriker,
                    child: _batterRow(
                        nonStrikerId, nonStrikerRuns, nonStrikerBalls),
                  ),
                ],
              ),
            ),

            // Bowler
            InkWell(
              onTap: _selectBowler,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppColors.creamSoft,
                  border: Border(bottom: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  children: [
                    TeamBadge(team: MockData.teamById(_bowlingTeamId), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(MockData.playerById(bowlerId).fullName,
                              style: AppTextStyles.dm(
                                  size: 12, weight: FontWeight.w600)),
                          Text('BOWLING · TAP TO CHANGE',
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
                      _padExtra('SWAP', false, _rotateStrike),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Tip: tap WIDE/NB/BYE/LB then a run button (e.g. WIDE → 4 = wide + 4 runs). Plain wide/NB = tap it then 0.',
                      style: AppTextStyles.mono(
                          size: 8, color: AppColors.grey, letterSpacing: 0.1),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _history.isEmpty ? null : _undo,
                          icon: const Icon(Icons.undo_rounded, size: 16),
                          label: const Text('UNDO'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navyDeep,
                            side: const BorderSide(color: AppColors.navyDeep),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showMatchEndSheet(),
                          icon: const Icon(Icons.stop_circle_outlined, size: 16),
                          label: const Text('END MATCH'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.ballRed,
                            side: const BorderSide(color: AppColors.ballRed),
                          ),
                        ),
                      ),
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
