import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../data/api_client.dart';

class SponsorsScreen extends StatefulWidget {
  const SponsorsScreen({super.key});

  @override
  State<SponsorsScreen> createState() => _SponsorsScreenState();
}

class _SponsorsScreenState extends State<SponsorsScreen> {
  bool _loading = false;
  bool _saving = false;
  List<Map<String, dynamic>> _items = [];

  static const _slots = [
    'Splash', 'Dashboard', 'Scorecard', 'Commentary', 'OverCard', 'Kit', 'MatchPresentedBy',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.get('/api/sponsors');
      _items = List<Map<String, dynamic>>.from(res as List);
    } catch (_) {/* */}
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _addOrEdit({Map<String, dynamic>? existing}) async {
    final nameCtl = TextEditingController(text: existing?['name'] ?? '');
    final tagCtl = TextEditingController(text: existing?['tagline'] ?? '');
    final webCtl = TextEditingController(text: existing?['websiteUrl'] ?? '');
    final phoneCtl = TextEditingController(text: existing?['contactPhone'] ?? '');
    final selected = ((existing?['slots'] as String?) ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Add sponsor' : 'Edit sponsor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: tagCtl, decoration: const InputDecoration(labelText: 'Tagline')),
                TextField(controller: webCtl, decoration: const InputDecoration(labelText: 'Website URL')),
                TextField(controller: phoneCtl, decoration: const InputDecoration(labelText: 'Contact phone')),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Slots', style: AppTextStyles.mono(size: 9, color: AppColors.grey, letterSpacing: 0.2)),
                ),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: _slots.map((s) => FilterChip(
                    label: Text(s),
                    selected: selected.contains(s),
                    onSelected: (v) => setS(() {
                      if (v) { selected.add(s); } else { selected.remove(s); }
                    }),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SAVE')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final body = {
      'name': nameCtl.text,
      'tagline': tagCtl.text,
      'websiteUrl': webCtl.text,
      'contactPhone': phoneCtl.text,
      'slots': selected.join(','),
      'isActive': true,
    };
    setState(() => _saving = true);
    try {
      if (existing == null) {
        await ApiClient.instance.post('/api/sponsors', body);
      } else {
        await ApiClient.instance.put('/api/sponsors/${existing['id']}', body);
      }
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete sponsor?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await ApiClient.instance.delete('/api/sponsors/$id');
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = ApiClient.instance.isSuperAdmin;
    return Scaffold(
      backgroundColor: AppColors.cream,
      floatingActionButton: canEdit
          ? FloatingActionButton(
              backgroundColor: AppColors.ballRed,
              onPressed: _saving ? null : () => _addOrEdit(),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          const BackBar(title: 'Sponsors', italic: ' '),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Text('No sponsors yet.',
                            style: AppTextStyles.italicAccent(size: 14, color: AppColors.grey)),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final s = _items[i];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.navyDeep.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.workspace_premium_rounded, color: AppColors.gold),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s['name'] as String? ?? '',
                                            style: AppTextStyles.fraunces(size: 14, weight: FontWeight.w700)),
                                        if ((s['tagline'] as String?)?.isNotEmpty == true)
                                          Text(s['tagline'] as String,
                                              style: AppTextStyles.italicAccent(size: 11, color: AppColors.grey)),
                                        if ((s['slots'] as String?)?.isNotEmpty == true)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text((s['slots'] as String).toUpperCase(),
                                                style: AppTextStyles.mono(size: 8, color: AppColors.goldDeep, letterSpacing: 0.18)),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (canEdit) ...[
                                    IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _addOrEdit(existing: s)),
                                    IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.ballRed), onPressed: () => _delete(s['id'] as int)),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
