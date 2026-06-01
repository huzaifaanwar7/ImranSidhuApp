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
  int? _captainUserId;
  List<Map<String, dynamic>> _candidateCaptains = [];
  String? _logoBase64;       // newly picked image, sent to backend
  String? _existingLogoUrl;  // already-saved CDN URL
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
      _existingLogoUrl = team.flagUrl;
    }
    _loadCandidateCaptains();
  }

  Future<void> _pickLogo() async {
    final b64 = await ImagePickerHelper.pickAsBase64();
    if (b64 != null) setState(() => _logoBase64 = b64);
  }

  Future<void> _loadCandidateCaptains() async {
    if (!ApiClient.instance.isSuperAdmin) return;
    try {
      final res = await ApiClient.instance.get('/api/users',
          query: {'pageSize': 200, 'status': 'Approved'});
      final list = List<Map<String, dynamic>>.from(res['items'] as List);
      // Allow assigning any non-fan user; Captain/Player/Scorer can all be promoted.
      _candidateCaptains = list.where((u) => u['role'] != 'SuperAdmin').toList();
      if (mounted) setState(() {});
    } catch (_) {/* ignore */}
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
    try {
      await BackendSync.instance.upsertTeam(team, logoBase64: _logoBase64, captainUserId: _captainUserId);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit
            ? 'Team updated.'
            : 'Team submitted — pending SuperAdmin approval.'),
      ));
      context.pop();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
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
    setState(() => _saving = true);
    try {
      await BackendSync.instance.deleteTeam(widget.teamId!);
      if (mounted) context.go('/teams');
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
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
                _section('TEAM LOGO'),
                _logoPicker(),
                const SizedBox(height: 16),
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
                if (ApiClient.instance.isSuperAdmin) ...[
                  const SizedBox(height: 16),
                  _section('CAPTAIN USER'),
                  _userCaptainDropdown(),
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

  Widget _userCaptainDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('ASSIGN CAPTAIN (existing user)'),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          initialValue: _captainUserId,
          items: [
            const DropdownMenuItem<int>(value: null, child: Text('No captain yet')),
            ..._candidateCaptains.map((u) => DropdownMenuItem<int>(
                  value: u['id'] as int,
                  child: Text('${u['fullName']} (${u['username']}) — ${u['role']}'),
                )),
          ],
          onChanged: (v) => setState(() => _captainUserId = v),
        ),
        const SizedBox(height: 4),
        Text(
          'The selected user becomes the team captain. They can then add players (each player is held pending until SuperAdmin approves).',
          style: AppTextStyles.italicAccent(size: 11, color: AppColors.grey),
        ),
      ],
    );
  }

  Widget _logoPicker() {
    final hasNew = _logoBase64 != null;
    final hasExisting = _existingLogoUrl != null && _existingLogoUrl!.isNotEmpty;
    return Row(
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppColors.navyDeep.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          alignment: Alignment.center,
          clipBehavior: (hasNew || hasExisting) ? Clip.antiAlias : Clip.none,
          child: hasNew
              ? Image.memory(
                  base64Decode(_logoBase64!.split(',').last),
                  width: 72, height: 72, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined, color: AppColors.grey, size: 30),
                )
              : hasExisting
                  ? Image.network(
                      ApiClient.imageUrl(_existingLogoUrl)!,
                      width: 72, height: 72, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.shield_rounded, color: AppColors.navyDeep, size: 30),
                    )
                  : const Icon(Icons.shield_outlined, color: AppColors.grey, size: 30),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hasNew ? 'New logo selected' : (hasExisting ? 'Current logo saved' : 'No logo yet'),
                  style: AppTextStyles.fraunces(size: 12, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickLogo,
                    icon: const Icon(Icons.image_outlined, size: 14),
                    label: const Text('PICK IMAGE'),
                  ),
                  if (hasNew) ...[
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: () => setState(() => _logoBase64 = null),
                      child: const Text('CLEAR'),
                    ),
                  ],
                ],
              ),
            ],
          ),
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
