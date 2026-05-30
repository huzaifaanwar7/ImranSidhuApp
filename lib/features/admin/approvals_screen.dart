import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../data/api_client.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  bool _loading = false;
  String _status = 'Pending';
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) _load();
    });
    _load();
  }

  String? get _entityFilter => switch (_tabs.index) {
        1 => 'User',
        2 => 'Team',
        3 => 'Player',
        _ => null,
      };

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.get('/api/approvals', query: {
        'status': _status,
        if (_entityFilter != null) 'entityType': _entityFilter,
      });
      _items = res as List;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(int id) async {
    try {
      await ApiClient.instance.post('/api/approvals/$id/approve');
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _reject(int id) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject — reason?'),
        content: TextField(controller: ctrl, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('REJECT')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.post('/api/approvals/$id/reject', {'rejectionReason': ctrl.text});
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          const BackBar(title: 'Approval', italic: 'Queue'),
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabs,
              labelColor: AppColors.navyDeep,
              unselectedLabelColor: AppColors.grey,
              indicatorColor: AppColors.gold,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Users'),
                Tab(text: 'Teams'),
                Tab(text: 'Players'),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                for (final s in const ['Pending', 'Approved', 'Rejected'])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: _status == s,
                      onSelected: (_) {
                        setState(() => _status = s);
                        _load();
                      },
                    ),
                  ),
                IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Text('Nothing in the queue.',
                            style: AppTextStyles.italicAccent(size: 14, color: AppColors.grey)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _card(_items[i] as Map),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _card(Map raw) {
    final req = Map<String, dynamic>.from(raw['request'] as Map);
    final entity = raw['entity'] is Map ? Map<String, dynamic>.from(raw['entity'] as Map) : null;
    final type = req['entityType'] as String;
    final isPending = req['status'] == 'Pending';

    String title;
    String subtitle;
    IconData icon;

    switch (type) {
      case 'User':
        title = entity?['fullName'] ?? entity?['username'] ?? 'User';
        subtitle = '${entity?['role'] ?? ''} · ${entity?['email'] ?? entity?['username'] ?? ''}';
        icon = Icons.person_outline;
        break;
      case 'Team':
        title = entity?['name'] ?? 'Team';
        subtitle = '${entity?['shortCode'] ?? ''} · ${entity?['city'] ?? ''}';
        icon = Icons.groups_rounded;
        break;
      case 'Player':
        title = entity?['fullName'] ?? 'Player';
        subtitle = '${entity?['role'] ?? ''} · ${entity?['city'] ?? ''}';
        icon = Icons.sports_cricket_rounded;
        break;
      default:
        title = type;
        subtitle = '';
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.navy.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppColors.navyDeep),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.fraunces(size: 14, weight: FontWeight.w700)),
                    Text(subtitle, style: AppTextStyles.italicAccent(size: 11, color: AppColors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
                child: Text(type.toUpperCase(),
                    style: AppTextStyles.mono(size: 8, color: AppColors.goldDeep, letterSpacing: 0.2, weight: FontWeight.w700)),
              ),
            ],
          ),
          if ((req['notes'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(req['notes'] as String, style: AppTextStyles.italicAccent(size: 12, color: AppColors.ink)),
          ],
          if (req['status'] == 'Rejected' && (req['rejectionReason'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text('Reason: ${req['rejectionReason']}', style: AppTextStyles.italicAccent(size: 11, color: AppColors.ballRed)),
          ],
          const SizedBox(height: 10),
          if (isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(req['id'] as int),
                    icon: const Icon(Icons.close, color: AppColors.ballRed),
                    label: const Text('REJECT', style: TextStyle(color: AppColors.ballRed)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approve(req['id'] as int),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('APPROVE'),
                  ),
                ),
              ],
            )
          else
            Text('Reviewed ${req['reviewedAt'] ?? ''}',
                style: AppTextStyles.mono(size: 8, color: AppColors.grey, letterSpacing: 0.15)),
        ],
      ),
    );
  }
}
