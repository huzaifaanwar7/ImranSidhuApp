import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/mock_data.dart';
import '../../models/enums.dart';
import '../../models/team.dart';

class AddTeamScreen extends StatefulWidget {
  final String? teamId;

  const AddTeamScreen({super.key, this.teamId});

  @override
  State<AddTeamScreen> createState() => _AddTeamScreenState();
}

class _AddTeamScreenState extends State<AddTeamScreen> {
  final _name = TextEditingController();
  final _shortCode = TextEditingController();
  final _foundedYear = TextEditingController();
  final _homeVenue = TextEditingController();
  final _matches = TextEditingController(text: '0');
  final _wins = TextEditingController(text: '0');
  final _losses = TextEditingController(text: '0');
  final _ties = TextEditingController(text: '0');
  final _noResults = TextEditingController(text: '0');

  TeamCategory _category = TeamCategory.senior;
  Color _primaryColor = AppColors.navy;
  Color _secondaryColor = AppColors.gold;
  String? _captainId;
  bool _saving = false;

  bool get _isEdit => widget.teamId != null;

  @override
  void initState() {
    super.initState();
    final team = MockData.teamOrNull(widget.teamId);
    if (team != null) {
      _name.text = team.name;
      _shortCode.text = team.shortCode;
      _foundedYear.text = team.foundedYear?.toString() ?? '';
      _homeVenue.text = team.homeVenue ?? '';
      _matches.text = team.matchesPlayed.toString();
      _wins.text = team.wins.toString();
      _losses.text = team.losses.toString();
      _ties.text = team.ties.toString();
      _noResults.text = team.noResults.toString();
      _category = team.category;
      _primaryColor = team.primaryColor;
      _secondaryColor = team.secondaryColor;
      _captainId = team.captainId;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _shortCode.dispose();
    _foundedYear.dispose();
    _homeVenue.dispose();
    _matches.dispose();
    _wins.dispose();
    _losses.dispose();
    _ties.dispose();
    _noResults.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _showMessage('Team name is required.');
      return;
    }
    final code = _shortCode.text.trim().isEmpty
        ? _codeFromName(name)
        : _shortCode.text.trim().toUpperCase();
    setState(() => _saving = true);
    final existing = MockData.teamOrNull(widget.teamId);
    final team = Team(
      id: existing?.id ?? MockData.nextId('team'),
      name: name,
      shortCode: code.length > 4 ? code.substring(0, 4) : code,
      category: _category,
      foundedYear: _nullableInt(_foundedYear.text),
      homeVenue: _emptyToNull(_homeVenue.text),
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      captainId: _captainId,
      matchesPlayed: _int(_matches.text),
      wins: _int(_wins.text),
      losses: _int(_losses.text),
      ties: _int(_ties.text),
      noResults: _int(_noResults.text),
    );
    await MockData.saveTeam(team);
    if (!mounted) return;
    setState(() => _saving = false);
    context.pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete team?'),
        content: const Text(
          'Players will remain in the app but will become free agents.',
        ),
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
    if (confirmed != true || widget.teamId == null) return;
    await MockData.deleteTeam(widget.teamId!);
    if (mounted) context.go('/teams');
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
    final roster = widget.teamId == null
        ? <dynamic>[]
        : MockData.playersByTeam(widget.teamId!);
    final captainExists = roster.any((player) => player.id == _captainId);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          BackBar(
            title: _isEdit ? 'Edit' : 'Add',
            italic: 'Team',
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
                _section('TEAM PROFILE'),
                _field('TEAM NAME', _name),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field('SHORT CODE', _shortCode)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _field('FOUNDED YEAR', _foundedYear,
                            keyboard: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                _dropdown<TeamCategory>(
                  'CATEGORY',
                  _category,
                  TeamCategory.values,
                  (value) => value.label,
                  (value) => setState(() => _category = value),
                ),
                const SizedBox(height: 12),
                _field('HOME VENUE', _homeVenue),
                const SizedBox(height: 16),
                _section('TEAM COLORS'),
                Row(
                  children: [
                    Expanded(
                      child: _colorChooser(
                        'PRIMARY',
                        _primaryColor,
                        (color) => setState(() => _primaryColor = color),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _colorChooser(
                        'SECONDARY',
                        _secondaryColor,
                        (color) => setState(() => _secondaryColor = color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _section('TEAM STATISTICS'),
                Row(
                  children: [
                    Expanded(
                        child: _field('MATCHES', _matches,
                            keyboard: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field('WINS', _wins,
                            keyboard: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field('LOSSES', _losses,
                            keyboard: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _field('TIES', _ties,
                            keyboard: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field('NO RESULTS', _noResults,
                            keyboard: TextInputType.number)),
                  ],
                ),
                if (roster.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _captainDropdown(captainExists ? _captainId : null, roster),
                ],
                const SizedBox(height: 22),
                PrimaryButton(
                  label: _isEdit ? 'Save Team' : 'Create Team',
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

  Widget _captainDropdown(String? value, List<dynamic> roster) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('CAPTAIN'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('No captain selected'),
            ),
            ...roster.map(
              (player) => DropdownMenuItem<String>(
                value: player.id,
                child: Text(player.fullName),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() =>
                _captainId = value == null || value.isEmpty ? null : value);
          },
        ),
      ],
    );
  }

  Widget _colorChooser(
      String label, Color selected, ValueChanged<Color> onPick) {
    const colors = [
      AppColors.navy,
      AppColors.ballRed,
      AppColors.gold,
      AppColors.amasGreen,
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final color in colors)
              InkWell(
                onTap: () => onPick(color),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected.toARGB32() == color.toARGB32()
                          ? AppColors.ink
                          : AppColors.line,
                      width: selected.toARGB32() == color.toARGB32() ? 2 : 1,
                    ),
                  ),
                ),
              ),
          ],
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

  static int _int(String value) => int.tryParse(value.trim()) ?? 0;
  static int? _nullableInt(String value) =>
      value.trim().isEmpty ? null : _int(value);
  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _codeFromName(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      final end = words.first.length.clamp(1, 3).toInt();
      return words.first.substring(0, end).toUpperCase();
    }
    return words.take(3).map((word) => word[0]).join().toUpperCase();
  }
}
