import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/api_client.dart';
import '../../data/backend_sync.dart';
import '../../data/mock_data.dart';
import '../../models/enums.dart';
import '../../models/match.dart';
import '../../models/team.dart';

class MatchSetupScreen extends StatefulWidget {
  const MatchSetupScreen({super.key});

  @override
  State<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends State<MatchSetupScreen> {
  final _name = TextEditingController();
  final _venue = TextEditingController();
  final _stage = TextEditingController();
  final _overs = TextEditingController(text: '20');
  final _ballsPerOver = TextEditingController(text: '6');
  final _homePenalty = TextEditingController(text: '0');
  final _awayPenalty = TextEditingController(text: '0');
  final _penaltyReason = TextEditingController();

  String? _homeId;
  String? _awayId;
  String? _tournamentId;
  MatchFormat _format = MatchFormat.t20;
  MatchState _state = MatchState.scheduled;
  DateTime _scheduledStart = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final teams = MockData.teams;
    if (teams.isNotEmpty) _homeId = teams.first.id;
    if (teams.length > 1) _awayId = teams[1].id;
  }

  @override
  void dispose() {
    _name.dispose();
    _venue.dispose();
    _stage.dispose();
    _overs.dispose();
    _ballsPerOver.dispose();
    _homePenalty.dispose();
    _awayPenalty.dispose();
    _penaltyReason.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledStart,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledStart),
    );
    if (time == null) return;
    setState(() {
      _scheduledStart =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (_homeId == null || _awayId == null || _homeId == _awayId) {
      _showMessage('Select two different teams.');
      return;
    }
    final home = MockData.teamById(_homeId!);
    final away = MockData.teamById(_awayId!);
    final name = _name.text.trim().isEmpty
        ? '${home.name} vs ${away.name}'
        : _name.text.trim();
    setState(() => _saving = true);
    final match = CricketMatch(
      id: MockData.nextId('match'),
      tournamentId: _tournamentId,
      matchName: name,
      homeTeamId: home.id,
      awayTeamId: away.id,
      venue: _emptyToNull(_venue.text),
      scheduledStart: _scheduledStart,
      actualStart: _state == MatchState.live ? DateTime.now() : null,
      actualEnd: _state == MatchState.completed ? DateTime.now() : null,
      format: _format,
      oversPerInnings:
          _int(_overs.text, _format.overs == 0 ? 20 : _format.overs),
      tossWinnerTeamId: null,
      tossDecision: null,
      state: _state,
      stageLabel: _emptyToNull(_stage.text),
      homePlayingXI: MockData.playersByTeam(home.id)
          .map((player) => player.id)
          .take(11)
          .toList(),
      awayPlayingXI: MockData.playersByTeam(away.id)
          .map((player) => player.id)
          .take(11)
          .toList(),
    );
    try {
      final saved = await BackendSync.instance.upsertMatch(
        match,
        ballsPerOver: _int(_ballsPerOver.text, 6),
        homePenaltyRuns: _int(_homePenalty.text, 0),
        awayPenaltyRuns: _int(_awayPenalty.text, 0),
        penaltyReason: _emptyToNull(_penaltyReason.text),
      );
      if (!mounted) return;
      setState(() => _saving = false);
      context.go(_state == MatchState.live
          ? '/match/${saved.id}/score'
          : '/match/${saved.id}');
    } on ApiException catch (e) {
      if (mounted) { setState(() => _saving = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); }
    } catch (e) {
      if (mounted) { setState(() => _saving = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e'))); }
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.navyDeep,
        content: Text(text,
            style: AppTextStyles.dm(size: 13, color: AppColors.cream)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teams = MockData.teams;
    final tournaments = MockData.tournaments;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          const BackBar(title: 'New', italic: 'Match'),
          Expanded(
            child: teams.length < 2
                ? _NeedsTeams()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                    children: [
                      _label('MATCH NAME'),
                      const SizedBox(height: 8),
                      _input(_name,
                          hint: 'Optional; defaults to Team A vs Team B'),
                      const SizedBox(height: 18),
                      _label('TEAMS'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _teamPicker(_homeId, true, teams)),
                          Container(
                            width: 36,
                            height: 36,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: const BoxDecoration(
                                color: AppColors.ballRed,
                                shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text('VS',
                                style: AppTextStyles.bebas(
                                    size: 14, color: Colors.white)),
                          ),
                          Expanded(child: _teamPicker(_awayId, false, teams)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (tournaments.isNotEmpty) ...[
                        _dropdown<String>(
                          'TOURNAMENT',
                          _tournamentId ?? '',
                          ['', ...tournaments.map((item) => item.id)],
                          (value) => value.isEmpty
                              ? 'Standalone match'
                              : tournaments
                                  .firstWhere((item) => item.id == value)
                                  .name,
                          (value) => setState(() {
                            _tournamentId = value.isEmpty ? null : value;
                            // Inherit overs + format from the tournament so a
                            // 10-over tournament match doesn't stay at 20.
                            if (_tournamentId != null) {
                              final t =
                                  MockData.tournamentOrNull(_tournamentId);
                              if (t != null) {
                                _format = t.matchFormat;
                                _overs.text = t.oversPerInnings.toString();
                              }
                            }
                          }),
                        ),
                        const SizedBox(height: 18),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: _dropdown<MatchFormat>(
                              'FORMAT',
                              _format,
                              MatchFormat.values,
                              (value) => value.label,
                              (value) => setState(() {
                                _format = value;
                                if (value.overs > 0) {
                                  _overs.text = value.overs.toString();
                                }
                              }),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _field('OVERS', _overs,
                                  keyboard: TextInputType.number)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _field('BALLS/OVER', _ballsPerOver,
                                  keyboard: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _label('LATE / SLOW-OVER PENALTY (RUNS)'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                              child: _field('vs HOME', _homePenalty,
                                  keyboard: TextInputType.number)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _field('vs AWAY', _awayPenalty,
                                  keyboard: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _field('PENALTY REASON', _penaltyReason),
                      const SizedBox(height: 18),
                      _dropdown<MatchState>(
                        'STATUS',
                        _state,
                        MatchState.values,
                        (value) => value.label,
                        (value) => setState(() => _state = value),
                      ),
                      const SizedBox(height: 18),
                      _label('SCHEDULED START'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDateTime,
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: const InputDecoration(),
                          child: Text(
                            DateFormat('MMM d, yyyy - h:mm a')
                                .format(_scheduledStart),
                            style: AppTextStyles.fraunces(
                                size: 13, weight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _field('STAGE / MATCH LABEL', _stage),
                      const SizedBox(height: 12),
                      _field('VENUE', _venue),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: _state == MatchState.live
                            ? 'Create & Score'
                            : 'Save Match',
                        loading: _saving,
                        onPressed: _save,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _teamPicker(String? selectedId, bool isHome, List<Team> teams) {
    final selected = selectedId == null ? null : MockData.teamById(selectedId);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final pickedId = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => _TeamPickerSheet(
            teams: teams,
            excludeId: isHome ? _awayId : _homeId,
          ),
        );
        if (pickedId == null) return;
        setState(() {
          if (isHome) {
            _homeId = pickedId;
          } else {
            _awayId = pickedId;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.navy, width: 1.6),
        ),
        child: Column(
          children: [
            if (selected == null)
              const Icon(Icons.groups_outlined, size: 42, color: AppColors.grey)
            else
              TeamBadge(team: selected, size: 42),
            const SizedBox(height: 6),
            Text(
              selected?.name ?? 'Select team',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.fraunces(size: 12, weight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              isHome ? 'HOME' : 'AWAY',
              style: AppTextStyles.mono(
                  size: 8, color: AppColors.grey, letterSpacing: 0.18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        _input(controller, keyboard: keyboard),
      ],
    );
  }

  Widget _input(TextEditingController controller,
      {String? hint, TextInputType? keyboard}) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: AppTextStyles.fraunces(size: 14, weight: FontWeight.w600),
      cursorColor: AppColors.navy,
      decoration: InputDecoration(hintText: hint),
    );
  }

  Widget _dropdown<T extends Object>(
    String label,
    T value,
    List<T> values,
    String Function(T) display,
    ValueChanged<T> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: values
              .map((item) =>
                  DropdownMenuItem<T>(value: item, child: Text(display(item))))
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppTextStyles.mono(
            size: 9, color: AppColors.grey, letterSpacing: 0.25),
      );

  static int _int(String value, int fallback) =>
      int.tryParse(value.trim()) ?? fallback;
  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _TeamPickerSheet extends StatelessWidget {
  final List<Team> teams;
  final String? excludeId;

  const _TeamPickerSheet({required this.teams, this.excludeId});

  @override
  Widget build(BuildContext context) {
    final list = teams.where((team) => team.id != excludeId).toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(20)),
            ),
            const SizedBox(height: 14),
            Text('Pick a team', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final team = list[i];
                  return ListTile(
                    leading: TeamBadge(team: team, size: 36),
                    title: Text(team.name,
                        style: AppTextStyles.fraunces(
                            size: 14, weight: FontWeight.w700)),
                    subtitle: Text(team.category.label,
                        style: AppTextStyles.mono(size: 9)),
                    onTap: () => Navigator.pop(context, team.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeedsTeams extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_outlined, size: 58, color: AppColors.grey),
            const SizedBox(height: 10),
            Text('Add at least two teams',
                style:
                    AppTextStyles.fraunces(size: 16, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Matches need two teams before they can be scheduled or scored.',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.italicAccent(size: 13, color: AppColors.grey),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => context.push('/team/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add team'),
            ),
          ],
        ),
      ),
    );
  }
}
