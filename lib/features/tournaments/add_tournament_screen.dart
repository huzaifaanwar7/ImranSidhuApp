import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/mock_data.dart';
import '../../models/enums.dart';
import '../../models/tournament.dart';

class AddTournamentScreen extends StatefulWidget {
  final String? tournamentId;

  const AddTournamentScreen({super.key, this.tournamentId});

  @override
  State<AddTournamentScreen> createState() => _AddTournamentScreenState();
}

class _AddTournamentScreenState extends State<AddTournamentScreen> {
  final _name = TextEditingController();
  final _edition = TextEditingController(text: DateTime.now().year.toString());
  final _overs = TextEditingController(text: '20');
  final _sponsor = TextEditingController();
  final _totalRuns = TextEditingController(text: '0');
  final _totalWickets = TextEditingController(text: '0');
  final _totalSixes = TextEditingController(text: '0');

  TeamCategory _category = TeamCategory.senior;
  TournamentFormat _format = TournamentFormat.roundRobin;
  TournamentStage _stage = TournamentStage.registration;
  MatchFormat _matchFormat = MatchFormat.t20;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  final Set<String> _teamIds = {};
  bool _saving = false;

  bool get _isEdit => widget.tournamentId != null;

  @override
  void initState() {
    super.initState();
    final tournament = MockData.tournamentOrNull(widget.tournamentId);
    if (tournament != null) {
      _name.text = tournament.name;
      _edition.text = tournament.edition;
      _overs.text = tournament.oversPerInnings.toString();
      _sponsor.text = tournament.sponsorTitle ?? '';
      _totalRuns.text = tournament.totalRuns.toString();
      _totalWickets.text = tournament.totalWickets.toString();
      _totalSixes.text = tournament.totalSixes.toString();
      _category = tournament.category;
      _format = tournament.format;
      _stage = tournament.stage;
      _matchFormat = tournament.matchFormat;
      _startDate = tournament.startDate;
      _endDate = tournament.endDate;
      _teamIds.addAll(tournament.teamIds);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _edition.dispose();
    _overs.dispose();
    _sponsor.dispose();
    _totalRuns.dispose();
    _totalWickets.dispose();
    _totalSixes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _showMessage('Tournament name is required.');
      return;
    }
    setState(() => _saving = true);
    final existing = MockData.tournamentOrNull(widget.tournamentId);
    final tournament = Tournament(
      id: existing?.id ?? MockData.nextId('tournament'),
      name: name,
      edition: _edition.text.trim().isEmpty
          ? DateTime.now().year.toString()
          : _edition.text.trim(),
      category: _category,
      format: _format,
      startDate: _startDate,
      endDate: _endDate,
      stage: _stage,
      matchFormat: _matchFormat,
      oversPerInnings:
          _int(_overs.text, _matchFormat.overs == 0 ? 20 : _matchFormat.overs),
      teamIds: _teamIds.toList(),
      sponsorTitle: _emptyToNull(_sponsor.text),
      totalRuns: _int(_totalRuns.text),
      totalWickets: _int(_totalWickets.text),
      totalSixes: _int(_totalSixes.text),
    );
    await MockData.saveTournament(tournament);
    if (!mounted) return;
    setState(() => _saving = false);
    context.pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete tournament?'),
        content: const Text(
            'Existing matches will stay in the app without a tournament link.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || widget.tournamentId == null) return;
    await MockData.deleteTournament(widget.tournamentId!);
    if (mounted) context.go('/tournaments');
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
      }
    });
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
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          BackBar(
            title: _isEdit ? 'Edit' : 'Add',
            italic: 'Tournament',
            actions: [
              if (_isEdit)
                IconButton(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline, color: AppColors.gold),
                ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              children: [
                _section('TOURNAMENT PROFILE'),
                _field('TOURNAMENT NAME', _name),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field('EDITION', _edition)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _field('OVERS', _overs,
                            keyboard: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                _field('TITLE SPONSOR', _sponsor),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _dateTile(
                            'START', _startDate, () => _pickDate(start: true))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _dateTile(
                            'END', _endDate, () => _pickDate(start: false))),
                  ],
                ),
                const SizedBox(height: 16),
                _section('FORMAT'),
                _dropdown<TeamCategory>(
                  'CATEGORY',
                  _category,
                  TeamCategory.values,
                  (value) => value.label,
                  (value) => setState(() => _category = value),
                ),
                const SizedBox(height: 12),
                _dropdown<TournamentFormat>(
                  'TOURNAMENT FORMAT',
                  _format,
                  TournamentFormat.values,
                  (value) => value.label,
                  (value) => setState(() => _format = value),
                ),
                const SizedBox(height: 12),
                _dropdown<TournamentStage>(
                  'CURRENT STAGE',
                  _stage,
                  TournamentStage.values,
                  (value) => value.label,
                  (value) => setState(() => _stage = value),
                ),
                const SizedBox(height: 12),
                _dropdown<MatchFormat>(
                  'MATCH FORMAT',
                  _matchFormat,
                  MatchFormat.values,
                  (value) => value.label,
                  (value) => setState(() {
                    _matchFormat = value;
                    if (value.overs > 0) _overs.text = value.overs.toString();
                  }),
                ),
                const SizedBox(height: 16),
                _section('TEAMS'),
                if (teams.isEmpty)
                  _emptyBox(
                      'Create teams first, then attach them to this tournament.')
                else
                  ...teams.map((team) => CheckboxListTile(
                        value: _teamIds.contains(team.id),
                        onChanged: (checked) => setState(() {
                          if (checked == true) {
                            _teamIds.add(team.id);
                          } else {
                            _teamIds.remove(team.id);
                          }
                        }),
                        controlAffinity: ListTileControlAffinity.trailing,
                        secondary: TeamBadge(team: team, size: 34),
                        title: Text(
                          team.name,
                          style: AppTextStyles.fraunces(
                              size: 13, weight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          team.category.label.toUpperCase(),
                          style:
                              AppTextStyles.mono(size: 8, letterSpacing: 0.18),
                        ),
                      )),
                const SizedBox(height: 16),
                _section('TOURNAMENT STATISTICS'),
                Row(
                  children: [
                    Expanded(
                        child: _field('RUNS', _totalRuns,
                            keyboard: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field('WICKETS', _totalWickets,
                            keyboard: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field('SIXES', _totalSixes,
                            keyboard: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: _isEdit ? 'Save Tournament' : 'Create Tournament',
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

  Widget _dateTile(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: const InputDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(label),
            const SizedBox(height: 6),
            Text(
              DateFormat('MMM d, yyyy').format(date),
              style: AppTextStyles.fraunces(size: 13, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        text,
        style: AppTextStyles.italicAccent(size: 13, color: AppColors.grey),
      ),
    );
  }

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: AppTextStyles.mono(
            size: 9,
            color: AppColors.grey,
            letterSpacing: 0.25,
            weight: FontWeight.w700,
          ),
        ),
      );

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboard,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          style: AppTextStyles.fraunces(size: 13, weight: FontWeight.w600),
          cursorColor: AppColors.navy,
          decoration: const InputDecoration(),
        ),
      ],
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
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: values
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(display(item)),
                ),
              )
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
          size: 8,
          color: AppColors.grey,
          letterSpacing: 0.2,
        ),
      );

  static int _int(String value, [int fallback = 0]) =>
      int.tryParse(value.trim()) ?? fallback;

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
