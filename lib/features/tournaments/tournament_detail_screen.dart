import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/match_card.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/api_client.dart';
import '../../data/mock_data.dart';
import '../../models/enums.dart';
import '../../models/player.dart';
import '../../models/tournament.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;
  final int initialTab;

  const TournamentDetailScreen({
    super.key,
    required this.tournamentId,
    this.initialTab = 0,
  });

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen>
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
    final tournament = MockData.tournamentOrNull(widget.tournamentId);
    if (tournament == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [
            const BackBar(title: 'Tournament', italic: 'Missing'),
            Expanded(
              child: Center(
                child: Text('This tournament no longer exists.',
                    style: AppTextStyles.bodyLarge),
              ),
            ),
          ],
        ),
      );
    }

    final fixtures = MockData.matchesForTournament(tournament.id)
      ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
    final players = MockData.players
        .where((player) =>
            player.teamId != null && tournament.teamIds.contains(player.teamId))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(tournament: tournament),
            _Summary(tournament: tournament, fixtures: fixtures),
            Container(
              color: AppColors.creamSoft,
              child: TabBar(
                controller: _tab,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: 'OVERVIEW'),
                  Tab(text: 'TABLE'),
                  Tab(text: 'FIXTURES'),
                  Tab(text: 'TOP STATS'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _Overview(tournament: tournament, players: players),
                  _BackendTable(tournamentId: tournament.id),
                  _Fixtures(matches: fixtures, tournamentId: tournament.id),
                  _TopStats(tournamentId: tournament.id, players: players),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Tournament tournament;

  const _Header({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.navyDeep, Color(0xFF020A1F)],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Text('BACK',
                      style: AppTextStyles.mono(
                          size: 9, color: AppColors.gold, letterSpacing: 0.25, weight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tournament.format.label.toUpperCase(),
                    style: AppTextStyles.mono(
                        size: 9, color: AppColors.gold, letterSpacing: 0.3),
                  ),
                ),
                if (ApiClient.instance.canManageTournaments)
                  IconButton(
                    onPressed: () =>
                        context.push('/tournament/${tournament.id}/edit'),
                    icon:
                        const Icon(Icons.edit_outlined, color: AppColors.cream),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tournament.name,
                  style: AppTextStyles.fraunces(
                      size: 24,
                      weight: FontWeight.w900,
                      color: AppColors.cream),
                ),
                Text(
                  '${tournament.edition} - ${tournament.category.label}',
                  style: AppTextStyles.italicAccent(
                      size: 16, color: AppColors.gold),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${DateFormat('MMM d').format(tournament.startDate).toUpperCase()} - ${DateFormat('MMM d').format(tournament.endDate).toUpperCase()}',
                  style: AppTextStyles.mono(
                    size: 9,
                    color: AppColors.cream.withValues(alpha: 0.8),
                    letterSpacing: 0.15,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(14)),
                  child: Text(
                    tournament.stage.label.toUpperCase(),
                    style: AppTextStyles.mono(
                        size: 8,
                        color: AppColors.navyDeep,
                        letterSpacing: 0.2,
                        weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final Tournament tournament;
  final List fixtures;

  const _Summary({required this.tournament, required this.fixtures});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _stat('${tournament.teamIds.length}', 'TEAMS'),
          _stat('${fixtures.length}', 'MATCHES'),
          _stat('${tournament.totalRuns}', 'RUNS'),
          _stat('${tournament.totalWickets}', 'WICKETS', last: true),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, {bool last = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          border: Border(
            right: last
                ? BorderSide.none
                : const BorderSide(color: AppColors.line),
            bottom: const BorderSide(color: AppColors.line),
          ),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTextStyles.fraunces(
                    size: 18,
                    weight: FontWeight.w900,
                    color: AppColors.ballRed)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  final Tournament tournament;
  final List<Player> players;

  const _Overview({required this.tournament, required this.players});

  @override
  Widget build(BuildContext context) {
    final teams = tournament.teamIds
        .map(MockData.teamOrNull)
        .whereType<dynamic>()
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tournament Setup', style: AppTextStyles.titleLarge),
              const SizedBox(height: 10),
              _kv('Format', tournament.format.label),
              _kv('Match type',
                  '${tournament.matchFormat.label} - ${tournament.oversPerInnings} overs'),
              _kv('Stage', tournament.stage.label),
              _kv('Sponsor', tournament.sponsorTitle ?? 'Not set'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Teams', style: AppTextStyles.titleLarge),
        const SizedBox(height: 8),
        if (teams.isEmpty)
          _empty('No teams are attached to this tournament.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final team in teams)
                InkWell(
                  onTap: () => context.push('/team/${team.id}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line)),
                    child: TeamBadge(team: team, size: 30, showName: true),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
              width: 92,
              child: Text(label.toUpperCase(), style: AppTextStyles.caption)),
          Expanded(
              child: Text(value,
                  style: AppTextStyles.fraunces(
                      size: 13, weight: FontWeight.w600))),
        ],
      ),
    );
  }
}

/// Live standings + NRR fetched from backend.
class _BackendTable extends StatefulWidget {
  final String tournamentId;
  const _BackendTable({required this.tournamentId});
  @override
  State<_BackendTable> createState() => _BackendTableState();
}

class _BackendTableState extends State<_BackendTable> {
  bool _loading = false;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final id = int.tryParse(widget.tournamentId);
    if (id == null) return;
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.get('/api/tournaments/$id/standings');
      _rows = List<Map<String, dynamic>>.from(res as List);
    } catch (_) {/* keep last */}
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_rows.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.table_chart_outlined,
        title: 'No table yet',
        message: 'Add teams to the tournament and play matches to populate standings.',
      );
    }
    // Group by pool when the tournament uses pools (GroupName present).
    final pooled = _rows.any((r) => (r['groupName'] as String?)?.isNotEmpty == true);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        children: [
          if (!pooled)
            _card(child: Column(children: [
              _header(),
              for (var i = 0; i < _rows.length; i++) _dataRow(i, _rows[i]),
            ]))
          else
            ..._poolCards(),
          const SizedBox(height: 8),
          Text(
            'P=Played, W/L/T/NR=Wins/Losses/Ties/No-Result, PTS=Points, NRR=Net Run Rate',
            style: AppTextStyles.italicAccent(size: 10, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  List<Widget> _poolCards() {
    final pools = <String, List<Map<String, dynamic>>>{};
    for (final r in _rows) {
      final g = (r['groupName'] as String?)?.isNotEmpty == true
          ? r['groupName'] as String
          : 'Unassigned';
      pools.putIfAbsent(g, () => []).add(r);
    }
    final keys = pools.keys.toList()..sort();
    return [
      for (final pool in keys) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
          child: Text(pool.toUpperCase(),
              style: AppTextStyles.mono(
                  size: 10,
                  color: AppColors.navyDeep,
                  letterSpacing: 0.3,
                  weight: FontWeight.w700)),
        ),
        _card(child: Column(children: [
          _header(),
          for (var i = 0; i < pools[pool]!.length; i++)
            _dataRow(i, pools[pool]![i]),
        ])),
      ],
    ];
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.navyDeep.withValues(alpha: 0.06),
        border: const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          SizedBox(width: 22, child: Text('#', style: AppTextStyles.caption)),
          Expanded(child: Text('TEAM', style: AppTextStyles.caption)),
          _hCell('P'), _hCell('W'), _hCell('L'), _hCell('T'), _hCell('NR'),
          _hCell('PTS'), _hCell('NRR', width: 50),
        ],
      ),
    );
  }

  Widget _hCell(String s, {double width = 24}) =>
      SizedBox(width: width, child: Text(s, textAlign: TextAlign.center, style: AppTextStyles.caption));

  Widget _dataRow(int i, Map<String, dynamic> r) {
    final team = r['team'] is Map ? Map<String, dynamic>.from(r['team'] as Map) : null;
    final teamName = (team?['name'] as String?) ?? 'Team ${r['teamId']}';
    final form = (r['last5Form'] as List?)?.cast<String>() ?? const [];
    final nrr = r['netRunRate'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(width: 22, child: Text('${i + 1}',
                  style: AppTextStyles.fraunces(size: 13, weight: FontWeight.w800,
                      color: i == 0 ? AppColors.goldDeep : AppColors.navyDeep))),
              Expanded(
                child: Text(teamName,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.dm(size: 12, weight: FontWeight.w700)),
              ),
              _vCell('${r['matchesPlayed']}'),
              _vCell('${r['wins']}'),
              _vCell('${r['losses']}'),
              _vCell('${r['ties']}'),
              _vCell('${r['noResults']}'),
              _vCell('${r['points']}', bold: true),
              SizedBox(width: 50, child: Text(
                nrr == null ? '-' : (nrr as num).toStringAsFixed(3),
                textAlign: TextAlign.center,
                style: AppTextStyles.mono(size: 10, color: AppColors.ink),
              )),
            ],
          ),
          if (form.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 22),
              child: Row(
                children: [
                  Text('FORM', style: AppTextStyles.mono(size: 8, color: AppColors.grey, letterSpacing: 0.2)),
                  const SizedBox(width: 6),
                  for (final f in form) ...[
                    Container(
                      width: 16, height: 16,
                      margin: const EdgeInsets.only(right: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: switch (f) {
                          'W' => AppColors.amasGreen,
                          'L' => AppColors.ballRed,
                          _ => AppColors.grey,
                        }.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(f,
                          style: AppTextStyles.mono(size: 8, color: Colors.white, weight: FontWeight.w800)),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _vCell(String s, {bool bold = false, double width = 24}) =>
      SizedBox(width: width, child: Text(
        s, textAlign: TextAlign.center,
        style: bold
            ? AppTextStyles.fraunces(size: 12, weight: FontWeight.w900, color: AppColors.navyDeep)
            : AppTextStyles.mono(size: 10, color: AppColors.ink),
      ));
}

class _Fixtures extends StatefulWidget {
  final List matches;
  final String tournamentId;
  const _Fixtures({required this.matches, required this.tournamentId});

  @override
  State<_Fixtures> createState() => _FixturesState();
}

class _FixturesState extends State<_Fixtures> {
  bool _generating = false;

  Future<void> _createKnockout() async {
    final id = int.tryParse(widget.tournamentId);
    if (id == null) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _KnockoutSheet(tournamentId: id),
    );
  }

  Future<void> _generate() async {
    final id = int.tryParse(widget.tournamentId);
    if (id == null) return;
    final clearExisting = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate Fixtures'),
        content: const Text(
            'This will create fixtures based on the tournament format (round-robin / knockout / hybrid). '
            'Clear existing scheduled matches first?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('KEEP EXISTING')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('CLEAR & REGEN')),
        ],
      ),
    );
    if (clearExisting == null) return;
    setState(() => _generating = true);
    try {
      final res = await ApiClient.instance.post('/api/tournaments/$id/generate-fixtures', {
        'clearExisting': clearExisting,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${res['created']} fixtures created'),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGenerate = ApiClient.instance.isSuperAdmin || ApiClient.instance.isScorer;
    return Column(
      children: [
        if (canGenerate)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _generating ? null : _generate,
                    icon: _generating
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(_generating ? 'GENERATING...' : 'AUTO-GENERATE'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _createKnockout,
                    icon: const Icon(Icons.emoji_events_outlined, size: 16),
                    label: const Text('KNOCKOUT'),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: widget.matches.isEmpty
              ? const _EmptyPanel(
                  icon: Icons.sports_cricket_outlined,
                  title: 'No fixtures yet',
                  message: 'Tap "Auto-generate" above to create round-robin / knockout fixtures based on tournament format.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
                  itemCount: widget.matches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => MatchCard(match: widget.matches[i]),
                ),
        ),
      ],
    );
  }
}

/// Build a single knockout fixture by choosing two teams from the pool
/// qualifiers (top-N per pool). Used for Quarter-Finals / Semis / Final.
class _KnockoutSheet extends StatefulWidget {
  final int tournamentId;
  const _KnockoutSheet({required this.tournamentId});

  @override
  State<_KnockoutSheet> createState() => _KnockoutSheetState();
}

class _KnockoutSheetState extends State<_KnockoutSheet> {
  final _stage = TextEditingController(text: 'Quarter-Final 1');
  final _perPool = TextEditingController(text: '2');
  List<Map<String, dynamic>> _qualifiers = [];
  String? _homeId;
  String? _awayId;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _stage.dispose();
    _perPool.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final n = int.tryParse(_perPool.text.trim()) ?? 2;
      final res = await ApiClient.instance.get(
          '/api/tournaments/${widget.tournamentId}/qualifiers',
          query: {'perPool': n});
      _qualifiers = List<Map<String, dynamic>>.from(
          (res as List).map((e) => Map<String, dynamic>.from(e as Map)));
    } catch (_) {
      _qualifiers = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _labelFor(Map<String, dynamic> q) {
    final team = q['team'] is Map ? Map<String, dynamic>.from(q['team'] as Map) : null;
    final name = (team?['name'] as String?) ?? 'Team ${q['teamId']}';
    return '${q['seedLabel'] ?? q['pool']} · $name';
  }

  Future<void> _create() async {
    if (_homeId == null || _awayId == null || _homeId == _awayId) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pick two different teams.')));
      return;
    }
    setState(() => _saving = true);
    final t = MockData.tournamentOrNull('${widget.tournamentId}');
    try {
      await ApiClient.instance.post('/api/matches', {
        'tournamentId': widget.tournamentId,
        'matchName': _stage.text.trim().isEmpty ? 'Knockout' : _stage.text.trim(),
        'homeTeamId': int.tryParse(_homeId!),
        'awayTeamId': int.tryParse(_awayId!),
        'scheduledStart': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'matchFormat': t?.matchFormat.label ?? 'T20',
        'oversPerInnings': t?.oversPerInnings ?? 20,
        'stageLabel': _stage.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${_stage.text.trim()} created. Reopen tournament to see it.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create Knockout Fixture', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 4),
          Text('Pick any two teams from the pool qualifiers.',
              style: AppTextStyles.italicAccent(size: 12, color: AppColors.grey)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _stage,
                  decoration: const InputDecoration(labelText: 'STAGE LABEL'),
                  style: AppTextStyles.fraunces(size: 13, weight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _perPool,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _load(),
                  decoration: const InputDecoration(labelText: 'QUALIFY/POOL'),
                  style: AppTextStyles.fraunces(size: 13, weight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_qualifiers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No qualifiers yet. Finish enough pool matches so standings can rank teams.',
                style: AppTextStyles.italicAccent(size: 13, color: AppColors.grey),
              ),
            )
          else ...[
            _teamDrop('HOME', _homeId, (v) => setState(() => _homeId = v)),
            const SizedBox(height: 10),
            _teamDrop('AWAY', _awayId, (v) => setState(() => _awayId = v)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _create,
                icon: _saving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_rounded, size: 16),
                label: Text(_saving ? 'CREATING...' : 'CREATE FIXTURE'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _teamDrop(String label, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: _qualifiers.map((q) {
        final id = '${q['teamId']}';
        return DropdownMenuItem<String>(
          value: id,
          child: Text(_labelFor(q),
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.fraunces(size: 13, weight: FontWeight.w600)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _TopStats extends StatefulWidget {
  final String tournamentId;
  final List<Player> players;
  const _TopStats({required this.tournamentId, required this.players});

  @override
  State<_TopStats> createState() => _TopStatsState();
}

class _TopStatsState extends State<_TopStats> {
  Map<String, dynamic>? _data;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = int.tryParse(widget.tournamentId);
    if (id == null) return;
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.get('/api/tournaments/$id/leaders', query: {'top': 10});
      _data = Map<String, dynamic>.from(res as Map);
    } catch (_) {/* keep null */}
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final d = _data;
    if (d == null) {
      return const _EmptyPanel(
        icon: Icons.bar_chart_rounded,
        title: 'No stats yet',
        message: 'Play matches in this tournament to populate leaders.',
      );
    }
    final totals = d['totals'] is Map ? Map<String, dynamic>.from(d['totals'] as Map) : <String, dynamic>{};
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
        children: [
          _totalsBar(totals),
          const SizedBox(height: 14),
          if ((d['runScorers'] as List).isNotEmpty) ...[
            Text('Most Runs', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            _leaderRows(d['runScorers'] as List, (m) => '${m['runs']}', 'RUNS',
                trailingExtra: (m) => 'HS ${m['highestScore']} · ${m['innings']} inns'),
            const SizedBox(height: 18),
          ],
          if ((d['wicketTakers'] as List).isNotEmpty) ...[
            Text('Most Wickets', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            _leaderRows(d['wicketTakers'] as List, (m) => '${m['wickets']}', 'WKTS',
                trailingExtra: (m) => 'Econ ${(m['economy'] as num).toStringAsFixed(2)}'),
            const SizedBox(height: 18),
          ],
          if ((d['sixHitters'] as List).isNotEmpty) ...[
            Text('Most Sixes', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            _leaderRows(d['sixHitters'] as List, (m) => '${m['sixes']}', 'SIXES'),
            const SizedBox(height: 18),
          ],
          if ((d['fourHitters'] as List).isNotEmpty) ...[
            Text('Most Fours', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            _leaderRows(d['fourHitters'] as List, (m) => '${m['fours']}', 'FOURS'),
            const SizedBox(height: 18),
          ],
          if ((d['bestInnings'] as List).isNotEmpty) ...[
            Text('Best Individual Score', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            _innFigures(d['bestInnings'] as List, isBowling: false),
            const SizedBox(height: 18),
          ],
          if ((d['bestBowling'] as List).isNotEmpty) ...[
            Text('Best Bowling', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            _innFigures(d['bestBowling'] as List, isBowling: true),
          ],
        ],
      ),
    );
  }

  Widget _totalsBar(Map<String, dynamic> totals) {
    Widget cell(String n, String l) => Expanded(
          child: Column(
            children: [
              Text(n, style: AppTextStyles.fraunces(size: 18, weight: FontWeight.w900, color: AppColors.navyDeep)),
              const SizedBox(height: 2),
              Text(l, style: AppTextStyles.mono(size: 8, color: AppColors.grey, letterSpacing: 0.18)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(children: [
        cell('${totals['matches'] ?? 0}', 'MATCHES'),
        cell('${totals['runs'] ?? 0}', 'RUNS'),
        cell('${totals['wickets'] ?? 0}', 'WICKETS'),
        cell('${totals['sixes'] ?? 0}', 'SIXES'),
        cell('${totals['fours'] ?? 0}', 'FOURS'),
      ]),
    );
  }

  Widget _leaderRows(
    List rows,
    String Function(Map<String, dynamic>) value,
    String label, {
    String Function(Map<String, dynamic>)? trailingExtra,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            _leaderRow(i, Map<String, dynamic>.from(rows[i] as Map), value, label, trailingExtra),
        ],
      ),
    );
  }

  Widget _leaderRow(int i, Map<String, dynamic> r, String Function(Map<String, dynamic>) value, String label,
      String Function(Map<String, dynamic>)? trailingExtra) {
    final p = r['player'] is Map ? Map<String, dynamic>.from(r['player'] as Map) : null;
    final fullName = (p?['fullName'] as String?) ?? 'Player ${r['playerId']}';
    return InkWell(
      onTap: () {
        final pid = p?['id'];
        if (pid != null) context.push('/player/$pid');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            SizedBox(width: 20, child: Text('${i + 1}', style: AppTextStyles.fraunces(size: 14, weight: FontWeight.w900))),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullName, style: AppTextStyles.fraunces(size: 13, weight: FontWeight.w700)),
                  if (p?['role'] != null)
                    Text((p!['role'] as String).toUpperCase(),
                        style: AppTextStyles.mono(size: 8, color: AppColors.grey, letterSpacing: 0.18)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value(r), style: AppTextStyles.fraunces(size: 16, weight: FontWeight.w900, color: AppColors.navyDeep)),
                Text(label, style: AppTextStyles.mono(size: 8, color: AppColors.grey, letterSpacing: 0.18)),
                if (trailingExtra != null)
                  Text(trailingExtra(r), style: AppTextStyles.italicAccent(size: 10, color: AppColors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _innFigures(List rows, {required bool isBowling}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: rows.map<Widget>((raw) {
          final r = Map<String, dynamic>.from(raw as Map);
          final p = r['player'] is Map ? Map<String, dynamic>.from(r['player'] as Map) : null;
          final name = (p?['fullName'] as String?) ?? '—';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Expanded(child: Text(name, style: AppTextStyles.fraunces(size: 13, weight: FontWeight.w700))),
                if (isBowling) ...[
                  Text(r['figures'] as String,
                      style: AppTextStyles.fraunces(size: 14, weight: FontWeight.w900, color: AppColors.navyDeep)),
                  const SizedBox(width: 6),
                  Text('(${r['overs']})', style: AppTextStyles.mono(size: 9, color: AppColors.grey)),
                ] else ...[
                  Text('${r['runs']}',
                      style: AppTextStyles.fraunces(size: 14, weight: FontWeight.w900, color: AppColors.navyDeep)),
                  const SizedBox(width: 6),
                  Text('(${r['ballsFaced']}b)', style: AppTextStyles.mono(size: 9, color: AppColors.grey)),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyPanel(
      {required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 54, color: AppColors.grey),
              const SizedBox(height: 10),
              Text(title,
                  style: AppTextStyles.fraunces(
                      size: 16, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.italicAccent(
                      size: 13, color: AppColors.grey)),
            ],
          ),
        ),
      );
}

Widget _card({required Widget child}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );

Widget _empty(String text) => _card(
      child: Text(text,
          style: AppTextStyles.italicAccent(size: 13, color: AppColors.grey)),
    );
