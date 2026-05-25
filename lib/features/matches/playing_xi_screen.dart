import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/mock_data.dart';
import '../../models/enums.dart';

class PlayingXIScreen extends StatefulWidget {
  final String homeId;
  final String awayId;
  const PlayingXIScreen(
      {super.key, required this.homeId, required this.awayId});

  @override
  State<PlayingXIScreen> createState() => _PlayingXIScreenState();
}

class _PlayingXIScreenState extends State<PlayingXIScreen>
    with SingleTickerProviderStateMixin {
  late final _tab = TabController(length: 2, vsync: this);
  final _homeXI = <String>{};
  final _awayXI = <String>{};

  @override
  void initState() {
    super.initState();
    _homeXI
        .addAll(MockData.playersByTeam(widget.homeId).take(5).map((p) => p.id));
    _awayXI
        .addAll(MockData.playersByTeam(widget.awayId).take(5).map((p) => p.id));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = MockData.teamById(widget.homeId);
    final away = MockData.teamById(widget.awayId);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          const BackBar(title: 'Playing', italic: 'XI'),
          Container(
            color: AppColors.cream,
            child: TabBar(
              controller: _tab,
              tabs: [
                Tab(text: '${home.shortCode} (${_homeXI.length}/11)'),
                Tab(text: '${away.shortCode} (${_awayXI.length}/11)'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _list(widget.homeId, _homeXI),
                _list(widget.awayId, _awayXI),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: 'Confirm Playing XI',
                onPressed: () => context.pop({
                  'homeXI': _homeXI.toList(),
                  'awayXI': _awayXI.toList(),
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(String teamId, Set<String> selected) {
    final players = [...MockData.playersByTeam(teamId)];
    if (players.isEmpty) {
      return Center(
        child: Text('No players in this squad', style: AppTextStyles.bodyLarge),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      itemCount: players.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final p = players[i];
        final isSel = selected.contains(p.id);
        final full = selected.length >= 11 && !isSel;
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: full
              ? null
              : () => setState(() {
                    if (isSel) {
                      selected.remove(p.id);
                    } else {
                      selected.add(p.id);
                    }
                  }),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSel ? AppColors.creamSoft : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isSel ? AppColors.navyDeep : AppColors.line,
                  width: isSel ? 1.4 : 1),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: isSel,
                  onChanged: full
                      ? null
                      : (_) => setState(() {
                            if (isSel) {
                              selected.remove(p.id);
                            } else {
                              selected.add(p.id);
                            }
                          }),
                  activeColor: AppColors.navyDeep,
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFF57F17), Color(0xFFE65100)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(p.initials,
                      style:
                          AppTextStyles.bebas(size: 12, color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.fullName,
                          style: AppTextStyles.fraunces(
                              size: 13, weight: FontWeight.w700)),
                      Text(
                        '${p.role.short} · ${p.battingHand == BattingHand.right ? 'RHB' : 'LHB'}${p.jerseyNumber != null ? ' · #${p.jerseyNumber}' : ''}',
                        style: AppTextStyles.mono(
                            size: 8,
                            color: AppColors.grey,
                            letterSpacing: 0.15),
                      ),
                    ],
                  ),
                ),
                if (isSel)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${selected.toList().indexOf(p.id) + 1}',
                        style: AppTextStyles.mono(
                          size: 8,
                          color: AppColors.navyDeep,
                          weight: FontWeight.w700,
                          letterSpacing: 0.15,
                        )),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
