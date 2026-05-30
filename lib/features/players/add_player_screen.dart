import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/api_client.dart';
import '../../data/backend_sync.dart';
import '../../data/image_picker_helper.dart';
import '../../data/mock_data.dart';
import '../../models/enums.dart';
import '../../models/player.dart';

class AddPlayerScreen extends StatefulWidget {
  final String? playerId;
  final String? teamId;

  const AddPlayerScreen({super.key, this.playerId, this.teamId});

  @override
  State<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends State<AddPlayerScreen> {
  final _name = TextEditingController();
  final _jersey = TextEditingController();
  final _city = TextEditingController();
  final _matches = TextEditingController(text: '0');
  final _innings = TextEditingController(text: '0');
  final _runs = TextEditingController(text: '0');
  final _highest = TextEditingController(text: '0');
  final _average = TextEditingController(text: '0');
  final _strikeRate = TextEditingController(text: '0');
  final _fours = TextEditingController(text: '0');
  final _sixes = TextEditingController(text: '0');
  final _fifties = TextEditingController(text: '0');
  final _hundreds = TextEditingController(text: '0');
  final _wickets = TextEditingController(text: '0');
  final _bestBowling = TextEditingController(text: '-');
  final _economy = TextEditingController(text: '0');
  final _catches = TextEditingController(text: '0');

  PlayerRole _role = PlayerRole.batter;
  BattingHand _battingHand = BattingHand.right;
  BowlingStyle? _bowlingStyle;
  String? _teamId;
  String? _photoBase64;
  String? _existingPhotoUrl;
  bool _retired = false;
  bool _saving = false;

  bool get _isEdit => widget.playerId != null;

  @override
  void initState() {
    super.initState();
    final player = MockData.playerOrNull(widget.playerId);
    if (player != null) {
      _name.text = player.fullName;
      _jersey.text = player.jerseyNumber?.toString() ?? '';
      _city.text = player.city ?? '';
      _matches.text = player.matches.toString();
      _innings.text = player.innings.toString();
      _runs.text = player.runs.toString();
      _highest.text = player.highestScore.toString();
      _average.text = player.average.toStringAsFixed(1);
      _strikeRate.text = player.strikeRate.toStringAsFixed(1);
      _fours.text = player.fours.toString();
      _sixes.text = player.sixes.toString();
      _fifties.text = player.fifties.toString();
      _hundreds.text = player.hundreds.toString();
      _wickets.text = player.wickets.toString();
      _bestBowling.text = player.bestBowling;
      _economy.text = player.economy.toStringAsFixed(1);
      _catches.text = player.catches.toString();
      _role = player.role;
      _battingHand = player.battingHand;
      _bowlingStyle = player.bowlingStyle;
      _teamId = player.teamId;
      _retired = player.retired;
      _existingPhotoUrl = player.photoUrl;
    } else {
      _teamId = widget.teamId;
    }
  }

  Future<void> _pickPhoto() async {
    final b64 = await ImagePickerHelper.pickAsBase64();
    if (b64 != null) setState(() => _photoBase64 = b64);
  }

  @override
  void dispose() {
    _name.dispose();
    _jersey.dispose();
    _city.dispose();
    _matches.dispose();
    _innings.dispose();
    _runs.dispose();
    _highest.dispose();
    _average.dispose();
    _strikeRate.dispose();
    _fours.dispose();
    _sixes.dispose();
    _fifties.dispose();
    _hundreds.dispose();
    _wickets.dispose();
    _bestBowling.dispose();
    _economy.dispose();
    _catches.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _showMessage('Player name is required.');
      return;
    }
    setState(() => _saving = true);
    final existing = MockData.playerOrNull(widget.playerId);
    final player = Player(
      id: existing?.id ?? MockData.nextId('player'),
      fullName: name,
      role: _role,
      battingHand: _battingHand,
      bowlingStyle: _bowlingStyle,
      city: _emptyToNull(_city.text),
      jerseyNumber: _nullableInt(_jersey.text),
      teamId: _teamId,
      retired: _retired,
      matches: _int(_matches.text),
      innings: _int(_innings.text),
      runs: _int(_runs.text),
      highestScore: _int(_highest.text),
      average: _double(_average.text),
      strikeRate: _double(_strikeRate.text),
      fours: _int(_fours.text),
      sixes: _int(_sixes.text),
      fifties: _int(_fifties.text),
      hundreds: _int(_hundreds.text),
      wickets: _int(_wickets.text),
      bestBowling:
          _bestBowling.text.trim().isEmpty ? '-' : _bestBowling.text.trim(),
      economy: _double(_economy.text),
      catches: _int(_catches.text),
    );
    try {
      await BackendSync.instance.upsertPlayer(player, photoBase64: _photoBase64);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? 'Player updated.' : 'Player submitted — pending approval.'),
      ));
      context.pop();
    } on ApiException catch (e) {
      if (mounted) { setState(() => _saving = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); }
    } catch (e) {
      if (mounted) { setState(() => _saving = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e'))); }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete player?'),
        content: const Text(
            'This removes the player profile and entered career statistics.'),
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
    if (confirmed != true || widget.playerId == null) return;
    try {
      await BackendSync.instance.deletePlayer(widget.playerId!);
      if (mounted) context.go('/players');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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
    final teamValue =
        teams.any((team) => team.id == _teamId) ? _teamId ?? '' : '';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          BackBar(
            title: _isEdit ? 'Edit' : 'Add',
            italic: 'Player',
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
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          width: 96, height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF57F17), Color(0xFFE65100)],
                            ),
                            border: Border.all(color: AppColors.gold, width: 2),
                          ),
                          alignment: Alignment.center,
                          clipBehavior: Clip.antiAlias,
                          child: _photoBase64 != null
                              ? Image.memory(
                                  base64Decode(_photoBase64!.split(',').last),
                                  width: 96, height: 96, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person, color: Colors.white, size: 40),
                                )
                              : (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty
                                  ? Image.network(
                                      ApiClient.imageUrl(_existingPhotoUrl)!,
                                      width: 96, height: 96, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.person, color: Colors.white, size: 40),
                                    )
                                  : Text(
                                      _name.text.trim().isEmpty ? '?' : _initials(_name.text),
                                      style: AppTextStyles.bebas(size: 30, color: Colors.white),
                                    )),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: _pickPhoto,
                        icon: const Icon(Icons.image_outlined, size: 14),
                        label: Text(_photoBase64 != null ? 'PHOTO SELECTED' : 'PICK PHOTO'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _section('PLAYER PROFILE'),
                _field('FULL NAME', _name, onChanged: (_) => setState(() {})),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _field('JERSEY #', _jersey,
                            keyboard: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _field('CITY', _city)),
                  ],
                ),
                const SizedBox(height: 12),
                _teamDropdown(teamValue, teams),
                const SizedBox(height: 12),
                _dropdown<PlayerRole>(
                  'PLAYING ROLE',
                  _role,
                  PlayerRole.values,
                  (value) => value.label,
                  (value) => setState(() => _role = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _dropdown<BattingHand>(
                        'BATTING HAND',
                        _battingHand,
                        BattingHand.values,
                        (value) => value == BattingHand.right
                            ? 'Right hand'
                            : 'Left hand',
                        (value) => setState(() => _battingHand = value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _bowlingDropdown()),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _retired,
                  onChanged: (value) => setState(() => _retired = value),
                  title: Text('Retired player',
                      style: AppTextStyles.fraunces(
                          size: 13, weight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                _section('BATTING STATISTICS'),
                Row(
                  children: [
                    Expanded(
                        child: _field('MATCHES', _matches,
                            keyboard: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field('INNINGS', _innings,
                            keyboard: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field('RUNS', _runs,
                            keyboard: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _field('HIGHEST', _highest,
                            keyboard: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field('AVERAGE', _average,
                            keyboard: const TextInputType.numberWithOptions(
                                decimal: true))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field('STRIKE RATE', _strikeRate,
                            keyboard: const TextInputType.numberWithOptions(
                                decimal: true))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _field('FOURS', _fours,
                            keyboard: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field('SIXES', _sixes,
                            keyboard: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field('50s', _fifties,
                            keyboard: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field('100s', _hundreds,
                            keyboard: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 16),
                _section('BOWLING & FIELDING'),
                Row(
                  children: [
                    Expanded(
                        child: _field('WICKETS', _wickets,
                            keyboard: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: _field('BEST', _bestBowling)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field('ECONOMY', _economy,
                            keyboard: const TextInputType.numberWithOptions(
                                decimal: true))),
                  ],
                ),
                const SizedBox(height: 12),
                _field('CATCHES', _catches, keyboard: TextInputType.number),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: _isEdit ? 'Save Player' : 'Create Player',
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

  Widget _teamDropdown(String value, List teams) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('TEAM'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: [
            const DropdownMenuItem(value: '', child: Text('Free agent')),
            ...teams.map(
              (team) => DropdownMenuItem<String>(
                value: team.id,
                child: Text(team.name),
              ),
            ),
          ],
          onChanged: (value) => setState(
              () => _teamId = value == null || value.isEmpty ? null : value),
        ),
      ],
    );
  }

  Widget _bowlingDropdown() {
    final value = _bowlingStyle?.name ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('BOWLING STYLE'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: [
            const DropdownMenuItem(value: '', child: Text('None')),
            ...BowlingStyle.values.map(
              (style) => DropdownMenuItem(
                value: style.name,
                child: Text(style.label),
              ),
            ),
          ],
          onChanged: (value) => setState(() {
            _bowlingStyle = value == null || value.isEmpty
                ? null
                : BowlingStyle.values
                    .firstWhere((style) => style.name == value);
          }),
        ),
      ],
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
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          onChanged: onChanged,
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

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static int _int(String value) => int.tryParse(value.trim()) ?? 0;
  static int? _nullableInt(String value) =>
      value.trim().isEmpty ? null : _int(value);
  static double _double(String value) => double.tryParse(value.trim()) ?? 0;
  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
