import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../data/mock_data.dart';
import '../../models/enums.dart';

class PlayersListScreen extends StatefulWidget {
  const PlayersListScreen({super.key});

  @override
  State<PlayersListScreen> createState() => _PlayersListScreenState();
}

class _PlayersListScreenState extends State<PlayersListScreen> {
  String query = '';
  PlayerRole? role;

  @override
  Widget build(BuildContext context) {
    var list = MockData.players;
    if (role != null) list = list.where((p) => p.role == role).toList();
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((p) => p.fullName.toLowerCase().contains(q)).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(actions: [
              IconBtn(
                icon: Icons.add_rounded,
                onTap: () async {
                  await context.push('/player/new');
                  if (mounted) setState(() {});
                },
              ),
            ]),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        size: 14, color: AppColors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => query = v),
                        style: AppTextStyles.fraunces(
                            size: 13, weight: FontWeight.w400),
                        cursorColor: AppColors.navy,
                        decoration: InputDecoration(
                          hintText: 'Search players...',
                          hintStyle: AppTextStyles.italicAccent(
                              size: 12, color: AppColors.grey),
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
                children: [
                  _pill('All', role == null, () => setState(() => role = null)),
                  const SizedBox(width: 6),
                  for (final r in PlayerRole.values) ...[
                    _pill(r.short, role == r, () => setState(() => role = r)),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? _EmptyPlayers(hasFilter: query.isNotEmpty || role != null)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final p = list[i];
                        final team = p.teamId == null
                            ? null
                            : MockData.teamById(p.teamId!);
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.push('/player/${p.id}'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFF57F17),
                                        Color(0xFFE65100)
                                      ],
                                    ),
                                    border: Border.all(
                                        color: AppColors.gold, width: 2),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(p.initials,
                                      style: AppTextStyles.bebas(
                                          size: 14, color: Colors.white)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(p.fullName,
                                          style: AppTextStyles.fraunces(
                                              size: 13,
                                              weight: FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text(
                                          '${p.role.label}${team != null ? '  ·  ${team.name}' : ''}',
                                          style: AppTextStyles.mono(
                                            size: 8,
                                            color: AppColors.grey,
                                            letterSpacing: 0.15,
                                          )),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${p.runs}',
                                        style: AppTextStyles.fraunces(
                                            size: 14,
                                            weight: FontWeight.w900,
                                            color: AppColors.navyDeep)),
                                    Text('RUNS',
                                        style: AppTextStyles.mono(
                                            size: 8,
                                            letterSpacing: 0.18,
                                            color: AppColors.goldDeep)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.navyDeep : AppColors.creamSoft,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: active ? AppColors.navyDeep : AppColors.line),
        ),
        child: Text(label,
            style: AppTextStyles.mono(
              size: 9,
              color: active ? AppColors.cream : AppColors.grey,
              letterSpacing: 0.15,
              weight: FontWeight.w700,
            )),
      ),
    );
  }
}

class _EmptyPlayers extends StatelessWidget {
  final bool hasFilter;

  const _EmptyPlayers({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_add_alt_1_outlined,
                size: 58, color: AppColors.grey),
            const SizedBox(height: 10),
            Text(
              hasFilter ? 'No players match this filter' : 'No players yet',
              style: AppTextStyles.fraunces(size: 16, weight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilter
                  ? 'Try another name or role.'
                  : 'Add players with batting, bowling, and fielding statistics.',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.italicAccent(size: 13, color: AppColors.grey),
            ),
            if (!hasFilter) ...[
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => context.push('/player/new'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add player'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
