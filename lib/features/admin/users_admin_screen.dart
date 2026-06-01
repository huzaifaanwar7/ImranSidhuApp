import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../data/api_client.dart';

class UsersAdminScreen extends StatefulWidget {
  const UsersAdminScreen({super.key});

  @override
  State<UsersAdminScreen> createState() => _UsersAdminScreenState();
}

class _UsersAdminScreenState extends State<UsersAdminScreen> {
  final _search = TextEditingController();
  String? _roleFilter;
  bool _loading = false;
  final Set<int> _busyIds = {};
  List<Map<String, dynamic>> _users = [];
  static const _roles = ['SuperAdmin', 'Captain', 'Scorer', 'Player', 'Fan'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.get('/api/users', query: {
        if (_search.text.isNotEmpty) 'search': _search.text,
        if (_roleFilter != null) 'role': _roleFilter,
        'pageSize': 100,
      });
      _users = List<Map<String, dynamic>>.from(res['items'] as List);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> u) async {
    final id = u['id'] as int;
    setState(() => _busyIds.add(id));
    try {
      await ApiClient.instance.put('/api/users/$id/status', {'isActive': !(u['isActive'] as bool)});
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<void> _changeRole(Map<String, dynamic> u) async {
    final newRole = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Change role'),
        children: [
          for (final r in _roles)
            SimpleDialogOption(onPressed: () => Navigator.pop(ctx, r), child: Text(r)),
        ],
      ),
    );
    if (newRole == null || newRole == u['role']) return;
    final id = u['id'] as int;
    setState(() => _busyIds.add(id));
    try {
      await ApiClient.instance.put('/api/users/$id/role', {'role': newRole});
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<void> _delete(Map<String, dynamic> u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${u['username']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE')),
        ],
      ),
    );
    if (ok != true) return;
    final id = u['id'] as int;
    setState(() => _busyIds.add(id));
    try {
      await ApiClient.instance.delete('/api/users/$id');
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<void> _resetPassword(Map<String, dynamic> u) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset password for ${u['username']}'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Min 6 chars')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SAVE')),
        ],
      ),
    );
    if (ok != true || ctrl.text.length < 6) return;
    final id = u['id'] as int;
    setState(() => _busyIds.add(id));
    try {
      await ApiClient.instance.post('/api/users/$id/reset-password', {'newPassword': ctrl.text});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          const BackBar(title: 'User', italic: 'Management'),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: TextField(
              controller: _search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                _filterChip('All', null),
                for (final r in _roles) _filterChip(r, r),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Text('No users found.',
                            style: AppTextStyles.italicAccent(size: 14, color: AppColors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _userTile(_users[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value) {
    final selected = _roleFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _roleFilter = value);
          _load();
        },
      ),
    );
  }

  Widget _userTile(Map<String, dynamic> u) {
    final isActive = u['isActive'] == true;
    final status = u['approvalStatus'] as String? ?? '';
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
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.navyDeep,
                child: Text(
                  (u['fullName'] as String? ?? u['username'] as String)
                      .split(' ').map((s) => s.isEmpty ? '' : s[0]).take(2).join().toUpperCase(),
                  style: AppTextStyles.bebas(size: 14, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u['fullName'] as String? ?? u['username'] as String,
                        style: AppTextStyles.fraunces(size: 14, weight: FontWeight.w700)),
                    Text(u['username'] as String,
                        style: AppTextStyles.mono(size: 9, color: AppColors.grey, letterSpacing: 0.15)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.navyDeep.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(u['role'] as String,
                    style: AppTextStyles.mono(size: 8, color: AppColors.navyDeep, letterSpacing: 0.2, weight: FontWeight.w700)),
              ),
            ],
          ),
          if (u['email'] != null || u['phone'] != null) ...[
            const SizedBox(height: 6),
            Text([u['email'], u['phone']].whereType<String>().join(' · '),
                style: AppTextStyles.italicAccent(size: 11, color: AppColors.grey)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _statusPill(status, isActive),
              const Spacer(),
              if (_busyIds.contains(u['id'] as int))
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else ...[
                IconButton(icon: const Icon(Icons.swap_horiz_rounded, size: 18), tooltip: 'Change role', onPressed: () => _changeRole(u)),
                IconButton(icon: Icon(isActive ? Icons.block : Icons.check_circle, size: 18), tooltip: isActive ? 'Suspend' : 'Activate', onPressed: () => _toggleActive(u)),
                IconButton(icon: const Icon(Icons.lock_reset, size: 18), tooltip: 'Reset password', onPressed: () => _resetPassword(u)),
                IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.ballRed), onPressed: () => _delete(u)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String status, bool isActive) {
    final color = !isActive
        ? AppColors.ballRed
        : status == 'Pending'
            ? Colors.orange
            : status == 'Rejected'
                ? AppColors.ballRed
                : Colors.green;
    final label = !isActive ? 'SUSPENDED' : status.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: AppTextStyles.mono(size: 8, color: color, letterSpacing: 0.2, weight: FontWeight.w700)),
    );
  }
}
